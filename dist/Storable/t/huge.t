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
    plan skip_all => 'Need ~4 GiB of core for this test'
        if !$ENV{PERL_TEST_MEMORY} || $ENV{PERL_TEST_MEMORY} < 4;
}

# Just too big to fit in an I32.
my $huge = int(2 ** 31);

# For now, all of these should throw an exception. Actually storing and
# retrieving them would require changing the serialisation format, and
# that's a larger task than I'm looking to undertake right now.
my @cases = (
    ['huge string',
     sub { my $s = 'x' x $huge; \$s }],

    ['huge array',
     sub { my @x; $x[$huge] = undef; \@x }],

    ['array with huge element',
     sub { my $s = 'x' x $huge; [$s] }],

    # A hash with a huge number of keys would require tens of gigabytes of
    # memory, which doesn't seem like a good idea even for this test file.

    ['hash with huge value',
     sub { my $s = 'x' x $huge; +{ foo => $s } }],

    # Can't test hash with a huge key, because Perl internals currently
    # limit hash keys to <2**31 anyway
);

plan tests => scalar @cases;

for (@cases) {
    my ($desc, $build) = @$_;
    note "building test input: $desc";
    my $input = $build->();
    note "running test: $desc";
    my ($exn, $clone);
    $exn = $@ if !eval { $clone = dclone($input); 1 };
    like($exn, qr/^Storable cannot yet handle data that needs a 64-bit machine\b/,
         "$desc: throw an exception, not a segfault or panic");

    # Ensure the huge objects are freed right now:
    undef $input;
    undef $clone;
}
