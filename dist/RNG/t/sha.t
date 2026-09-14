use strict;
use warnings;
use Test::More;

use lib 'lib';
use RNG::SHA;

my $rng = RNG::SHA->new('hello');
isa_ok($rng, 'RNG::SHA');

my @first = map { $rng->rand_bytes(8) } 1 .. 5;
my @second = map { RNG::SHA->new('hello')->rand_bytes(8) } 1 .. 1;
my $copy = RNG::SHA->new('hello');
is_deeply([ map { $copy->rand_bytes(8) } 1 .. 5 ], \@first,
          'the same seed produces the same sequence');
isnt($first[0], $first[4], 'the fifth value comes from a new digest block');

my $reset = RNG::SHA->new('different');
$reset->rand_bytes(8) for 1 .. 3;
is($reset->srand('hello'), 0, 'string srand returns zero');
is($reset->rand_bytes(8), $first[0], 'srand resets the sequence');

for my $value (map { RNG::SHA->new($_)->rand01 } 0, 1, 'hello') {
    cmp_ok($value, '>=', 0, 'rand01 is non-negative');
    cmp_ok($value, '<', 1, 'rand01 is below one');
}

{
    my $direct = RNG::SHA->new(42);
    local ${^RNG} = RNG::SHA->new(42);
    is_deeply([ map { int rand(100) } 1 .. 4 ],
              [ map { int $direct->rand(100) } 1 .. 4 ],
              'the core uses RNG::SHA through ${^RNG}');
}

done_testing;
