#!/usr/bin/perl
# $Id: /mirror/googlecode/test-more/t/Tester/tbt_03die.t 60331 2008-09-09T12:17:12.607612Z schwern  $

use Test::Builder::Tester tests => 1;
use Test::More;

eval {
    test_test("foo");
};
like($@,
     "/Not testing\.  You must declare output with a test function first\./",
     "dies correctly on error");

