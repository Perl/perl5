#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/thread_taint.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

use Test::More tests => 1;

ok( !$INC{'threads.pm'}, 'Loading Test::More does not load threads.pm' );
