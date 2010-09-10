#!/usr/bin/perl -w 

# check that simple requiring BigFloat and then bnan() works

use strict;
use Test;

BEGIN
  {
  plan tests => 1;
  } 

require Math::BigFloat; my $x = Math::BigFloat->bnan(1); ok ($x,'NaN');

# all tests done

