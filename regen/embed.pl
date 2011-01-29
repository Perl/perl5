#!/usr/bin/perl -w
# 
# Regenerate (overwriting only if changed):
#
#    embed.h
#    embedvar.h
#    global.sym
#    perlapi.c
#    perlapi.h
#    proto.h
#
# from information stored in
#
#    embed.fnc
#    intrpvar.h
#    perlvars.h
#    regen/opcodes
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.

require 5.004;	# keep this compatible, an old perl is all we may have before
                # we build the new one

use strict;

BEGIN {
    # Get function prototypes
    require 'regen/regen_lib.pl';
}

my $SPLINT = 0; # Turn true for experimental splint support http://www.splint.org
my $unflagged_pointers;

#
# See database of global and static function prototypes in embed.fnc
# This is used to generate prototype headers under various configurations,
# export symbols lists for different platforms, and macros to provide an
# implicit interpreter context argument.
#

sub do_not_edit ($)
{
    my $file = shift;

    return read_only_top(lang => ($file =~ /\.[ch]$/ ? 'C' : 'Perl'),
			 file => $file, style => '*', by => 'regen/embed.pl',
			 from => ['data in embed.fnc', 'regen/embed.pl',
				  'regen/opcodes', 'intrpvar.h', 'perlvars.h'],
			 final => "\nEdit those files and run 'make regen_headers' to effect changes.\n",
			 copyright => [1993 .. 2009]);
} # do_not_edit

open IN, "embed.fnc" or die $!;

my @embed;
my (%has_va, %has_nocontext);

while (<IN>) {
    chomp;
    next if /^:/;
    next if /^$/;
    while (s|\\$||) {
	$_ .= <IN>;
	chomp;
    }
    s/\s+$//;
    my @args;
    if (/^\s*(#|$)/) {
	@args = $_;
    }
    else {
	@args = split /\s*\|\s*/, $_;
	my $func = $args[2];
	if ($func) {
	    ++$has_va{$func} if $args[-1] =~ /\.\.\./;
	    ++$has_nocontext{$1} if $func =~ /(.*)_nocontext/;
	}
    }
    if (@args == 1 && $args[0] !~ /^#\s*(?:if|ifdef|ifndef|else|endif)/) {
	die "Illegal line $. '$args[0]' in embed.fnc";
    }
    push @embed, \@args;
}

open IN, 'regen/opcodes' or die $!;
{
    my %syms;

    while (<IN>) {
	chop;
	next unless $_;
	next if /^#/;
	my (undef, undef, $check) = split /\t+/, $_;
	++$syms{$check};
    }

    foreach (keys %syms) {
	# These are all indirectly referenced by globals.c.
	push @embed, ['pR', 'OP *', $_, 'NN OP *o'];
    }
}
close IN;

my (@core, @ext, @api);
{
    # Cluster entries in embed.fnc that have the same #ifdef guards.
    # Also, split out at the top level the three classes of functions.
    my @state;
    my %groups;
    my $current;
    foreach (@embed) {
	if (@$_ > 1) {
	    push @$current, $_;
	    next;
	}
	$_->[0] =~ s/^#\s+/#/;
	$_->[0] =~ /^\S*/;
	$_->[0] =~ s/^#ifdef\s+(\S+)/#if defined($1)/;
	$_->[0] =~ s/^#ifndef\s+(\S+)/#if !defined($1)/;
	if ($_->[0] =~ /^#if\s*(.*)/) {
	    push @state, $1;
	} elsif ($_->[0] =~ /^#else\s*$/) {
	    die "Unmatched #else in embed.fnc" unless @state;
	    $state[-1] = "!($state[-1])";
	} elsif ($_->[0] =~ m!^#endif\s*(?:/\*.*\*/)?$!) {
	    die "Unmatched #endif in embed.fnc" unless @state;
	    pop @state;
	} else {
	    die "Unhandled pre-processor directive '$_->[0]' in embed.fnc";
	}
	$current = \%groups;
	# Nested #if blocks are effectively &&ed together
	# For embed.fnc, ordering withing the && isn't relevant, so we can
	# sort them to try to group more functions together.
	my @sorted = sort @state;
	while (my $directive = shift @sorted) {
	    $current->{$directive} ||= {};
	    $current = $current->{$directive};
	}
	$current->{''} ||= [];
	$current = $current->{''};
    }

    sub add_level {
	my ($level, $indent, $wanted) = @_;
	my $funcs = $level->{''};
	my @entries;
	if ($funcs) {
	    if (!defined $wanted) {
		@entries = @$funcs;
	    } else {
		foreach (@$funcs) {
		    if ($_->[0] =~ /A/) {
			push @entries, $_ if $wanted eq 'A';
		    } elsif ($_->[0] =~ /E/) {
			push @entries, $_ if $wanted eq 'E';
		    } else {
			push @entries, $_ if $wanted eq '';
		    }
		}
	    }
	    @entries = sort {$a->[2] cmp $b->[2]} @entries;
	}
	foreach (sort grep {length $_} keys %$level) {
	    my @conditional = add_level($level->{$_}, $indent . '  ', $wanted);
	    push @entries,
		["#${indent}if $_"], @conditional, ["#${indent}endif"]
		    if @conditional;
	}
	return @entries;
    }
    @core = add_level(\%groups, '', '');
    @ext = add_level(\%groups, '', 'E');
    @api = add_level(\%groups, '', 'A');

    @embed = add_level(\%groups, '');
}

# walk table providing an array of components in each line to
# subroutine, printing the result
sub walk_table (&@) {
    my ($function, $filename) = @_;
    my $F;
    if (ref $filename) {	# filehandle
	$F = $filename;
    }
    else {
	$F = safer_open("$filename-new", $filename);
	print $F do_not_edit ($filename);
    }
    foreach (@embed) {
	my @outs = &{$function}(@$_);
	# $function->(@args) is not 5.003
	print $F @outs;
    }
    unless (ref $filename) {
	read_only_bottom_close_and_rename($F);
    }
}

# generate proto.h
{
    my $pr = safer_open('proto.h-new', 'proto.h');
    print $pr do_not_edit ("proto.h"), "START_EXTERN_C\n";
    my $ret;

    foreach (@embed) {
	if (@$_ == 1) {
	    print $pr "$_->[0]\n";
	    next;
	}

	my ($flags,$retval,$plain_func,@args) = @$_;
	my @nonnull;
	my $has_context = ( $flags !~ /n/ );
	my $never_returns = ( $flags =~ /r/ );
	my $commented_out = ( $flags =~ /m/ );
	my $binarycompat = ( $flags =~ /b/ );
	my $is_malloc = ( $flags =~ /a/ );
	my $can_ignore = ( $flags !~ /R/ ) && !$is_malloc;
	my @names_of_nn;
	my $func;

	my $splint_flags = "";
	if ( $SPLINT && !$commented_out ) {
	    $splint_flags .= '/*@noreturn@*/ ' if $never_returns;
	    if ($can_ignore && ($retval ne 'void') && ($retval !~ /\*/)) {
		$retval .= " /*\@alt void\@*/";
	    }
	}

	if ($flags =~ /([si])/) {
	    my $type = ($1 eq 's') ? "STATIC" : "PERL_STATIC_INLINE";
	    warn "$func: i and s flags are mutually exclusive"
					    if $flags =~ /s/ && $flags =~ /i/;
	    $retval = "$type $splint_flags$retval";
	    $func = "S_$plain_func";
	}
	else {
	    $retval = "PERL_CALLCONV $splint_flags$retval";
	    if ($flags =~ /[bp]/) {
		$func = "Perl_$plain_func";
	    } else {
		$func = $plain_func;
	    }
	}
	$ret = "$retval\t$func(";
	if ( $has_context ) {
	    $ret .= @args ? "pTHX_ " : "pTHX";
	}
	if (@args) {
	    my $n;
	    for my $arg ( @args ) {
		++$n;
		if ( $arg =~ /\*/ && $arg !~ /\b(NN|NULLOK)\b/ ) {
		    warn "$func: $arg needs NN or NULLOK\n";
		    ++$unflagged_pointers;
		}
		my $nn = ( $arg =~ s/\s*\bNN\b\s+// );
		push( @nonnull, $n ) if $nn;

		my $nullok = ( $arg =~ s/\s*\bNULLOK\b\s+// ); # strip NULLOK with no effect

		# Make sure each arg has at least a type and a var name.
		# An arg of "int" is valid C, but want it to be "int foo".
		my $temp_arg = $arg;
		$temp_arg =~ s/\*//g;
		$temp_arg =~ s/\s*\bstruct\b\s*/ /g;
		if ( ($temp_arg ne "...")
		     && ($temp_arg !~ /\w+\s+(\w+)(?:\[\d+\])?\s*$/) ) {
		    warn "$func: $arg ($n) doesn't have a name\n";
		}
		if ( $SPLINT && $nullok && !$commented_out ) {
		    $arg = '/*@null@*/ ' . $arg;
		}
		if (defined $1 && $nn && !($commented_out && !$binarycompat)) {
		    push @names_of_nn, $1;
		}
	    }
	    $ret .= join ", ", @args;
	}
	else {
	    $ret .= "void" if !$has_context;
	}
	$ret .= ")";
	my @attrs;
	if ( $flags =~ /r/ ) {
	    push @attrs, "__attribute__noreturn__";
	}
	if ( $flags =~ /D/ ) {
	    push @attrs, "__attribute__deprecated__";
	}
	if ( $is_malloc ) {
	    push @attrs, "__attribute__malloc__";
	}
	if ( !$can_ignore ) {
	    push @attrs, "__attribute__warn_unused_result__";
	}
	if ( $flags =~ /P/ ) {
	    push @attrs, "__attribute__pure__";
	}
	if( $flags =~ /f/ ) {
	    my $prefix	= $has_context ? 'pTHX_' : '';
	    my $args	= scalar @args;
 	    my $pat	= $args - 1;
	    my $macro	= @nonnull && $nonnull[-1] == $pat  
				? '__attribute__format__'
				: '__attribute__format__null_ok__';
	    push @attrs, sprintf "%s(__printf__,%s%d,%s%d)", $macro,
				$prefix, $pat, $prefix, $args;
	}
	if ( @nonnull ) {
	    my @pos = map { $has_context ? "pTHX_$_" : $_ } @nonnull;
	    push @attrs, map { sprintf( "__attribute__nonnull__(%s)", $_ ) } @pos;
	}
	if ( @attrs ) {
	    $ret .= "\n";
	    $ret .= join( "\n", map { "\t\t\t$_" } @attrs );
	}
	$ret .= ";";
	$ret = "/* $ret */" if $commented_out;
	if (@names_of_nn) {
	    $ret .= "\n#define PERL_ARGS_ASSERT_\U$plain_func\E\t\\\n\t"
		. join '; ', map "assert($_)", @names_of_nn;
	}
	$ret .= @attrs ? "\n\n" : "\n";

	print $pr $ret;
    }

    print $pr <<'EOF';
#ifdef PERL_CORE
#  include "pp_proto.h"
#endif
END_EXTERN_C
EOF

    read_only_bottom_close_and_rename($pr);
}

# generates global.sym (API export list)
{
  my %seen;
  sub write_global_sym {
      if (@_ > 1) {
	  my ($flags,$retval,$func,@args) = @_;
	  if ($flags =~ /[AX]/ && $flags !~ /[xm]/
	      || $flags =~ /b/) { # public API, so export
	      # If a function is defined twice, for example before and after
	      # an #else, only export its name once.
	      return '' if $seen{$func}++;
	      $func = "Perl_$func" if $flags =~ /[pbX]/;
	      return "$func\n";
	  }
      }
      return '';
  }
}

warn "$unflagged_pointers pointer arguments to clean up\n" if $unflagged_pointers;
walk_table(\&write_global_sym, "global.sym");

sub readvars(\%$$@) {
    my ($syms, $file,$pre,$keep_pre) = @_;
    local (*FILE, $_);
    open(FILE, "< $file")
	or die "embed.pl: Can't open $file: $!\n";
    while (<FILE>) {
	s/[ \t]*#.*//;		# Delete comments.
	if (/PERLVARA?I?S?C?\($pre(\w+)/) {
	    my $sym = $1;
	    $sym = $pre . $sym if $keep_pre;
	    warn "duplicate symbol $sym while processing $file line $.\n"
		if exists $$syms{$sym};
	    $$syms{$sym} = $pre || 1;
	}
    }
    close(FILE);
}

my %intrp;
my %globvar;

readvars %intrp,  'intrpvar.h','I';
readvars %globvar, 'perlvars.h','G';

my $sym;

sub undefine ($) {
    my ($sym) = @_;
    "#undef  $sym\n";
}

sub hide {
    my ($from, $to, $indent) = @_;
    $indent = '' unless defined $indent;
    my $t = int(length("$indent$from") / 8);
    "#${indent}define $from" . "\t" x ($t < 3 ? 3 - $t : 1) . "$to\n";
}

sub bincompat_var ($$) {
    my ($pfx, $sym) = @_;
    my $arg = ($pfx eq 'G' ? 'NULL' : 'aTHX');
    undefine("PL_$sym") . hide("PL_$sym", "(*Perl_${pfx}${sym}_ptr($arg))");
}

sub multon ($$$) {
    my ($sym,$pre,$ptr) = @_;
    hide("PL_$sym", "($ptr$pre$sym)");
}

sub multoff ($$) {
    my ($sym,$pre) = @_;
    return hide("PL_$pre$sym", "PL_$sym");
}

my $em = safer_open('embed.h-new', 'embed.h');

print $em do_not_edit ("embed.h"), <<'END';
/* (Doing namespace management portably in C is really gross.) */

/* By defining PERL_NO_SHORT_NAMES (not done by default) the short forms
 * (like warn instead of Perl_warn) for the API are not defined.
 * Not defining the short forms is a good thing for cleaner embedding. */

#ifndef PERL_NO_SHORT_NAMES

/* Hide global symbols */

END

my @az = ('a'..'z');

sub embed_h {
    my ($guard, $funcs) = @_;
    print $em "$guard\n" if $guard;

    my $lines;
    foreach (@$funcs) {
	if (@$_ == 1) {
	    my $cond = $_->[0];
	    # Indent the conditionals if we are wrapped in an #if/#endif pair.
	    $cond =~ s/#(.*)/#  $1/ if $guard;
	    $lines .= "$cond\n";
	    next;
	}
	my $ret = "";
	my ($flags,$retval,$func,@args) = @$_;
	unless ($flags =~ /[om]/) {
	    my $args = scalar @args;
	    if ($flags =~ /n/) {
		if ($flags =~ /s/) {
		    $ret = hide($func,"S_$func");
		}
		elsif ($flags =~ /p/) {
		    $ret = hide($func,"Perl_$func");
		}
	    }
	    elsif ($args and $args[$args-1] =~ /\.\.\./) {
		if ($flags =~ /p/) {
		    # we're out of luck for varargs functions under CPP
		    # So we can only do these macros for no implicit context:
		    $ret = "#ifndef PERL_IMPLICIT_CONTEXT\n"
			. hide($func,"Perl_$func") . "#endif\n";
		}
	    }
	    else {
		my $alist = join(",", @az[0..$args-1]);
		$ret = "#define $func($alist)";
		my $t = int(length($ret) / 8);
		$ret .=  "\t" x ($t < 4 ? 4 - $t : 1);
		if ($flags =~ /[si]/) {
		    $ret .= "S_$func(aTHX";
		}
		elsif ($flags =~ /p/) {
		    $ret .= "Perl_$func(aTHX";
		}
		$ret .= "_ " if $alist;
		$ret .= $alist . ")\n";
	    }
	}
	$lines .= $ret;
    }
    # Prune empty #if/#endif pairs.
    while ($lines =~ s/#\s*if[^\n]+\n#\s*endif\n//) {
    }
    # Merge adjacent blocks.
    while ($lines =~ s/(#ifndef PERL_IMPLICIT_CONTEXT
[^\n]+
)#endif
#ifndef PERL_IMPLICIT_CONTEXT
/$1/) {
    }

    print $em $lines;
    print $em "#endif\n" if $guard;
}

embed_h('', \@api);
embed_h('#if defined(PERL_CORE) || defined(PERL_EXT)', \@ext);
embed_h('#ifdef PERL_CORE', \@core);

print $em <<'END';

#endif	/* #ifndef PERL_NO_SHORT_NAMES */

/* Compatibility stubs.  Compile extensions with -DPERL_NOCOMPAT to
   disable them.
 */

#if !defined(PERL_CORE)
#  define sv_setptrobj(rv,ptr,name)	sv_setref_iv(rv,name,PTR2IV(ptr))
#  define sv_setptrref(rv,ptr)		sv_setref_iv(rv,NULL,PTR2IV(ptr))
#endif

#if !defined(PERL_CORE) && !defined(PERL_NOCOMPAT)

/* Compatibility for various misnamed functions.  All functions
   in the API that begin with "perl_" (not "Perl_") take an explicit
   interpreter context pointer.
   The following are not like that, but since they had a "perl_"
   prefix in previous versions, we provide compatibility macros.
 */
#  define perl_atexit(a,b)		call_atexit(a,b)
END

walk_table {
    my ($flags,$retval,$func,@args) = @_;
    return unless $func;
    return unless $flags =~ /O/;

    my $alist = join ",", @az[0..$#args];
    my $ret = "#  define perl_$func($alist)";
    my $t = (length $ret) >> 3;
    $ret .=  "\t" x ($t < 5 ? 5 - $t : 1);
    "$ret$func($alist)\n";
} $em;

print $em <<'END';

/* varargs functions can't be handled with CPP macros. :-(
   This provides a set of compatibility functions that don't take
   an extra argument but grab the context pointer using the macro
   dTHX.
 */
#if defined(PERL_IMPLICIT_CONTEXT) && !defined(PERL_NO_SHORT_NAMES)
END

foreach (sort keys %has_va) {
    next unless $has_nocontext{$_};
    next if /printf/; # Not clear to me why these are skipped but they are.
    print $em hide($_, "Perl_${_}_nocontext", "  ");
}

print $em <<'END';
#endif

#endif /* !defined(PERL_CORE) && !defined(PERL_NOCOMPAT) */

#if !defined(PERL_IMPLICIT_CONTEXT)
/* undefined symbols, point them back at the usual ones */
END

foreach (sort keys %has_va) {
    next unless $has_nocontext{$_};
    next if /printf/; # Not clear to me why these are skipped but they are.
    print $em hide("Perl_${_}_nocontext", "Perl_$_", "  ");
}

print $em <<'END';
#endif
END

read_only_bottom_close_and_rename($em);

$em = safer_open('embedvar.h-new', 'embedvar.h');

print $em do_not_edit ("embedvar.h"), <<'END';
/* (Doing namespace management portably in C is really gross.) */

/*
   The following combinations of MULTIPLICITY and PERL_IMPLICIT_CONTEXT
   are supported:
     1) none
     2) MULTIPLICITY	# supported for compatibility
     3) MULTIPLICITY && PERL_IMPLICIT_CONTEXT

   All other combinations of these flags are errors.

   only #3 is supported directly, while #2 is a special
   case of #3 (supported by redefining vTHX appropriately).
*/

#if defined(MULTIPLICITY)
/* cases 2 and 3 above */

#  if defined(PERL_IMPLICIT_CONTEXT)
#    define vTHX	aTHX
#  else
#    define vTHX	PERL_GET_INTERP
#  endif

END

for $sym (sort keys %intrp) {
    print $em multon($sym,'I','vTHX->');
}

print $em <<'END';

#else	/* !MULTIPLICITY */

/* case 1 above */

END

for $sym (sort keys %intrp) {
    print $em multoff($sym,'I');
}

print $em <<'END';

END

print $em <<'END';

#endif	/* MULTIPLICITY */

#if defined(PERL_GLOBAL_STRUCT)

END

for $sym (sort keys %globvar) {
    print $em multon($sym,   'G','my_vars->');
    print $em multon("G$sym",'', 'my_vars->');
}

print $em <<'END';

#else /* !PERL_GLOBAL_STRUCT */

END

for $sym (sort keys %globvar) {
    print $em multoff($sym,'G');
}

print $em <<'END';

#endif /* PERL_GLOBAL_STRUCT */
END

read_only_bottom_close_and_rename($em);

my $capi = safer_open('perlapi.c-new', 'perlapi.c');
my $capih = safer_open('perlapi.h-new', 'perlapi.h');

print $capih do_not_edit ("perlapi.h"), <<'EOT';
/* declare accessor functions for Perl variables */
#ifndef __perlapi_h__
#define __perlapi_h__

#if defined (MULTIPLICITY) && defined (PERL_GLOBAL_STRUCT)

START_EXTERN_C

#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#undef PERLVARISC
#define PERLVAR(v,t)	EXTERN_C t* Perl_##v##_ptr(pTHX);
#define PERLVARA(v,n,t)	typedef t PL_##v##_t[n];			\
			EXTERN_C PL_##v##_t* Perl_##v##_ptr(pTHX);
#define PERLVARI(v,t,i)	PERLVAR(v,t)
#define PERLVARIC(v,t,i) PERLVAR(v, const t)
#define PERLVARISC(v,i)	typedef const char PL_##v##_t[sizeof(i)];	\
			EXTERN_C PL_##v##_t* Perl_##v##_ptr(pTHX);

#include "perlvars.h"

#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#undef PERLVARISC

END_EXTERN_C

#if defined(PERL_CORE)

/* accessor functions for Perl "global" variables */

/* these need to be mentioned here, or most linkers won't put them in
   the perl executable */

#ifndef PERL_NO_FORCE_LINK

START_EXTERN_C

#ifndef DOINIT
EXTCONST void * const PL_force_link_funcs[];
#else
EXTCONST void * const PL_force_link_funcs[] = {
#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#define PERLVAR(v,t)	(void*)Perl_##v##_ptr,
#define PERLVARA(v,n,t)	PERLVAR(v,t)
#define PERLVARI(v,t,i)	PERLVAR(v,t)
#define PERLVARIC(v,t,i) PERLVAR(v,t)
#define PERLVARISC(v,i) PERLVAR(v,char)

/* In Tru64 (__DEC && __osf__) the cc option -std1 causes that one
 * cannot cast between void pointers and function pointers without
 * info level warnings.  The PL_force_link_funcs[] would cause a few
 * hundred of those warnings.  In code one can circumnavigate this by using
 * unions that overlay the different pointers, but in declarations one
 * cannot use this trick.  Therefore we just disable the warning here
 * for the duration of the PL_force_link_funcs[] declaration. */

#if defined(__DECC) && defined(__osf__)
#pragma message save
#pragma message disable (nonstandcast)
#endif

#include "perlvars.h"

#if defined(__DECC) && defined(__osf__)
#pragma message restore
#endif

#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#undef PERLVARISC
};
#endif	/* DOINIT */

END_EXTERN_C

#endif	/* PERL_NO_FORCE_LINK */

#else	/* !PERL_CORE */

EOT

foreach $sym (sort keys %globvar) {
    print $capih bincompat_var('G',$sym);
}

print $capih <<'EOT';

#endif /* !PERL_CORE */
#endif /* MULTIPLICITY && PERL_GLOBAL_STRUCT */

#endif /* __perlapi_h__ */
EOT

read_only_bottom_close_and_rename($capih);

my $warning = do_not_edit ("perlapi.c");
$warning =~ s! \*/\n! *
 *
 * Up to the threshold of the door there mounted a flight of twenty-seven
 * broad stairs, hewn by some unknown art of the same black stone.  This
 * was the only entrance to the tower; ...
 *
 *     [p.577 of _The Lord of the Rings_, III/x: "The Voice of Saruman"]
 *
 */
!;

print $capi $warning, <<'EOT';
#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"

#if defined (MULTIPLICITY) && defined (PERL_GLOBAL_STRUCT)

/* accessor functions for Perl "global" variables */
START_EXTERN_C

#undef PERLVARI
#define PERLVARI(v,t,i) PERLVAR(v,t)

#undef PERLVAR
#undef PERLVARA
#define PERLVAR(v,t)	t* Perl_##v##_ptr(pTHX)				\
			{ dVAR; PERL_UNUSED_CONTEXT; return &(PL_##v); }
#define PERLVARA(v,n,t)	PL_##v##_t* Perl_##v##_ptr(pTHX)		\
			{ dVAR; PERL_UNUSED_CONTEXT; return &(PL_##v); }
#undef PERLVARIC
#undef PERLVARISC
#define PERLVARIC(v,t,i)	\
			const t* Perl_##v##_ptr(pTHX)		\
			{ PERL_UNUSED_CONTEXT; return (const t *)&(PL_##v); }
#define PERLVARISC(v,i)	PL_##v##_t* Perl_##v##_ptr(pTHX)	\
			{ dVAR; PERL_UNUSED_CONTEXT; return &(PL_##v); }
#include "perlvars.h"

#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#undef PERLVARISC

END_EXTERN_C

#endif /* MULTIPLICITY && PERL_GLOBAL_STRUCT */
EOT

read_only_bottom_close_and_rename($capi);

# ex: set ts=8 sts=4 sw=4 noet:
