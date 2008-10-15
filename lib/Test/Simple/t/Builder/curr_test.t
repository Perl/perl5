#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/Builder/curr_test.t 60332 2008-09-09T12:24:03.060291Z schwern  $

# Dave Rolsky found a bug where if current_test() is used and no
# tests are run via Test::Builder it will blow up.

use Test::Builder;
$TB = Test::Builder->new;
$TB->plan(tests => 2);
print "ok 1\n";
print "ok 2\n";
$TB->current_test(2);
