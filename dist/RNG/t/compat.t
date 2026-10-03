use strict;
use warnings;
BEGIN {
    warnings->unimport('experimental::builtin') if $] >= 5.036;
}
use Test::More;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

use lib 'lib';
use RNG;
use RNG::Provider ();
use RNG::Seed;

plan skip_all => 'the compatibility shim is only used on older Perls'
    if $RNG::HAS_NATIVE_RNG;

{
    srand('compatibility seed');
    my $first_rand = rand;
    my $first_octets = builtin::rand_bytes(12);

    my $state = srand('compatibility seed');
    srand($state);
    is(rand, $first_rand, 'the old host generator is reset through srand');
    is(builtin::rand_bytes(12), $first_octets,
       'rand_bytes advances the old host generator reproducibly');
}

{
    my $seed = RNG::Seed->from_bytes("\x01\x02\x03\x04");

    is(srand($seed), 0x04030201,
       'a raw seed object returns its built-in Drand48 state');
    my $first = rand;
    srand($seed);
    is(rand, $first, 'raw seed material resets the old host generator');
}

{
    package RNG::CompatProvider;

    our @ISA = 'RNG::Provider';

    sub new { bless { calls => [], seed => undef }, shift }
    sub rand_bytes {
        my ($self, $length) = @_;

        push @{$self->{calls}}, $length;
        return "\x80" . "\0" x ($length - 1);
    }
    sub srand {
        my ($self, @seed) = @_;

        $self->{seed} = $seed[0] if @seed;
        return $self->{seed};
    }
}

{
    my $provider = RNG::CompatProvider->new;
    local ${^RNG} = $provider;

    is(srand('provider seed'), 'provider seed',
       'srand dispatches to the selected provider');
    is($provider->{seed}, 'provider seed', 'the provider receives the seed');
    is(rand, 0.5, 'rand obtains its value through rand_bytes');
    is(builtin::rand_bytes(7), "\x80" . "\0" x 6,
       'rand_bytes dispatches to the selected provider');
    is($List::Util::RAND->(), 0.5,
       'the List::Util bridge uses the selected provider');
    is_deeply($provider->{calls}, [8, 7, 8],
       'the shim requests octets through the provider protocol');
}

{
    my $provider = RNG::CompatProvider->new;
    my $wide = "caf\x{e9}";
    my $octets = $wide;

    utf8::upgrade($wide);
    utf8::downgrade($octets, 1);
    local ${^RNG} = $provider;
    srand($wide);
    my $wide_seed = $provider->{seed};
    srand($octets);
    is($provider->{seed}, $wide_seed,
       'the shim normalizes equivalent UTF-8 seed storage');
    ok(utf8::is_utf8($provider->{seed}),
       'the shim passes providers a UTF-8 seed string');
}

SKIP: {
    skip 'PERL_RAND_SEED was added in Perl 5.38', 2 if $] < 5.038;
    my $program = q{
        use lib qw(blib/lib blib/arch);
        use RNG;
        use RNG::Provider ();
        {
            package RNG::CompatSeedProvider;
            our @ISA = 'RNG::Provider';
            sub rand_bytes { "\0" x $_[1] }
            sub srand { print $_[1], "\n"; return $_[1] }
        }
        local ${^RNG} = bless {}, 'RNG::CompatSeedProvider';
        srand();
    };
    my $error = gensym;
    my ($in, $out);
    local $ENV{PERL_RAND_SEED} = 1;
    my $pid = open3($in, $out, $error, $^X,
                    '-Iblib/lib', '-Iblib/arch', '-e', $program);
    close $in;
    my $stdout = do { local $/; <$out> };
    my $stderr = do { local $/; <$error> };

    waitpid $pid, 0;
    is($stdout, "1\n", 'PERL_RAND_SEED reaches a compatibility provider');
    is($stderr, '', 'compatibility PERL_RAND_SEED child has no diagnostics');
}

done_testing;
