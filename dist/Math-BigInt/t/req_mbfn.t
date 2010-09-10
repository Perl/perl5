#!/usr/bin/perl -w

# check that simple requiring BigFloat and then new() works

use strict;
use Test;

BEGIN
  {
  plan tests => 1;
  } 

require Math::BigFloat; my $x = Math::BigFloat->new(1);  ++$x; ok ($x,2);

# all tests done

