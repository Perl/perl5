#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    skip_all_without_config('d_setpgrp');
}

plan tests => 2;

ok(!eval { package A;sub foo { die("got here") }; package main; A->foo(setpgrp())});
ok($@ =~ /got here/, "setpgrp() should extend the stack before modifying it");
