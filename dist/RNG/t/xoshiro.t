use strict;
use warnings;
use Test::More;

use lib 'lib';
BEGIN {
    plan skip_all => 'RNG::Xoshiro is not available'
        unless eval { require RNG::Xoshiro; 1 };
}

{
    package RNG::Xoshiro::MethodOverride;
    our @ISA = qw(RNG::Xoshiro);
    sub rand_bytes { die 'the Perl rand_bytes fallback was used' }
}

my $rng = RNG::Xoshiro->new(42);
isa_ok($rng, 'RNG::Xoshiro');
is(length($rng->rand_bytes(0)), 0, 'rand_bytes accepts zero');
is(length($rng->rand_bytes(17)), 17, 'rand_bytes returns the requested length');

# These outputs are from the xoshiro256** reference implementation with
# state s[0..3] = 1, 2, 3, 4.  Raw state words are little-endian; rand_bytes
# emits each generated word in network order.
my $reference = RNG::Xoshiro->new(RNG::Seed->from_bytes(
    pack('V8', 1, 0, 2, 0, 3, 0, 4, 0)
));
is_deeply(
    [ map { unpack 'H*', $reference->rand_bytes(8) } 1 .. 5 ],
    [ qw(
        0000000000002d00
        0000000000000000
        000000005a007080
        10e0000000009d80
        10e0b61ce1009d80
    ) ],
    'raw state follows the xoshiro256** reference implementation',
);

my $left = RNG::Xoshiro->new('hello');
my $right = RNG::Xoshiro->new('hello');
is_deeply(
    [ map { $left->rand_bytes(8) } 1 .. 8 ],
    [ map { $right->rand_bytes(8) } 1 .. 8 ],
    'the same seed produces the same sequence',
);
isnt(RNG::Xoshiro->new(1)->rand_bytes(8),
     RNG::Xoshiro->new(2)->rand_bytes(8),
     'different seeds produce different sequences');

my $reset = RNG::Xoshiro->new('different');
$reset->rand_bytes(8);
is($reset->srand('hello'), 'hello', 'string srand returns its seed');
is($reset->rand_bytes(8), RNG::Xoshiro->new('hello')->rand_bytes(8),
   'srand resets the sequence');
my $unit = $rng->rand_U01;
cmp_ok($unit, '>=', 0, 'rand_U01 is non-negative');
cmp_ok($unit, '<', 1, 'rand_U01 is below one');
my $callback_rng = RNG::Xoshiro->new(99);
my $direct_rng = RNG::Xoshiro->new(99);
is($callback_rng->rand_U01_callback->(), $direct_rng->rand_U01,
   'rand_U01_callback follows the provider sequence');

for my $limit (1, 10, 100, 1_000_000) {
    my $value = $rng->rand($limit);
    cmp_ok($value, '>=', 0, "rand($limit) is non-negative");
    cmp_ok($value, '<', $limit, "rand($limit) is below its limit");
}

{
    SKIP: {
        skip 'the old-Perl shim uses the provider protocol', 1
            unless $RNG::HAS_NATIVE_RNG;
        my $direct = RNG::Xoshiro->new(42);
        my $fast = RNG::Xoshiro::MethodOverride->new(42);
        local ${^RNG} = $fast;
        is_deeply(
            [ map { int rand(100) } 1 .. 8 ],
            [ map { int $direct->rand(100) } 1 .. 8 ],
            'the core uses the discovered XS callback',
        );
    }
}

done_testing;
