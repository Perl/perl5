use strict;
use warnings;

use Test::Stream;
use Test::More;
use Test::Stream::Tester qw/events_are event directive check/;
use Test::MostlyLike;

require Test::Builder;
require Test::CanFork;

use Test::Stream::API qw{
    listen munge follow_up
    enable_forking cull
    peek_todo push_todo pop_todo set_todo inspect_todo
    is_tester init_tester
    is_modern set_modern
    context peek_context clear_context set_context
    intercept
    state_count state_failed state_plan state_ended is_passing
    current_stream

    disable_tap enable_tap subtest_tap_instant subtest_tap_delayed tap_encoding
    enable_numbers disable_numbers set_tap_outputs get_tap_outputs
};

can_ok(__PACKAGE__, qw{
    listen munge follow_up
    enable_forking cull
    peek_todo push_todo pop_todo set_todo inspect_todo
    is_tester init_tester
    is_modern set_modern
    context peek_context clear_context set_context
    intercept
    state_count state_failed state_plan state_ended is_passing
    current_stream

    disable_tap enable_tap subtest_tap_instant subtest_tap_delayed tap_encoding
    enable_numbers disable_numbers set_tap_outputs get_tap_outputs
});

ok(!is_tester('My::Tester'), "Not a tester");
isa_ok(init_tester('My::Tester'), 'Test::Stream::Meta');
isa_ok(is_tester('My::Tester'), 'Test::Stream::Meta');

ok(!is_modern('My::Tester'), "Not a modern tester");
set_modern('My::Tester', 1);
ok(is_modern('My::Tester'), "a modern tester");
set_modern('My::Tester', 0);
ok(!is_modern('My::Tester'), "Not a modern tester");

ok(my $ctx = context(), "Got context");
isa_ok($ctx, 'Test::Stream::Context');
is(context(), $ctx, "Got the same instance again");
is(peek_context(), $ctx, "peek");
my $ref = "$ctx";

clear_context();
my $ne = context() . "" ne $ref;
ok($ne, "cleared");

set_context($ctx);
is(context(), $ctx, "Got the same instance again");

$ctx = undef;
$ne = context() . "" ne $ref;
ok($ne, "New instance");

isa_ok(current_stream(), 'Test::Stream');

my @munge;
my @listen;
my @follow;
intercept {
    munge  { push @munge  => $_[1] };
    listen { push @listen => $_[1] };

    follow_up { push @follow => $_[0]->snapshot };

    ok(1, "pass");
    diag "foo";

    done_testing;
};

is(@listen, 3, "listen got 3 events");
is(@munge,  3, "munge got 3 events");
is(@follow, 1, "Follow was triggered");

my $want = check {
    event ok => { bool => 1 };
    event diag => { message => 'foo' };
    event plan => { max => 1 };
    directive 'end';
};
events_are( \@listen, $want, "Listen events" );
events_are( \@munge, $want, "Munge events" );
isa_ok($follow[0], 'Test::Stream::Context');

my $events = intercept {
    Test::CanFork->import;

    enable_forking;

    my $pid = fork();
    if ($pid) { # Parent
        waitpid($pid, 0);
        cull;
        ok(1, "From Parent");
    }
    else { # child
        ok(1, "From Child");
        exit 0;
    }
};

if (@$events == 1) {
    events_are (
        $events,
        check {
            event plan => {};
        },
        "Not testing forking"
    );
}
else {
    events_are (
        $events,
        check {
            event ok => { name => 'From Child' };
            event ok => { name => 'From Parent' };
        },
        "Got forked events"
    );
}

events_are(
    intercept {
        ok(0, "fail");
        push_todo('foo');
        ok(0, "fail");
        push_todo('bar');
        ok(0, "fail");
        is(peek_todo(), 'bar', "peek works");
        pop_todo();
        ok(0, "fail");
        pop_todo();
        ok(0, "fail");
    },
    check {
        event ok => {todo => '',    in_todo   => 0};
        event ok => {todo => 'foo', in_todo   => 1};
        event ok => {todo => 'bar', in_todo   => 1};
        event ok => {bool => 1,     real_bool => 1}; # Verify peek
        event ok => {todo => 'foo', in_todo   => 1};
        event ok => {todo => '',    in_todo   => 0};
    },
    "Verified TODO stack"
);

my $meta = init_tester('My::Tester');
ok(!$meta->todo, "Package is not in todo");
set_todo('My::Tester', 'foo');
is($meta->todo, 'foo', "Package is in todo");

my @todos = (
    inspect_todo,
    inspect_todo('My::Tester'),
);
push_todo('foo');
push_todo('bar');
Test::Builder->new->todo_start('tb todo');
$My::Tester::TODO = 'pkg todo';
push @todos => inspect_todo, inspect_todo('My::Tester');
$My::Tester::TODO = undef;
Test::Builder->new->todo_end();
pop_todo;
pop_todo;
set_todo('My::Tester', undef);
push @todos => inspect_todo, inspect_todo('My::Tester');

is_deeply(
    \@todos,
    [
        {
            TB   => undef,
            TODO => [],
        },
        {
            META => 'foo',
            PKG  => undef,
            TB   => undef,
            TODO => [],
        },
        {
            TB   => 'tb todo',
            TODO => [qw/foo bar/],
        },
        {
            META => 'foo',
            PKG  => 'pkg todo',
            TB   => 'tb todo',
            TODO => [qw/foo bar/],
        },
        {
            TB   => undef,
            TODO => [],
        },
        {
            META => undef,
            PKG  => undef,
            TB   => undef,
            TODO => [],
        }
    ],
    "Todo state from inspect todo"
);

my @state;
intercept {
    plan tests => 3;
    ok(1, "pass");
    ok(2, "pass");

    push @state => {
        count   => state_count()  || 0,
        failed  => state_failed() || 0,
        plan    => state_plan()   || undef,
        ended   => state_ended()  || undef,
        passing => is_passing(),
    };

    ok(0, "fail");
    done_testing;

    push @state => {
        count   => state_count()  || 0,
        failed  => state_failed() || 0,
        plan    => state_plan()   || undef,
        ended   => state_ended()  || undef,
        passing => is_passing(),
    };
};

mostly_like(
    \@state,
    [
        { count => 2, failed => 0, passing => 1, ended => undef },
        { count => 3, failed => 1, passing => 0 },
    ],
    "Verified Test state"
);

events_are(
    [ $state[0]->{plan}, $state[1]->{plan} ],
    check {
        event plan => { max => 3 };
        event plan => { max => 3 };
    },
    "Parts of state that are events check out."
);

isa_ok( $state[1]->{ended}, 'Test::Stream::Context' );

my $got;
my $results = "";
my $utf8 = "";
open( my $fh, ">>", \$results ) || die "Could not open handle to scalar!";
open( my $fh_utf8, ">>", \$utf8 ) || die "Could not open handle to scalar!";

intercept {
    enable_tap(); # Disabled by default in intercept()
    set_tap_outputs( std => $fh, err => $fh, todo => $fh );
    $got = get_tap_outputs();

    ok(1, "pass");

    disable_tap();
    ok(0, "fail");

    enable_tap();
    tap_encoding('utf8');
    set_tap_outputs( encoding => 'utf8', std => $fh_utf8, err => $fh_utf8, todo => $fh_utf8 );
    ok(1, "pass");
    tap_encoding('legacy');

    disable_numbers();
    ok(1, "pass");
    enable_numbers();
    ok(1, "pass");

    subtest_tap_instant();
    subtest foo => sub { ok(1, 'pass') };

    subtest_tap_delayed();
    subtest foo => sub { ok(1, 'pass') };
};

is_deeply(
    $got,
    { encoding => 'legacy', std => $fh, err => $fh, todo => $fh },
    "Got outputs"
);

is( $results, <<EOT, "got TAP output");
ok 1 - pass
ok - pass
ok 5 - pass
# Subtest: foo
    ok 1 - pass
    1..1
ok 6 - foo
ok 7 - foo {
    ok 1 - pass
    1..1
}
EOT

is( $utf8, <<EOT, "got utf8 TAP output");
ok 3 - pass
EOT

done_testing;
