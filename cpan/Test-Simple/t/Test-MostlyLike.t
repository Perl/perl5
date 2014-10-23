use strict;
use warnings;

use Test::Stream;
use Test::MostlyLike;
use Test::More;
use Test::Stream::Tester;

use ok 'Test::MostlyLike';

{
    package XXX;

    sub new { bless {ref => ['a']}, shift };

    sub numbers { 1 .. 10 };
    sub letters { 'a' .. 'e' };
    sub ref { [ 1 .. 10 ] };
}

events_are (
    intercept {
        mostly_like( 'a', 'a', "match" );
        mostly_like( 'a', 'b', "no match" );

        mostly_like(
            [ qw/a b c/ ],
            [ qw/a b c/ ],
            "all match",
        );

        mostly_like(
            [qw/a b c/],
            { 1 => 'b' },
            "Only check one index (match)",
        );
        mostly_like(
            [qw/a b c/],
            { 1 => 'x' },
            "Only check one index (no match)",
        );

        mostly_like(
            { a => 1, b => 2, c => 3 },
            { a => 1, b => 2, c => 3 },
            "all match"
        );

        mostly_like(
            { a => 1, b => 2, c => 3 },
            { b => 2, d => undef },
            "A match and an expected empty"
        );

        mostly_like(
            { a => 1, b => 2, c => 3 },
            { b => undef },
            "Expect empty (fail)"
        );

        mostly_like(
            { a => 'foo', b => 'bar' },
            { a => qr/o/, b => qr/a/ },
            "Regex check"
        );

        mostly_like(
            { a => 'foo', b => 'bar' },
            { a => qr/o/, b => qr/o/ },
            "Regex check fail"
        );

        mostly_like(
            { a => { b => { c => { d => 1 }}}},
            { a => { b => { c => { d => 1 }}}},
            "Deep match"
        );

        mostly_like(
            { a => { b => { c => { d => 1 }}}},
            { a => { b => { c => { d => 2 }}}},
            "Deep mismatch"
        );

        mostly_like(
            XXX->new,
            {
                ':ref' => ['a'],
                ref => [ 1 .. 10 ],
                '[numbers]' => [ 1 .. 10 ],
                '[letters]' => [ 'a' .. 'e' ],
            },
            "Object check"
        );

        mostly_like(
            XXX->new,
            {
                ':ref' => ['a'],
                ref => [ 1 .. 10 ],
                '[numbers]' => [ 1 .. 10 ],
                '[letters]' => [ 'a' .. 'e' ],
                '[invalid]' => [ 'x' ],
            },
            "Object check"
        );

    },
    check {
        event ok => { bool => 1 };
        event ok => {
            bool => 0,
            diag => qr/got: 'a'.*\n.*expected: 'b'/,
        };

        event ok => { bool => 1 };
        event ok => { bool => 1 };

        event ok => {
            bool => 0,
            diag => qr/\$got->\[1\] = 'b'\n\s*\$expected->\[1\] = 'x'/,
        };

        event ok => { bool => 1 };
        event ok => { bool => 1 };

        event ok => {
            bool => 0,
            diag => qr/\$got->\{b\} = '2'\n\s*\$expected->\{b\} = undef/,
        };

        event ok => { bool => 1 };
        event ok => {
            bool => 0,
            diag => qr/\$got->\{b\} = 'bar'\n\s+\$expected->\{b\} = .*o/,
        };

        event ok => { bool => 1 };
        event ok => {
            bool => 0,
            diag => qr/\$got->\Q{a}{b}{c}{d}\E = '1'\n\s+\$expected->\Q{a}{b}{c}{d}\E = '2'/,
        };

        event ok => { bool => 1 };
        event ok => {
            bool => 0,
            diag => [
                qr/\[\s+\$got->invalid\(\)\] = '\(EXCEPTION\)'/,
                qr/\[\$expected->\{invalid\}\] = ARRAY/,
                qr/Can't locate object method "invalid" via package "XXX"/,
            ],
        };

        directive 'end';
    },
    "Tolerant"
);

done_testing;
