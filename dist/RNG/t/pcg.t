use strict;
use warnings;
use Test::More;

use lib 'lib';
BEGIN {
    plan skip_all => 'RNG::PCG is not available'
        unless eval { require RNG::PCG; 1 };
}

my $rng = RNG::PCG->new(42);
isa_ok($rng, 'RNG::PCG');
is(ref($$rng), '', 'the state is a scalar');

my @expected = qw(
    59a325388164c81b
    4d7e040259fd72bd
    9e60fcdf4106b543
    92d1d3d877d6da51
    8e9943662a35b671
);
my @got = map { unpack 'H*', $rng->rand_bytes(8) } 1 .. 5;
is_deeply(\@got, \@expected, 'matches the two-dimensional PCG-XSH-RR sequence');

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
is(unpack('H*', $rng->rand_bytes(8)), '59a325388164c81b',
   'srand resets the generator');

my $string_rng = RNG::PCG->new('hello');
is(unpack('H*', $string_rng->rand_bytes(8)), '8bbf9e6a28c6ecad',
   'string seeds are accepted');
is($string_rng->srand('hello'), 0, 'string srand returns zero');
is(unpack('H*', $string_rng->rand_bytes(8)), '8bbf9e6a28c6ecad',
   'string srand resets the generator');
for my $limit (1, 10, 100, 1_000_000) {
    my $value = $rng->rand($limit);
    cmp_ok($value, '>=', 0, "rand($limit) is non-negative");
    cmp_ok($value, '<', $limit, "rand($limit) is below its limit");
}
my $unit = $rng->rand;
cmp_ok($unit, '>=', 0, 'rand() is non-negative');
cmp_ok($unit, '<', 1, 'rand() is below one');
my $unit01 = $rng->rand01;
cmp_ok($unit01, '>=', 0, 'rand01() is non-negative');
cmp_ok($unit01, '<', 1, 'rand01() is below one');

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

SKIP: {
    my $have_list_util = eval {
        require List::Util;
        List::Util->import('shuffle');
        1;
    };
    skip 'List::Util is not available', 3 unless $have_list_util;

    my @input = 1 .. 12;
    my $first = RNG::PCG->new(8675309);
    my $second = RNG::PCG->new(8675309);
    my $third = RNG::PCG->new(8675309);
    my @first_shuffle;
    my @second_shuffle;
    my @callback_shuffle;
    {
        {
            local ${^RNG} = $first;
            @first_shuffle = shuffle(@input);
        }
        {
            local ${^RNG} = $second;
            @second_shuffle = shuffle(@input);
        }
        {
            local $List::Util::RAND = $third->rand01_callback;
            @callback_shuffle = shuffle(@input);
        }
    }
    is_deeply(\@first_shuffle, \@second_shuffle,
              'List::Util::shuffle follows ${^RNG} deterministically');
    is_deeply(\@first_shuffle, \@callback_shuffle,
              'rand01_callback reproduces the ${^RNG} shuffle sequence');
    is_deeply([ sort { $a <=> $b } @first_shuffle ], \@input,
              'List::Util::shuffle preserves all input values');
}

done_testing;
