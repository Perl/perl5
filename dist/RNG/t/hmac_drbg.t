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
    sub get_rand_U01_XS_func_addr { undef }
    sub rand_bytes {
        ++$calls;
        shift->SUPER::rand_bytes(@_);
    }
}

{
    package RNG::HMAC_DRBG::TiedScalar;
    sub TIESCALAR { bless { value => $_[1], fetches => 0 }, $_[0] }
    sub FETCH {
        $_[0]{fetches}++;
        return $_[0]{value};
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

# NIST SP 800-90A Rev. 1, HMAC_DRBG SHA-256 example, first Generate call.
my $nist_seed = RNG::HMAC_DRBG->seed_from_entropy(
    pack('H*', '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f'
             . '202122232425262728292a2b2c2d2e2f30313233343536'),
    pack('H*', '2021222324252627'),
);
{
    my ($entropy, $nonce, $personalization);
    my $entropy_tie = tie $entropy, 'RNG::HMAC_DRBG::TiedScalar',
        pack('H*', '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f'
                   . '202122232425262728292a2b2c2d2e2f30313233343536');
    my $nonce_tie = tie $nonce, 'RNG::HMAC_DRBG::TiedScalar',
        pack('H*', '2021222324252627');
    my $personalization_tie = tie $personalization,
        'RNG::HMAC_DRBG::TiedScalar', 'personalization';
    my $tied_seed = RNG::HMAC_DRBG->seed_from_entropy(
        $entropy, $nonce, $personalization);
    my $ordinary_seed = RNG::HMAC_DRBG->seed_from_entropy(
        pack('H*', '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f'
                   . '202122232425262728292a2b2c2d2e2f30313233343536'),
        pack('H*', '2021222324252627'), 'personalization');
    is($entropy_tie->{fetches}, 1, 'seed_from_entropy fetches entropy once');
    is($nonce_tie->{fetches}, 1, 'seed_from_entropy fetches nonce once');
    is($personalization_tie->{fetches}, 1,
       'seed_from_entropy fetches personalization once');
    is($tied_seed->bytes, $ordinary_seed->bytes,
       'seed_from_entropy uses the fetched input values');
}
isa_ok($nist_seed, 'RNG::Seed', 'standard input produces a replayable seed');
is(length($nist_seed->bytes), 64, 'standard input seed holds Key and V');
my $nist = RNG::HMAC_DRBG->new($nist_seed);
is(
    unpack('H*', $nist->rand_bytes(64)),
    'd67b8c1734f46fa3f763cf57c6f9f4f2dc1089bd8bc1f6f023950bfc56176352'
    . '08c8501238ad7a4400defee46c640b61af77c2d1a3bfaa90ede5d207406e5403',
    'matches the NIST HMAC_DRBG SHA-256 example',
);
is(
    RNG::HMAC_DRBG->new_from_entropy(
        pack('H*', '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f'
                 . '202122232425262728292a2b2c2d2e2f30313233343536'),
        pack('H*', '2021222324252627'),
    )->rand_bytes(64),
    RNG::HMAC_DRBG->new($nist_seed)->rand_bytes(64),
    'new_from_entropy consumes its replayable seed',
);
is(
    RNG::HMAC_DRBG->new(42)->get_rand_U01_XS_func_addr > 0,
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
isnt($reset_to_zero->rand_bytes(32), $zero_seed->rand_bytes(32),
    'srand without a seed uses automatic seed material');

my $replay_seed = RNG::HMAC_DRBG->new(42)->srand;
isa_ok($replay_seed, 'RNG::Seed', 'automatic seed is replayable seed material');
my $replay_left = RNG::HMAC_DRBG->new(0);
my $replay_right = RNG::HMAC_DRBG->new(0);
$replay_left->srand($replay_seed);
$replay_right->srand($replay_seed);
is($replay_left->rand_bytes(32), $replay_right->rand_bytes(32),
   'raw automatic seed material reproduces the sequence');

my $reseeded = RNG::HMAC_DRBG->new(1);
my $same_reseed = RNG::HMAC_DRBG->new(1);
$same_reseed->reseed('additional input');
my $additional;
my $additional_tie = tie $additional,
    'RNG::HMAC_DRBG::TiedScalar', 'additional input';
$reseeded->reseed($additional);
is($additional_tie->{fetches}, 1, 'reseed fetches tied input once');
is($reseeded->rand_bytes(32), $same_reseed->rand_bytes(32),
   'reseed uses the fetched input value');

is($left->reseed_interval, 1_000_000, 'default reseed interval');
my $interval;
my $interval_tie = tie $interval, 'RNG::HMAC_DRBG::TiedScalar', 2;
$left->reseed_interval($interval);
is($interval_tie->{fetches}, 1, 'reseed_interval fetches a tied value once');
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
    skip "secure entropy unavailable: $@", 13 unless $secure;
    my $personalization;
    my $personalization_tie = tie $personalization,
        'RNG::HMAC_DRBG::TiedScalar', 'test personalization';
    RNG::HMAC_DRBG->new_secure($personalization);
    is($personalization_tie->{fetches}, 1,
       'new_secure fetches tied personalization once');
    is(length($secure->rand_bytes(64)), 64, 'secure provider returns requested bytes');
    ok(!$secure->prediction_resistance, 'secure provider starts without prediction resistance');
    ok($secure->rand_U01 >= 0 && $secure->rand_U01 < 1,
       'secure rand_U01 is in range');
    ok($secure->rand(10) >= 0 && $secure->rand(10) < 10,
       'secure rand is below its limit');
    my $prediction_resistance;
    my $prediction_tie = tie $prediction_resistance,
        'RNG::HMAC_DRBG::TiedScalar', 1;
    $secure->prediction_resistance($prediction_resistance);
    is($prediction_tie->{fetches}, 1,
       'prediction_resistance fetches its tied value once');
    ok($secure->prediction_resistance, 'prediction resistance can be enabled');
    is(length($secure->rand_bytes(8)), 8, 'prediction-resistant generation works');
    $secure->srand(1234);
    ok(!$secure->prediction_resistance,
       'explicit srand switches secure mode back to deterministic mode');
    is($secure->rand_bytes(8), RNG::HMAC_DRBG->new(1234)->rand_bytes(8),
       'explicit secure srand selects the deterministic sequence');
    my $redacted = RNG::HMAC_DRBG->new_secure('test provider')->srand;
    isa_ok($redacted, 'RNG::Seed', 'secure automatic seed is redacted');
    ok($redacted->is_redacted, 'secure automatic seed reports redaction');
    is($redacted->provider, 'RNG::HMAC_DRBG',
       'redacted seed records the seeded provider');
}

{
    SKIP: {
        skip 'the old-Perl shim uses the provider protocol', 1
            unless $RNG::HAS_NATIVE_RNG;
        my $direct = RNG::HMAC_DRBG->new(42);
        my $fast = RNG::HMAC_DRBG::MethodOverride->new(42);
        local ${^RNG} = $fast;
        is_deeply(
            [ map { int rand(100) } 1 .. 8 ],
            [ map { int $direct->rand(100) } 1 .. 8 ],
            'the core uses the discovered XS callback',
        );
    }
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
