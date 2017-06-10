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
