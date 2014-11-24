use strict;
use warnings;

use Test::CanFork;

use Test::Stream 'enable_fork';
use Test::More;
# This just goes to show how silly forking inside a subtest would actually
# be....

ok(1, "fine $$");

my $pid;
subtest my_subtest => sub {
    ok(1, "inside 1 | $$");
    $pid = fork();
    ok(1, "inside 2 | $$");
};

if($pid) {
    waitpid($pid, 0);

    ok(1, "after $$");

    done_testing;
}
