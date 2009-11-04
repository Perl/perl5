#!perl

use strict;
use warnings;

require "test.pl";

plan(4);

use XS::APItest;

my ($prog, $expect) = (<<'PROG', <<'EXPECT');
use XS::APItest;
print "ok\n";
my_exit(1);
print "not\n";
PROG
ok
EXPECT
fresh_perl_is($prog, $expect);
is($? >> 8, 1, "exit code plain my_exit");

($prog, $expect) = (<<'PROG', <<'EXPECT');
use XS::APItest;
print "ok\n";
call_sv( sub { my_exit(1); }, G_EVAL );
print "not\n";
PROG
ok
EXPECT
fresh_perl_is($prog, $expect);
is($? >> 8, 1, "exit code my_exit inside a call_sv with G_EVAL");

