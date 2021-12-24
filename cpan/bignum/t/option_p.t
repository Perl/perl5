# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;

{
    my $class = "Math::BigInt";

    use bigint p => "12";
    cmp_ok($class -> precision(), "==", 12, "$class precision = 12");

    bigint -> import(precision => "23");
    cmp_ok($class -> precision(), "==", 23, "$class precision = 23");
}

{
    my $class = "Math::BigFloat";

    use bignum p => "12";
    cmp_ok($class -> precision(), "==", 12, "$class precision = 12");

    bignum -> import(precision => "23");
    cmp_ok($class -> precision(), "==", 23, "$class precision = 23");
}

{
    my $class = "Math::BigRat";

    use bigrat p => "12";
    cmp_ok($class -> precision(), "==", 12, "$class precision = 12");

    bigrat -> import(precision => "23");
    cmp_ok($class -> precision(), "==", 23, "$class precision = 23");
}
