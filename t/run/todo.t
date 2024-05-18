#!./perl
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';    # for fresh_perl_is() etc
}

use strict;
use warnings;

# This file is a place for tests that fail at the time they are added here.
#
# When a ticket is filed, just follow the paradigm(s) in this file to add a
# test that shows the failure.
#
# It is expected that when new tickets are opened, some will actually be
# duplicates of existing known bad behavior.  And since there are so many open
# tickets, we might overlook that.  If there is a test here, we would
# automatically discover that a fix for the newer ticket actually fixed an
# earlier one (or ones) as well.  Thus the issue can be closed, and the final
# disposition of the test here determined at that time.  (For example, perhaps
# it is redundant to the test demonstrating the bug that was intentionally
# fixed, so can be removed altogether.)

my $switches = "";

our $TODO;
TODO: {
    local $TODO = "GH 16250";
    fresh_perl_is(<<~'EOF',
        "abcde5678" =~ / b (*pla:.*(*plb:(*plb:(.{4}))? (.{5})).$)/x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        "abcde5678" =~ / b .* (*plb:(*plb:(.{4}))? (.{5}) ) .$ /x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        EOF
    "undef:de567\nundef:de567", { $switches }, "");
}

done_testing();
