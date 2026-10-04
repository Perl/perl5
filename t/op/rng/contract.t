#!./perl -w

BEGIN {
    chdir "t" if -d "t";
    require "./test.pl";
    set_up_inc(qw(. ../lib ../dist/RNG/lib));
}

use strict;
use List::Util qw(shuffle);
use Scalar::Util qw(weaken);
use RNG::Provider ();
use RNG::Seed ();
use RNG::SeedBase ();

plan(tests => 36);

sub mk_rand { map int rand 10000, 1..100; }

{
    package RNG::SeedPretender;
    sub bytes { "\0\0\0" }
}

{
    package RNG::AlternativeSeed;
    our @ISA = 'RNG::SeedBase';
    sub is_redacted { 0 }
    sub bytes { $_[0]->{octets} }
    sub provider { undef }
}

{
    package RNG::InvalidSeed;
    our @ISA = 'RNG::SeedBase';
    sub is_redacted { 0 }
    sub bytes { 1 }
    sub provider { undef }
}

{
    my $seed = bless { octets => "\x01\0\0\0" }, 'RNG::AlternativeSeed';

    srand($seed);
    my @alternative = mk_rand;
    my $raw = bless { octets => "\x01\0\0\0" }, 'RNG::AlternativeSeed';
    srand($raw);
    ok(eq_array(\@alternative, [mk_rand]),
       'a SeedBase implementation supplies raw seed octets');

    srand($seed);
    @alternative = mk_rand;
    srand(1);
    ok(eq_array(\@alternative, [mk_rand]),
       'built-in Drand48 reads raw seed octets little-endian');

    is(srand($raw), 1,
       'built-in Drand48 returns the state loaded from raw seed octets');
}

like(eval { srand(bless {}, 'RNG::InvalidSeed'); 1 } ? '' : $@,
     qr/RNG::SeedBase::bytes\(\) did not return seed octets/,
     'built-in Drand48 requires SeedBase octets');

{
    no warnings qw(misc overflow);
    my $error = eval { srand(bless {}, 'RNG::SeedPretender'); 1 } ? '' : $@;
    unlike($error, qr/RNG::Seed for built-in Drand48/,
           'only RNG::SeedBase objects carry raw seed material');
}

{
    package RNG::RedactedSeed;
    our @ISA = 'RNG::SeedBase';
    sub is_redacted { 1 }
    sub bytes { die 'redacted seed bytes must not be read' }
    sub provider { 'RNG::Test' }
}

{
    like(eval { srand(bless {}, 'RNG::RedactedSeed'); 1 } ? "" : $@,
         qr/Cannot use a redacted RNG seed/,
         "a redacted seed cannot initialize an RNG");
}

{
    my $seed = RNG::Seed->from_bytes("\x01\0\0\0");
    is(srand($seed), 1,
       'RNG::Seed raw material returns its built-in Drand48 state');
}

{
package RNG::TestObject;
    our @ISA = 'RNG::Provider';
    sub new { bless { calls => 0, length => 0, seeds => [] }, shift }
    sub rand_bytes {
        $_[0]{calls}++;
        $_[0]{length} = $_[1];
        "\x80" . "\0" x ($_[1] - 1)
    }
    sub srand {
        my ($self, @seed) = @_;

        push @{$self->{seeds}}, \@seed;
        if (@seed && $seed[0] eq 'mutable') {
            $seed[0] .= '-changed';
            $self->{modified_seed} = $seed[0];
        }
        return 'object result';
    }
}

package main;

{
    package RNG::MissingRandBytes;
    our @ISA = 'RNG::Provider';
}

{
    package RNG::MissingSrand;
    our @ISA = 'RNG::Provider';
    sub rand_bytes { "\0" x $_[1] }
}

{
    package RNG::StackGrowth;
    our @ISA = 'RNG::Provider';
    sub rand_bytes { "\0" x $_[1] }
    no warnings 'recursion';
    sub grow {
        my ($depth) = @_;
        grow($depth - 1) if $depth;
    }
    sub srand {
        grow(500);
        return 'stack-grown';
    }
}

package main;

{
    my $object = RNG::TestObject->new;
    local ${^RNG} = $object;
    is(int rand(10), 5, "object rand_bytes method is used");
    is($object->{calls}, 1, "object rand_bytes receives the requested length");
    is($object->{length}, 8, "object rand_bytes receives eight");
    my $calls = $object->{calls};
    my @shuffled = shuffle 1..10;
    cmp_ok($object->{calls}, '>', $calls,
           'List::Util::shuffle uses the selected provider');
    my $got = srand();
    is($got, "object result", "object srand method is used");
    is(scalar @{$object->{seeds}}, 1, "object srand() records one seed");
    is(scalar @{$object->{seeds}[0]}, 0,
       "object srand() receives no seed argument");
    srand("seed");
    is(scalar @{$object->{seeds}}, 2, "object seed is recorded");
    is($object->{seeds}[1][0], "seed", "object seed is forwarded");
    is(srand('mutable'), 'object result',
       'an explicit string seed is dispatched to the provider');
    is($object->{modified_seed}, 'mutable-changed',
       'a provider may modify its normalized seed argument');
}

{
    my $provider = bless {}, 'RNG::StackGrowth';
    local ${^RNG} = $provider;
    is(srand(), 'stack-grown',
       'provider srand survives stack growth during its callback');
}

{
    my $provider = RNG::TestObject->new;
    my $weak_provider = $provider;

    weaken($weak_provider);
    {
        local ${^RNG} = $provider;
        undef $provider;
    }
    ok(!defined $weak_provider,
       'clearing ${^RNG} releases the cached provider');
}

package RNG::BlessedCode;
our @ISA = 'RNG::Provider';
sub rand_bytes { "\0" x $_[1] }
sub srand { "blessed" }
package main;

{
    my $object = bless sub { die "must not be called" }, "RNG::BlessedCode";
    local ${^RNG} = $object;
    is(rand(), 0, "blessed CODE is dispatched as an object");
    my $got = CORE::srand();
    is($got, "blessed", "blessed CODE uses the object srand method");
}

{
    like(eval { local ${^RNG} = sub { "\0" }; rand(); 1 } ? "" : $@,
         qr/\$\{\^RNG\} must be an RNG::Provider object or undef/,
         "unblessed CODE providers are rejected");
    like(eval { local ${^RNG} = 42; rand(); 1 } ? "" : $@,
         qr/\$\{\^RNG\} must be an RNG::Provider object or undef/,
         "invalid RNG provider is rejected");
}

{
    no warnings 'experimental::builtin';
    use builtin 'rand_bytes';
    my $object = RNG::TestObject->new;
    local ${^RNG} = $object;
    is(unpack('H*', rand_bytes(4)), '80000000',
       'builtin::rand_bytes uses the selected provider');
    is($object->{length}, 4, 'builtin::rand_bytes forwards its length');
    is(rand_bytes(0), '', 'builtin::rand_bytes(0) returns an empty string');
    is($object->{calls}, 1, 'builtin::rand_bytes(0) does not advance the provider');

    for my $bad (undef, -1, 1.5, 'not a number') {
        like(eval { rand_bytes($bad); '' } || $@,
             qr/builtin::rand_bytes\(\) count must be a non-negative integer/,
             'builtin::rand_bytes rejects an invalid count');
    }
}

{
    like(eval { local ${^RNG} = bless({}, "RNG::MissingRandBytes"); rand(); 1 }
             ? "" : $@,
         qr/RNG::Provider must implement rand_bytes/,
         "an incomplete provider fails at rand_bytes()");
    like(eval { local ${^RNG} = bless({}, "RNG::MissingSrand"); srand(); 1 }
             ? "" : $@,
         qr/RNG::Provider must implement srand/,
         "an incomplete provider fails at srand()");
}

SKIP: {
    eval { require threads; 1 }
        or skip 'Perl was not built with threads', 2;
    require RNG::Xoshiro;

    package RNG::Xoshiro::MethodOverride;
    our @ISA = 'RNG::Xoshiro';
    sub rand_bytes { die 'the Perl rand_bytes fallback was used' }
    package main;

    my $expected = RNG::Xoshiro->new(42)->rand;
    my $provider = RNG::Xoshiro::MethodOverride->new(42);
    my $thread;
    {
        local ${^RNG} = $provider;
        $thread = threads->create(sub {
            my $value = eval { rand() };
            return [ $@, $value ];
        });
    }
    my ($error, $value) = @{$thread->join};

    is($error, '', 'a cloned XS provider keeps its native callback');
    is($value, $expected, 'a cloned XS provider starts from cloned state');
}
