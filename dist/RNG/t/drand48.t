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
    [ map { $left->rand_U01 } 1 .. 8 ],
    [ map { $right->rand_U01 } 1 .. 8 ],
    'the same seed produces the same sequence',
);

my $reset = RNG::Drand48->new(7);
$reset->rand_U01;
is($reset->srand(42), 42, 'numeric srand returns its seed');
is($reset->rand_U01, RNG::Drand48->new(42)->rand_U01,
   'srand resets the sequence');

SKIP: {
    skip 'the old host RNG has no Drand48 provider hook', 2
        unless $RNG::HAS_NATIVE_RNG;

    for my $seed (42, 'hello') {
        my @built_in;
        my $provider = RNG::Drand48->new($seed);

        {
            local ${^RNG};
            srand($seed);
            @built_in = map { rand() } 1 .. 8;
        }
        is_deeply(\@built_in, [ map { $provider->rand_U01 } 1 .. 8 ],
                  "built-in Drand48 and the provider agree for $seed");
    }
}

{
    my $left = RNG::Drand48->new(0);
    my $right = RNG::Drand48->new(0);
    my $seed = $left->srand;

    cmp_ok($seed, '<=', 281474976710655,
           'an automatic seed is limited to 48 bits');
    $right->srand($seed);
    is($left->rand_bytes(24), $right->rand_bytes(24),
       'an automatic seed is replayable on this Perl');
}

{
    my $left = RNG::Drand48->new(0);
    my $right = RNG::Drand48->new(0);
    my $seed = $left->srand('4294967296');

    is("$seed", '4294967296',
       'a decimal string is recognized as a 48-bit initializer');
    $right->srand($seed);
    is($left->rand_bytes(24), $right->rand_bytes(24),
       'a decimal string seed replays a 48-bit state');
}

{
    my $warning = '';
    my $rng = RNG::Drand48->new(0);
    my $seed;

    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    $seed = $rng->srand('281474976710656');

    is($seed, 0,
       'a numeric string wider than 48 bits returns its retained bits');
    ok(defined($seed) && !$seed,
       'an overflow-reduced zero is defined and false');
    like($warning, qr/Integer overflow in srand/,
         'the provider warns when a numeric seed exceeds 48 bits');
}

my $string_direct = RNG::Drand48->new(0);
my $string_core = RNG::Drand48->new(0);
$string_direct->srand('hello');
{
    local ${^RNG} = $string_core;
    srand('hello');
}
is($string_direct->rand_U01, $string_core->rand_U01,
   'string seeds initialize the provider and core identically');

my $wide_seed = RNG::Drand48->new(0);
$wide_seed->srand('4294967296');
isnt($wide_seed->rand_U01, RNG::Drand48->new(0)->rand_U01,
     'the provider accepts numeric seeds wider than 32 bits');

for my $case (
    [ 123.5,     123 ],
    [ -123.5,    123 ],
    [ '+123.5',  123 ],
    [ '-123.5',  123 ],
    [ '.5',         0 ],
    [ '-.5',        0 ],
) {
    my ($seed, $integer) = @$case;
    my $provider = RNG::Drand48->new(0);

    $provider->srand($seed);
    is($provider->rand_U01, RNG::Drand48->new($integer)->rand_U01,
       "$seed retains the native numeric compatibility path");
}

{
    my $exponent = RNG::Drand48->new(0);

    $exponent->srand('1e6');
    isnt($exponent->rand_U01, RNG::Drand48->new(1_000_000)->rand_U01,
       'exponent notation uses the ordinary string seed path');
}

{
    my $warning = '';
    my $large = RNG::Drand48->new(0);
    local $SIG{__WARN__} = sub { $warning .= $_[0] };

    $large->srand('18446744073709551616');
    isnt($large->rand_U01, RNG::Drand48->new(0)->rand_U01,
         'a decimal seed beyond U64 uses the ordinary string seed path');
    is($warning, '', 'a decimal seed beyond U64 does not warn');
}

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

SKIP: {
    skip 'the old-Perl shim has no C callback path', 1
        unless $RNG::HAS_NATIVE_RNG;
    my $direct = RNG::Drand48->new(42);
    my $fast = RNG::Drand48->new(42);
    local ${^RNG} = $fast;
    is_deeply(
        [ map { rand() } 1 .. 8 ],
        [ map { $direct->rand_U01 } 1 .. 8 ],
        'the core fast callback matches the provider sequence',
    );
}

done_testing;
