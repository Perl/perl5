#!./perl -w

BEGIN {
    chdir "t" if -d "t";
    require "./test.pl";
    set_up_inc( qw(. ../lib) );
}

# Test srand.

use strict;

plan(tests => 27);

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

my $string_seed = 'a reproducible string seed';
srand($string_seed);
my @string_seed_run = mk_rand;
my $string_seed_state = srand($string_seed);
srand($string_seed_state);
ok(eq_array(\@string_seed_run, [mk_rand]),
   'a nonnumeric string seed returns its built-in Drand48 state for replay');

my $automatic_seed = srand;
cmp_ok($automatic_seed, '<=', 0xffffffff,
       'automatic built-in srand returns a 32-bit seed');

$seed = srand(0);
ok( defined($seed) && !$seed, "defined false return value for srand(0)");
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
    is( $b, 0, "is a zero");
    is( "@warnings", "", "Does not warn");
}

# [perl #40605]
{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    srand(2**100);
    is($w, '', "large string seeds do not warn");
}

for my $case (
    [ 123.5,     123 ],
    [ -123.5,    123 ],
    [ '+123.5',  123 ],
    [ '-123.5',  123 ],
    [ '.5',         0 ],
    [ '-.5',        0 ],
) {
    my ($seed, $integer) = @$case;

    srand($seed);
    my @fractional = mk_rand;
    srand($integer);
    ok(eq_array(\@fractional, [mk_rand]),
       "$seed retains the built-in drand48 numeric compatibility path");
}

{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    srand('1e6');
    is($w, '', 'exponent notation takes the string seed path');
}

{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    srand('18446744073709551616');
    my @large_decimal = mk_rand;
    srand(0);
    ok(!eq_array(\@large_decimal, [mk_rand]),
       'a decimal seed beyond U64 takes the string seed path');
    is($w, '', 'a decimal seed beyond U64 does not warn');
}

{
    my $wide = "caf\x{e9}";
    my $octets = $wide;
    utf8::upgrade($wide);
    utf8::downgrade($octets, 1);
    srand($wide);
    my @wide = mk_rand;
    srand($octets);
    ok(eq_array(\@wide, [mk_rand]),
       'UTF-8 seed storage does not change the seed octets');
}

{
    srand(42);
    my @number = mk_rand;
    srand('42');
    ok(eq_array(\@number, [mk_rand]), 'numeric and string integer seeds agree');
}

{
    use warnings;
    my $w = '';
    my $seed;
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    $seed = srand("4294967296");
    like($w, qr/Integer overflow in srand/,
         "a numeric seed wider than 32 bits warns");
    cmp_ok($seed, '==', 0,
           "a numeric seed wider than 32 bits retains its low bits");
    ok(defined($seed) && !$seed,
       'an overflow-reduced zero is defined and false');
}

{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= $_[0] };
    srand(bless {}, 'RNG::UnstringifiedReference');
    like($w, qr/reference without string overloading/,
         "an unstringified reference seed warns");
}
