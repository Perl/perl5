package charnames;
use strict;
use warnings;
use Carp;
our $VERSION = '1.01';

use bytes ();		# for $bytes::hint_bits
$charnames::hint_bits = 0x20000;

my $txt;

# This is not optimized in any way yet
sub charnames
{
  my $name = shift;

  ## Suck in the code/name list as a big string.
  ## Lines look like:
  ##     "0052\t\tLATIN CAPITAL LETTER R\n"
  $txt = do "unicore/Name.pl" unless $txt;

  ## @off will hold the index into the code/name string of the start and
  ## end of the name as we find it.
  my @off;

  ## If :full, look for the the name exactly
  if ($^H{charnames_full} and $txt =~ /\t\t$name$/m) {
    @off = ($-[0], $+[0]);
  }

  ## If we didn't get above, and :short allowed, look for the short name.
  ## The short name is like "greek:Sigma"
  unless (@off) {
    if ($^H{charnames_short} and $name =~ /^(.+?):(.+)/s) {
      my ($script, $cname) = ($1,$2);
      my $case = ( $cname =~ /[[:upper:]]/ ? "CAPITAL" : "SMALL");
      if ($txt =~ m/\t\t\U$script\E (?:$case )?LETTER \U$cname$/m) {
	@off = ($-[0], $+[0]);
      }
    }
  }

  ## If we still don't have it, check for the name among the loaded
  ## scripts.
  if (not @off)
  {
      my $case = ( $name =~ /[[:upper:]]/ ? "CAPITAL" : "SMALL");
      for my $script ( @{$^H{charnames_scripts}} )
      {
          if ($txt =~ m/\t\t$script (?:$case )?LETTER \U$name$/m) {
              @off = ($-[0], $+[0]);
              last;
          }
      }
  }

  ## If we don't have it by now, give up.
  die "Unknown charname '$name'" unless @off;

  ##
  ## Now know where in the string the name starts.
  ## The code, in hex, is befor that.
  ##
  ## The code can be 4-6 characters long, so we've got to sort of
  ## go look for it, just after the newline that comes before $off[0].
  ##
  ## This would be much easier if unicore/Name.pl had info in
  ## a name/code order, instead of code/name order.
  ##
  ## The +1 after the rindex() is to skip past the newline we're finding,
  ## or, if the rindex() fails, to put us to an offset of zero.
  ##
  my $hexstart = rindex($txt, "\n", $off[0]) + 1;

  ## we know where it starts, so turn into number - the ordinal for the char.
  my $ord = hex substr($txt, $hexstart, $off[0] - $hexstart);

  if ($^H & $bytes::hint_bits) {	# "use bytes" in effect?
    use bytes;
    return chr $ord if $ord <= 255;
    my $hex = sprintf '%X=0%o', $ord, $ord;
    my $fname = substr $txt, $off[0] + 2, $off[1] - $off[0] - 2;
    die "Character 0x$hex with name '$fname' is above 0xFF";
  }
  return pack "U", $ord;
}

sub import
{
  shift; ## ignore class name

  if (not @_)
  {
      carp("`use charnames' needs explicit imports list");
  }
  $^H |= $charnames::hint_bits;
  $^H{charnames} = \&charnames ;

  ##
  ## fill %h keys with our @_ args.
  ##
  my %h;
  @h{@_} = (1) x @_;

  $^H{charnames_full} = delete $h{':full'};
  $^H{charnames_short} = delete $h{':short'};
  $^H{charnames_scripts} = [map uc, keys %h];

  ##
  ## If utf8? warnings are enabled, and some scripts were given,
  ## see if at least we can find one letter of each script.
  ##
  if (warnings::enabled('utf8') && @{$^H{charnames_scripts}})
  {
      $txt = do "unicore/Name.pl" unless $txt;

      for my $script (@{$^H{charnames_scripts}})
      {
          if (not $txt =~ m/\t\t$script (?:CAPITAL |SMALL )?LETTER /) {
              warnings::warn('utf8',  "No such script: '$script'");
          }
      }
  }
}

my %viacode;

sub viacode
{
    if (@_ != 1) {
        carp "charnames::viacode() expects one numeric argument";
        return ()
    }
    my $arg = shift;

    my $hex;
    if ($arg =~ m/^[0-9]+$/) {
        $hex = sprintf "%04X", $arg;
    } else {
        carp("unexpected arg \"$arg\" to charnames::viacode()");
        return;
    }

    return $viacode{$hex} if exists $viacode{$hex};

    $txt = do "unicore/Name.pl" unless $txt;

    if ($txt =~ m/^$hex\t\t(.+)/m) {
        return $viacode{$hex} = $1;
    } else {
        return;
    }
}

my %vianame;

sub vianame
{
    if (@_ != 1) {
        carp "charnames::vianame() expects one name argument";
        return ()
    }

    my $arg = shift;

    return $vianame{$arg} if exists $vianame{$arg};

    $txt = do "unicore/Name.pl" unless $txt;

    if ($txt =~ m/^([0-9A-F]+)\t\t($arg)/m) {
        return $vianame{$arg} = hex $1;
    } else {
        return;
    }
}


1;
__END__

=head1 NAME

charnames - define character names for C<\N{named}> string literal escapes.

=head1 SYNOPSIS

  use charnames ':full';
  print "\N{GREEK SMALL LETTER SIGMA} is called sigma.\n";

  use charnames ':short';
  print "\N{greek:Sigma} is an upper-case sigma.\n";

  use charnames qw(cyrillic greek);
  print "\N{sigma} is Greek sigma, and \N{be} is Cyrillic b.\n";

  print charname::viacode(0x1234); # prints "ETHIOPIC SYLLABLE SEE"
  printf "%04X", charname::vianame("GOTHIC LETTER AHSA"); # prints "10330"

=head1 DESCRIPTION

Pragma C<use charnames> supports arguments C<:full>, C<:short> and
script names.  If C<:full> is present, for expansion of
C<\N{CHARNAME}}> string C<CHARNAME> is first looked in the list of
standard Unicode names of chars.  If C<:short> is present, and
C<CHARNAME> has the form C<SCRIPT:CNAME>, then C<CNAME> is looked up
as a letter in script C<SCRIPT>.  If pragma C<use charnames> is used
with script name arguments, then for C<\N{CHARNAME}}> the name
C<CHARNAME> is looked up as a letter in the given scripts (in the
specified order).

For lookup of C<CHARNAME> inside a given script C<SCRIPTNAME>
this pragma looks for the names

  SCRIPTNAME CAPITAL LETTER CHARNAME
  SCRIPTNAME SMALL LETTER CHARNAME
  SCRIPTNAME LETTER CHARNAME

in the table of standard Unicode names.  If C<CHARNAME> is lowercase,
then the C<CAPITAL> variant is ignored, otherwise the C<SMALL> variant
is ignored.

Note that C<\N{...}> is compile-time, it's a special form of string
constant used inside double-quoted strings: in other words, you cannot
use variables inside the C<\N{...}>.  If you want similar run-time
functionality, use charnames::vianame().

=head1 CUSTOM TRANSLATORS

The mechanism of translation of C<\N{...}> escapes is general and not
hardwired into F<charnames.pm>.  A module can install custom
translations (inside the scope which C<use>s the module) with the
following magic incantation:

    use charnames ();		# for $charnames::hint_bits
    sub import {
	shift;
	$^H |= $charnames::hint_bits;
	$^H{charnames} = \&translator;
    }

Here translator() is a subroutine which takes C<CHARNAME> as an
argument, and returns text to insert into the string instead of the
C<\N{CHARNAME}> escape.  Since the text to insert should be different
in C<bytes> mode and out of it, the function should check the current
state of C<bytes>-flag as in:

    use bytes ();			# for $bytes::hint_bits
    sub translator {
	if ($^H & $bytes::hint_bits) {
	    return bytes_translator(@_);
	}
	else {
	    return utf8_translator(@_);
	}
    }

=head1 charnames::viacode(code)

Returns the full name of the character indicated by the numeric code.
The example

    print charnames::viacode(0x2722);

prints "FOUR TEARDROP-SPOKED ASTERISK".

Returns undef if no name is known for the code.

This works only for the standard names, and does not yet aply 
to custom translators.

=head1 charnames::vianame(code)

Returns the code point indicated by the name.
The example

    printf "%04X", charnames::vianame("FOUR TEARDROP-SPOKED ASTERISK");

prints "2722".

Returns undef if no name is known for the name.

This works only for the standard names, and does not yet aply 
to custom translators.

=head1 BUGS

Since evaluation of the translation function happens in a middle of
compilation (of a string literal), the translation function should not
do any C<eval>s or C<require>s.  This restriction should be lifted in
a future version of Perl.

=cut
