#!perl

###############################################################################

use strict;
use warnings;

use Test::More tests => 50;

use bignum qw/oct hex/;

###############################################################################
# general tests

my $x = 5;
like(ref($x), qr/^Math::BigInt/, '$x = 5 makes $x a Math::BigInt'); # :constant

is(2 + 2.5, 4.5, '2 + 2.5 = 4.5');
$x = 2 + 3.5;
is(ref($x), 'Math::BigFloat', '$x = 2 + 3.5 makes $x a Math::BigFloat');

is(2 * 2.1, 4.2, '2 * 2.1 = 4.2');
$x = 2 + 2.1;
is(ref($x), 'Math::BigFloat', '$x = 2 + 2.1 makes $x a Math::BigFloat');

$x = 2 ** 255;
like(ref($x), qr/^Math::BigInt/, '$x = 2 ** 255 makes $x a Math::BigInt');

# see if Math::BigInt constant and upgrading works
is(Math::BigInt::bsqrt("12"), '3.464101615137754587054892683011744733886',
   'Math::BigInt::bsqrt("12")');
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

is(bignum->accuracy(),        undef,  'get accuracy');
is(bignum->accuracy(12),      12,     'set accuracy to 12');
is(bignum->accuracy(),        12,     'get accuracy again');

is(bignum->precision(),       undef,  'get precision');
is(bignum->precision(12),     12,     'set precision to 12');
is(bignum->precision(),       12,     'get precision again');

is(bignum->round_mode(),      'even', 'get round mode');
is(bignum->round_mode('odd'), 'odd',  'set round mode');
is(bignum->round_mode(),      'odd',  'get round mode again');

###############################################################################
# hex() and oct()

my $class = 'Math::BigInt';

my @table =
  (

   [ 'hex(1)',       1 ],
   [ 'hex(01)',      1 ],
   [ 'hex(0x1)',     1 ],
   [ 'hex("01")',    1 ],
   [ 'hex("0x1")',   1 ],
   [ 'hex("0X1")',   1 ],
   [ 'hex("x1")',    1 ],
   [ 'hex("X1")',    1 ],
   [ 'hex("af")',  175 ],

   [ 'oct(1)',       1 ],
   [ 'oct(01)',      1 ],
   [ 'oct(" 1")',    1 ],

   [ 'oct(0x1)',     1 ],
   [ 'oct("0x1")',   1 ],
   [ 'oct("0X1")',   1 ],
   [ 'oct("x1")',    1 ],
   [ 'oct("X1")',    1 ],
   [ 'oct(" 0x1")',  1 ],

   [ 'oct(0b1)',     1 ],
   [ 'oct("0b1")',   1 ],
   [ 'oct("0B1")',   1 ],
   [ 'oct("b1")',    1 ],
   [ 'oct("B1")',    1 ],
   [ 'oct(" 0b1")',  1 ],

   #[ 'oct(0o1)',     1 ],       # requires Perl 5.33.8
   [ 'oct("01")',    1 ],
   [ 'oct("0o1")',   1 ],
   [ 'oct("0O1")',   1 ],
   [ 'oct("o1")',    1 ],
   [ 'oct("O1")',    1 ],
   [ 'oct(" 0o1")',  1 ],

  );

for my $entry (@table) {
    my ($test, $want) = @$entry;
    subtest $test, sub {
        plan tests => 2;
        my $got = eval $test;
        cmp_ok($got, '==', $want, 'the output value is correct');
        is(ref($x), $class, 'the reference type is correct');
    };
}
