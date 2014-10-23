use strict;
use warnings;

use Test::Simple tests => 1;
use Test::Stream::Tester;

events_are (
    intercept {
        ok(1, "Pass");
        ok(0, "Fail");
    },
    check {
        event ok => {
            bool => 1,
            name => 'Pass',
            diag => '',
        };
        event ok => {
            bool => 0,
            name => 'Fail',
            diag => qr/Failed test 'Fail'/,
        };
    },
);
