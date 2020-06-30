#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.'; 
    push @INC, '../lib';
}

use Tie::Array;
tie my @foo, 'Tie::StdArray';
tie my @ary, 'Tie::StdArray';
tie my @bar, 'Tie::StdArray';
require "op/array.t"
