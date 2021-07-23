#!perl

###############################################################################

use strict;
use warnings;

use Test::More tests => 55;

use bigrat qw/oct hex/;

###############################################################################
# general tests

my $x = 5;
like(ref($x), qr/^Math::BigInt/, '$x = 5 makes $x a Math::BigInt'); # :constant

# todo:  is(2 + 2.5, 4.5);				# should still work
# todo: $x = 2 + 3.5; is(ref($x), 'Math::BigFloat');

$x = 2 ** 255;
like(ref($x), qr/^Math::BigInt/, '$x = 2 ** 255 makes $x a Math::BigInt');

# see if Math::BigRat constant works
is(1/3,         '1/3',    qq|1/3 = '1/3'|);
is(1/4+1/3,     '7/12',   qq|1/4+1/3 = '7/12'|);
is(5/7+3/7,     '8/7',    qq|5/7+3/7 = '8/7'|);

is(3/7+1,       '10/7',   qq|3/7+1 = '10/7'|);
is(3/7+1.1,     '107/70', qq|3/7+1.1 = '107/70'|);
is(3/7+3/7,     '6/7',    qq|3/7+3/7 = '6/7'|);

is(3/7-1,       '-4/7',   qq|3/7-1 = '-4/7'|);
is(3/7-1.1,     '-47/70', qq|3/7-1.1 = '-47/70'|);
is(3/7-2/7,     '1/7',    qq|3/7-2/7 = '1/7'|);

# fails ?
# is(1+3/7, '10/7', qq|1+3/7 = '10/7'|);

is(1.1+3/7,     '107/70', qq|1.1+3/7 = '107/70'|);
is(3/7*5/7,     '15/49',  qq|3/7*5/7 = '15/49'|);
is(3/7 / (5/7), '3/5',    qq|3/7 / (5/7) = '3/5'|);
is(3/7 / 1,     '3/7',    qq|3/7 / 1 = '3/7'|);
is(3/7 / 1.5,   '2/7',    qq|3/7 / 1.5 = '2/7'|);

###############################################################################
# accuracy and precision

is(bigrat->accuracy(),        undef, 'get accuracy');
is(bigrat->accuracy(12),      12,    'set accuracy to 12');
is(bigrat->accuracy(),        12,    'get accuracy again');

is(bigrat->precision(),       undef, 'get precision');
is(bigrat->precision(12),     12,    'set precision to 12');
is(bigrat->precision(),       12,    'get precision again');

is(bigrat->round_mode(),      'even', 'get round mode');
is(bigrat->round_mode('odd'), 'odd',  'set round mode');
is(bigrat->round_mode(),      'odd',  'get round mode again');

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
