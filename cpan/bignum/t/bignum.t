# -*- mode: perl; -*-

###############################################################################

use strict;
use warnings;

use Test::More tests => 19;

use bignum qw/oct hex/;

###############################################################################
# general tests

my $x = 5;
is(ref($x), 'Math::BigFloat', '$x = 5 makes $x a Math::BigFloat'); # :constant

is(2 + 2.5, 4.5, '2 + 2.5 = 4.5');
$x = 2 + 3.5;
is(ref($x), 'Math::BigFloat', '$x = 2 + 3.5 makes $x a Math::BigFloat');

is(2 * 2.1, 4.2, '2 * 2.1 = 4.2');
$x = 2 + 2.1;
is(ref($x), 'Math::BigFloat', '$x = 2 + 2.1 makes $x a Math::BigFloat');

$x = 2 ** 255;
is(ref($x), 'Math::BigFloat', '$x = 2 ** 255 makes $x a Math::BigFloat');

is(sqrt(12), '3.464101615137754587054892683011744733886',
   'sqrt(12)');

is(2/3, "0.6666666666666666666666666666666666666667", '2/3');

#is(2 ** 0.5, 'NaN');   # should be sqrt(2);

is(12->bfac(), 479001600, '12->bfac() = 479001600');

# see if Math::BigFloat constant works

#                     0123456789          0123456789    <- default 40
#           0123456789          0123456789
is(1/3, '0.3333333333333333333333333333333333333333', '1/3');

###############################################################################
# accuracy and precision

is(bignum->accuracy(), undef, 'get accuracy');
bignum->accuracy(12);
is(bignum->accuracy(), 12, 'get accuracy again');
bignum->accuracy(undef);
is(bignum->accuracy(), undef, 'get accuracy again');

is(bignum->precision(), undef, 'get precision');
bignum->precision(12);
is(bignum->precision(), 12, 'get precision again');
bignum->precision(undef);
is(bignum->precision(), undef, 'get precision again');

is(bignum->round_mode(), 'even', 'get round mode');
bignum->round_mode('odd');
is(bignum->round_mode(), 'odd', 'get round mode again');
bignum->round_mode('even');
is(bignum->round_mode(), 'even', 'get round mode again');
