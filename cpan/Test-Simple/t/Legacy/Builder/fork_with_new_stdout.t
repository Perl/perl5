#!perl -w
use strict;
use warnings;

use Test::CanFork;

use IO::Pipe;
use Test::Builder;

my $b = Test::Builder->new;
$b->reset;
$b->plan('tests' => 2);

my $pipe = IO::Pipe->new;
if (my $pid = fork) {
    $pipe->reader;
    my @output = <$pipe>;
    $b->like($output[0], qr/ok 1/,   "ok 1 from child");
    $b->like($output[1], qr/1\.\.1/, "got 1..1 from child");
    waitpid($pid, 0);
}
else {
    Test::Stream::IOSets->hard_reset;
    Test::Stream->clear;
    $pipe->writer;
    my $pipe_fd = $pipe->fileno;
    close STDOUT;
    open(STDOUT, ">&$pipe_fd");
    my $b = Test::Builder->create(shared_stream => 1);
    $b->reset;
    $b->no_plan;
    $b->ok(1);

    exit 0;
}

=pod
#actual
1..2
ok 1
1..1
ok 1
ok 2
#expected
1..2
ok 1
ok 2
=cut
