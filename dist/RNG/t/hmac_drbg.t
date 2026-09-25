use strict;
use warnings;
use Test::More;

use lib 'lib';
BEGIN {
    plan skip_all => 'RNG::HMAC_DRBG is not available'
        unless eval { require RNG::HMAC_DRBG; 1 };
}

{
    package RNG::HMAC_DRBG::MethodOverride;
    our @ISA = qw(RNG::HMAC_DRBG);
    sub rand_bytes { die 'the Perl rand_bytes fallback was used' }
}

{
    package RNG::HMAC_DRBG::PerlFallback;
    our @ISA = qw(RNG::HMAC_DRBG);
    our $calls;
    sub get_rand_u64_XS_func_addr { undef }
    sub rand_bytes {
        ++$calls;
        shift->SUPER::rand_bytes(@_);
    }
}

my $left = RNG::HMAC_DRBG->new('hello');
my $right = RNG::HMAC_DRBG->new('hello');
isa_ok($left, 'RNG::HMAC_DRBG');
is_deeply(
    [ map { $left->rand_bytes(32) } 1 .. 4 ],
    [ map { $right->rand_bytes(32) } 1 .. 4 ],
    'deterministic mode reproduces the sequence',
);
isnt(RNG::HMAC_DRBG->new('one')->rand_bytes(32),
     RNG::HMAC_DRBG->new('two')->rand_bytes(32),
     'different deterministic seeds produce different sequences');
is(
    unpack('H*', RNG::HMAC_DRBG->new(42)->rand_bytes(32)),
    'fa0f26db3f072610874c8933c7b7c6629a7c1de71eb2b671985d4ccaf613b1ca',
    'deterministic output matches the independent HMAC_DRBG calculation',
);
is(
    RNG::HMAC_DRBG->new(42)->get_rand_u64_XS_func_addr > 0,
    1,
    'the XS provider publishes a callback address',
);

for my $length (0, 1, 7, 8, 31, 32, 33, 64, 255) {
    is(
        length(RNG::HMAC_DRBG->new(42)->rand_bytes($length)),
        $length,
        "rand_bytes($length) returns exactly the requested length",
    );
}

my $zero_seed = RNG::HMAC_DRBG->new(0);
my $reset_to_zero = RNG::HMAC_DRBG->new(42);
$reset_to_zero->rand_bytes(32);
$reset_to_zero->srand;
is($reset_to_zero->rand_bytes(32), $zero_seed->rand_bytes(32),
   'srand without a seed resets deterministic mode to seed zero');

my $reseeded = RNG::HMAC_DRBG->new(1);
my $same_reseed = RNG::HMAC_DRBG->new(1);
$reseeded->reseed('additional input');
$same_reseed->reseed('additional input');
is($reseeded->rand_bytes(32), $same_reseed->rand_bytes(32),
   'deterministic reseeding is reproducible');

is($left->reseed_interval, 1_000_000, 'default reseed interval');
$left->reseed_interval(2);
is($left->reseed_interval, 2, 'reseed interval can be changed');
my $reset = RNG::HMAC_DRBG->new('different');
$reset->rand_bytes(16);
$reset->srand('hello');
is($reset->rand_bytes(32), RNG::HMAC_DRBG->new('hello')->rand_bytes(32),
   'explicit srand restores deterministic sequence');
$reset->reseed('additional input');
ok(!$reset->prediction_resistance, 'deterministic mode starts without prediction resistance');
my $prediction_error = eval {
    $reset->prediction_resistance(1);
    '';
};
$prediction_error = $@ if $@;
like(
    $prediction_error,
    qr/prediction resistance requires a secure HMAC_DRBG/,
    'prediction resistance requires secure mode',
);

SKIP: {
    my $secure = eval { RNG::HMAC_DRBG->new_secure('test provider') };
    skip "secure entropy unavailable: $@", 8 unless $secure;
    is(length($secure->rand_bytes(64)), 64, 'secure provider returns requested bytes');
    ok(!$secure->prediction_resistance, 'secure provider starts without prediction resistance');
    ok($secure->rand01 >= 0 && $secure->rand01 < 1,
       'secure rand01 is in range');
    ok($secure->rand(10) >= 0 && $secure->rand(10) < 10,
       'secure rand is below its limit');
    $secure->prediction_resistance(1);
    ok($secure->prediction_resistance, 'prediction resistance can be enabled');
    is(length($secure->rand_bytes(8)), 8, 'prediction-resistant generation works');
    $secure->srand(1234);
    ok(!$secure->prediction_resistance,
       'explicit srand switches secure mode back to deterministic mode');
    is($secure->rand_bytes(8), RNG::HMAC_DRBG->new(1234)->rand_bytes(8),
       'explicit secure srand selects the deterministic sequence');
}

{
    my $direct = RNG::HMAC_DRBG->new(42);
    my $fast = RNG::HMAC_DRBG::MethodOverride->new(42);
    local ${^RNG} = $fast;
    is_deeply(
        [ map { int rand(100) } 1 .. 8 ],
        [ map { int $direct->rand(100) } 1 .. 8 ],
        'the core uses the discovered XS callback',
    );
}

{
    my $fallback = RNG::HMAC_DRBG::PerlFallback->new(42);
    $RNG::HMAC_DRBG::PerlFallback::calls = 0;
    local ${^RNG} = $fallback;
    rand(100) for 1 .. 3;
    is($RNG::HMAC_DRBG::PerlFallback::calls, 3,
       'a provider without an XS callback uses rand_bytes');
}

done_testing;
