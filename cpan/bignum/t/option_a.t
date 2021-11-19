# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;

{
    my $class = "Math::BigInt";

    use bigint a => "12";
    cmp_ok($class -> accuracy(), "==", 12, "$class accuracy = 12");

    bigint -> import(accuracy => "23");
    cmp_ok($class -> accuracy(), "==", 23, "$class accuracy = 23");
}

{
    my $class = "Math::BigFloat";

    use bignum a => "12";
    cmp_ok($class -> accuracy(), "==", 12, "$class accuracy = 12");

    bignum -> import(accuracy => "23");
    cmp_ok($class -> accuracy(), "==", 23, "$class accuracy = 23");
}

{
    my $class = "Math::BigRat";

    use bigrat a => "12";
    cmp_ok($class -> accuracy(), "==", 12, "$class accuracy = 12");

    bigrat -> import(accuracy => "23");
    cmp_ok($class -> accuracy(), "==", 23, "$class accuracy = 23");
}
