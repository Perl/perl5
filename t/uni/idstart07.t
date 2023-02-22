#!./perl

use strict;
use warnings;
no warnings 'once';

__FILE__ =~ m/ ( \d+ ) \. t $ /x;
$::TESTCHUNK = $1 + 0;
#print STDERR __FILE__, ": ", __LINE__, ": ", $::TESTCHUNK, "\n";
do './uni/idstart.pl';
#print STDERR __FILE__, ": ", __LINE__, ": ", $@, "\n";

1
