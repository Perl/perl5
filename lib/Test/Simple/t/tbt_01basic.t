#!/usr/bin/perl

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::Builder::Tester tests => 12;
use Test::More;

ok(1,"This is a basic test");

test_out("ok 1 - tested");
ok(1,"tested");
test_test("captured okay on basic");

test_out("ok 1 - tested");
ok(1,"tested");
test_test("captured okay again without changing number");

ok(1,"test unrelated to Test::Builder::Tester");

test_out("ok 1 - one");
test_out("ok 2 - two");
ok(1,"one");
ok(2,"two");
test_test("multiple tests");

test_out("not ok 1 - should fail");
test_err("#     Failed test ($0 at line 35)");
test_err("#          got: 'foo'");
test_err("#     expected: 'bar'");
is("foo","bar","should fail");
test_test("testing failing");


test_fail(+2);
test_fail(+1);
fail();  fail();
test_test("testing failing on the same line with no name");


test_fail(+2, 'name');
test_fail(+1, 'name_two');
fail("name");  fail("name_two");
test_test("testing failing on the same line with the same name");


test_out("not ok 1 - name # TODO Something");
my $line = __LINE__ + 4;
test_err("#     Failed (TODO) test ($0 at line $line)");
TODO: { 
    local $TODO = "Something";
    fail("name");
}
test_test("testing failing with todo");

test_pass();
pass();
test_test("testing passing with test_pass()");

test_pass("some description");
pass("some description");
test_test("testing passing with test_pass() and description");

test_pass("one test");
test_pass("... and another");
ok(1, "one test");
ok(1, "... and another");
test_test("testing pass_test() and multiple tests");
