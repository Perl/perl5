#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 3;

pass() if not();
is(not(), 1);
is(not(), not(0));
