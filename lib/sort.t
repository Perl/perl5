#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 2;

BEGIN {
    require "sort.pm"; # require sort; does not work
    ok(sort::current() eq 'mergesort');
}

use sort 'fast';
ok(sort::current() eq 'quicksort fast');

