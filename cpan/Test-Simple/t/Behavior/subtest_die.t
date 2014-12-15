use strict;
use warnings;
use Test::More;

use Test::Stream::Tester;

my ($ok, $err);
events_are(
    intercept {
        $ok = eval {
            subtest foo => sub {
                ok(1, "Pass");
                die "Ooops";
            };
            1;
        };
        $err = $@;
    },
    check {
        directive seek => 1;
        event subtest => {
            bool => 0,
            real_bool => 0,
            name => 'foo',
            exception => qr/^Ooops/,
        };
        directive 'end';
    },
    "Subtest fails if it throws an exception"
);

ok(!$ok, "subtest died");
like($err, qr/^Ooops/, "Got expected exception");

done_testing;
