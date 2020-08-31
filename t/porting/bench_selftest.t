#!./perl -w

# run Porting/bench.pl's selftest

BEGIN {
    chdir '..' if -f 'test.pl' && -f 'thread_it.pl';
}
system "$^X -I. -MTestInit Porting/bench.pl --action=selftest";
