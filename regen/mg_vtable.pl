#!/usr/bin/perl -w
#
# Regenerate (overwriting only if changed):
#
#    mg_vtable.h
#
# from information stored in this file.
#
# Accepts the standard regen_lib -q and -v args.
#
# This script is normally invoked from regen.pl.

use strict;
require 5.004;

BEGIN {
    # Get function prototypes
    require 'regen/regen_lib.pl';
}

my @mg =
    (
     sv => { char => '\0', vtable => 'sv', desc => 'Special scalar variable' },
     overload => { char => 'A', vtable => 'amagic', desc => '%OVERLOAD hash' },
     overload_elem => { char => 'a', vtable => 'amagicelem',
			desc => '%OVERLOAD hash element' },
     overload_table => { char => 'c', vtable => 'ovrld',
			 desc => 'Holds overload table (AMT) on stash' },
     bm => { char => 'B', vtable => 'regexp', value_magic => 1,
	     desc => 'Boyer-Moore (fast string search)' },
     regdata => { char => 'D', vtable => 'regdata',
		  desc => 'Regex match position data (@+ and @- vars)' },
     regdatum => { char => 'd', vtable => 'regdatum',
		   desc => 'Regex match position data element' },
     env => { char => 'E', vtable => 'env', desc => '%ENV hash' },
     envelem => { char => 'e', vtable => 'envelem',
		  desc => '%ENV hash element' },
     fm => { char => 'f', vtable => 'regdata', value_magic => 1,
	     desc => "Formline ('compiled' format)" },
     regex_global => { char => 'g', vtable => 'mglob', value_magic => 1,
		       desc => 'm//g target / study()ed string' },
     hints => { char => 'H', vtable => 'hints', desc => '%^H hash' },
     hintselem => { char => 'h', vtable => 'hintselem',
		    desc => '%^H hash element' },
     isa => { char => 'I', vtable => 'isa', desc => '@ISA array' },
     isaelem => { char => 'i', vtable => 'isaelem',
		  desc => '@ISA array element' },
     nkeys => { char => 'k', vtable => 'nkeys', value_magic => 1,
		desc => 'scalar(keys()) lvalue' },
     dbfile => { char => 'L', vtable => 'dbline',
		 desc => 'Debugger %_<filename' },
     dbline => { char => 'l', desc => 'Debugger %_<filename element' },
     shared => { char => 'N', desc => 'Shared between threads',
		 unknown_to_sv_magic => 1 },
     shared_scalar => { char => 'n', desc => 'Shared between threads',
			unknown_to_sv_magic => 1 },
     collxfrm => { char => 'o', vtable => 'collxfrm', value_magic => 1,
		   desc => 'Locale transformation' },
     tied => { char => 'P', vtable => 'pack',
	       value_magic => 1, # treat as value, so 'local @tied' isn't tied
	       desc => 'Tied array or hash' },
     tiedelem => { char => 'p', vtable => 'packelem',
		   desc => 'Tied array or hash element' },
     tiedscalar => { char => 'q', vtable => 'packelem',
		     desc => 'Tied scalar or handle' },
     qr => { char => 'r', vtable => 'regexp', value_magic => 1, 
	     desc => 'precompiled qr// regex' },
     sig => { char => 'S', desc => '%SIG hash' },
     sigelem => { char => 's', vtable => 'sigelem',
		  desc => '%SIG hash element' },
     taint => { char => 't', vtable => 'taint', value_magic => 1,
		desc => 'Taintedness' },
     uvar => { char => 'U', vtable => 'uvar',
	       desc => 'Available for use by extensions' },
     uvar_elem => { char => 'u', desc => 'Reserved for use by extensions',
		    unknown_to_sv_magic => 1 },
     vec => { char => 'v', vtable => 'vec', value_magic => 1,
	      desc => 'vec() lvalue' },
     vstring => { char => 'V', value_magic => 1,
		  desc => 'SV was vstring literal' },
     utf8 => { char => 'w', vtable => 'utf8', value_magic => 1,
	       desc => 'Cached UTF-8 information' },
     substr => { char => 'x', vtable => 'substr',  value_magic => 1,
		 desc => 'substr() lvalue' },
     defelem => { char => 'y', vtable => 'defelem', value_magic => 1,
		  desc => 'Shadow "foreach" iterator variable / smart parameter vivification' },
     arylen => { char => '#', vtable => 'arylen', value_magic => 1,
		 desc => 'Array length ($#ary)' },
     pos => { char => '.', vtable => 'pos', value_magic => 1,
	      desc => 'pos() lvalue' },
     backref => { char => '<', vtable => 'backref', value_magic => 1,
		  desc => 'for weak ref data' },
     symtab => { char => ':', value_magic => 1,
		 desc => 'extra data for symbol tables' },
     rhash => { char => '%', value_magic => 1,
		desc => 'extra data for restricted hashes' },
     arylen_p => { char => '@', value_magic => 1,
		   desc => 'to move arylen out of XPVAV' },
     ext => { char => '~', desc => 'Available for use by extensions' },
     checkcall => { char => ']', value_magic => 1,
		    desc => 'inlining/mutation of call to this CV'},
);

# These have a subtly different "namespace" from the magic types.
my @sig =
    (
     'sv' => {get => 'get', set => 'set', len => 'len'},
     'env' => {set => 'set_all_env', clear => 'clear_all_env'},
     'envelem' => {set => 'setenv', clear => 'clearenv'},
     'sigelem' => {get => 'getsig', set => 'setsig', clear => 'clearsig',
		   cond => '#ifndef PERL_MICRO'},
     'pack' => {len => 'sizepack', clear => 'wipepack'},
     'packelem' => {get => 'getpack', set => 'setpack', clear => 'clearpack'},
     'dbline' => {set => 'setdbline'},
     'isa' => {set => 'setisa', clear => 'clearisa'},
     'isaelem' => {set => 'setisa'},
     'arylen' => {get => 'getarylen', set => 'setarylen', const => 1},
     'arylen_p' => {free => 'freearylen_p'},
     'mglob' => {set => 'setmglob'},
     'nkeys' => {get => 'getnkeys', set => 'setnkeys'},
     'taint' => {get => 'gettaint', set => 'settaint'},
     'substr' => {get => 'getsubstr', set => 'setsubstr'},
     'vec' => {get => 'getvec', set => 'setvec'},
     'pos' => {get => 'getpos', set => 'setpos'},
     'uvar' => {get => 'getuvar', set => 'setuvar'},
     'defelem' => {get => 'getdefelem', set => 'setdefelem'},
     'regexp' => {set => 'setregexp', alias => [qw(bm fm)]},
     'regdata' => {len => 'regdata_cnt'},
     'regdatum' => {get => 'regdatum_get', set => 'regdatum_set'},
     'amagic' => {set => 'setamagic', free => 'setamagic'},
     'amagicelem' => {set => 'setamagic', free => 'setamagic'},
     'backref' => {free => 'killbackrefs'},
     'ovrld' => {free => 'freeovrld'},
     'utf8' => {set => 'setutf8'},
     'collxfrm' => {set => 'setcollxfrm',
		    cond => '#ifdef USE_LOCALE_COLLATE'},
     'hintselem' => {set => 'sethint', clear => 'clearhint'},
     'hints' => {clear => 'clearhints'},
);

my ($vt, $raw) = map {
    open_new($_, '>',
	     { by => 'regen/mg_vtable.pl', file => $_, style => '*' });
} 'mg_vtable.h', 'mg_raw.h';

# Of course, it would be *much* easier if we could output this table directly
# here and now. However, for our sins, we try to support EBCDIC, which wouldn't
# be *so* bad, except that there are (at least) 3 EBCDIC charset variants, and
# they don't agree on the code point for '~'. Which we use. Great.
# So we have to get the local build runtime to sort our table in character order
# (And of course, just to be helpful, in POSIX BC '~' is \xFF, so we can't even
# simplify the C code by assuming that the last element of the array is
# predictable)

{
    while (my ($name, $data) = splice @mg, 0, 2) {
	my $i = ord eval qq{"$data->{char}"};
	unless ($data->{unknown_to_sv_magic}) {
	    my $value = $data->{vtable}
		? "want_vtbl_$data->{vtable}" : 'magic_vtable_max';
	    $value .= ' | PERL_MAGIC_VALUE_MAGIC' if $data->{value_magic};
	    my $comment = "/* $name '$data->{char}' $data->{desc} */";
	    $comment =~ s/([\\"])/\\$1/g;
	    print $raw qq{    { '$data->{char}', "$value",\n      "$comment" },\n};
	}
    }
}

{
    my @names = grep {!ref $_} @sig;
    my $want = join ",\n    ", (map {"want_vtbl_$_"} @names), 'magic_vtable_max';
    my $names = join qq{",\n    "}, @names;

    print $vt <<"EOH";
enum {		/* pass one of these to get_vtbl */
    $want
};

#ifdef DOINIT
EXTCONST char *PL_magic_vtable_names[magic_vtable_max] = {
    "$names"
};
#else
EXTCONST char *PL_magic_vtable_names[magic_vtable_max];
#endif

EOH
}

print $vt <<'EOH';
/* These all need to be 0, not NULL, as NULL can be (void*)0, which is a
 * pointer to data, whereas we're assigning pointers to functions, which are
 * not the same beast. ANSI doesn't allow the assignment from one to the other.
 * (although most, but not all, compilers are prepared to do it)
 */

/* order is:
    get
    set
    len
    clear
    free
    copy
    dup
    local
*/

#ifdef DOINIT
EXT_MGVTBL PL_magic_vtables[magic_vtable_max] = {
EOH

my @vtable_names;
my @aliases;

while (my ($name, $data) = splice @sig, 0, 2) {
    push @vtable_names, $name;
    my @funcs = map {
	$data->{$_} ? "Perl_magic_$data->{$_}" : 0;
    } qw(get set len clear free copy dup local);

    $funcs[0] = "(int (*)(pTHX_ SV *, MAGIC *))" . $funcs[0] if $data->{const};
    my $funcs = join ", ", @funcs;

    # Because we can't have a , after the last {...}
    my $comma = @sig ? ',' : '';

    print $vt "$data->{cond}\n" if $data->{cond};
    print $vt "  { $funcs }$comma\n";
    print $vt <<"EOH" if $data->{cond};
#else
  { 0, 0, 0, 0, 0, 0, 0, 0 }$comma
#endif
EOH
    foreach(@{$data->{alias}}) {
	push @aliases, "#define want_vtbl_$_ want_vtbl_$name\n";
	push @vtable_names, $_;
    }
}

print $vt <<'EOH';
};
#else
EXT_MGVTBL PL_magic_vtables[magic_vtable_max];
#endif

EOH

print $vt (sort @aliases), "\n";

print $vt "#define PL_vtbl_$_ PL_magic_vtables[want_vtbl_$_]\n"
    foreach sort @vtable_names;

# 63, not 64, As we rely on the last possible value to mean "NULL vtable"
die "Too many vtable names" if @vtable_names > 63;

read_only_bottom_close_and_rename($_) foreach $vt, $raw;
