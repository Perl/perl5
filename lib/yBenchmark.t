#!./perl -w
# https://rt.perl.org/Ticket/Display.html?id=131531
BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib');
}

use warnings;
use strict;

use Benchmark qw(:all);
$Benchmark::Debug++;

my $foo = 0;
my $reps = 5;
my $coderef = sub {++$foo};
my $t = timeit($reps, $coderef);
($t->isa('Benchmark'))
    ? print "timeit CODEREF returned a Benchmark object\n"
    : print "timeit CODEREF did NOT return a Benchmark object\n";
($foo == $reps)
    ? print "benchmarked code was run $reps times\n"
    : print "FAIL: requested $reps reps, but $foo were run\n";
