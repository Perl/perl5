#!/usr/bin/perl -w

# Try opening libperl.a with nm, and verifying it has the kind of symbols
# we expected.  Fail softly, expect things only on known platforms.
#
# Also, if the rarely-used builds options -DPERL_GLOBAL_STRUCT or
# -DPERL_GLOBAL_STRUCT_PRIVATE are used, verify that they did what
# they were meant to do, hide the global variables (see perlguts for
# the details).
#
# Debugging tip: nm output (this script's input) can be faked by
# giving one command line argument for this script: it should be
# either the filename to read, or "-" for STDIN.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

use strict;

use Config;

if ($Config{cc} =~ /g\+\+/) {
    # XXX Could use c++filt, maybe.
    skip_all "on g++";
}

my $libperl_a;

for my $f (qw(../libperl.a libperl.a)) {
  if (-f $f) {
    $libperl_a = $f;
    last;
  }
}

unless (defined $libperl_a) {
  skip_all "no libperl.a";
}

print "# \$^O = $^O\n";
print "# \$Config{cc} = $Config{cc}\n";
print "# libperl = $libperl_a\n";

my $nm;
my $nm_opt = '';
my $nm_style;

if ($^O eq 'linux') {
    $nm = '/usr/bin/nm';
    $nm_style = 'gnu';
} elsif ($^O eq 'darwin') {
    $nm = '/usr/bin/nm';
    $nm_style = 'darwin';
    # With the -m option we get better information than the BSD-like
    # default: with the default, a lot of symbols get dumped into 'S'
    # or 's', for example one cannot tell the difference between const
    # and non-const symbols.
    $nm_opt = '-m';
}

unless (defined $nm) {
  skip_all "no nm";
}

unless (defined $nm_style) {
  skip_all "no nm style";
}

print "# nm = $nm\n";
print "# nm_style = $nm_style\n";
print "# nm_opt = $nm_opt\n";

unless (-x $nm) {
    skip_all "no executable nm $nm";
}

if ($nm_style eq 'gnu') {
    open(my $nm_fh, "$nm --version|") or
        skip_all "nm failed: $!";
    my $gnu_verified;
    while (<$nm_fh>) {
        if (/^GNU nm/) {
            $gnu_verified = 1;
            last;
        }
    }
    unless ($gnu_verified) {
        skip_all "no GNU nm";
    }
}

my $nm_err_tmp = "libperl$$";

END {
    # this is still executed when we skip_all above, avoid a warning
    unlink $nm_err_tmp if $nm_err_tmp;
}

my $nm_fh;

if (@ARGV == 1) {
    my $fake = shift @ARGV;
    print "# Faking nm output from $fake\n";
    if ($fake eq '-') {
        open($nm_fh, "<&STDIN") or
            skip_all "Duping STDIN failed: $!";
    } else {
        open($nm_fh, "<", $fake) or
            skip_all "Opening '$fake' failed: $!";
    }
    undef $nm_err_tmp; # In this case there will be no nm errors.
} else {
    open($nm_fh, "$nm $nm_opt $libperl_a 2>$nm_err_tmp |") or
        skip_all "$nm $nm_opt $libperl_a failed: $!";
}
 
sub nm_parse_gnu {
    my $symbols = shift;
    my $line = $_;
    if (m{^(\w+\.o):$}) {
        $symbols->{obj}{$1}++;
        $symbols->{o} = $1;
        return;
    } else {
        die "$0: undefined current object: $line"
            unless defined $symbols->{o};
        if (s/^[0-9a-f]{8}(?:[0-9a-f]{8})? //) {
            if (/^[Rr] (\w+)$/) {
                $symbols->{data}{const}{$1}{$symbols->{o}}++;
            } elsif (/^r .+$/) {
                # Skip local const.
            } elsif (/^[Tti] (\w+)(\..+)?$/) {
                $symbols->{text}{$1}{$symbols->{o}}++;
            } elsif (/^C (\w+)$/) {
                $symbols->{data}{common}{$1}{$symbols->{o}}++;
            } elsif (/^[BbSs] (\w+)(\.\d+)?$/) {
                $symbols->{data}{bss}{$1}{$symbols->{o}}++;
            } elsif (/^0{16} D _LIB_VERSION$/) {
                # Skip the _LIB_VERSION (not ours).
            } elsif (/^[DdGg] (\w+)$/) {
                $symbols->{data}{data}{$1}{$symbols->{o}}++;
            } elsif (/^. \.?(\w+)$/) {
                # Skip the unknown types.
                print "# Unknown type: $line ($symbols->{o})\n";
            }
            return;
        } elsif (/^ {8}(?: {8})? U (\w+)$/) {
            # Skip the undefined.
            return;
	}
    }
    print "# Unexpected nm output '$line' ($symbols->{o})\n";
}

sub nm_parse_darwin {
    my $symbols = shift;
    my $line = $_;
    if (m{^(?:\.\./)?libperl\.a\((\w+\.o)\):$}) {
        $symbols->{obj}{$1}++;
        $symbols->{o} = $1;
        return;
    } else {
        die "$0: undefined current object: $line" unless defined $symbols->{o};
        if (s/^[0-9a-f]{8}(?:[0-9a-f]{8})? //) {
            if (/^\(__TEXT,__(?:eh_frame|cstring)\) /) {
                # Skip the eh_frame and cstring.
            } elsif (/^\(__TEXT,__(?:const|literal\d+)\) (?:non-)?external _?(\w+)(\.\w+)?$/) {
                my ($symbol, $suffix) = ($1, $2);
                # Ignore function-local constants like
                # _Perl_av_extend_guts.oom_array_extend
                return if defined $suffix && /__TEXT,__const/;
                $symbols->{data}{const}{$symbol}{$symbols->{o}}++;
            } elsif (/^\(__TEXT,__text\) (?:non-)?external _(\w+)$/) {
                $symbols->{text}{$1}{$symbols->{o}}++;
            } elsif (/^\(__DATA,__(const|data|bss|common)\) (?:non-)?external _(\w+)(\.\w+)?$/) {
                my ($dtype, $symbol, $suffix) = ($1, $2, $3);
                # Ignore function-local constants like
                # _Perl_pp_gmtime.dayname
                return if defined $suffix;
                $symbols->{data}{$dtype}{$symbol}{$symbols->{o}}++;
            } elsif (/^\(__DATA,__const\) non-external _\.memset_pattern\d*$/) {
                # Skip this, whatever it is (some inlined leakage from
                # darwin libc?)
            } elsif (/^\(__\w+,__\w+\) /) {
                # Skip the unknown types.
                print "# Unknown type: $line ($symbols->{o})\n";
            }
            return;
        } elsif (/^ {8}(?: {8})? \(undefined\) /) {
            # Skip the undefined.
            return;
        }
    }
    print "# Unexpected nm output '$line' ($symbols->{o})\n";
}

my $nm_parse;

if ($nm_style eq 'gnu') {
    $nm_parse = \&nm_parse_gnu;
} elsif ($nm_style eq 'darwin') {
    $nm_parse = \&nm_parse_darwin;
}

unless (defined $nm_parse) {
    skip_all "no nm parser ($nm_style $nm_style, \$^O $^O)";
}

my %symbols;

while (<$nm_fh>) {
    next if /^$/;
    chomp;
    $nm_parse->(\%symbols);
}

# use Data::Dumper; print Dumper(\%symbols);

if (keys %symbols == 0) {
    skip_all "no symbols\n";
}

# These should always be true for everyone.

ok($symbols{obj}{'pp.o'}, "has object pp.o");
ok($symbols{text}{'Perl_peep'}, "has text Perl_peep");
ok($symbols{text}{'Perl_pp_uc'}{'pp.o'}, "has text Perl_pp_uc in pp.o");
ok(exists $symbols{data}{const}, "has data const symbols");
ok($symbols{data}{const}{PL_no_mem}{'globals.o'}, "has PL_no_mem");

my $DEBUGGING = $Config{ccflags} =~ /-DDEBUGGING/ ? 1 : 0;

my $GS  = $Config{ccflags} =~ /-DPERL_GLOBAL_STRUCT\b/ ? 1 : 0;
my $GSP = $Config{ccflags} =~ /-DPERL_GLOBAL_STRUCT_PRIVATE/ ? 1 : 0;

print "# GS  = $GS\n";
print "# GSP = $GSP\n";

my %data_symbols;

for my $dtype (sort keys %{$symbols{data}}) {
    for my $symbol (sort keys %{$symbols{data}{$dtype}}) {
        $data_symbols{$symbol}++;
    }
}

# Since we are deprived of Test::More.
sub is_deeply {
    my ($a, $b) = @_;
    if (ref $a eq 'ARRAY' && ref $b eq 'ARRAY') {
	if (@$a == @$b) {
	    for my $i (0..$#$a) {
		unless ($a->[$i] eq $b->[$i]) {
                    printf("# LHS elem #%d '%s' ne RHS elem #%d '%s'\n",
                           $a->[$i], $b->[$i]);
		    return 0;
		}
	    }
	    return 1;
	} else {
            printf("# LHS length %d, RHS length %d\n",
                   @$a, @$b);
	    return 0;
	}
    } else {
	die "$0: Unexpcted: is_deeply $a $b\n";
    }
}

# The following tests differ between vanilla vs $GSP or $GS.
#
# Some terminology:
# - "text" symbols are code
# - "data" symbols are data (duh), with subdivisions:
#   - "bss": (Block-Started-by-Symbol: originally from IBM assembler...),
#     uninitialized data, which often even doesn't exist in the object
#     file as such, only its size does, which is then created on demand
#     by the loader
#  - "const": initialized read-only data, like string literals
#  - "common": uninitialized data unless initialized...
#    (the full story is too long for here, see "man nm")
#  - "data": initialized read-write data
#    (somewhat confusingly below: "data data", but it makes code simpler)

if ($GSP) {
    print "# -DPERL_GLOBAL_STRUCT_PRIVATE\n";
    ok(!exists $data_symbols{PL_hash_seed}, "has no PL_hash_seed");
    ok(!exists $data_symbols{PL_ppaddr}, "has no PL_ppaddr");

    ok(! exists $symbols{data}{bss}, "has no data bss symbols");
    ok(! exists $symbols{data}{data} ||
            # clang with ASAN seems to add this symbol to every object file:
            !grep($_ ne '__unnamed_1', keys %{$symbols{data}{data}}),
        "has no data data symbols");
    ok(! exists $symbols{data}{common}, "has no data common symbols");

    # -DPERL_GLOBAL_STRUCT_PRIVATE should NOT have
    # the extra text symbol for accessing the vars
    # (as opposed to "just" -DPERL_GLOBAL_STRUCT)
    ok(! exists $symbols{text}{Perl_GetVars}, "has no Perl_GetVars");
} elsif ($GS) {
    print "# -DPERL_GLOBAL_STRUCT\n";
    ok(!exists $data_symbols{PL_hash_seed}, "has no PL_hash_seed");
    ok(!exists $data_symbols{PL_ppaddr}, "has no PL_ppaddr");

    ok(! exists $symbols{data}{bss}, "has no data bss symbols");

    # These PerlIO data symbols are left visible with
    # -DPERL_GLOBAL_STRUCT (as opposed to -DPERL_GLOBAL_STRUCT_PRIVATE)
    my @PerlIO =
        qw(
           PerlIO_byte
           PerlIO_crlf
           PerlIO_pending
           PerlIO_perlio
           PerlIO_raw
           PerlIO_remove
           PerlIO_stdio
           PerlIO_unix
           PerlIO_utf8
          );

    # PL_magic_vtables is const with -DPERL_GLOBAL_STRUCT_PRIVATE but
    # otherwise not const -- because of SWIG which wants to modify
    # the table.  Evil SWIG, eeevil.

    # my_cxt_index is used with PERL_IMPLICIT_CONTEXT, which
    # -DPERL_GLOBAL_STRUCT has turned on.
    is_deeply([sort keys %{$symbols{data}{data}}],
              [sort('PL_VarsPtr',
                    @PerlIO,
                    'PL_magic_vtables',
                    'my_cxt_index')],
              "data data symbols");

    # Only one data common symbol, our "supervariable".
    is_deeply([sort keys %{$symbols{data}{common}}],
              ['PL_Vars'],
              "data common symbols");

    ok($symbols{data}{data}{PL_VarsPtr}{'globals.o'}, "has PL_VarsPtr");
    ok($symbols{data}{common}{PL_Vars}{'globals.o'}, "has PL_Vars");

    # -DPERL_GLOBAL_STRUCT has extra text symbol for accessing the vars.
    ok($symbols{text}{Perl_GetVars}{'util.o'}, "has Perl_GetVars");
} else {
    print "# neither -DPERL_GLOBAL_STRUCT nor -DPERL_GLOBAL_STRUCT_PRIVATE\n";

    if ( !$symbols{data}{common} ) {
        # This is likely because Perl was compiled with 
        # -Accflags="-fno-common"
        $symbols{data}{common} = $symbols{data}{bss};
    }
    
    ok($symbols{data}{common}{PL_hash_seed}{'globals.o'}, "has PL_hash_seed");
    ok($symbols{data}{data}{PL_ppaddr}{'globals.o'}, "has PL_ppaddr");

    # None of the GLOBAL_STRUCT* business here.
    ok(! exists $symbols{data}{data}{PL_VarsPtr}, "has no PL_VarsPtr");
    ok(! exists $symbols{data}{common}{PL_Vars}, "has no PL_Vars");
    ok(! exists $symbols{text}{Perl_GetVars}, "has no Perl_GetVars");
}

if (defined $nm_err_tmp) {
    if (open(my $nm_err_fh, $nm_err_tmp)) {
        my $error;
        while (<$nm_err_fh>) {
            # OS X has weird error where nm warns about
            # "no name list" but then outputs fine.
            if (/nm: no name list/ && $^O eq 'darwin') {
                print "# $^O ignoring $nm output: $_";
                next;
            }
            warn "$0: Unexpected $nm error: $_";
            $error++;
        }
        die "$0: Unexpected $nm errors\n" if $error;
    } else {
        warn "Failed to open '$nm_err_tmp': $!\n";
    }
}

done_testing();
