use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'ok';

use Test::Stream::Tester;

events_are (
    intercept {
        eval "use ok 'Something::Fake'; 1" || die $@;
    },
    check {
        event ok => {
            bool => 0,
            name => 'use Something::Fake;',
            diag => qr/^\s*Failed test 'use Something::Fake;'/,
        };
    },
    "Basic test"
);

done_testing;
