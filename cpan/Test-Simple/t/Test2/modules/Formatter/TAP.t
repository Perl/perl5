use strict;
use warnings;
use Test2::Formatter::TAP;
use Test2::API qw/context/;
use PerlIO;

BEGIN {
    require "t/tools.pl";
    *OUT_STD = Test2::Formatter::TAP->can('OUT_STD') or die;
    *OUT_ERR = Test2::Formatter::TAP->can('OUT_ERR') or die;
}

use Test2::API;
Test2::API::test2_add_callback_context_release(sub {
    my $ctx = shift;
    return if $ctx->hub->is_passing;
    $ctx->throw("(Die On Fail)");
});

ok(my $one = Test2::Formatter::TAP->new, "Created a new instance");
my $handles = $one->handles;
is(@$handles, 2, "Got 2 handles");
ok($handles->[0] != $handles->[1], "First and second handles are not the same");
my $layers = { map {$_ => 1} PerlIO::get_layers($handles->[0]) };

if (${^UNICODE} & 2) { # 2 means STDIN
    ok($layers->{utf8}, "'S' is set in PERL_UNICODE, or in -C, honor it, utf8 should be on")
}
else {
    ok(!$layers->{utf8}, "Not utf8 by default")
}

$one->encoding('utf8');
is($one->encoding, 'utf8', "Got encoding");
$handles = $one->handles;
is(@$handles, 2, "Got 2 handles");
$layers = { map {$_ => 1} PerlIO::get_layers($handles->[0]) };
ok($layers->{utf8}, "Now utf8");

my $two = Test2::Formatter::TAP->new(encoding => 'utf8');
$handles = $two->handles;
is(@$handles, 2, "Got 2 handles");
$layers = { map {$_ => 1} PerlIO::get_layers($handles->[0]) };
ok($layers->{utf8}, "Now utf8");


{
    package My::Event;

    use base 'Test2::Event';
    use Test2::Util::HashBase qw{pass name diag note};

    Test2::Formatter::TAP->register_event(
        __PACKAGE__,
        sub {
            my $self = shift;
            my ($e, $num) = @_;
            return (
                [main::OUT_STD, "ok $num - " . $e->name . "\n"],
                [main::OUT_ERR, "# " . $e->name . " " . $e->diag . "\n"],
                [main::OUT_STD, "# " . $e->name . " " . $e->note . "\n"],
            );
        }
    );
}

my ($std, $err);
open( my $stdh, '>', \$std ) || die "Ooops";
open( my $errh, '>', \$err ) || die "Ooops";

my $it = Test2::Formatter::TAP->new(
    handles => [$stdh, $errh, $stdh],
);

$it->write(
    My::Event->new(
        pass => 1,
        name => 'foo',
        diag => 'diag',
        note => 'note',
        trace => 'fake',
    ),
    55,
);

$it->write(
    My::Event->new(
        pass => 1,
        name => 'bar',
        diag => 'diag',
        note => 'note',
        trace => 'fake',
        nested => 1,
    ),
    1,
);

is($std, <<EOT, "Got expected TAP output to std");
ok 55 - foo
# foo note
    ok 1 - bar
    # bar note
EOT

is($err, <<EOT, "Got expected TAP output to err");
# foo diag
    # bar diag
EOT

$it = undef;
close($stdh);
close($errh);

my ($trace, $ok, $diag, $plan, $bail);

my $fmt = Test2::Formatter::TAP->new;
sub before_each {
    # Make sure there is a fresh trace object for each group
    $trace = Test2::Util::Trace->new(
        frame => ['main_foo', 'foo.t', 42, 'main_foo::flubnarb'],
    );
}

tests bail => sub {
    my $bail = Test2::Event::Bail->new(
        trace => $trace,
        reason => 'evil',
    );

    is_deeply(
        [$fmt->event_tap($bail, 1)],
        [[OUT_STD, "Bail out!  evil\n" ]],
        "Got tap"
    );
};

tests diag => sub {
    my $diag = Test2::Event::Diag->new(
        trace => $trace,
        message => 'foo',
    );

    is_deeply(
        [$fmt->event_tap($diag, 1)],
        [[OUT_ERR, "# foo\n"]],
        "Got tap"
    );

    $diag->set_message("foo\n");
    is_deeply(
        [$fmt->event_tap($diag, 1)],
        [[OUT_ERR, "# foo\n"]],
        "Only 1 newline"
    );

    $diag->set_message("foo\nbar\nbaz");
    is_deeply(
        [$fmt->event_tap($diag, 1)],
        [[OUT_ERR, "# foo\n# bar\n# baz\n"]],
        "All lines have proper prefix"
    );
};

tests exception => sub {
    my $exception = Test2::Event::Exception->new(
        trace => $trace,
        error => "evil at lake_of_fire.t line 6\n",
    );

    is_deeply(
        [$fmt->event_tap($exception, 1)],
        [[OUT_ERR, "evil at lake_of_fire.t line 6\n" ]],
        "Got tap"
    );
};

tests note => sub {
    my $note = Test2::Event::Note->new(
        trace => $trace,
        message => 'foo',
    );

    is_deeply(
        [$fmt->event_tap($note, 1)],
        [[OUT_STD, "# foo\n"]],
        "Got tap"
    );

    $note->set_message("foo\n");
    is_deeply(
        [$fmt->event_tap($note, 1)],
        [[OUT_STD, "# foo\n"]],
        "Only 1 newline"
    );

    $note->set_message("foo\nbar\nbaz");
    is_deeply(
        [$fmt->event_tap($note, 1)],
        [[OUT_STD, "# foo\n# bar\n# baz\n"]],
        "All lines have proper prefix"
    );
};

tests special_characters => sub {
    my $ok = Test2::Event::Ok->new(
        trace => $trace,
        name  => 'nothing special',
        pass  => 1,
    );

    is_deeply(
        [$fmt->event_tap($ok, 1)],
        [[OUT_STD, "ok 1 - nothing special\n"]],
        "Got regular ok"
    );

    $ok = Test2::Event::Ok->new(
        trace => $trace,
        name  => 'just a \\ slash',
        pass  => 1,
    );

    is_deeply(
        [$fmt->event_tap($ok, 1)],
        [[OUT_STD, "ok 1 - just a \\ slash\n"]],
        "Do not escape slashes without a '#'"
    );

    $ok = Test2::Event::Ok->new(
        trace => $trace,
        name  => 'a \\ slash and a # hash',
        pass  => 1,
    );

    is_deeply(
        [$fmt->event_tap($ok, 1)],
        [[OUT_STD, "ok 1 - a \\\\ slash and a \\# hash\n"]],
        "Escape # and any slashes already present"
    );

    $ok = Test2::Event::Ok->new(
        trace => $trace,
        name  => "a \\ slash and a # hash\nand \\ some # newlines\nlike this # \\",
        pass  => 1,
    );

    is_deeply(
        [$fmt->event_tap($ok, 1)],
        [
            [OUT_STD, "ok 1 - a \\\\ slash and a \\# hash\n"],
            [OUT_STD, "#      and \\ some # newlines\n"],
            [OUT_STD, "#      like this # \\\n"],
        ],
        "Escape # and any slashes already present, and split newlines, do not escape the newlines"
    );

    $ok = Test2::Event::Ok->new(
        trace => $trace,
        name  => "Nothing special until the end \\\nfoo \\ bar",
        pass  => 1,
    );

    is_deeply(
        [$fmt->event_tap($ok, 1)],
        [
            [OUT_STD, "ok 1 - Nothing special until the end \\\\\n"],
            [OUT_STD, "#      foo \\ bar\n"],
        ],
        "Special case, escape things if last character of the first line is a \\"
    );

};

for my $pass (1, 0) {
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    tests name_and_number => sub {
        my $ok = Test2::Event::Ok->new(trace => $trace, pass => $pass, name => 'foo');
        my @tap = $fmt->event_tap($ok, 7);
        is_deeply(
            \@tap,
            [
                [OUT_STD, ($pass ? 'ok' : 'not ok') . " 7 - foo\n"],
            ],
            "Got expected output"
        );
    };

    tests no_number => sub {
        my $ok = Test2::Event::Ok->new(trace => $trace, pass => $pass, name => 'foo');
        my @tap = $fmt->event_tap($ok, );
        is_deeply(
            \@tap,
            [
                [OUT_STD, ($pass ? 'ok' : 'not ok') . " - foo\n"],
            ],
            "Got expected output"
        );
    };

    tests no_name => sub {
        my $ok = Test2::Event::Ok->new(trace => $trace, pass => $pass);
        my @tap = $fmt->event_tap($ok, 7);
        is_deeply(
            \@tap,
            [
                [OUT_STD, ($pass ? 'ok' : 'not ok') . " 7\n"],
            ],
            "Got expected output"
        );
    };

    tests todo => sub {
        my $ok = Test2::Event::Ok->new(trace => $trace, pass => $pass);
        $ok->set_todo('b');
        my @tap = $fmt->event_tap($ok, 7);
        is_deeply(
            \@tap,
            [
                [OUT_STD, ($pass ? 'ok' : 'not ok') . " 7 # TODO b\n"],
            ],
            "Got expected output"
        );

        $ok->set_todo("");

        @tap = $fmt->event_tap($ok, 7);
        is_deeply(
            \@tap,
            [
                [OUT_STD, ($pass ? 'ok' : 'not ok') . " 7 # TODO\n"],
            ],
            "Got expected output"
        );
    };
};

tests plan => sub {
    my $plan = Test2::Event::Plan->new(
        trace => $trace,
        max => 100,
    );

    is_deeply(
        [$fmt->event_tap($plan, 1)],
        [[OUT_STD, "1..100\n"]],
        "Got tap"
    );

    $plan->set_max(0);
    $plan->set_directive('SKIP');
    $plan->set_reason('foo');
    is_deeply(
        [$fmt->event_tap($plan, 1)],
        [[OUT_STD, "1..0 # SKIP foo\n"]],
        "Got tap for skip_all"
    );

    $plan = Test2::Event::Plan->new(
        trace => $trace,
        max => 0,
        directive => 'skip_all',
    );
    is_deeply(
        [$fmt->event_tap($plan)],
        [[OUT_STD, "1..0 # SKIP\n"]],
        "SKIP without reason"
    );

    $plan = Test2::Event::Plan->new(
        trace => $trace,
        max => 0,
        directive => 'no_plan',
    );
    is_deeply(
        [$fmt->event_tap($plan)],
        [],
        "NO PLAN"
    );

    $plan = Test2::Event::Plan->new(
        trace => $trace,
        max => 0,
        directive => 'skip_all',
        reason => "Foo\nBar\nBaz",
    );
    is_deeply(
        [$fmt->event_tap($plan)],
        [
            [OUT_STD, "1..0 # SKIP Foo\n# Bar\n# Baz\n"],
        ],
        "Multi-line reason for skip"
    );
};

tests subtest => sub {
    my $st = 'Test2::Event::Subtest';

    my $one = $st->new(
        trace      => $trace,
        pass       => 1,
        buffered   => 1,
        name       => 'foo',
        subtest_id => '1-1-1',
    );

    is_deeply(
        [$fmt->event_tap($one, 5)],
        [
            [OUT_STD, "ok 5 - foo {\n"],
            [OUT_STD, "}\n"],
        ],
        "Got Buffered TAP output"
    );

    $one->set_buffered(0);
    is_deeply(
        [$fmt->event_tap($one, 5)],
        [
            [OUT_STD, "ok 5 - foo\n"],
        ],
        "Got Unbuffered TAP output"
    );

    $one = $st->new(
        trace     => $trace,
        pass      => 0,
        buffered  => 1,
        name      => 'bar',
        subtest_id => '1-1-1',
        subevents => [
            Test2::Event::Ok->new(trace => $trace, name => 'first',  pass => 1),
            Test2::Event::Ok->new(trace => $trace, name => 'second', pass => 0),
            Test2::Event::Ok->new(trace => $trace, name => 'third',  pass => 1),

            Test2::Event::Diag->new(trace => $trace, message => 'blah blah'),

            Test2::Event::Plan->new(trace => $trace, max => 3),
        ],
    );

    {
        local $ENV{HARNESS_IS_VERBOSE};
        is_deeply(
            [$fmt->event_tap($one, 5)],
            [
                [OUT_STD, "not ok 5 - bar {\n"],
                [OUT_STD, "    ok 1 - first\n"],
                [OUT_STD, "    not ok 2 - second\n"],
                [OUT_STD, "    ok 3 - third\n"],
                [OUT_ERR, "    # blah blah\n"],
                [OUT_STD, "    1..3\n"],
                [OUT_STD, "}\n"],
            ],
            "Got Buffered TAP output (non-verbose)"
        );
    }

    {
        local $ENV{HARNESS_IS_VERBOSE} = 1;
        is_deeply(
            [$fmt->event_tap($one, 5)],
            [
                [OUT_STD, "not ok 5 - bar {\n"],
                [OUT_STD, "    ok 1 - first\n"],
                [OUT_STD, "    not ok 2 - second\n"],
                [OUT_STD, "    ok 3 - third\n"],
                [OUT_ERR, "    # blah blah\n"],
                [OUT_STD, "    1..3\n"],
                [OUT_STD, "}\n"],
            ],
            "Got Buffered TAP output (verbose)"
        );
    }

    {
        local $ENV{HARNESS_IS_VERBOSE};
        $one->set_buffered(0);
        is_deeply(
            [$fmt->event_tap($one, 5)],
            [
                # In unbuffered TAP the subevents are rendered outside of this.
                [OUT_STD, "not ok 5 - bar\n"],
            ],
            "Got Unbuffered TAP output (non-verbose)"
        );
    }

    {
        local $ENV{HARNESS_IS_VERBOSE} = 1;
        $one->set_buffered(0);
        is_deeply(
            [$fmt->event_tap($one, 5)],
            [
                # In unbuffered TAP the subevents are rendered outside of this.
                [OUT_STD, "not ok 5 - bar\n"],
            ],
            "Got Unbuffered TAP output (verbose)"
        );
    }
};

tests skip => sub {
    my $skip = Test2::Event::Skip->new(trace => $trace, pass => 1, name => 'foo', reason => 'xxx');
    my @tap = $fmt->event_tap($skip, 7);
    is_deeply(
        \@tap,
        [
            [OUT_STD, "ok 7 - foo # skip xxx\n"],
        ],
        "Passing Skip"
    );

    $skip->set_pass(0);
    @tap = $fmt->event_tap($skip, 7);
    is_deeply(
        \@tap,
        [
            [OUT_STD, "not ok 7 - foo # skip xxx\n"],
        ],
        "Failling Skip"
    );

    $skip->set_todo("xxx");
    @tap = $fmt->event_tap($skip, 7);
    is_deeply(
        \@tap,
        [
            [OUT_STD, "not ok 7 - foo # TODO & SKIP xxx\n"],
        ],
        "Todo Skip"
    );
};

done_testing;
