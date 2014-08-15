use strict;
use warnings;
use utf8;

use Test::More qw/modern/;
use Test::Tester2;

my $results = intercept {
    ok(0, "test failure" );
    ok(1, "test success" );

    subtest 'subtest' => sub {
        ok(0, "subtest failure" );
        ok(1, "subtest success" );

        subtest 'subtest_deeper' => sub {
            ok(0, "deeper subtest failure" );
            ok(1, "deeper subtest success" );
        };
    };

    ok(0, "another test failure" );
    ok(1, "another test success" );
};

results_are(
    $results,

    ok   => {bool => 0},
    diag => {},
    ok   => {bool => 1},

    child => {action => 'push'},
        ok   => {bool => 0},
        diag => {},
        ok   => {bool => 1},

        child => {action => 'push'},
            ok   => {bool => 0},
            diag => {},
            ok   => {bool => 1},

            plan   => {},
            finish => {},

            diag => {tap  => qr/Looks like you failed 1 test of 2/},
            ok   => {bool => 0},
            diag => {},
        child => {action => 'pop'},

        plan   => {},
        finish => {},

        diag => {tap  => qr/Looks like you failed 2 tests of 3/},
        ok   => {bool => 0},
        diag => {},
    child => {action => 'pop'},

    ok   => {bool => 0},
    diag => {},
    ok   => {bool => 1},

    end => "subtest results as expected",
);

done_testing;
