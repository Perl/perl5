use Test::Stream::ForceExit;
use strict;
use warnings;

use Test::CanFork;

use Test::Stream qw/enable_fork/;
use Test::More;
use Test::Stream::ForceExit;

my ($read, $write);
pipe($read, $write) || die "Failed to create a pipe.";

my $pid = fork();
unless ($pid) {
    die "Failed to fork" unless defined $pid;
    close($read);
    $SIG{__WARN__} = sub { print $write @_ };

    {
        my $force_exit = Test::Stream::ForceExit->new;
        note "In Child";
    }

    print $write "Did not exit!";

    ok(0, "Failed to exit");
    exit 0;
}

close($write);
waitpid($pid, 0);
my $error = $?;
ok($error, "Got an error");
my $msg = join("", <$read>);
is($msg, <<EOT, "Got warning");
Something prevented child process $pid from exiting when it should have, Forcing exit now!
EOT

close($read);
pipe($read, $write) || die "Failed to create a pipe.";

$pid = fork();
unless ($pid) {
    die "Failed to fork" unless defined $pid;
    close($read);
    $SIG{__WARN__} = sub { print $write @_ };

    {
        my $force_exit = Test::Stream::ForceExit->new;
        note "In Child $$";
        $force_exit->done(1);
    }

    print $write "Did not exit!\n";

    exit 0;
}

close($write);
waitpid($pid, 0);
$error = $?;
ok(!$error, "no error");
$msg = join("", <$read>);
is($msg, <<EOT, "Did not exit early");
Did not exit!
EOT

done_testing;
