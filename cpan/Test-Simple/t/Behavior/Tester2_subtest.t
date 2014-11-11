use strict;
use warnings;
use utf8;

use Test::Stream;
use Test::More;
use Test::Stream::Tester;

my $events = intercept {
    ok(0, "test failure" );
    ok(1, "test success" );

    subtest 'subtest' => sub {
        ok(0, "subtest failure" );
        ok(1, "subtest success" );

        subtest 'subtest_deeper' => sub {
            ok(1, "deeper subtest success" );
        };
    };

    ok(0, "another test failure" );
    ok(1, "another test success" );
};

events_are(
    $events,

    check {
        event ok   => {bool => 0, diag => qr/Fail/};
        event ok   => {bool => 1};

        event note => {message => 'Subtest: subtest'};
        event subtest => {
            name => 'subtest',
            bool => 0,
            diag => qr/Failed test 'subtest'/,

            events => check {
                event ok => {bool => 0};
                event ok => {bool => 1};

                event note => {message => 'Subtest: subtest_deeper'};
                event subtest => {
                    bool => 1,
                    name => 'subtest_deeper',
                    events => check {
                        event ok => { bool => 1 };
                    },
                };

                event plan   => { max => 3 };
                event finish => { tests_run => 3, tests_failed => 1 };
                event diag   => { message => qr/Looks like you failed 1 test of 3/ };

                dir end => 'End of subtests events';
            },
        };

        event ok => {bool => 0};
        event ok => {bool => 1};

        dir end => "subtest events as expected";
    },

    "Subtest events"
);

done_testing;
