use strict;
use warnings;
use Test::More;
use lib 'lib';
use RNG::PCG;
use RNG::Seed;

# The first six outputs are from PCG's published test-low vectors at
# https://github.com/imneme/pcg-c/tree/83252d9c23df9c82ecb42210afed61a7b42402d7/test-low
# Raw initializers were obtained with that revision's seeding functions for
# seed 42 and stream 54.  They bypass our string seed expansion.  The LCG
# initializer contains the actual odd increment 109, rather than stream 54.
my @cases = (
    [ 'rxs-m-xs-64/64', 'RNG::PCG::RXS_M_XS_64_64',
      '944a411580fd7a97',
      [ qw(27a53829edf003a9 df28458e5c04c31c 2756dc550bc36037
           a10325553eb09ee9 40a0fccb8d9df09f 5c2047cfefb5e9ca) ] ],
    [ 'xsl-rr-128/64-mcg', 'RNG::PCG::XSL_RR_128_64_MCG',
      '2b000000000000000000000000000000',
      [ qw(63b4a3a813ce700a 382954200617ab24 a7fd85ae3fe950ce
           d715286aa2887737 60c92fee2e59f32c 84c4e96beff30017) ] ],
    [ 'xsl-rr-128/64-lcg', 'RNG::PCG::XSL_RR_128_64_LCG',
      '2043e5415ac4f6d3e33b01be05ce2bde6d000000000000000000000000000000',
      [ qw(86b1da1d72062b68 1304aa46c9853d39 a3670e9e0dd50358
           f9090e529a7dae00 c85b9fd837996f2c 606121f8e3919196) ] ],
);

for my $case (@cases) {
    my ($variant, $class, $raw, $expected) = @$case;
    subtest $variant => sub {
        my $seed = RNG::Seed->from_bytes(pack('H*', $raw));
        my $rng = RNG::PCG->new($seed, variant => $variant);
        isa_ok($rng, $class);
        is_deeply([ map { unpack('H*', $rng->rand_bytes(8)) } 1 .. 6 ],
                  $expected, 'matches the published PCG output words');
        $rng->srand($seed);
        is(unpack('H*', $rng->rand_bytes(48)), join('', @$expected),
           'a single byte request matches the same output words');
        done_testing;
    };
}

done_testing;
