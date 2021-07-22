#!perl

###############################################################################

use strict;
use warnings;

use Test::More tests => 66;

use bigint qw/hex oct/;

###############################################################################
# _constant tests

foreach (qw/
  123:123
  123.4:123
  1.4:1
  0.1:0
  -0.1:0
  -1.1:-1
  -123.4:-123
  -123:-123
  123e2:123e2
  123e-1:12
  123e-4:0
  123e-3:0
  123.345e-1:12
  123.456e+2:12345
  1234.567e+3:1234567
  1234.567e+4:1234567E1
  1234.567e+6:1234567E3
  /)
{
    my ($x, $y) = split /:/;
    is(bigint::_float_constant("$x"), "$y",
       qq|bigint::_float_constant("$x") = $y|);
}

foreach (qw/
  0100:64
  0200:128
  0x100:256
  0b1001:9
  /)
{
    my ($x, $y) = split /:/;
    is(bigint::_binary_constant("$x"), "$y",
       qq|bigint::_binary_constant("$x") = "$y")|);
}

###############################################################################
# general tests

my $x = 5;
like(ref($x), qr/^Math::BigInt/, '$x = 5 makes $x a Math::BigInt'); # :constant

# todo:  is(2 + 2.5, 4.5);                              # should still work
# todo: $x = 2 + 3.5; is(ref($x), 'Math::BigFloat');

$x = 2 ** 255;
like(ref($x), qr/^Math::BigInt/, '$x = 2 ** 255 makes $x a Math::BigInt');

is(12->bfac(), 479001600, '12->bfac() = 479001600');
is(9/4, 2, '9/4 = 2');

is(4.5 + 4.5, 8, '4.5 + 4.5 = 2');                         # truncate
like(ref(4.5 + 4.5), qr/^Math::BigInt/, '4.5 + 4.5 makes a Math::BigInt');

###############################################################################
# accuracy and precision

is(bigint->accuracy(),        undef, 'get accuracy');
is(bigint->accuracy(12),      12,    'set accuracy to 12');
is(bigint->accuracy(),        12,    'get accuracy again');

is(bigint->precision(),       undef, 'get precision');
is(bigint->precision(12),     12,    'set precision to 12');
is(bigint->precision(),       12,    'get precision again');

is(bigint->round_mode(),      'even', 'get round mode');
is(bigint->round_mode('odd'), 'odd',  'set round mode');
is(bigint->round_mode(),      'odd',  'get round mode again');

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
