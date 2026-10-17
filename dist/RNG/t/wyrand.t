use strict;
use warnings;
use Test::More;

use lib 'lib';
use RNG::Seed;
BEGIN {
    plan skip_all => 'RNG::Wyrand is not available'
        unless eval { require RNG::Wyrand; 1 };
}

{
    package RNG::Wyrand::MethodOverride;
    our @ISA = qw(RNG::Wyrand);
    sub rand_bytes { die 'the Perl rand_bytes fallback was used' }
}

my $rng = RNG::Wyrand->new(42);
isa_ok($rng, 'RNG::Wyrand');
is(length($rng->rand_bytes(0)), 0, 'rand_bytes accepts zero');
is(length($rng->rand_bytes(17)), 17, 'rand_bytes returns the requested length');

# wyhash_final4's wyrand() increments a U64 state before mixing it.  The raw
# all-zero seed below is that initial state in little-endian octet order; the
# expected sequence was produced by the tagged reference implementation.
my $reference = RNG::Wyrand->new(RNG::Seed->from_bytes("\0" x 8));
is_deeply(
    [ map { unpack 'H*', $reference->rand_bytes(8) } 1 .. 5 ],
    [ qw(111cb3a78f59a58e ceabd938ff4e856d 61fb51318f47d2a4
         78bd03c491909760 7c003d7fb14820de) ],
    'matches the wyhash_final4 wyrand reference implementation',
);

my $left = RNG::Wyrand->new('hello');
my $right = RNG::Wyrand->new('hello');
is_deeply(
    [ map { $left->rand_bytes(8) } 1 .. 8 ],
    [ map { $right->rand_bytes(8) } 1 .. 8 ],
    'the same seed produces the same sequence',
);
isnt(RNG::Wyrand->new(1)->rand_bytes(8),
     RNG::Wyrand->new(2)->rand_bytes(8),
     'different seeds produce different sequences');

my $reset = RNG::Wyrand->new('different');
$reset->rand_bytes(8);
is($reset->srand('hello'), 'hello', 'string srand returns its seed');
is($reset->rand_bytes(8), RNG::Wyrand->new('hello')->rand_bytes(8),
   'srand resets the sequence');
my $unit = $rng->rand_U01;
cmp_ok($unit, '>=', 0, 'rand_U01 is non-negative');
cmp_ok($unit, '<', 1, 'rand_U01 is below one');
my $callback_rng = RNG::Wyrand->new(99);
my $direct_rng = RNG::Wyrand->new(99);
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
        my $direct = RNG::Wyrand->new(42);
        my $fast = RNG::Wyrand::MethodOverride->new(42);
        local ${^RNG} = $fast;
        is_deeply(
            [ map { int rand(100) } 1 .. 8 ],
            [ map { int $direct->rand(100) } 1 .. 8 ],
            'the core uses the discovered XS callback',
        );
    }
}

done_testing;
