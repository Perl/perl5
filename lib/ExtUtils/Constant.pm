package ExtUtils::Constant;
use vars qw (@ISA $VERSION %XS_Constant %XS_TypeSet @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.06';

=head1 NAME

ExtUtils::Constant - generate XS code to import C header constants

=head1 SYNOPSIS

    use ExtUtils::Constant qw (constant_types C_constant XS_constant);
    print constant_types(); # macro defs
    foreach (C_constant ("Foo", undef, "IV", undef, undef, undef,
                         @names) ) {
	print $_, "\n"; # C constant subs
    }
    print "MODULE = Foo		PACKAGE = Foo\n";
    print XS_constant ("Foo", {NV => 1, IV => 1}); # XS for Foo::constant

=head1 DESCRIPTION

ExtUtils::Constant facilitates generating C and XS wrapper code to allow
perl modules to AUTOLOAD constants defined in C library header files.
It is principally used by the C<h2xs> utility, on which this code is based.
It doesn't contain the routines to scan header files to extract these
constants.

=head1 USAGE

Generally one only needs to call the 3 functions shown in the synopsis,
C<constant_types()>, C<C_constant> and C<XS_constant>.

Currently this module understands the following types. h2xs may only know
a subset. The sizes of the numeric types are chosen by the C<Configure>
script at compile time.

=over 4

=item IV

signed integer, at least 32 bits.

=item UV

unsigned integer, the same size as I<IV>

=item NV

floating point type, probably C<double>, possibly C<long double>

=item PV

NUL terminated string, length will be determined with C<strlen>

=item PVN

A fixed length thing, given as a [pointer, length] pair. If you know the
length of a string at compile time you may use this instead of I<PV>

=item PVN

A B<mortal> SV.

=item YES

Truth.  (C<PL_sv_yes>)  The value is not needed (and ignored).

=item NO

Defined Falsehood.  (C<PL_sv_no>)  The value is not needed (and ignored).

=item UNDEF

C<undef>.  The value of the macro is not needed.

=back

=head1 FUNCTIONS

=over 4

=cut

require 5.006; # I think, for [:cntrl:] in REGEXP
use warnings;
use strict;
use Carp;

use Exporter;
use Text::Wrap;
$Text::Wrap::huge = 'overflow';
$Text::Wrap::columns = 80;

@ISA = 'Exporter';

%EXPORT_TAGS = ( 'all' => [ qw(
	XS_constant constant_types return_clause memEQ_clause C_stringify
	C_constant autoload
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

%XS_Constant = (
		IV    => 'PUSHi(iv)',
		UV    => 'PUSHu((UV)iv)',
		NV    => 'PUSHn(nv)',
		PV    => 'PUSHp(pv, strlen(pv))',
		PVN   => 'PUSHp(pv, iv)',
		SV    => 'PUSHs(sv)',
		YES   => 'PUSHs(&PL_sv_yes)',
		NO    => 'PUSHs(&PL_sv_no)',
		UNDEF => '',	# implicit undef
);

%XS_TypeSet = (
		IV    => '*iv_return =',
		UV    => '*iv_return = (IV)',
		NV    => '*nv_return =',
		PV    => '*pv_return =',
		PVN   => ['*pv_return =', '*iv_return = (IV)'],
		SV    => '*sv_return = ',
		YES   => undef,
		NO    => undef,
		UNDEF => undef,
);


=item C_stringify NAME

A function which returns a correctly \ escaped version of the string passed
suitable for C's "" or ''.  It will also be valid as a perl "" string.

=cut

# Hopefully make a happy C identifier.
sub C_stringify {
  local $_ = shift;
  return unless defined $_;
  s/\\/\\\\/g;
  s/([\"\'])/\\$1/g;	# Grr. fix perl mode.
  s/\n/\\n/g;		# Ensure newlines don't end up in octal
  s/\r/\\r/g;
  s/\t/\\t/g;
  s/\f/\\f/g;
  s/\a/\\a/g;
  s/([[:cntrl:]])/sprintf "\\%03o", ord $1/ge;
  s/\177/\\177/g;	# DEL doesn't seem to be a [:cntrl:]
  $_;
}

=item constant_types

A function returning a single scalar with C<#define> definitions for the
constants used internally between the generated C and XS functions.

=cut

sub constant_types () {
  my $start = 1;
  my @lines;
  push @lines, "#define PERL_constant_NOTFOUND\t$start\n"; $start++;
  push @lines, "#define PERL_constant_NOTDEF\t$start\n"; $start++;
  foreach (sort keys %XS_Constant) {
    push @lines, "#define PERL_constant_IS$_\t$start\n"; $start++;
  }
  push @lines, << 'EOT';

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
EOT

  return join '', @lines;
}

=item memEQ_clause NAME, CHECKED_AT, INDENT

A function to return a suitable C C<if> statement to check whether I<NAME>
is equal to the C variable C<name>. If I<CHECKED_AT> is defined, then it
is used to avoid C<memEQ> for short names, or to generate a comment to
highlight the position of the character in the C<switch> statement.

=cut

sub memEQ_clause {
#    if (memEQ(name, "thingy", 6)) {
  # Which could actually be a character comparison or even ""
  my ($name, $checked_at, $indent) = @_;
  $indent = ' ' x ($indent || 4);
  my $len = length $name;

  if ($len < 2) {
    return $indent . "{\n" if (defined $checked_at and $checked_at == 0);
    # We didn't switch, drop through to the code for the 2 character string
    $checked_at = 1;
  }
  if ($len < 3 and defined $checked_at) {
    my $check;
    if ($checked_at == 1) {
      $check = 0;
    } elsif ($checked_at == 0) {
      $check = 1;
    }
    if (defined $check) {
      my $char = C_stringify (substr $name, $check, 1);
      return $indent . "if (name[$check] == '$char') {\n";
    }
  }
  # Could optimise a memEQ on 3 to 2 single character checks here
  $name = C_stringify ($name);
  my $body = $indent . "if (memEQ(name, \"$name\", $len)) {\n";
    $body .= $indent . "/*               ". (' ' x $checked_at) . '^'
      . (' ' x ($len - $checked_at + length $len)) . "    */\n"
        if defined $checked_at;
  return $body;
}

=item assign INDENT, TYPE, PRE, POST, VALUE...

A function to return a suitable assignment clause. If I<TYPE> is aggregate
(eg I<PVN> expects both pointer and length) then there should be multiple
I<VALUE>s for the components. I<PRE> and I<POST> if defined give snippets
of C code to preceed and follow the assignment. I<PRE> will be at the start
of a block, so variables may be defined in it.

=cut

# Hmm. value undef to to NOTDEF? value () to do NOTFOUND?

sub assign {
  my $indent = shift;
  my $type = shift;
  my $pre = shift;
  my $post = shift || '';
  my $clause;
  my $close;
  if ($pre) {
    chomp $pre;
    $clause = $indent . "{\n$pre";
    $clause .= ";" unless $pre =~ /;$/;
    $clause .= "\n";
    $close = "$indent}\n";
    $indent .= "  ";
  }
  die "Can't generate code for type $type" unless exists $XS_TypeSet{$type};
  my $typeset = $XS_TypeSet{$type};
  if (ref $typeset) {
    die "Type $type is aggregate, but only single value given"
      if @_ == 1;
    foreach (0 .. $#$typeset) {
      $clause .= $indent . "$typeset->[$_] $_[$_];\n";
    }
  } elsif (defined $typeset) {
    die "Aggregate value given for type $type"
      if @_ > 1;
    $clause .= $indent . "$typeset $_[0];\n";
  }
  chomp $post;
  if (length $post) {
    $clause .= "$post";
    $clause .= ";" unless $post =~ /;$/;
    $clause .= "\n";
  }    
  $clause .= "${indent}return PERL_constant_IS$type;\n";
  $clause .= $close if $close;
  return $clause;
}

=item return_clause VALUE, TYPE, INDENT, MACRO, DEFAULT, PRE, POST, PRE, POST

A function to return a suitable C<#ifdef> clause. I<MACRO> defaults to
I<VALUE> when not defined.  If I<TYPE> is aggregate (eg I<PVN> expects both
pointer and length) then I<VALUE> should be a reference to an array of
values in the order expected by the type.  C<C_constant> will always call
this function with I<MACRO> defined, defaulting to the constant's name.
I<DEFAULT> if defined is an array reference giving default type and and
value(s) if the clause generated by I<MACRO> doesn't evaluate to true.
The two pairs I<PRE> and I<POST> if defined give C code snippets to proceed
and follow the value, and the default value.

=cut

sub return_clause ($$$$$$$$$) {
##ifdef thingy
#      *iv_return = thingy;
#      return PERL_constant_ISIV;
##else
#      return PERL_constant_NOTDEF;
##endif
  my ($value, $type, $indent, $macro, $default, $pre, $post,
      $def_pre, $def_post) = @_;
  $macro = $value unless defined $macro;
  $indent = ' ' x ($indent || 6);

  my $clause;

  ##ifdef thingy
  if (ref $macro) {
    $clause = $macro->[0];
  } else {
    $clause = "#ifdef $macro\n";
  }

  #      *iv_return = thingy;
  #      return PERL_constant_ISIV;
  $clause .= assign ($indent, $type, $pre, $post,
                     ref $value ? @$value : $value);

  ##else
  $clause .= "#else\n";
  
  #      return PERL_constant_NOTDEF;
  if (!defined $default) {
    $clause .= "${indent}return PERL_constant_NOTDEF;\n";
  } else {
    my @default = ref $default ? @$default : $default;
    $type = shift @default;
    $clause .= assign ($indent, $type, $def_pre, $def_post, @default);
  }

  ##endif
  if (ref $macro) {
    $clause .= $macro->[1];
  } else {
    $clause .= "#endif\n";
  }
  return $clause
}

=item switch_clause INDENT, NAMELEN, ITEMHASH, ITEM...

An internal function to generate a suitable C<switch> clause, called by
C<C_constant> I<ITEM>s are in the hash ref format as given in the description
of C<C_constant>, and must all have the names of the same length, given by
I<NAMELEN> (This is not checked).  I<ITEMHASH> is a reference to a hash,
keyed by name, values being the hashrefs in the I<ITEM> list.
(No parameters are modified, and there can be keys in the I<ITEMHASH> that
are not in the list of I<ITEM>s without causing problems).

=cut

sub switch_clause {
  my ($indent, $comment, $namelen, $items, @items) = @_;
  $indent = ' ' x ($indent || 2);
  
  my @names = sort map {$_->{name}} @items;
  my $leader = $indent . '/* ';
  my $follower = ' ' x length $leader;
  my $body = $indent . "/* Names all of length $namelen.  */\n";
  if ($comment) {
    $body = wrap ($leader, $follower, $comment) . "\n";
    $leader = $follower;
  }
  $body .= wrap ($leader, $follower, join (" ", @names) . " */") . "\n";
  # Figure out what to switch on.
  # (RMS, Spread of jump table, Position, Hashref)
  my @best = (1e38, ~0);
  foreach my $i (0 .. ($namelen - 1)) {
    my ($min, $max) = (~0, 0);
    my %spread;
    foreach (@names) {
      my $char = substr $_, $i, 1;
      my $ord = ord $char;
      $max = $ord if $ord > $max; 
      $min = $ord if $ord < $min;
      push @{$spread{$char}}, $_;
      # warn "$_ $char";
    }
    # I'm going to pick the character to split on that minimises the root
    # mean square of the number of names in each case. Normally this should
    # be the one with the most keys, but it may pick a 7 where the 8 has
    # one long linear search. I'm not sure if RMS or just sum of squares is
    # actually better.
    # $max and $min are for the tie-breaker if the root mean squares match.
    # Assuming that the compiler may be building a jump table for the
    # switch() then try to minimise the size of that jump table.
    # Finally use < not <= so that if it still ties the earliest part of
    # the string wins. Because if that passes but the memEQ fails, it may
    # only need the start of the string to bin the choice.
    # I think. But I'm micro-optimising. :-)
    my $ss;
    $ss += @$_ * @$_ foreach values %spread;
    my $rms = sqrt ($ss / keys %spread);
    if ($rms < $best[0] || ($rms == $best[0] && ($max - $min) < $best[1])) {
      @best = ($rms, $max - $min, $i, \%spread);
    }
  }
  die "Internal error. Failed to pick a switch point for @names"
    unless defined $best[2];
  # use Data::Dumper; print Dumper (@best);
  my ($offset, $best) = @best[2,3];
  $body .= $indent . "/* Offset $offset gives the best switch position.  */\n";
  $body .= $indent . "switch (name[$offset]) {\n";
  foreach my $char (sort keys %$best) {
    $body .= $indent . "case '" . C_stringify ($char) . "':\n";
    foreach my $name (sort @{$best->{$char}}) {
      my $thisone = $items->{$name};
      my ($value, $macro, $default, $pre, $post, $def_pre, $def_post)
        = @$thisone{qw (value macro default pre post def_pre def_post)};
      $value = $name unless defined $value;
      $macro = $name unless defined $macro;

      # We have checked this offset.
      $body .= memEQ_clause ($name, $offset, 2 + length $indent);
      $body .= return_clause ($value, $thisone->{type},  4 + length $indent,
                              $macro, $default, $pre, $post,
                              $def_pre, $def_post);
      $body .= $indent . "  }\n";
    }
    $body .= $indent . "  break;\n";
  }
  $body .= $indent . "}\n";
  return $body;
}

=item params WHAT

An internal function. I<WHAT> should be a hashref of types the constant
function will return. I<params> returns the list of flags C<$use_iv, $use_nv,
$use_pv> to show which combination of pointers will be needed in the C
argument list.

=cut

sub params {
  my $what = shift;
  foreach (sort keys %$what) {
    warn "ExtUtils::Constant doesn't know how to handle values of type $_" unless defined $XS_Constant{$_};
  }
  my $use_iv = $what->{IV} || $what->{UV} || $what->{PVN};
  my $use_nv = $what->{NV};
  my $use_pv = $what->{PV} || $what->{PVN};
  my $use_sv = $what->{SV};
  return ($use_iv, $use_nv, $use_pv, $use_sv);
}

=item dump_names  

dump_names  PACKAGE, SUBNAME, DEFAULT_TYPE, TYPES, INDENT, BREAKOUT, ITEM...

An internal function to generate the embedded perl code that will regenerate
the constant subroutines.  Parameters are the same as for C_constant.

=cut

sub dump_names {
  my ($package, $subname, $default_type, $what, $indent, $breakout, @items)
    = @_;
  my (@simple, @complex);
  foreach (@items) {
    my $type = $_->{type} || $default_type;
    if ($type eq $default_type and 0 == ($_->{name} =~ tr/A-Za-z0-9_//c)
        and !defined ($_->{macro}) and !defined ($_->{value})
        and !defined ($_->{default}) and !defined ($_->{pre})
        and !defined ($_->{post}) and !defined ($_->{def_pre})
        and !defined ($_->{def_post})) {
      # It's the default type, and the name consists only of A-Za-z0-9_
      push @simple, $_->{name};
    } else {
      push @complex, $_;
    }
  }
  my $result = <<"EOT";
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!$^X -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

EOT
  $result .= 'my $types = {map {($_, 1)} qw(' . join (" ", sort keys %$what)
    . ")};\n";
  $result .= wrap ("my \@names = (qw(",
		   "               ", join (" ", sort @simple) . ")");
  if (@complex) {
    foreach my $item (sort {$a->{name} cmp $b->{name}} @complex) {
      my $name = C_stringify $item->{name};
      my $line = ",\n            {name=>\"$name\"";
      $line .= ", type=>\"$item->{type}\"" if defined $item->{type};
      foreach my $thing (qw (macro value default pre post def_pre def_post)) {
        my $value = $item->{$thing};
        if (defined $value) {
          if (ref $value) {
            $line .= ", $thing=>[\""
              . join ('", "', map {C_stringify $_} @$value) . '"]';
          } else {
            $line .= ", $thing=>\"" . C_stringify($value) . "\"";
          }
        }
      }
      $line .= "}";
      # Ensure that the enclosing C comment doesn't end
      # by turning */  into *" . "/
      $line =~ s!\*\/!\*" . "/!gs;
      # gcc -Wall doesn't like finding /* inside a comment
      $line =~ s!\/\*!/" . "\*!gs;
      $result .= $line;
    }
  }
  $result .= ");\n";

  $result .= <<'EOT';

print constant_types(); # macro defs
EOT
  $package = C_stringify($package);
  $result .=
    "foreach (C_constant (\"$package\", '$subname', '$default_type', \$types, ";
  # The form of the indent parameter isn't defined. (Yet)
  if (defined $indent) {
    require Data::Dumper;
    $Data::Dumper::Terse=1;
    $Data::Dumper::Terse=1; # Not used once. :-)
    chomp ($indent = Data::Dumper::Dumper ($indent));
    $result .= $indent;
  } else {
    $result .= 'undef';
  }
  $result .= ", $breakout" . ', @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("' . $package . '", $types);
__END__
   */

';
  
  $result;
}

=item C_constant 

C_constant PACKAGE, SUBNAME, DEFAULT_TYPE, TYPES, INDENT, BREAKOUT, ITEM...

A function that returns a B<list> of C subroutine definitions that return
the value and type of constants when passed the name by the XS wrapper.
I<ITEM...> gives a list of constant names. Each can either be a string,
which is taken as a C macro name, or a reference to a hash with the following
keys

=over 8

=item name

The name of the constant, as seen by the perl code.

=item type

The type of the constant (I<IV>, I<NV> etc)

=item value

A C expression for the value of the constant, or a list of C expressions if
the type is aggregate. This defaults to the I<name> if not given.

=item macro

The C pre-processor macro to use in the C<#ifdef>. This defaults to the
I<name>, and is mainly used if I<value> is an C<enum>. If a reference an
array is passed then the first element is used in place of the C<#ifdef>
line, and the second element in place of the C<#endif>. This allows
pre-processor constructions such as

    #if defined (foo)
    #if !defined (bar)
    ...
    #endif
    #endif

to be used to determine if a constant is to be defined.

=item default

Default value to use (instead of C<croak>ing with "your vendor has not
defined...") to return if the macro isn't defined. Specify a reference to
an array with type followed by value(s).

=item pre

C code to use before the assignment of the value of the constant. This allows
you to use temporary variables to extract a value from part of a C<struct>
and return this as I<value>. This C code is places at the start of a block,
so you can declare variables in it.

=item post

C code to place between the assignment of value (to a temporary) and the
return from the function. This allows you to clear up anything in I<pre>.
Rarely needed.

=item def_pre
=item def_post

Equivalents of I<pre> and I<post> for the default value.

=back

I<PACKAGE> is the name of the package, and is only used in comments inside the
generated C code.

The next 5 arguments can safely be given as C<undef>, and are mainly used
for recursion. I<SUBNAME> defaults to C<constant> if undefined.

I<DEFAULT_TYPE> is the type returned by C<ITEM>s that don't specify their
type. In turn it defaults to I<IV>. I<TYPES> should be given either as a comma
separated list of types that the C subroutine C<constant> will generate or as
a reference to a hash. I<DEFAULT_TYPE> will be added to the list if not
present, as will any types given in the list of I<ITEM>s. The resultant list
should be the same list of types that C<XS_constant> is given. [Otherwise
C<XS_constant> and C<C_constant> may differ in the number of parameters to the
constant function. I<INDENT> is currently unused and ignored. In future it may
be used to pass in information used to change the C indentation style used.]
The best way to maintain consistency is to pass in a hash reference and let
this function update it.

I<BREAKOUT> governs when child functions of I<SUBNAME> are generated.  If there
are I<BREAKOUT> or more I<ITEM>s with the same length of name, then the code
to switch between them is placed into a function named I<SUBNAME>_I<LEN>, for
example C<constant_5> for names 5 characters long.  The default I<BREAKOUT> is
3.  A single C<ITEM> is always inlined.

=cut

# The parameter now BREAKOUT was previously documented as:
#
# I<NAMELEN> if defined signals that all the I<name>s of the I<ITEM>s are of
# this length, and that the constant name passed in by perl is checked and
# also of this length. It is used during recursion, and should be C<undef>
# unless the caller has checked all the lengths during code generation, and
# the generated subroutine is only to be called with a name of this length.
#
# As you can see it now performs this function during recursion by being a
# scalar reference.

sub C_constant {
  my ($package, $subname, $default_type, $what, $indent, $breakout, @items)
    = @_;
  my $namelen;
  if (ref $breakout) {
    $namelen = $$breakout;
  } else {
    $breakout ||= 3;
  }
  $package ||= 'Foo';
  $subname ||= 'constant';
  # I'm not using this. But a hashref could be used for full formatting without
  # breaking this API
  # $indent ||= 0;
   $default_type ||= 'IV';
  if (!ref $what) {
    # Convert line of the form IV,UV,NV to hash
    $what = {map {$_ => 1} split /,\s*/, ($what || '')};
    # Figure out what types we're dealing with, and assign all unknowns to the
    # default type
  }
  my %items;
  foreach (@items) {
    my $name;
    if (ref $_) {
      my $orig = $_;
      # Make a copy which is a normalised version of the ref passed in.
      $name = $_->{name};
      my ($type, $macro, $value) = @$_{qw (type macro value)};
      $type ||= $default_type;
      $what->{$type} = 1;
      $_ = {name=>$name, type=>$type};

      undef $macro if defined $macro and $macro eq $name;
      $_->{macro} = $macro if defined $macro;
      undef $value if defined $value and $value eq $name;
      $_->{value} = $value if defined $value;
      foreach my $key (qw(default pre post def_pre def_post)) {
        my $value = $orig->{$key};
        $_->{$key} = $value if defined $value;
        # warn "$key $value";
      }
    } else {
      $name = $_;
      $_ = {name=>$_, type=>$default_type};
      $what->{$default_type} = 1;
    }
    warn "ExtUtils::Constant doesn't know how to handle values of type $_ used in macro $name" unless defined $XS_Constant{$_->{type}};
    if (exists $items{$name}) {
      die "Multiple definitions for macro $name";
    }
    $items{$name} = $_;
  }
  my ($use_iv, $use_nv, $use_pv, $use_sv) = params ($what);

  my ($body, @subs) = "static int\n$subname (const char *name";
  $body .= ", STRLEN len" unless defined $namelen;
  $body .= ", IV *iv_return" if $use_iv;
  $body .= ", NV *nv_return" if $use_nv;
  $body .= ", const char **pv_return" if $use_pv;
  $body .= ", SV **sv_return" if $use_sv;
  $body .= ") {\n";

  if (defined $namelen) {
    # We are a child subroutine. Print the simple description
    my $comment = 'When generated this function returned values for the list'
      . ' of names given here.  However, subsequent manual editing may have'
        . ' added or removed some.';
    $body .= switch_clause (2, $comment, $namelen, \%items, @items);
  } else {
    # We are the top level.
    $body .= "  /* Initially switch on the length of the name.  */\n";
    $body .= dump_names ($package, $subname, $default_type, $what, $indent,
                         $breakout, @items);
    $body .= "  switch (len) {\n";
    # Need to group names of the same length
    my @by_length;
    foreach (@items) {
      push @{$by_length[length $_->{name}]}, $_;
    }
    foreach my $i (0 .. $#by_length) {
      next unless $by_length[$i];	# None of this length
      $body .= "  case $i:\n";
      if (@{$by_length[$i]} == 1) {
        my $thisone = $by_length[$i]->[0];
        my ($name, $value, $macro, $default, $pre, $post, $def_pre, $def_post)
          = @$thisone{qw (name value macro default pre post def_pre def_post)};
        $value = $name unless defined $value;
        $macro = $name unless defined $macro;

        $body .= memEQ_clause ($name);
        $body .= return_clause ($value, $thisone->{type}, undef, $macro,
                                $default, $pre, $post, $def_pre, $def_post);
        $body .= "    }\n";
      } elsif (@{$by_length[$i]} < $breakout) {
        $body .= switch_clause (4, '', $i, \%items, @{$by_length[$i]});
      } else {
        push @subs, C_constant ($package, "${subname}_$i", $default_type,
                                $what, $indent, \$i, @{$by_length[$i]});
        $body .= "    return ${subname}_$i (name";
        $body .= ", iv_return" if $use_iv;
        $body .= ", nv_return" if $use_nv;
        $body .= ", pv_return" if $use_pv;
        $body .= ", sv_return" if $use_sv;
        $body .= ");\n";
      }
      $body .= "    break;\n";
    }
    $body .= "  }\n";
  }
  $body .= "  return PERL_constant_NOTFOUND;\n}\n";
  return (@subs, $body);
}

=item XS_constant PACKAGE, TYPES, SUBNAME, C_SUBNAME

A function to generate the XS code to implement the perl subroutine
I<PACKAGE>::constant used by I<PACKAGE>::AUTOLOAD to load constants.
This XS code is a wrapper around a C subroutine usually generated by
C<C_constant>, and usually named C<constant>.

I<TYPES> should be given either as a comma separated list of types that the
C subroutine C<constant> will generate or as a reference to a hash. It should
be the same list of types as C<C_constant> was given.
[Otherwise C<XS_constant> and C<C_constant> may have different ideas about
the number of parameters passed to the C function C<constant>]

You can call the perl visible subroutine something other than C<constant> if
you give the parameter I<SUBNAME>. The C subroutine it calls defaults to the
the name of the perl visible subroutine, unless you give the parameter
I<C_SUBNAME>.

=cut

sub XS_constant {
  my $package = shift;
  my $what = shift;
  my $subname = shift;
  my $C_subname = shift;
  $subname ||= 'constant';
  $C_subname ||= $subname;

  if (!ref $what) {
    # Convert line of the form IV,UV,NV to hash
    $what = {map {$_ => 1} split /,\s*/, ($what)};
  }
  my ($use_iv, $use_nv, $use_pv, $use_sv) = params ($what);
  my $type;

  my $xs = <<"EOT";
void
$subname(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
EOT

  if ($use_iv) {
    $xs .= "	IV		iv;\n";
  } else {
    $xs .= "	/* IV\t\tiv;\tUncomment this if you need to return IVs */\n";
  }
  if ($use_nv) {
    $xs .= "	NV		nv;\n";
  } else {
    $xs .= "	/* NV\t\tnv;\tUncomment this if you need to return NVs */\n";
  }
  if ($use_pv) {
    $xs .= "	const char	*pv;\n";
  } else {
    $xs .=
      "	/* const char\t*pv;\tUncomment this if you need to return PVs */\n";
  }

  $xs .= << 'EOT';
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
EOT

  if ($use_iv xor $use_nv) {
    $xs .= << "EOT";
        /* Change this to $C_subname(s, len, &iv, &nv);
           if you need to return both NVs and IVs */
EOT
  }
  $xs .= "	type = $C_subname(s, len";
  $xs .= ', &iv' if $use_iv;
  $xs .= ', &nv' if $use_nv;
  $xs .= ', &pv' if $use_pv;
  $xs .= ', &sv' if $use_sv;
  $xs .= ");\n";

  $xs .= << "EOT";
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid $package macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined $package macro %s, used", s));
          PUSHs(sv);
          break;
EOT

  foreach $type (sort keys %XS_Constant) {
    $xs .= "\t/* Uncomment this if you need to return ${type}s\n"
      unless $what->{$type};
    $xs .= "        case PERL_constant_IS$type:\n";
    if (length $XS_Constant{$type}) {
      $xs .= << "EOT";
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          $XS_Constant{$type};
EOT
    } else {
      # Do nothing. return (), which will be correctly interpreted as
      # (undef, undef)
    }
    $xs .= "          break;\n";
    unless ($what->{$type}) {
      chop $xs; # Yes, another need for chop not chomp.
      $xs .= " */\n";
    }
  }
  $xs .= << "EOT";
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing $package macro %s, used",
               type, s));
          PUSHs(sv);
        }
EOT

  return $xs;
}


=item autoload PACKAGE, VERSION, AUTOLOADER

A function to generate the AUTOLOAD subroutine for the module I<PACKAGE>
I<VERSION> is the perl version the code should be backwards compatible with.
It defaults to the version of perl running the subroutine.  If I<AUTOLOADER>
is true, the AUTOLOAD subroutine falls back on AutoLoader::AUTOLOAD for all
names that the constant() routine doesn't recognise.

=cut

# ' # Grr. syntax highlighters that don't grok pod.

sub autoload {
  my ($module, $compat_version, $autoloader) = @_;
  $compat_version ||= $];
  croak "Can't maintain compatibility back as far as version $compat_version"
    if $compat_version < 5;
  my $func = "sub AUTOLOAD {\n"
  . "    # This AUTOLOAD is used to 'autoload' constants from the constant()\n"
  . "    # XS function.";
  $func .= "  If a constant is not found then control is passed\n"
  . "    # to the AUTOLOAD in AutoLoader." if $autoloader;


  $func .= "\n\n"
  . "    my \$constname;\n";
  $func .= 
    "    our \$AUTOLOAD;\n"  if ($compat_version >= 5.006);

  $func .= <<"EOT";
    (\$constname = \$AUTOLOAD) =~ s/.*:://;
    croak "&${module}::constant not defined" if \$constname eq 'constant';
    my (\$error, \$val) = constant(\$constname);
EOT

  if ($autoloader) {
    $func .= <<'EOT';
    if ($error) {
	if ($error =~  /is not a valid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak $error;
	}
    }
EOT
  } else {
    $func .=
      "    if (\$error) { croak \$error; }\n";
  }

  $func .= <<'END';
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

END

  return $func;
}
1;
__END__

=back

=head1 AUTHOR

Nicholas Clark <nick@ccl4.org> based on the code in C<h2xs> by Larry Wall and
others

=cut
