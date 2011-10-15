#!perl -w

use strict;
use warnings;
use Test::More tests => 1;

use XS::APItest;

is join("", sort xs_cmp split//, '1415926535'), '1135559246',
  'sort treats XS cmp routines as having implicit ($$)';
