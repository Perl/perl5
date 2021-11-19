# -*- mode: perl; -*-

###############################################################################
# Test in_effect()

use strict;
use warnings;

use Test::More tests => 21;

{
    use bigint;

    can_ok('bigint', qw/in_effect/);

  SKIP: {
        skip('Need at least Perl v5.9.4', 3) if $] < "5.009005";

        is(bigint::in_effect(), 1,     'bigint in effect');
        is(bignum::in_effect(), undef, 'bignum not in effect');
        is(bigrat::in_effect(), undef, 'bigint not in effect');
    }

    {
        no bigint;

        is(bigint::in_effect(), undef, 'bigint not in effect');
        is(bignum::in_effect(), undef, 'bignum not in effect');
        is(bigrat::in_effect(), undef, 'bigrat not in effect');
    }
}

{
    use bignum;

    can_ok('bignum', qw/in_effect/);

  SKIP: {
        skip('Need at least Perl v5.9.4', 3) if $] < "5.009005";

        is(bigint::in_effect(), undef, 'bigint not in effect');
        is(bignum::in_effect(), 1,     'bignum in effect');
        is(bigrat::in_effect(), undef, 'bigint not in effect');
    }

    {
        no bignum;

        is(bigint::in_effect(), undef, 'bigint not in effect');
        is(bignum::in_effect(), undef, 'bignum not in effect');
        is(bigrat::in_effect(), undef, 'bigrat not in effect');
    }
}

{
    use bigrat;

    can_ok('bigrat', qw/in_effect/);

  SKIP: {
        skip('Need at least Perl v5.9.4', 3) if $] < "5.009005";

        is(bigint::in_effect(), undef, 'bigint not in effect');
        is(bignum::in_effect(), undef, 'bignum not in effect');
        is(bigrat::in_effect(), 1,     'bigint in effect');
    }

    {
        no bigrat;

        is(bigint::in_effect(), undef, 'bigint not in effect');
        is(bignum::in_effect(), undef, 'bignum not in effect');
        is(bigrat::in_effect(), undef, 'bigrat not in effect');
    }
}
