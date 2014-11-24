use strict;
use warnings;

use Test::CanThread qw/AUTHOR_TESTING/;
use Test::More;

{
    my $todo = sub {
        my $out;
        ok(1);
        42;
    };

    is(
        threads->create($todo)->join,
        42,
        "Correct result after do-er",
    );
}

done_testing;
