#!/usr/bin/perl -w
use strict;
use warnings;

use Test::CanFork;

use IO::Pipe;
use Test::Builder;
use Test::More;

subtest 'fork within subtest' => sub {
    my $pipe = IO::Pipe->new;

    my $pid = fork();
    plan skip_all => "Fork not working"
        unless defined $pid;

    if ($pid) {
        $pipe->reader;
        my $child_output = do { local $/ ; <$pipe> };
        waitpid $pid, 0;

        is $?, 0, 'child exit status';
        like $child_output, qr/^[\s#]+Child Done\s*\z/, 'child output';
    }
    else {
        $pipe->writer;

        # Force all T::B output into the pipe, for the parent
        # builder as well as the current subtest builder.
        my $builder = Test::Builder->new;
        $builder->output($pipe);
        $builder->failure_output($pipe);
        $builder->todo_output($pipe);

        diag 'Child Done';
        exit 0;
    }
};

done_testing;
