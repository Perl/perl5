use strict;
use warnings;
use Test::More;

use lib 'lib';
BEGIN {
    plan skip_all => 'RNG::Drand48 is not available'
        unless eval { require RNG::Drand48; 1 };
}

my $rng = RNG::Drand48->new(42);
isa_ok($rng, 'RNG::Drand48');
is(length($rng->rand_bytes(0)), 0, 'rand_bytes accepts zero');
is(length($rng->rand_bytes(17)), 17, 'rand_bytes returns the requested length');

my $left = RNG::Drand48->new(42);
my $right = RNG::Drand48->new(42);
is_deeply(
    [ map { $left->rand01 } 1 .. 8 ],
    [ map { $right->rand01 } 1 .. 8 ],
    'the same seed produces the same sequence',
);

my $reset = RNG::Drand48->new(7);
$reset->rand01;
is($reset->srand(42), 42, 'numeric srand returns its seed');
is($reset->rand01, RNG::Drand48->new(42)->rand01,
   'srand resets the sequence');

my @first_provider;
{
    local ${^RNG} = RNG::Drand48->new(42);
    @first_provider = map { rand() } 1 .. 8;
}
my @second_provider;
{
    local ${^RNG} = RNG::Drand48->new(42);
    @second_provider = map { rand() } 1 .. 8;
}
is_deeply(\@first_provider, \@second_provider,
          'the provider sequence is repeatable');

for my $limit (1, 10, 100, 1_000_000) {
    my $value = $rng->rand($limit);
    cmp_ok($value, '>=', 0, "rand($limit) is non-negative");
    cmp_ok($value, '<', $limit, "rand($limit) is below its limit");
}

my $direct = RNG::Drand48->new(42);
my $fast = RNG::Drand48->new(42);
local ${^RNG} = $fast;
is_deeply(
    [ map { rand() } 1 .. 8 ],
    [ map { $direct->rand01 } 1 .. 8 ],
    'the core fast callback matches the provider sequence',
);

done_testing;
