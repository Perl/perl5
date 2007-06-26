#!/usr/bin/perl -w

###############################################################################
# test for e() and PI() exports

use Test::More;
use strict;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib';
  plan tests => 4;
  }

use bigint qw/e PI/;

is (e, "2", 'e');
is (PI, "3", 'PI');

is (e(10), "2", 'e');
is (PI(10), "3", 'PI');
