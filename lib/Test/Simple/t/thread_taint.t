#!/usr/bin/perl -w
# $Id$

use Test::More tests => 1;

ok( !$INC{'threads.pm'}, 'Loading Test::More does not load threads.pm' );
