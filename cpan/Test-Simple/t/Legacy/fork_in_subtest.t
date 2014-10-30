use strict;
use warnings;

use Config;

BEGIN {
    my $Can_Fork = $Config{d_fork} ||
                   (($^O eq 'MSWin32' || $^O eq 'NetWare') and
                    $Config{useithreads} and
                    $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/
                   );

    if( !$Can_Fork ) {
        require Test::More;
        Test::More::plan(skip_all => "This system cannot fork");
        exit 0;
    }
    elsif ($^O eq 'MSWin32' && $] == 5.010000) {
        require Test::More;
        Test::More::plan('skip_all' => "5.10 has fork/threading issues that break fork on win32");
        exit 0;
    }
}

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
