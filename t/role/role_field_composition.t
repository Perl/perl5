#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.42;
use feature 'class';
no warnings 'experimental::class';

role BaseWithReaderAndParam {
    field $base :reader :param = -1;
}

class C::BaseWithReaderAndParam :does(BaseWithReaderAndParam) {}

role ExtendedBaseWithReaderAndParam :does(BaseWithReaderAndParam) {}

class C::E::BaseWithReaderAndParam :does(ExtendedBaseWithReaderAndParam) {}

ok(BaseWithReaderAndParam->can('base'), '... does BaseWithReaderAndParam::base exist');
ok(C::BaseWithReaderAndParam->can('base'), '... does C::BaseWithReaderAndParam::base exist');
ok(ExtendedBaseWithReaderAndParam->can('base'), '... does ExtendedBaseWithReaderAndParam::base exist');
ok(C::E::BaseWithReaderAndParam->can('base'), '... does C::E::BaseWithReaderAndParam::base exist');

my $c = C::BaseWithReaderAndParam->new( base => 20 );
isa_ok($c, 'C::BaseWithReaderAndParam');
ok($c->DOES('BaseWithReaderAndParam'), '... does BaseWithReaderAndParam');
is($c->base, 20, '... got the expected values');

my $ce = C::E::BaseWithReaderAndParam->new( base => 20 );
isa_ok($ce, 'C::E::BaseWithReaderAndParam');
ok($ce->DOES('ExtendedBaseWithReaderAndParam'), '... does ExtendedBaseWithReaderAndParam');
ok($ce->DOES('BaseWithReaderAndParam'), '... does BaseWithReaderAndParam');
is($ce->base, 20, '... got the expected values');

done_testing;
