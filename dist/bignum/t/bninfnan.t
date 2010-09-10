#!/usr/bin/perl -w

###############################################################################

use Test;
use strict;

BEGIN
  {
  plan tests => 26;
  }

use bignum;

my ($x);

require "t/infnan.inc";

