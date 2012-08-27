#!./perl -w
use Test::More;

use strict;
use Hash::Util::FieldHash qw( :all);

no warnings 'misc';

plan tests => 5;

fieldhash my %h;

ok (!Internals::HvREHASH(%h), "hash doesn't start with rehash flag on");


foreach (1..10) {
  $h{ "\0" x $_ }++;
}

ok (!Internals::HvREHASH(%h), "10 entries doesn't trigger rehash");

SKIP: {
    skip  "Nulls don't hash to the same bucket regardless of length with this PERL_HASH implementation", 1
        if Internals::PERL_HASH(%h, "\0") != Internals::PERL_HASH(%h, "\0" x 20);

    foreach (11..20) {
      $h{"\0"x$_}++;
    }

    ok (Internals::HvREHASH(%h), "20 entries triggers rehash");
}

# second part using an emulation of the PERL_HASH in perl, mounting an
# attack on a pre-populated hash. This is also useful if you need normal
# keys which don't contain \0 -- suitable for stashes

use constant MASK_U32  => 2**32;
use constant HASH_SEED => 0;
use constant THRESHOLD => 14;
use constant START     => "a";

# some initial hash data
fieldhash my %h2;
%h2 = map {$_ => 1} 'a'..'cc';

ok (!Internals::HvREHASH(%h2), 
    "starting with pre-populated non-pathological hash (rehash flag if off)");

my @keys = get_keys(\%h2);
$h2{$_}++ for @keys;
ok (Internals::HvREHASH(%h2), 
    scalar(@keys) . " colliding into the same bucket keys are triggering rehash");

sub get_keys {
    my $hr = shift;

    # the minimum of bits required to mount the attack on a hash
    my $min_bits = log(THRESHOLD)/log(2);

    # if the hash has already been populated with a significant amount
    # of entries the number of mask bits can be higher
    my $keys = scalar keys %$hr;
    my $bits = $keys ? log($keys)/log(2) : 0;
    $bits = $min_bits if $min_bits > $bits;

    $bits = int($bits) < $bits ? int($bits) + 1 : int($bits);
    # need to add 2 bits to cover the internal split cases
    $bits += 2;
    my $mask = 2**$bits-1;
    print "# using mask: $mask ($bits)\n";

    my @keys;
    my $s = START;
    my $c = 0;
    # get 2 keys on top of the THRESHOLD
    my $hash;
    while (@keys < THRESHOLD+2) {
        # next if exists $hash->{$s};
        $hash = Internals::PERL_HASH(%$hr,$s);
        next unless ($hash & $mask) == 0;
        $c++;
        printf "# %2d: %5s, %10s\n", $c, $s, $hash;
        push @keys, $s;
    } continue {
        $s++;
    }

    return @keys;
}


