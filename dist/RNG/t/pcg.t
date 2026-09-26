use strict;
use warnings;
use Test::More;
use List::Util qw(shuffle);

use lib 'lib';
BEGIN {
    plan skip_all => 'RNG::PCG is not available'
        unless eval { require RNG::PCG; 1 };
}

{
    package RNG::PCG::MethodOverride;
    our @ISA = qw(RNG::PCG);
    sub rand_bytes { die 'the Perl rand_bytes fallback was used' }
}

{
    package RNG::PCG::RelocatingSrand;
    our @ISA = qw(RNG::PCG);
    sub srand {
        my ($self, @seed) = @_;
        my $state = $$self;

        $$self = $state . "\0";
        chop $$self;
        return $self->SUPER::srand(@seed);
    }
}

{
    package RNG::PCG::PurePerl;
    our @ISA = qw(RNG::Provider);
    sub new { bless {}, shift }
    sub rand_bytes { return "\0" x $_[1] }
    sub srand { return 0 }
}

{
    package RNG::PCG::FakeGetter;
    our @ISA = qw(RNG::PCG);
    sub get_rand_U01_XS_func_addr { return 1 }
    sub rand_bytes { return "\0" x $_[1] }
}

{
    package RNG::PCG::CountingCan;
    our @ISA = qw(RNG::PCG);
    our $calls;
    sub can { ++$calls; shift->SUPER::can(@_) }
}

my $rng = RNG::PCG->new(42);
isa_ok($rng, 'RNG::PCG');
is(ref($$rng), '', 'the state is a scalar');
ok($rng->get_rand_U01_XS_func_addr > 0,
   'the XS provider publishes a callback address');
ok($rng->get_rand_U01_XS_state_addr > 0,
   'the XS provider publishes a state address');

my @expected = qw(
    51ef4ec54b6018f1
    6c2d8a0073c15d08
    788cd3bde4c58d1f
    2ecc356f0f50c7f8
    5f1f8364a7f25815
);
my @got = map { unpack 'H*', $rng->rand_bytes(8) } 1 .. 5;
is_deeply(\@got, \@expected, 'matches the two-dimensional PCG-XSH-RR sequence');

# PCG's checked pcg_oneseq_64_xsh_rr_32 vector seeds the base generator
# with 42.  Its post-seed state is stored below in little-endian order.  The
# zero extension words select the unextended reference stream.
my $pcg_reference = RNG::PCG->new(RNG::Seed->from_bytes(
    "\x94\x4a\x41\x15\x80\xfd\x7a\x97" . "\0" x 8,
));
is_deeply(
    [ map { unpack 'H*', $pcg_reference->rand_bytes(8) } 1 .. 3 ],
    [ qw(c2f57bd66b07c4a9 72b7b29b44215383 f5af5ead68beb632) ],
    'matches the PCG oneseq_64_xsh_rr_32 reference vector',
);

for my $length (0, 1, 7, 8, 9, 17) {
    is(length($rng->rand_bytes($length)), $length,
       "rand_bytes($length) returns the requested length");
}

my $same = RNG::PCG->new(42);
is_deeply(
    [ map { $same->rand_bytes(8) } 1 .. 8 ],
    [ do { my $copy = RNG::PCG->new(42); map { $copy->rand_bytes(8) } 1 .. 8 } ],
    'the same seed produces the same sequence',
);

my $different = RNG::PCG->new(43);
isnt($different->rand_bytes(8), RNG::PCG->new(42)->rand_bytes(8),
       'different seeds produce different sequences');

my $max_uv = ~0;
my @seed_cases = (0, 1, 42, 43, $max_uv >> 1, $max_uv,
                  '', 'hello', 'hello!', "\0\xff",
                  "snowman \x{2603}");
for my $index (0 .. $#seed_cases) {
    my $seed = $seed_cases[$index];
    my $left  = RNG::PCG->new($seed);
    my $right = RNG::PCG->new($seed);
    is_deeply(
        [ map { $left->rand_bytes(8) } 1 .. 6 ],
        [ map { $right->rand_bytes(8) } 1 .. 6 ],
        "seed case $index reproduces the sequence",
    );
}

for my $i (1 .. $#seed_cases) {
    my $left  = RNG::PCG->new($seed_cases[$i - 1]);
    my $right = RNG::PCG->new($seed_cases[$i]);
    isnt($left->rand_bytes(8), $right->rand_bytes(8),
         'different seeds select different streams');
}

is($rng->srand(42), 42, 'srand returns the numeric seed');
is(unpack('H*', $rng->rand_bytes(8)), '51ef4ec54b6018f1',
   'srand resets the generator');

my $string_rng = RNG::PCG->new('hello');
is(unpack('H*', $string_rng->rand_bytes(8)), '50087f3a03e048e1',
   'string seeds are accepted');
is($string_rng->srand('hello'), 'hello', 'string srand returns its seed');
is(unpack('H*', $string_rng->rand_bytes(8)), '50087f3a03e048e1',
   'string srand resets the generator');
for my $limit (1, 10, 100, 1_000_000) {
    my $value = $rng->rand($limit);
    cmp_ok($value, '>=', 0, "rand($limit) is non-negative");
    cmp_ok($value, '<', $limit, "rand($limit) is below its limit");
}
my $unit = $rng->rand;
cmp_ok($unit, '>=', 0, 'rand() is non-negative');
cmp_ok($unit, '<', 1, 'rand() is below one');
my $unit01 = $rng->rand_U01;
cmp_ok($unit01, '>=', 0, 'rand_U01() is non-negative');
cmp_ok($unit01, '<', 1, 'rand_U01() is below one');

{
    my $direct = RNG::PCG->new(42);
    local ${^RNG} = RNG::PCG->new(42);
    my @core = map { int rand(100) } 1 .. 4;
    my @direct = map { int $direct->rand(100) } 1 .. 4;
    is_deeply(\@core, \@direct,
              'the core uses RNG::PCG for its rand implementation');
    my $seed = srand(42);
    is($seed, 42, 'the core delegates srand to RNG::PCG');
    is_deeply([ map { int rand(100) } 1 .. 4 ], \@core,
              'the core and RNG::PCG are deterministic together');
    ok((grep { $_ >= 0 && $_ < 100 } @core) == @core,
       'the core receives values in range');

    SKIP: {
        skip 'the old-Perl shim uses the provider protocol', 1
            unless $RNG::HAS_NATIVE_RNG;
        my $fast = RNG::PCG::MethodOverride->new(42);
        my $expected = RNG::PCG->new(42)->rand(100);
        local ${^RNG} = $fast;
        is(rand(100), $expected,
           'the core uses the discovered XS callback without Perl method dispatch');
    }

    my $fallback = RNG::PCG::PurePerl->new;
    local ${^RNG} = $fallback;
    is(rand(1), 0,
       'an object without the XS callback uses the Perl-level protocol');

    my $fake = RNG::PCG::FakeGetter->new(42);
    local ${^RNG} = $fake;
    is(rand(1), 0,
       'a Perl getter returning an address cannot select the XS fast path');

    SKIP: {
        skip 'the old-Perl shim has no native callback cache', 1
            unless $RNG::HAS_NATIVE_RNG;
        $RNG::PCG::CountingCan::calls = 0;
        local ${^RNG} = RNG::PCG::CountingCan->new(42);
        rand() for 1 .. 3;
        is($RNG::PCG::CountingCan::calls, 0,
           'the native callback discovery does not call can()');
    }

    SKIP: {
        skip 'the old-Perl shim has no native callback cache', 1
            unless $RNG::HAS_NATIVE_RNG;
        my $direct = RNG::PCG->new(42);
        my $relocating = RNG::PCG::RelocatingSrand->new(42);

        $direct->srand(123);
        local ${^RNG} = $relocating;
        srand(123);
        is_deeply(
            [ map { int rand(100) } 1 .. 4 ],
            [ map { int $direct->rand(100) } 1 .. 4 ],
            'srand refreshes an XS provider state cache',
        );
    }

    my $string_direct = RNG::PCG->new('core string seed');
    local ${^RNG} = RNG::PCG->new(0);
    my $core_string_seed = srand('core string seed');
    ok(defined $core_string_seed,
       'the core accepts a string seed through RNG::PCG');
    is_deeply(
        [ map { int rand(100) } 1 .. 4 ],
        [ map { int $string_direct->rand(100) } 1 .. 4 ],
        'the core and RNG::PCG agree for string seeds',
    );
}

{
    local $@;
    my $ok = eval { local ${^RNG} = 42; rand(); 1 };
    ok(!$ok && $@ =~ /must be (?:an object or undef|an RNG::Provider object or undef)/,
       'an invalid localized ${^RNG} value is rejected');
}

{
    my @input = 1 .. 12;
    my $first = RNG::PCG->new(8675309);
    my $second = RNG::PCG->new(8675309);
    my $third = RNG::PCG->new(8675309);
    my @first_shuffle;
    my @second_shuffle;
    my @callback_shuffle;
    {
        local ${^RNG} = $first;
        @first_shuffle = shuffle(@input);
    }
    {
        local ${^RNG} = $second;
        @second_shuffle = shuffle(@input);
    }
    {
        local $List::Util::RAND = $third->rand_U01_callback;
        @callback_shuffle = shuffle(@input);
    }
    is_deeply(\@first_shuffle, \@second_shuffle,
              'List::Util::shuffle follows ${^RNG} deterministically');
    is_deeply(\@first_shuffle, \@callback_shuffle,
              'rand_U01_callback reproduces the ${^RNG} shuffle sequence');
    is_deeply([ sort { $a <=> $b } @first_shuffle ], \@input,
              'List::Util::shuffle preserves all input values');
}

done_testing;
