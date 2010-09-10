#!/usr/bin/perl -w 

# check that simple requiring BigFloat and then binf() works

use strict;
use Test;

BEGIN
  {
  plan tests => 1;
  } 

require Math::BigFloat; my $x = Math::BigFloat->binf(); ok ($x,'inf');

# all tests done

