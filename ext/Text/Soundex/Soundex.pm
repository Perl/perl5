# -*- perl -*-

# (c) Copyright 1998-2003 by Mark Mielke
#
# Freedom to use these sources for whatever you want, as long as credit
# is given where credit is due, is hereby granted. You may make modifications
# where you see fit but leave this copyright somewhere visible. As well, try
# to initial any changes you make so that if I like the changes I can
# incorporate them into later versions.
#
#      - Mark Mielke <mark@mielke.cc>
#

package Text::Soundex;
require 5.006;

use Exporter ();
use XSLoader ();

use strict;

our $VERSION   = '3.02';
our @EXPORT_OK = qw(soundex soundex_unicode soundex_nara soundex_nara_unicode
                    $soundex_nocode);
our @EXPORT    = qw(soundex $soundex_nocode);
our @ISA       = qw(Exporter);

our $nocode;

# Previous releases of Text::Soundex made $nocode available as $soundex_nocode.
# For now, this part of the interface is exported and maintained.
# In the feature, $soundex_nocode will be deprecated.
*Text::Soundex::soundex_nocode = \$nocode;

sub soundex_noxs
{
    # Strict implementation of Knuth's soundex algorithm.

    my @results = map {
        my $code = $_;
        $code =~ tr/AaEeHhIiOoUuWwYyBbFfPpVvCcGgJjKkQqSsXxZzDdTtLlMmNnRr//cd;

	if (length($code)) {
            my $firstchar = substr($code, 0, 1);
	    $code =~ tr[AaEeHhIiOoUuWwYyBbFfPpVvCcGgJjKkQqSsXxZzDdTtLlMmNnRr]
                       [0000000000000000111111112222222222222222333344555566]s;
	    ($code = substr($code, 1)) =~ tr/0//d;
	    substr($firstchar . $code . '000', 0, 4);
	} else {
	    $nocode;
	}
    } @_;

    wantarray ? @results : $results[0];
}

sub soundex_nara
{
    # Implementation of NARA's soundex algorithm. If two sounds are
    # identical, and separated by only an H or a W... they should be
    # treated as one. This requires an additional "s///", as well as
    # the "9" character code to represent H and W. ("9" works like "0"
    # except it combines indentical sounds around it into one)

    my @results = map {
	my $code = uc($_);
        $code =~ tr/AaEeHhIiOoUuWwYyBbFfPpVvCcGgJjKkQqSsXxZzDdTtLlMmNnRr//cd;

	if (length($code)) {
            my $firstchar = substr($code, 0, 1);
	    $code =~ tr[AaEeHhIiOoUuWwYyBbFfPpVvCcGgJjKkQqSsXxZzDdTtLlMmNnRr]
                       [0000990000009900111111112222222222222222333344555566]s;
            $code =~ s/(.)9\1/$1/g;
	    ($code = substr($code, 1)) =~ tr/09//d;
	    substr($firstchar . $code . '000', 0, 4);
	} else {
	    $nocode
	}
    } @_;

    wantarray ? @results : $results[0];
}

sub soundex_unicode
{
    require Text::Unidecode unless defined &Text::Unidecode::unidecode;
    soundex(Text::Unidecode::unidecode(@_));
}

sub soundex_nara_unicode
{
    require Text::Unidecode unless defined &Text::Unidecode::unidecode;
    soundex_nara(Text::Unidecode::unidecode(@_));
}

eval { XSLoader::load(__PACKAGE__, $VERSION) };

if (defined(&soundex_xs)) {
    *soundex = \&soundex_xs;
} else {
    *soundex = \&soundex_noxs;
    *soundex_xs = sub {
        require Carp;
        Carp::croak("XS implementation of Text::Soundex::soundex_xs() ".
                    "could not be loaded");
    };
}

1;

__END__

# Implementation of soundex algorithm as described by Knuth in volume
# 3 of The Art of Computer Programming.
#
# Some of this documention was written by Mike Stok.
#
# Knuth's test cases are:
#
# Euler, Ellery -> E460
# Gauss, Ghosh -> G200
# Hilbert, Heilbronn -> H416
# Knuth, Kant -> K530
# Lloyd, Ladd -> L300
# Lukasiewicz, Lissajous -> L222
#

=head1 NAME

Text::Soundex - Implementation of the Soundex Algorithm as Described by Knuth

=head1 SYNOPSIS

  use Text::Soundex 'soundex';

  $code = soundex($name);    # Get the soundex code for a name.
  @codes = soundex(@names);  # Get the list of codes for a list of names.

  # Redefine the value that soundex() will return if the input string
  # contains no identifiable sounds within it.
  $Text::Soundex::nocode = 'Z000';

=head1 DESCRIPTION

This module implements the soundex algorithm as described by Donald Knuth
in Volume 3 of B<The Art of Computer Programming>.  The algorithm is
intended to hash words (in particular surnames) into a small space
using a simple model which approximates the sound of the word when
spoken by an English speaker.  Each word is reduced to a four
character string, the first character being an upper case letter and
the remaining three being digits.

The value returned for strings which have no soundex encoding is
defined using C<$Text::Soundex::nocode>. The default value is C<undef>,
however values such as C<'Z000'> are commonly used alternatives.

For backward compatibility with older versions of this module the
C<$Text::Soundex::nocode> is exported into the caller's namespace as
C<$soundex_nocode>.

In scalar context, C<soundex()> returns the soundex code of its first
argument. In list context, a list is returned in which each element is the
soundex code for the corresponding argument passed to C<soundex()>. For
example, the following code assigns @codes the value C<('M200', 'S320')>:

  @codes = soundex qw(Mike Stok);

To use C<Text::Soundex> to generate codes that can be used to search one
of the publically available US Censuses, a variant of the soundex()
subroutine must be used:

    use Text::Soundex 'soundex_nara';
    $code = soundex_nara($name);

The algorithm used by the US Censuses is slightly different than that
defined by Knuth and others. The descrepancy shows up in names such as
"Ashcraft":

    use Text::Soundex qw(soundex soundex_nara);
    print soundex("Ashcraft"), "\n";       # prints: A226
    print soundex_nara("Ashcraft"), "\n";  # prints: A261

=head1 EXAMPLES

Knuth's examples of various names and the soundex codes they map to
are listed below:

  Euler, Ellery -> E460
  Gauss, Ghosh -> G200
  Hilbert, Heilbronn -> H416
  Knuth, Kant -> K530
  Lloyd, Ladd -> L300
  Lukasiewicz, Lissajous -> L222

so:

  $code = soundex 'Knuth';         # $code contains 'K530'
  @list = soundex qw(Lloyd Gauss); # @list contains 'L300', 'G200'

=head1 LIMITATIONS

As the soundex algorithm was originally used a B<long> time ago in the US
it considers only the English alphabet and pronunciation. In particular,
non-ASCII characters will be ignored. The recommended method of dealing
with characters that have accents, or other unicode characters, is to use
the Text::Unidecode module available from CPAN. Either use the module
explicitly:

    use Text::Soundex;
    use Text::Unidecode;

    print soundex(unidecode("Fran\xE7ais")), "\n"; # Prints "F652\n"

Or use the convenient wrapper routine:

    use Text::Soundex 'soundex_unicode';

    print soundex_unicode("Fran\xE7ais"), "\n";    # Prints "F652\n"

Since the soundex algorithm maps a large space (strings of arbitrary
length) onto a small space (single letter plus 3 digits) no inference
can be made about the similarity of two strings which end up with the
same soundex code.  For example, both C<Hilbert> and C<Heilbronn> end
up with a soundex code of C<H416>.

=head1 MAINTAINER

This module is currently maintain by Mark Mielke (C<mark@mielke.cc>).

=head1 HISTORY

Version 3 is a significant update to provide support for versions of
Perl later than Perl 5.004. Specifically, the XS version of the
soundex() subroutine understands strings that are encoded using UTF-8
(unicode strings).

Version 2 of this module was a re-write by Mark Mielke (C<mark@mielke.cc>)
to improve the speed of the subroutines. The XS version of the soundex()
subroutine was introduced in 2.00.

Version 1 of this module was written by Mike Stok (C<mike@stok.co.uk>)
and was included into the Perl core library set.

Dave Carlsen (C<dcarlsen@csranet.com>) made the request for the NARA
algorithm to be included. The NARA soundex page can be viewed at:
C<http://www.nara.gov/genealogy/soundex/soundex.html>

Ian Phillips (C<ian@pipex.net>) and Rich Pinder (C<rpinder@hsc.usc.edu>)
supplied ideas and spotted mistakes for v1.x.

=cut
