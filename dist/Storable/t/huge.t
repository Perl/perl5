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

# These overlarge sizes are enabled only since Storable 3.00 and some
# cases need cperl support. Perl5 (as of 5.24) has some internal
# problems with >I32 sizes.
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
    # limit hash keys to <2**31 length.

    # Only cperl can handle more than I32 hash keys due to limited iterator size.
    ['huge hash',
     sub { my %x = (0..0xffffffff); \%x }],
);

plan tests => 2 * scalar @cases;

for (@cases) {
    my ($desc, $build) = @$_;
    note "building test input: $desc";
    my $input = $build->();
    note "running test: $desc";
    my ($exn, $clone);
    $exn = $@ if !eval { $clone = dclone($input); 1 };
    if ($Config{usecperl} or $] >= 5.025003) { # guessing
        is($exn, '');
        is($input, $clone);
    } else {
        like($exn, qr/^Storable cannot yet handle data that needs a 64-bit machine\b/,
             "$desc: throw an exception, not a segfault or panic");
        ok(1, "skip comparison");
    }

    # Ensure the huge objects are freed right now:
    undef $input;
    undef $clone;
}
