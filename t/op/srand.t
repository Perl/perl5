#!./perl -w

BEGIN {
    chdir "t" if -d "t";
    require "./test.pl";
    set_up_inc( qw(. ../lib) );
}

# Test srand.

use strict;

plan(tests => 32);

# Generate a load of random numbers.
# int() avoids possible floating point error.
sub mk_rand { map int rand 10000, 1..100; }


# Check that rand() is deterministic.
srand(1138);
my @first_run  = mk_rand;

srand(1138);
my @second_run = mk_rand;

ok( eq_array(\@first_run, \@second_run),  'srand(), same arg, same rands' );


# Check that different seeds provide different random numbers
srand(31337);
@first_run  = mk_rand;

srand(1138);
@second_run = mk_rand;

ok( !eq_array(\@first_run, \@second_run),
                                 'srand(), different arg, different rands' );


# Check that srand() isn't affected by $_
{   
    local $_ = 42;
    srand();
    @first_run  = mk_rand;

    srand(42);
    @second_run = mk_rand;

    ok( !eq_array(\@first_run, \@second_run),
                       'srand(), no arg, not affected by $_');
}

# This test checks whether Perl called srand for you.
{
    local $ENV{PERL_RAND_SEED};
    @first_run  = `"$^X" -le "print int rand 100 for 1..100"`;
    sleep(1); # in case our srand() is too time-dependent
    @second_run = `"$^X" -le "print int rand 100 for 1..100"`;
}

ok( !eq_array(\@first_run, \@second_run), 'srand() called automatically');

# check srand's return value
my $seed = srand(1764);
is( $seed, 1764, "return value" );

$seed = srand(0);
ok( $seed, "true return value for srand(0)");
cmp_ok( $seed, '==', 0, "numeric 0 return value for srand(0)");

{
    my @warnings;
    my $b;
    {
	local $SIG{__WARN__} = sub {
	    push @warnings, "@_";
	    warn @_;
	};
	$b = $seed + 0;
    }
    is( $b, 0, "Quacks like a zero");
    is( "@warnings", "", "Does not warn");
}

# [perl #40605]
{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    srand(2**100);
    like($w, qr/^Integer overflow in srand at /, "got a warning");
}


{
    my $half = "\x80" . "\0" x 7;
    my @args;
    local ${^RNG} = sub {
        @args = @_;
        return @_ && defined $_[0] && !ref($_[0]) && "$_[0]" eq "8"
            ? $half : "provider result";
    };

    is(int rand(10), 5, "CODE provider supplies bytes to rand");
    ok(eq_array(\@args, [8]), "rand asks a CODE provider for eight bytes");
    my $got = srand("not numeric");
    is($got, "provider result", "custom srand returns the provider result");
    ok(eq_array(\@args, ["not numeric"]), "custom srand receives its explicit argument");

    @args = ("stale");
    $got = srand();
    is($got, "provider result", "custom srand() returns the provider result");
    ok(eq_array(\@args, [undef]), "custom srand() receives undef");
    @args = ("stale");
    srand(undef);
    ok(eq_array(\@args, [undef]), "custom srand(undef) matches srand()");
}

{
    package RNG::TestObject;
    sub new { bless { calls => 0, length => 0, seeds => [] }, shift }
    sub rand_bytes {
        $_[0]{calls}++;
        $_[0]{length} = $_[1];
        "\x80" . "\0" x ($_[1] - 1)
    }
    sub srand { push @{$_[0]{seeds}}, [@_[1 .. $#_]]; "object result" }
}

package main;

{
    my $object = RNG::TestObject->new;
    local ${^RNG} = $object;
    is(int rand(10), 5, "object rand_bytes method is used");
    is($object->{calls}, 1, "object rand_bytes receives the requested length");
    is($object->{length}, 8, "object rand_bytes receives eight");
    my $got = srand();
    is($got, "object result", "object srand method is used");
    is(scalar @{$object->{seeds}}, 1, "object srand() records one seed");
    ok(!defined $object->{seeds}[0][0], "object srand() receives undef");
    srand("seed");
    is(scalar @{$object->{seeds}}, 2, "object seed is recorded");
    is($object->{seeds}[1][0], "seed", "object seed is forwarded");
}

package RNG::BlessedCode;
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
    my $calls = 0;
    ${^RNG} = sub { ++$calls; "\0" x $_[0] };
    rand();
    {
        local ${^RNG};
        rand();
    }
    rand();
    is($calls, 2, "local RNG provider is restored");
}

{
    local ${^RNG} = 42;
    like(eval { rand(); 1 } ? "" : $@,
         qr/\$\{\^RNG\} must be an object, a CODE reference, or undef/,
         "invalid RNG provider is rejected");
}

{
    local ${^RNG} = sub { "12" };
    like(eval { rand(); 1 } ? "" : $@,
         qr/rand_bytes\(\) did not return the requested byte count/,
         "short RNG result is rejected");
}

{
    local ${^RNG} = sub { "\0" x 7 };
    like(eval { rand(); 1 } ? "" : $@,
         qr/rand_bytes\(\) did not return the requested byte count/,
         "short byte-string RNG result is rejected");
}

{
    local ${^RNG} = sub { die "RNG callback failed" };
    like(eval { rand(); 1 } ? "" : $@,
         qr/RNG callback failed/, "provider exceptions propagate");
}
