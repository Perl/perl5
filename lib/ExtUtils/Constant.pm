package ExtUtils::Constant;

=head1 NAME

ExtUtils::Constant - generate XS code to import C header constants

=head1 SYNOPSIS

    use ExtUtils::Constant qw (constant_types C_constant XS_constant);
    print constant_types(); # macro defs
    foreach (C_constant (undef, "IV", undef, undef, undef, @names) ) {
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

=back

=head1 FUNCTIONS

=over 4

=cut

require 5.006; # I think, for [:cntrl:] in REGEXP
use warnings;
use strict;
use Carp;

use Exporter;
use vars qw (@ISA $VERSION %XS_Constant %XS_TypeSet @EXPORT_OK %EXPORT_TAGS);
use Text::Wrap;
$Text::Wrap::huge = 'overflow';
$Text::Wrap::columns = 80;

@ISA = 'Exporter';
$VERSION = '0.01';

%EXPORT_TAGS = ( 'all' => [ qw(
	XS_constant constant_types return_clause memEQ_clause C_stringify
	C_constant autoload
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

%XS_Constant = (
                IV => 'PUSHi(iv)',
                UV => 'PUSHu((UV)iv)',
                NV => 'PUSHn(nv)',
                PV => 'PUSHp(pv, strlen(pv))',
                PVN => 'PUSHp(pv, iv)'
);

%XS_TypeSet = (
                IV => '*iv_return =',
                UV => '*iv_return = (IV)',
                NV => '*nv_return =',
                PV => '*pv_return =',
                PVN => ['*pv_return =', '*iv_return = (IV)']
);


=item C_stringify NAME

A function which returns a correctly \ escaped version of the string passed
suitable for C's "" or ''

=cut

# Hopefully make a happy C identifier.
sub C_stringify {
  local $_ = shift;
  s/\\/\\\\/g;
  s/([\"\'])/\\$1/g;	# Grr. fix perl mode.
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

=item return_clause VALUE, TYPE, INDENT, MACRO

A function to return a suitable C<#ifdef> clause. I<MACRO> defaults to
I<VALUE> when not defined. If I<TYPE> is aggregate (eg I<PVN> expects both
pointer and length) then I<VALUE> should be a reference to an array of
values in the order expected by the type.

=cut

sub return_clause {
##ifdef thingy
#      *iv_return = thingy;
#      return PERL_constant_ISIV;
##else
#      return PERL_constant_NOTDEF;
##endif
  my ($value, $type, $indent, $macro) = @_;
  $macro = $value unless defined $macro;
  $indent = ' ' x ($indent || 6);

  die "Macro must not be a reference" if ref $macro;
  my $clause = "#ifdef $macro\n";

  my $typeset = $XS_TypeSet{$type};
  die "Can't generate code for type $type" unless defined $typeset;
  if (ref $typeset) {
    die "Type $type is aggregate, but only single value given"
      unless ref $value;
    foreach (0 .. $#$typeset) {
      $clause .= $indent . "$typeset->[$_] $value->[$_];\n";
    }
  } else {
    die "Aggregate value given for type $type"
      if ref $value;
    $clause .= $indent . "$typeset $value;\n";
  }
  return $clause . <<"EOT";
${indent}return PERL_constant_IS$type;
#else
${indent}return PERL_constant_NOTDEF;
#endif
EOT
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
  return ($use_iv, $use_nv, $use_pv);
}

=item C_constant SUBNAME, DEFAULT_TYPE, TYPES, INDENT, NAMELEN, ITEM...

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
I<name>, and is mainly used if I<value> is an C<enum>.

=back

The first 5 argument can safely be given as C<undef>, and are mainly used
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

I<NAMELEN> if defined signals that all the I<name>s of the I<ITEM>s are of
this length, and that the constant name passed in by perl is checked and
also of this length. It is used during recursion, and should be C<undef>
unless the caller has checked all the lengths during code generation, and
the generated subroutine is only to be called with a name of this length.

=cut

sub C_constant {
  my ($subname, $default_type, $what, $indent, $namelen, @items) = @_;
  $subname ||= 'constant';
  # I'm not using this. But a hashref could be used for full formatting without
  # breaking this API
  $indent ||= 0;
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
      $name = $_->{name};
      $what->{$_->{type} ||= $default_type} = 1;
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
  my ($use_iv, $use_nv, $use_pv) = params ($what);

  my ($body, @subs) = "static int\n$subname (const char *name";
  $body .= ", STRLEN len" unless defined $namelen;
  $body .= ", IV *iv_return" if $use_iv;
  $body .= ", NV *nv_return" if $use_nv;
  $body .= ", const char **pv_return" if $use_pv;
  $body .= ") {\n";

  my @names = sort map {$_->{name}} @items;
  my $names = << 'EOT'
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
EOT
  . wrap ("     ", "     ", join (" ", @names) . " */") . "\n";

  if (defined $namelen) {
    # We are a child subroutine.
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
    $body .= "  /* Names all of length $namelen.  */\n";
    $body .= $names;
    $body .= "  /* Offset $offset gives the best switch position.  */\n";
    $body .= "  switch (name[$offset]) {\n";
    foreach my $char (sort keys %$best) {
      $body .= "  case '" . C_stringify ($char) . "':\n";
      foreach my $name (sort @{$best->{$char}}) {
        my $thisone = $items{$name};
        my ($value, $macro) = (@$thisone{qw (value macro)});
        $value = $name unless defined $value;
        $macro = $name unless defined $macro;

        $body .= memEQ_clause ($name, $offset); # We have checked this offset.
        $body .= return_clause ($value, $thisone->{type}, undef, $macro);
        $body .= "    }\n";
      }
      $body .= "    break;\n";
    }
    $body .= "  }\n";
  } else {
    # We are the top level.
    $body .= "  /* Initially switch on the length of the name.  */\n";
    $body .= $names;
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
        my ($name, $value, $macro) = (@$thisone{qw (name value macro)});
        $value = $name unless defined $value;
        $macro = $name unless defined $macro;

        $body .= memEQ_clause ($name);
        $body .= return_clause ($value, $thisone->{type}, undef, $macro);
        $body .= "    }\n";
      } else {
        push @subs, C_constant ("${subname}_$i", $default_type, $what, $indent,
                                $i, @{$by_length[$i]});
        $body .= "    return ${subname}_$i (name";
        $body .= ", iv_return" if $use_iv;
        $body .= ", nv_return" if $use_nv;
        $body .= ", pv_return" if $use_pv;
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
  my ($use_iv, $use_nv, $use_pv) = params ($what);
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
  $xs .= ");\n";

  $xs .= << "EOT";
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid $package macro", s));
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined $package macro %s used", s));
          break;
EOT

  foreach $type (sort keys %XS_Constant) {
    $xs .= "\t/* Uncomment this if you need to return ${type}s\n"
      unless $what->{$type};
    $xs .= << "EOT";
        case PERL_constant_IS$type:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          $XS_Constant{$type};
          break;
EOT
    unless ($what->{$type}) {
      chop $xs; # Yes, another need for chop not chomp.
      $xs .= " */\n";
    }
  }
  $xs .= << "EOT";
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing $package macro %s used",
               type, s));
        }
EOT

  return $xs;
}


=item autoload PACKAGE, VERSION

A function to generate the AUTOLOAD subroutine for the module I<PACKAGE>
I<VERSION> is the perl version the code should be backwards compatible with.
It defaults to the version of perl running the subroutine.

=cut

sub autoload {
  my ($module, $compat_version) = @_;
  $compat_version ||= $];
  croak "Can't maintain compatibility back as far as version $compat_version"
    if $compat_version < 5;
  my $tmp = ( $compat_version < 5.006 ?  "" : "our \$AUTOLOAD;" );
  return <<"END";
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my \$constname;
    $tmp
    (\$constname = \$AUTOLOAD) =~ s/.*:://;
    croak "&${module}::constant not defined" if \$constname eq 'constant';
    my (\$error, \$val) = constant(\$constname);
    if (\$error) {
	if (\$error =~  /is not a valid/) {
	    \$AutoLoader::AUTOLOAD = \$AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak \$error;
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if (\$] >= 5.00561) {
#XXX	    *\$AUTOLOAD = sub () { \$val };
#XXX	}
#XXX	else {
	    *\$AUTOLOAD = sub { \$val };
#XXX	}
    }
    goto &\$AUTOLOAD;
}

END

}
1;
__END__

=back

=head1 AUTHOR

Nicholas Clark <nick@ccl4.org> based on the code in C<h2xs> by Larry Wall and
others

=cut
