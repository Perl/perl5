use strict;
use warnings;

# This test is for gh #16
# Also see https://rt.perl.org/Public/Bug/Display.html?id=127774

# Ceate this END before anything else so that $? gets set to 0
END { $? = 0 }

BEGIN {
    print "\n1..1\n";
    close(STDERR);
    open(STDERR, '>&', STDOUT);
}

use Test2::API;

eval(' sub { die "xxx" } ')->();
END {
    sub { my $ctx = Test2::API::context(); $ctx->release; }->();
    print "ok 1 - Did not segv\n";
    $? = 0;
}
