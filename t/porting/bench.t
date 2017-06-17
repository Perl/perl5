#!/usr/bin/perl

# Check the functionality of the Porting/bench.pl executable;
# in particular, its argument handling and its ability to produce
# the expected output for particular arguments.
#
# See also t/porting/bench_selftest.pl

use warnings;
use strict;

BEGIN {
    chdir '..' if -f 'test.pl' && -f 'thread_it.pl';
    require './t/test.pl';
}

# Only test on git checkouts - this is more of a perl core developer
# tool than an end-user tool.
# Only test on a platform likely to support forking, pipes, cachegrind
# etc.  Add other platforms if you think they're safe.

skip_all "not devel"   unless -d ".git";
skip_all "not linux"   unless $^O eq 'linux';
skip_all "no valgrind" unless -x '/bin/valgrind' || -x '/usr/bin/valgrind';


my $bench_pl = "Porting/bench.pl";

ok -e $bench_pl, "$bench_pl exists and is executable";

my $bench_cmd = "$^X -Ilib $bench_pl";

my $out;

# Read in the expected output format templates and create qr//s from them.

my %formats;
my %format_qrs;

{
    my $cur;
    while (<DATA>) {
        next if /^#/;
        if (/^FORMAT:/) {
            die "invalid format line: $_" unless /^FORMAT:\s+(\w+)\s*$/;
            $cur = $1;
            die "duplicate format: '$cur'\n" if exists $formats{$cur};
            next;
        }
        $formats{$cur} .= $_;
    }

    for my $name (sort keys %formats) {
        my $f = $formats{$name};

        # expand "%%SUB_FORMAT%%
        $f =~ s{^ \s* %% (\w+) %% [ \t]* \n}
               {
                    my $f1 = $formats{$1};
                    die "No such sub-format '%%$1%%' in format '$name'\n"
                        unless defined $f1;
                    $f1;
               }gmxe;

        $f = quotemeta $f;

        # convert NNNN.NN placeholders into a regex
        $f =~ s{(N+)\\.(N+)}
               {
                    "("
                    . "\\s*-?\\d+\."
                    . "\\d" x length($2)
                    ."|-)"
               }ge;
        $format_qrs{$name} = qr/\A$f\z/;
    }
}


# ---------------------------------------------------
# check croaks

for my $test (
    [
        "--boz",
        "Unknown option: boz\nUse the -h option for usage information.\n",
        "croak: basic unknown option"
    ],
    [
        "--fields=Ir,Boz",
        "Error: --fields: unknown field 'Boz'\n",
        "croak: unknown --field"
    ],
    [
        "--action=boz",
        "Error: unrecognised action 'boz'\nmust be one of: grind, selftest\n",
        "croak: unknown --action"
    ],
    [
        "--sort=boz",
        "Error: --sort argument should be of the form field:perl: 'boz'\n",
        "croak: invalid --sort"
    ],
    [
        "--sort=boz:perl",
        "Error: --sort: unknown field 'boz'\n",
        "croak: unknown --sort field"
    ],
    [
        "-action=selftest perl",
        "Error: no perl executables may be specified with selftest\n",
        "croak: --action-selftest with executable"
    ],
    [
        "--tests=/boz perl",
        "Error: --tests regex must be of the form /.../\n",
        "croak: invalid --tests regex"
    ],
    [
        "--tests=call::sub::empty,foo::bar::baz::boz perl",
        "Error: no such test found: 'foo::bar::baz::boz'\n",
        "croak: unknown test in --tests"
    ],
    [
        "--tests=/foo::bar::baz::boz/ perl",
        "Error: no tests to run\n",
        "croak: no --tests to run "
    ],
    [
        "--benchfile=no-such-file-boz perl",
        qr/\AError: can't read 'no-such-file-boz':/,
        "croak: non-existent --benchfile "
    ],
    [
        "--benchfile=t/porting/bench/synerr perl",
        qr{\AError: can't parse 't/porting/bench/synerr':\nsyntax error},
        "croak: --benchfile with syntax error"
    ],
    [
        "--benchfile=t/porting/bench/ret0 perl",
        "Error: can't load 't/porting/bench/ret0': code didn't return a true value\n",
        "croak: --benchfile which returns 0"
    ],
    [
        "--norm=2 ./miniperl ./perl",
        "Error: --norm value 2 outside range 0..1\n",
        "croak: select-a-perl out of range"
    ],
    [
        "--sort=Ir:myperl ./miniperl ./perl",
        "Error: --sort: unrecognised perl 'myperl'\n",
        "croak: select-a-perl unrecognised"
    ],
    [
        "--compact=./perl ./perl=A ./perl=B",
        "Error: --compact: ambiguous perl './perl'\n",
        "croak: select-a-perl ambiguous"
    ],
    [
        " ./perl=A ./miniperl=A",
        "A cannot be used on 2 different perls under test\n",
        "croak: duplicate label"
    ],
    [
        "--grindargs=Boz --tests=call::sub::empty ./perl=A ./perl=B",
        qr{Error: while executing call::sub::empty/A empty/short loop:\nunexpected code or cachegrind output:\n},
        "croak: cachegrind output format "
    ],
    [
        "--bisect=Ir",,
        "Error: --bisect option must be of form 'field,integer,integer'\n",
        "croak: --bisect=Ir"
    ],
    [
        "--bisect=Ir,1",,
        "Error: --bisect option must be of form 'field,integer,integer'\n",
        "croak: --bisect=Ir,1"
    ],
    [
        "--bisect=Ir,1,2,3",
        "Error: --bisect option must be of form 'field,integer,integer'\n",
        "croak: --bisect=Ir,1,2,3"
    ],
    [
        "--bisect=Ir,1,x",
        "Error: --bisect option must be of form 'field,integer,integer'\n",
        "croak: --bisect=Ir,1,x"
    ],
    [
        "--bisect=Ir,x,2",
        "Error: --bisect option must be of form 'field,integer,integer'\n",
        "croak: --bisect=Ir,x,2"
    ],
    [
        "--bisect=boz,1,2",
        "Error: unrecognised field 'boz' in --bisect option\n",
        "croak: --bisect=boz,1,2"
    ],
    [
        "--bisect=Ir,2,1",
        "Error: --bisect min (2) must be <= max (1)\n",
        "croak: --bisect=boz,2,1"
    ],
    [
        "--read=no-such-file-boz",
        qr/\AError: can't open 'no-such-file-boz' for reading:/,
        "croak: non-existent --read file "
    ],
    [
        "--read=t/porting/bench/badversion.json",
        "Error: unsupported version 9999.9 in file 't/porting/bench/badversion.json' (too new)\n",
        "croak: --read version"
    ],
    [
        "",
        "Error: nothing to do: no perls to run, no data to read.\n",
        "croak: no input"
    ],
    [
        "./perl",
        "Error: need at least 2 perls for comparison.\n",
        "croak: need 2 perls"
    ],
    [
        "--bisect=Ir,1,2 ./perl=A ./perl=B",
        "Error: exactly one perl executable must be specified for bisect\n",
        "croak: --bisect, need 1 perls"
    ],
    [
        "--bisect=Ir,1,2 --tests=/call/ ./perl=A",
        "Error: only a single test may be specified with --bisect\n",
        "croak: --bisect one test only"
    ],
    # note that callsub.json was created using
    # ./perl -Ilib Porting/bench.pl --tests='/call::sub::(amp_)?empty/' \
    #                     --write=t/porting/bench/callsub.json ./perl
    [
        "--read=t/porting/bench/callsub.json --write=no/such/file/boz",
        qr{\AError: can't open 'no/such/file/boz' for writing: },
        "croak: --write open error"
    ],
    # note that callsub2.json was created using
    # ./perl -Ilib Porting/bench.pl \
    #    --tests='call::sub::empty,call::sub::args3' \
    #                     --write=t/porting/bench/callsub2.json ./perl
    [
           "--read=t/porting/bench/callsub.json "
        . " --read=t/porting/bench/callsub2.json",
        "Can't merge multiple read files: they contain differing test sets.\n"
        . "Re-run with --verbose to see the differences.\n",
        "croak: --read callsub, callsub2"
    ],
    [
           "--read=t/porting/bench/callsub.json "
        . " --read=t/porting/bench/callsub2.json"
        . " --verbose",
        "Can't merge multiple read files: they contain differing test sets.\n"
        . "Previous tests:\n"
        . "  call::sub::amp_empty\n"
        . "  call::sub::empty\n"
        . "tests from 't/porting/bench/callsub2.json':\n"
        . "  call::sub::args3\n"
        . "  call::sub::empty\n",
        "croak: --read callsub, callsub2 --verbose"
    ],

    # these ones aren't tested (and nor are any "Panic:" ones):

    # Error: can't parse '$field' field from cachegrind output
    # Error: while starting cachegrind subprocess for NNNN:
    # File '$file' contains no results
    # File '$file' contains differing test and results names
    # File '$file' contains differing test and sort order names
    # Can't merge multiple read files: differing loop counts:
)
{
    my ($args, $expected, $desc) = @$test;
    $out = qx($bench_cmd $args 2>&1);
    if (ref($expected)) {
        like $out, $expected, $desc;
    }
    else {
        is $out, $expected, $desc;
    }
}

# ---------------------------------------------------
# run benchmarks


my $resultfile1 = tempfile(); # benchmark results for 1 perl
my $resultfile2 = tempfile(); # benchmark results for 2 perls

# Run a real cachegrind session and write results to file.
# the -j 2 is to minimally exercise its parallel facility.

note("running cachegrind for 1st perl; may be slow...");
$out = qx($bench_cmd -j 2 --write=$resultfile1 --tests=call::sub::empty $^X=p0 2>&1);
is length($out), 0, "--write should produce no output (1 perl)";
ok -s $resultfile1, "--write should create a non-empty results file (1 perl)";

# and again with 2 perls. This is also tests the 'mix read and new new
# perls' functionality.

note("running cachegrind for 2nd perl; may be slow...");
$out = qx($bench_cmd -j 2 --read=$resultfile1 --write=$resultfile2 $^X=p1 2>&1);
is length($out), 0, "--write should produce no output (2 perls)"
    or diag("got: $out");
ok -s $resultfile2, "--write should create a non-empty results file (2 perls)";

# 1 perl:

# read back the results in raw form

$out = qx($bench_cmd --read=$resultfile1 --raw 2>&1);
like $out, $format_qrs{raw1}, "basic cachegrind raw format; 1 perl";

# and read back the results in raw compact form

$out = qx($bench_cmd --read=$resultfile1 --raw --compact=0 2>&1);
like $out, $format_qrs{raw_compact}, "basic cachegrind raw compact format; 1 perl";

# 2 perls:

# read back the results in relative-percent form

$out = qx($bench_cmd --read=$resultfile2 2>&1);
like $out, $format_qrs{percent2}, "basic cachegrind percent format; 2 perls";

# and read back the results in raw form

$out = qx($bench_cmd --read=$resultfile2 --raw 2>&1);
like $out, $format_qrs{raw2}, "basic cachegrind raw format; 2 perls";

# and read back the results in compact form

$out = qx($bench_cmd --read=$resultfile2 --compact=1 2>&1);
like $out, $format_qrs{compact}, "basic cachegrind compact format; 2 perls";


# bisect

note("running cachegrind bisect on 1 perl; may be slow...");

# the Ir range here is intended such that the bisect will always fail
$out = qx($bench_cmd --tests=call::sub::empty --bisect=Ir,100000,100001 $^X=p0 2>&1);

is $?, 1 << 8, "--bisect should not match";
is length($out), 0, "--bisect should produce no output"
    or diag("got: $out");

# multiple reads with differing test sets but common --tests subset

$out = qx($bench_cmd --read=t/porting/bench/callsub.json  --read=t/porting/bench/callsub2.json --tests=call::sub::empty 2>&1);
$out =~ s{^\./perl}{p0}m;
$out =~ s{\Q./perl ./perl}{    p0     p1};
like $out, $format_qrs{percent2}, "2 reads; overlapping test sets";

# A read defines what benchmarks to run

note("running cachegrind on 1 perl; may be slow...");
$out = qx($bench_cmd --read=t/porting/bench/callsub.json --tests=call::sub::empty $^X=p1 2>&1);
$out =~ s{^\./perl}{p0}m;
$out =~ s{\Q./perl}{    p0};
like $out, $format_qrs{percent2}, "1 read; 1 generate";



done_testing();


# Templates for expected output formats.
#
# Lines starting with '#' are skipped.
# Lines of the form 'FORMAT: foo' start and name a new template
# All other lines are part of the template
# Entries of the form NNNN.NN are converted into a regex of the form
#    ( \s* -? \d+\.\d\d | - )
# i.e. it expects number with a fixed number of digits after the point,
# or a '-'.
# Lines of the form %%FOO%% are substituted with format 'FOO'


__END__
# ===================================================================
FORMAT: STD_HEADER
Key:
    Ir   Instruction read
    Dr   Data read
    Dw   Data write
    COND conditional branches
    IND  indirect branches
    _m   branch predict miss
    _m1  level 1 cache miss
    _mm  last cache (e.g. L3) miss
    -    indeterminate percentage (e.g. 1/0)
# ===================================================================
FORMAT: percent2
%%STD_HEADER%%

The numbers represent relative counts per loop iteration, compared to
p0 at 100.0%.
Higher is better: for example, using half as many instructions gives 200%,
while using twice as many gives 50%.

call::sub::empty
function call with no args or body

           p0     p1
       ------ ------
    Ir 100.00 NNN.NN
    Dr 100.00 NNN.NN
    Dw 100.00 NNN.NN
  COND 100.00 NNN.NN
   IND 100.00 NNN.NN

COND_m 100.00 NNN.NN
 IND_m 100.00 NNN.NN

 Ir_m1 100.00 NNN.NN
 Dr_m1 100.00 NNN.NN
 Dw_m1 100.00 NNN.NN

 Ir_mm 100.00 NNN.NN
 Dr_mm 100.00 NNN.NN
 Dw_mm 100.00 NNN.NN
# ===================================================================
FORMAT: raw1
%%STD_HEADER%%

The numbers represent raw counts per loop iteration.

call::sub::empty
function call with no args or body

             p0
       --------
    Ir NNNNNN.N
    Dr NNNNNN.N
    Dw NNNNNN.N
  COND NNNNNN.N
   IND NNNNNN.N

COND_m NNNNNN.N
 IND_m NNNNNN.N

 Ir_m1 NNNNNN.N
 Dr_m1 NNNNNN.N
 Dw_m1 NNNNNN.N

 Ir_mm NNNNNN.N
 Dr_mm NNNNNN.N
 Dw_mm NNNNNN.N
# ===================================================================
FORMAT: raw2
%%STD_HEADER%%

The numbers represent raw counts per loop iteration.

call::sub::empty
function call with no args or body

             p0       p1
       -------- --------
    Ir NNNNNN.N NNNNNN.N
    Dr NNNNNN.N NNNNNN.N
    Dw NNNNNN.N NNNNNN.N
  COND NNNNNN.N NNNNNN.N
   IND NNNNNN.N NNNNNN.N

COND_m NNNNNN.N NNNNNN.N
 IND_m NNNNNN.N NNNNNN.N

 Ir_m1 NNNNNN.N NNNNNN.N
 Dr_m1 NNNNNN.N NNNNNN.N
 Dw_m1 NNNNNN.N NNNNNN.N

 Ir_mm NNNNNN.N NNNNNN.N
 Dr_mm NNNNNN.N NNNNNN.N
 Dw_mm NNNNNN.N NNNNNN.N
# ===================================================================
FORMAT: compact
%%STD_HEADER%%

The numbers represent relative counts per loop iteration, compared to
p0 at 100.0%.
Higher is better: for example, using half as many instructions gives 200%,
while using twice as many gives 50%.

Results for p1

     Ir     Dr     Dw   COND    IND COND_m  IND_m  Ir_m1  Dr_m1  Dw_m1  Ir_mm  Dr_mm  Dw_mm
 ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------
 NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN NNN.NN  call::sub::empty
# ===================================================================
FORMAT: raw_compact
%%STD_HEADER%%

The numbers represent raw counts per loop iteration.

Results for p0

      Ir      Dr      Dw    COND     IND  COND_m   IND_m   Ir_m1   Dr_m1   Dw_m1   Ir_mm   Dr_mm   Dw_mm
  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------
 NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N NNNNN.N  call::sub::empty
# ===================================================================
