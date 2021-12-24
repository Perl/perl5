# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 48;

note "\nbigint -> bignum -> bigrat\n\n";

{
    note "use bigint;";
    use bigint;
    is(ref(1), "Math::BigInt");

    {
        note "use bignum;";
        use bignum;
        is(ref(1), "Math::BigFloat");

        {
            note "use bigrat;";
            use bigrat;
            is(ref(1), "Math::BigRat");

            note "no bigrat;";
            no bigrat;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigFloat");

        note "no bignum;";
        no bignum;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigInt");

    note "no bigint;";
    no bigint;
    is(ref(1), "");
}

note "\nbigint -> bigrat -> bignum\n\n";

{
    note "use bigint;";
    use bigint;
    is(ref(1), "Math::BigInt");

    {
        note "use bigrat;";
        use bigrat;
        is(ref(1), "Math::BigRat");

        {
            note "use bignum;";
            use bignum;
            is(ref(1), "Math::BigFloat");

            note "no bignum;";
            no bignum;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigRat");

        note "no bigrat;";
        no bigrat;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigInt");

    note "no bigint;";
    no bigint;
    is(ref(1), "");
}

note "\nbignum -> bigint -> bigrat\n\n";

{
    note "use bignum;";
    use bignum;
    is(ref(1), "Math::BigFloat");

    {
        note "use bigint;";
        use bigint;
        is(ref(1), "Math::BigInt");

        {
            note "use bigrat;";
            use bigrat;
            is(ref(1), "Math::BigRat");

            note "no bigrat;";
            no bigrat;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigInt");

        note "no bigint;";
        no bigint;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigFloat");

    note "no bignum;";
    no bignum;
    is(ref(1), "");
}

note "\nbignum -> bigrat -> bigint\n\n";

{
    note "use bignum;";
    use bignum;
    is(ref(1), "Math::BigFloat");

    {
        note "use bigrat;";
        use bigrat;
        is(ref(1), "Math::BigRat");

        {
            note "use bigint;";
            use bigint;
            is(ref(1), "Math::BigInt");

            note "no bigint;";
            no bigint;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigRat");

        note "no bigrat;";
        no bigrat;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigFloat");

    note "no bignum;";
    no bignum;
    is(ref(1), "");
}

note "\nbigrat -> bigint -> bignum\n\n";

{
    note "use bigrat;";
    use bigrat;
    is(ref(1), "Math::BigRat");

    {
        note "use bigint;";
        use bigint;
        is(ref(1), "Math::BigInt");

        {
            note "use bignum;";
            use bignum;
            is(ref(1), "Math::BigFloat");

            note "no bignum;";
            no bignum;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigInt");

        note "no bigint;";
        no bigint;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigRat");

    note "no bigrat;";
    no bigrat;
    is(ref(1), "");
}

note "\nbigrat -> bignum -> bigint\n\n";

{
    note "use bigrat;";
    use bigrat;
    is(ref(1), "Math::BigRat");

    {
        note "use bignum;";
        use bignum;
        is(ref(1), "Math::BigFloat");

        {
            note "use bigint;";
            use bigint;
            is(ref(1), "Math::BigInt");

            note "no bigint;";
            no bigint;
            is(ref(1), "");
        }

        is(ref(1), "Math::BigFloat");

        note "no bignum;";
        no bignum;
        is(ref(1), "");
    }

    is(ref(1), "Math::BigRat");

    note "no bigrat;";
    no bigrat;
    is(ref(1), "");
}
