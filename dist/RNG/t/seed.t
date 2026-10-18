use strict;
use warnings;
use Test::More;

use lib 'lib';
use RNG::Seed;
use RNG::SeedBase ();

for my $value ('', '0') {
    my $seed = RNG::Seed->from_string($value);
    ok($seed, 'a false string seed is a true object');
    is("$seed", $value, 'stringification preserves the seed string');
    ok(!$seed->isa('RNG::SeedBase'), 'a string seed is not raw state');
    my $warning = '';
    my $number;
    {
        local $SIG{__WARN__} = sub { $warning .= $_[0] };
        $number = 0 + $seed;
    }
    is($number, 0, 'numeric conversion uses the stored string');
    if (length $value) {
        is($warning, '', 'numeric zero string converts without warnings');
    }
    else {
        like($warning, qr/isn't numeric/,
             'empty string retains its normal numeric warning');
    }
}

{
    my $seed = RNG::Seed->from_string("snowman \x{2603}");
    is("$seed", "snowman \x{2603}", 'stringification preserves Unicode');
    my $raw = RNG::Seed->from_bytes("\0\xff");
    isa_ok($raw, 'RNG::Seed');
    isa_ok($raw, 'RNG::SeedBase');
    is("$raw", "\0\xff", 'raw seed stringification preserves octets');
    ok($raw, 'a raw seed is a true object');
}

for my $method (qw(is_redacted bytes provider)) {
    like(eval { RNG::SeedBase->$method; 1 } ? '' : $@,
         qr/RNG::SeedBase is an abstract base class/,
         "RNG::SeedBase->$method is abstract");
}

{
    package RNG::Test::Seed;

    our @ISA = 'RNG::SeedBase';

    sub new { bless { octets => $_[1] }, $_[0] }
    sub is_redacted { 0 }
    sub bytes { $_[0]->{octets} }
    sub provider { undef }
}

{
    package RNG::Test::TiedScalar;

    sub TIESCALAR { bless { value => $_[1], fetches => 0 }, $_[0] }
    sub FETCH {
        $_[0]{fetches}++;
        return $_[0]{value};
    }
}

my %width = (
    'RNG::Drand48'   => 6,
    'RNG::PCG'       => 16,
    'RNG::Wyrand'    => 8,
    'RNG::Xoshiro'   => 32,
    'RNG::HMAC_DRBG' => 64,
);

for my $class (sort keys %width) {
    eval "require $class";
    BAIL_OUT("could not load $class: $@") if $@;

    my $default_seed = $class->new;
    is(length($default_seed->rand_bytes(8)), 8,
       "$class accepts an omitted constructor seed");

    my $raw = RNG::Seed->from_bytes(chr(1) x $width{$class});
    my $left = $class->new(0);
    my $right = $class->new(0);
    if ($class eq 'RNG::Drand48') {
        is("" . $left->srand($raw), '1103823438081',
           "$class returns the state loaded from raw material");
    }
    else {
        is($left->srand($raw), $raw, "$class returns an explicit raw seed");
    }
    $right->srand($raw);
    is($left->rand_bytes(24), $right->rand_bytes(24),
       "$class replays exact-width raw material");

    my $alternate = RNG::Test::Seed->new(chr(2) x $width{$class});
    $left->srand($alternate);
    $right->srand(RNG::Seed->from_bytes(chr(2) x $width{$class}));
    is($left->rand_bytes(24), $right->rand_bytes(24),
       "$class accepts a SeedBase implementation with its own representation");

    {
        my $octets = "\xff" x $width{$class};
        my $upgraded = $octets;
        utf8::upgrade($upgraded);
        $left->srand(RNG::Seed->from_bytes($upgraded));
        $right->srand(RNG::Seed->from_bytes($octets));
        is($left->rand_bytes(24), $right->rand_bytes(24),
           "$class downgrades raw seed characters to their byte values");

        my $wide = RNG::Seed->from_bytes("\x{100}" x $width{$class});
        like(eval { $left->srand($wide); 1 } ? '' : $@,
             qr/Wide character/,
             "$class rejects raw seed characters that cannot be downgraded");
    }

    my $wrong = RNG::Seed->from_bytes(chr(1) x ($width{$class} - 1));
    like(eval { $left->srand($wrong); 1 } ? '' : $@,
         qr/exactly \Q$width{$class}\E octets/,
         "$class rejects incorrectly sized raw material");

    {
        my $tied_seed;
        my $tie_obj = tie $tied_seed, 'RNG::Test::TiedScalar', 'magic seed';
        my $tied_rng = $class->new($tied_seed);
        is($tie_obj->{fetches}, 1,
           "$class constructor fetches a tied seed once");
        is($tied_rng->rand_bytes(24), $class->new('magic seed')->rand_bytes(24),
           "$class constructor uses the fetched seed value");
    }

    {
        my $rng = $class->new('different seed');
        my $tied_seed;
        my $tie_obj = tie $tied_seed, 'RNG::Test::TiedScalar', 'magic seed';
        $rng->srand($tied_seed);
        is($tie_obj->{fetches}, 1,
           "$class srand fetches a tied seed once");
        is($rng->rand_bytes(24), $class->new('magic seed')->rand_bytes(24),
           "$class srand uses the fetched seed value");
    }

    {
        my $left = $class->new(42);
        my $right = $class->new(42);
        my $tied_limit;
        my $tie_obj = tie $tied_limit, 'RNG::Test::TiedScalar', 5;
        is($left->rand($tied_limit), $right->rand(5),
           "$class rand uses a tied limit");
        is($tie_obj->{fetches}, 1,
           "$class rand fetches a tied limit once");
    }
}

my $zero = RNG::Seed->from_bytes("\0" x 32);
my $xoshiro = RNG::Xoshiro->new(0);
$xoshiro->srand($zero);
ok($xoshiro->rand_bytes(16) ne "\0" x 16,
   'Xoshiro adjusts its forbidden all-zero state');

my $hmac_raw = RNG::Seed->from_bytes("\1" x 64);
my $hmac_from_raw = RNG::HMAC_DRBG->new(0);
my $hmac_from_string = RNG::HMAC_DRBG->new(0);
$hmac_from_raw->srand($hmac_raw);
$hmac_from_string->srand("\1" x 32);
isnt($hmac_from_raw->rand_bytes(24), $hmac_from_string->rand_bytes(24),
     'HMAC_DRBG raw state is not hashed as an ordinary seed string');

for my $class (qw(RNG::PCG RNG::Wyrand RNG::Xoshiro RNG::HMAC_DRBG)) {
    my $rng = $class->new(0);
    my $seed = $rng->srand;
    isa_ok($seed, 'RNG::Seed', "$class automatic seed is replayable");
    is(length($seed->bytes), $width{$class},
       "$class automatic seed has its raw width");
}

for my $class (qw(RNG::PCG RNG::Wyrand RNG::Xoshiro)) {
    my $left = $class->new(0);
    my $right = $class->new(0);
    my $seed = $left->srand;

    $right->srand($seed);
    is($left->rand_bytes(24), $right->rand_bytes(24),
       "$class automatic seed reproduces the sequence");
}

{
    my $wide = "caf\x{e9}";
    my $octets = $wide;

    utf8::upgrade($wide);
    utf8::downgrade($octets, 1);
    is(RNG::HMAC_DRBG->new($wide)->rand_bytes(24),
       RNG::HMAC_DRBG->new($octets)->rand_bytes(24),
       'HMAC_DRBG constructor normalizes ordinary seed storage as UTF-8');

    my $left = RNG::HMAC_DRBG->new(0);
    my $right = RNG::HMAC_DRBG->new(0);
    $left->srand($wide);
    $right->srand($octets);
    is($left->rand_bytes(24), $right->rand_bytes(24),
       'HMAC_DRBG srand normalizes ordinary seed storage as UTF-8');
}

my $redacted = RNG::Seed->redacted('RNG::HMAC_DRBG');
ok($redacted->is_redacted, 'serialized redaction is recognized');
is($redacted->provider, 'RNG::HMAC_DRBG', 'redaction records the provider');
like(eval { $redacted->bytes; 1 } ? '' : $@,
     qr/Cannot reveal a redacted RNG seed/, 'redaction never exposes bytes');

for my $class (sort keys %width) {
    my $rng = $class->new(0);

    like(eval { $rng->srand($redacted); 1 } ? '' : $@,
         qr/Cannot use a redacted RNG seed/,
         "$class rejects a redacted seed before reading its octets");
}

my $serialized_redaction = 'perl-rng-seed-redacted:RNG::HMAC_DRBG:v1';
my $raw_lookalike = RNG::Seed->from_bytes($serialized_redaction);
ok(!$raw_lookalike->is_redacted,
   'from_bytes treats a serialized redaction as raw material');
is($raw_lookalike->bytes, $serialized_redaction,
   'from_bytes preserves redaction-looking raw octets');
ok(RNG::Seed->new($serialized_redaction)->is_redacted,
   'new recognizes the serialized redaction form');

done_testing;
