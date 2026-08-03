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

is(test_sv_set_undef(), 1, "sv_set_undef() preserves temp");
is(test_sv_set_PL_sv_undef(), 1, "sv_setsv(..., &PL_sv_undef) preserves temp");
is(test_sv_setiv_temp(), 1, "sv_setiv(..., 0) preserves temp");

done_testing();
