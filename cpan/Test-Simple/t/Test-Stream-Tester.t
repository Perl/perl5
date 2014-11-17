use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::Tester';

can_ok( __PACKAGE__, 'intercept', 'events_are' );

my $events = intercept {
    ok(1, "Woo!");
    ok(0, "Boo!");
};

isa_ok($events->[0], 'Test::Stream::Event::Ok');
is($events->[0]->bool, 1, "Got one success");
is($events->[0]->name, "Woo!", "Got test name");

isa_ok($events->[1], 'Test::Stream::Event::Ok');
is($events->[1]->bool, 0, "Got one fail");
is($events->[1]->name, "Boo!", "Got test name");

$events = undef;
my $grab = grab();
my $got = $grab ? 1 : 0;
ok(1, "Intercepted!");
ok(0, "Also Intercepted!");
$events = $grab->finish;
ok($got, "Delayed test that we did in fact get a grab object");
is($grab, undef, "Poof! vanished!");
is(@$events, 2, "got 2 events (2 ok)");
events_are(
    $events,
    check {
        event ok => { bool => 1 };
        event ok => {
            bool => 0,
            diag => qr/Failed/,
        };
        dir 'end';
    },
    'intercepted via grab 1'
);

$events = undef;
$grab = grab();
ok(1, "Intercepted!");
ok(0, "Also Intercepted!");
events_are(
    $grab,
    check {
        event ok => { bool => 1 };
        event ok => { bool => 0, diag => qr/Failed/ };
        dir 'end';
    },
    'intercepted via grab 2'
);
ok(!$grab, "Maybe it never existed?");

$events = intercept {
    ok(1, "Woo!");
    BAIL_OUT("Ooops");
    ok(0, "Should not see this");
};
is(@$events, 2, "Only got 2");
isa_ok($events->[0], 'Test::Stream::Event::Ok');
isa_ok($events->[1], 'Test::Stream::Event::Bail');

$events = intercept {
    plan skip_all => 'All tests are skipped';

    ok(1, "Woo!");
    BAIL_OUT("Ooops");
    ok(0, "Should not see this");
};
is(@$events, 1, "Only got 1");
isa_ok($events->[0], 'Test::Stream::Event::Plan');

my $file = __FILE__;
my $line1;
my $line2;
events_are(
    intercept {
        events_are(
            intercept { ok(1, "foo"); $line1 = __LINE__ },
            check {
                $line2 = __LINE__ + 1;
                event ok => {bool => 0};
                dir 'end';
            },
            'Lets name this test!',
        );
    },

    check {
        event ok => {
            bool => 0,
            diag => [
                qr{Failed test 'Lets name this test!'.*at (\./)?\Q$0\E line}s,
                qr{  Event: 'ok' from \Q$0\E line $line1}s,
                qr{  Check: 'ok' from \Q$0\E line $line2}s,
                qr{  \$got->\{bool\} = '1'},
                qr{  \$exp->\{bool\} = '0'},
            ],
        };

        dir 'end';
    },
    'Failure diag checking',
);

my $line3;
events_are(
    intercept {
        events_are(
            intercept { ok(1, "foo"); ok(1, "bar"); $line3 = __LINE__ },
            check {
                event ok => {bool => 1};
                dir 'end'
            },
            "Should Fail"
        );
    },

    check {
        event ok => {
            bool => 0,
            diag => [
                qr/Failed test 'Should Fail'/,
                qr/Expected end of events, got 'ok' from \Q$0\E line $line3/,
            ],
        };
    },

    end => 'skipping a diag',
);


done_testing;
