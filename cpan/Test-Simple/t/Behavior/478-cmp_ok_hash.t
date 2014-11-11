use strict;
use warnings;
use Test::More;

use Test::Stream::Tester;

my $want = 0;
my $got  = 0;

cmp_ok($got, 'eq', $want, "Passes on correct comparison");

my @warn;
my $events = intercept {
    no warnings 'redefine';
    local $SIG{__WARN__} = sub {
        push @warn => @_;
    };
    cmp_ok($got, '#eq', $want, "You shall not pass!");
};

# We are not going to inspect the warning because it is not super predictable,
# and changes with eval specifics.
ok(@warn, "We got warnings");

events_are(
    $events,
    check {
        event ok => {
            bool => 0,
            diag => qr/syntax error at \(eval in cmp_ok\)/,
        };
    },
    "Events meet expectations"
);

done_testing;
