#!/usr/bin/perl -w

###############################################################################
# Test no bigint;

use Test::More;
use strict;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib';
  plan tests => 6;
  }

use bigint;

isnt (ref(1), '', 'is in effect');
isnt (ref(2.0), '', 'is in effect');
isnt (ref(0x20), '', 'is in effect');

{
  no bigint;

  is (ref(1), '', 'is not in effect');
  is (ref(2.0), '', 'is not in effect');
  is (ref(0x20), '', 'is not in effect');
}

