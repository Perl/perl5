use strict;
use warnings;
use Test2::IPC;
BEGIN { require "t/tools.pl" };
use Test2::API qw/context test2_stack/;
use Test2::Util qw/CAN_FORK/;

BEGIN {
    skip_all "System cannot fork" unless CAN_FORK;
}

plan(3);

pipe(my ($read, $write));

test2_stack()->top;
my $hub = test2_stack()->new_hub();

my $pid = fork();
die "Failed to fork" unless defined $pid;

if ($pid) {
    close($read);
    test2_stack()->pop($hub);
    $hub = undef;
    print $write "Go\n";
    close($write);
    waitpid($pid, 0);
    my $err = $? >> 8;
    is($err, 255, "Exit code was not masked");
    ok($err != 100, "Did not hit the safety exit");
}
else {
    close($write);
    my $ignore = <$read>;
    close($read);
    close(STDERR);
    close(STDOUT);
    open(STDERR, '>', my $x);
    my $ctx = context(hub => $hub, level => -1);
    my $clone = $ctx->snapshot;
    $ctx->release;
    $clone->ok(0, "Should not see this");
    print STDERR "\n\nSomething went wrong!!!!\n\n";
    exit 100; # Safety exit
};


# The rest of this is to make sure nothing that happens when reading the event
# messes with $?.

pipe($read, $write);

$pid = fork;
die "Failed to fork" unless defined $pid;

unless($pid) {
    my $ignore = <$read>;
    ok(1, "Test in forked process");
}

print $write "Go\n";
