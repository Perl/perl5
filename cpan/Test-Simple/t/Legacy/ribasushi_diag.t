use strict;
use warnings;

use Test::More;

BEGIN {
    my $has_module = eval { require SQL::Abstract::Test; 1 };
    my $required = $ENV{AUTHOR_TESTING};

    if ($required && !$has_module) {
        die "This test requires 'SQL::Abstract::Test' to be installed when AUTHOR_TESTING.\n";
    }

    unless($required) {
        plan skip_all => "Only run when AUTHOR_TESTING is set";
    }
}

{
    package Worker;

    sub do_work {
        local $Test::Builder::Level = $Test::Builder::Level + 2;
        shift->();
    }
}

use SQL::Abstract::Test;
use Test::Stream::Tester;

my $events = intercept {
    local $TODO = "Not today";

    Worker::do_work(
        sub {
            SQL::Abstract::Test::is_same_sql_bind(
                'buh', [],
                'bah', [1],
            );
        }
    );
};

ok( !(grep { $_->context->in_todo ? 0 : 1 } @{$events->[0]->diag}), "All diag is todo" );

events_are(
    $events,
    check {
        event ok => {
            in_todo => 1,
        };
        event note => { in_todo => 1 };
        event note => { in_todo => 1 };
        dir 'end';
    },
    "All events are TODO"
);

done_testing;
