#!./perl

use strict;
use warnings;

use Config;
use Storable qw(dclone);
use Test::More;

BEGIN {
    plan skip_all => 'Storable was not built'
        if $ENV{PERL_CORE} && $Config{'extensions'} !~ /\b Storable \b/x;
    plan skip_all => 'Need 64-bit pointers for this test'
        if $Config{ptrsize} < 8;
    plan skip_all => 'Need ~4 GiB memory for this test, set PERL_TEST_MEMORY > 4'
        if !$ENV{PERL_TEST_MEMORY} || $ENV{PERL_TEST_MEMORY} < 4;
}

# Just too big to fit in an I32.
my $huge = int(2 ** 31);
#my $veryhuge = int(0x90000000); # go all the way

# These overlarge sizes are enabled only since Storable 3.00 and some
# cases need cperl support. Perl5 (as of 5.24) has some internal
# problems with >I32 sizes, which only cperl has fixed.
# hash key size: U32

my @cases = (
    ['huge string',
     sub { my $s = 'x' x $huge; \$s }],

    ['array with huge element',
     sub { my $s = 'x' x $huge; [$s] }],

    # A hash with a huge number of keys would require tens of gigabytes of
    # memory, which doesn't seem like a good idea even for this test file.

    ['hash with huge value',
     sub { my $s = 'x' x $huge; +{ foo => $s } }],

    # Can't test hash with a huge key, because Perl internals currently
    # limit hash keys to <2**31 length.
  );

# v5.24.1c/v5.25.1c switched to die earlier with "Too many elements",
# which is much safer.
if (!($Config{usecperl} and
      (($] >= 5.024001 and $] < 5.025000)
       or $] >= 5.025001))) {
  push @cases,
    ['huge array',
     sub { my @x; $x[$huge] = undef; \@x }],
    # number of keys
    ['huge hash',
     sub { my %x = (0..$huge); \%x } ];
}


plan tests => 2 * scalar @cases;

for (@cases) {
    my ($desc, $build) = @$_;
    note "building test input: $desc";
    my ($input, $exn, $clone);
    if ($build) {
      $input = $build->();
      note "running test: $desc";
      $exn = $@ if !eval { $clone = dclone($input); 1 };
    }
    if ($build && $Config{usecperl}) { # perl5 is not yet 2GB safe.
        is($exn, undef, "$desc no exception");
        is_deeply($clone, $input, "$desc cloned");
    } else {
        like($exn, qr/^Storable cannot yet handle data that needs a 64-bit machine\b/,
             "$desc: throw an exception, not a segfault or panic");
        ok(1, "$desc skip comparison");
    }

    # Ensure the huge objects are freed right now:
    undef $input;
    undef $clone;
}
