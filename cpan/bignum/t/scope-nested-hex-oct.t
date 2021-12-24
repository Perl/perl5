# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Need at least Perl v5.10.1' if $] < "5.010001";

plan tests => 96;

note "\nbigint -> bignum -> bigrat\n\n";

{
    note "use bigint;";
    use bigint;
    is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

    {
        note "use bignum;";
        use bignum;
        is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

        {
            note "use bigrat;";
            use bigrat;
            is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

            note "no bigrat;";
            no bigrat;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

        note "no bignum;";
        no bignum;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

    note "no bigint;";
    no bigint;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}

note "\nbigint -> bigrat -> bignum\n\n";

{
    note "use bigint;";
    use bigint;
    is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

    {
        note "use bigrat;";
        use bigrat;
        is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

        {
            note "use bignum;";
            use bignum;
            is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

            note "no bignum;";
            no bignum;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

        note "no bigrat;";
        no bigrat;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

    note "no bigint;";
    no bigint;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}

note "\nbignum -> bigint -> bigrat\n\n";

{
    note "use bignum;";
    use bignum;
    is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

    {
        note "use bigint;";
        use bigint;
        is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

        {
            note "use bigrat;";
            use bigrat;
            is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

            note "no bigrat;";
            no bigrat;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

        note "no bigint;";
        no bigint;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

    note "no bignum;";
    no bignum;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}

note "\nbignum -> bigrat -> bigint\n\n";

{
    note "use bignum;";
    use bignum;
    is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

    {
        note "use bigrat;";
        use bigrat;
        is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

        {
            note "use bigint;";
            use bigint;
            is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

            note "no bigint;";
            no bigint;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

        note "no bigrat;";
        no bigrat;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

    note "no bignum;";
    no bignum;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}

note "\nbigrat -> bigint -> bignum\n\n";

{
    note "use bigrat;";
    use bigrat;
    is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

    {
        note "use bigint;";
        use bigint;
        is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

        {
            note "use bignum;";
            use bignum;
            is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

            note "no bignum;";
            no bignum;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

        note "no bigint;";
        no bigint;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

    note "no bigrat;";
    no bigrat;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}

note "\nbigrat -> bignum -> bigint\n\n";

{
    note "use bigrat;";
    use bigrat;
    is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

    {
        note "use bignum;";
        use bignum;
        is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

        {
            note "use bigint;";
            use bigint;
            is(ref(hex("1")), "Math::BigInt", 'ref(hex("1"))');
            is(ref(oct("1")), "Math::BigInt", 'ref(oct("1"))');

            note "no bigint;";
            no bigint;
            is(ref(hex("1")), "", 'ref(hex("1"))');
            is(ref(oct("1")), "", 'ref(oct("1"))');
        }

        is(ref(hex("1")), "Math::BigFloat", 'ref(hex("1"))');
        is(ref(oct("1")), "Math::BigFloat", 'ref(oct("1"))');

        note "no bignum;";
        no bignum;
        is(ref(hex("1")), "", 'ref(hex("1"))');
        is(ref(oct("1")), "", 'ref(oct("1"))');
    }

    is(ref(hex("1")), "Math::BigRat", 'ref(hex("1"))');
    is(ref(oct("1")), "Math::BigRat", 'ref(oct("1"))');

    note "no bigrat;";
    no bigrat;
    is(ref(hex("1")), "", 'ref(hex("1"))');
    is(ref(oct("1")), "", 'ref(oct("1"))');
}
