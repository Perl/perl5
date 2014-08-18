use strict;
use warnings;

use Test::More;

BEGIN {
    my $has_module = eval { require SQL::Abstract::Test; 1 };
    my $required = $ENV{AUTHOR_TESTING};

    if ($required && !$has_module) {
        die "This test requires 'SQL::Abstract::Test' to be installed when AUTHOR_TESTING.\n";
    }
    else {
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
use Test::Tester2;

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

events_are(
    $events,
    ok   => { in_todo => 1 },
    diag => { in_todo => 1 },
    note => { in_todo => 1 },
    note => { in_todo => 1 },
    end => "All events are TODO"
);

done_testing;
