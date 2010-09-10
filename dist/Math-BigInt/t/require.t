#!/usr/bin/perl -w

# check that simple requiring BigInt works

use strict;
use Test;

BEGIN
  {
  plan tests => 1;
  } 

my ($x);

require Math::BigInt; $x = Math::BigInt->new(1); ++$x;

ok ($x||'undef',2);

# all tests done

