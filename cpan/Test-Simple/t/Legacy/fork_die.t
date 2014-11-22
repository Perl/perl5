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

# The failure case for this test is producing 2 results, 1 pass and 1 fail,
# both with the same test number. If this test file does anything other than 1
# (non-indented) result that passes, it has failed in one way or another.
use Test::More tests => 1;
use Test::Stream qw/context/;

my $line;

subtest do_it => sub {
    ok(1, "Pass!");

    my ($read, $write);
    pipe($read, $write) || die "Could not open pipe";

    my $pid = fork();
    die "Forking failed!" unless defined $pid;

    unless($pid) {
        close($read);
        Test::Stream::IOSets->_autoflush($write);
        my $ctx = context();
        my $handles = $ctx->stream->io_sets->init_encoding('legacy');
        $handles->[0] = $write;
        $handles->[1] = $write;
        $handles->[2] = $write;
        *STDERR = $write;
        *STDOUT = $write;

        die "This process did something wrong!"; BEGIN { $line = __LINE__ };
    }
    close($write);

    waitpid($pid, 0);
    ok($?, "Process exited with failure");

    {
        local $SIG{ALRM} = sub { die "Read Timeout\n" };
        alarm 2;
        my @output = map {chomp($_); $_} <$read>;
        alarm 0;
        is_deeply(
            \@output,
            [
                "Subtest finished with a new PID ($pid vs $$) while forking support was turned off!",
                'This is almost certainly not what you wanted. Did you fork and forget to exit?',
                "This process did something wrong! at t/Legacy/fork_die.t line $line.",
            ],
            "Got warning and exception, nothing else"
       );
    }

    ok(1, "Pass After!");
};

done_testing;
