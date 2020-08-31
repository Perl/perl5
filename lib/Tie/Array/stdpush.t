#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.'; 
    push @INC, '../lib';
}

use Tie::Array;
my @x;
tie @x, 'Tie::StdArray';
require "op/push.t"
