#!perl -w

use strict;
use Test::More;

use XS::APItest;

ok(test_isBLANK_uni(ord("\N{EM SPACE}")), "EM SPACE is blank in isBLANK_uni()");
ok(test_isBLANK_utf8("\N{EM SPACE}"), "EM SPACE is blank in isBLANK_utf8()");

ok(! test_isBLANK_uni(ord("\N{GREEK DASIA}")), "GREEK DASIA is not a blank in isBLANK_uni()");
ok(! test_isBLANK_utf8("\N{GREEK DASIA}"), "GREEK DASIA is not a blank in isBLANK_utf8()");

done_testing;
