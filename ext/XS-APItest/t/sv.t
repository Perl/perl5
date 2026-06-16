#!perl -w

use v5.42;

use Test::More;

use XS::APItest;
use B qw( SVt_NULL SVt_IV SVt_PVMG SVt_PVGV );

is(svtypename(SVt_NULL), "NULL");
is(svtypename(SVt_IV),   "IV");
is(svtypename(SVt_PVMG), "PVMG");
is(svtypename(SVt_PVGV), "PVGV");
is(svtypename(123),      undef);

done_testing();
