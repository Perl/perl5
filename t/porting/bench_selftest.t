#!./perl -w

# run Porting/bench.pl's selftest

use strict;

chdir '..' if -f 'test.pl' && -f 'thread_it.pl';
require './t/test.pl';

exec $^X, qw(-I. -MTestInit Porting/bench.pl --action=selftest);
die "$^X: $!";
