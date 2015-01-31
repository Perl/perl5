use Test::More;
use strict;
use warnings;

use Test::Stream::Tester;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings => @_ };
my @events = intercept { cmp_ok( undef, '==', 6 ) };

is(@warnings, 1, "1 warning");

like(
    $warnings[0],
    qr/Use of uninitialized value .* at \(eval in cmp_ok\)/,
    "Got the expected warning"
);

done_testing;
