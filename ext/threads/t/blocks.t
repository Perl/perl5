use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use threads;

BEGIN {
    eval {
        require threads::shared;
        import threads::shared;
    };
    if ($@ || ! $threads::shared::threads_shared) {
        print("1..0 # Skip: threads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..5\n");   ### Number of tests that will be run ###
};

my $TEST = 1;
share($TEST);

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

$SIG{'__WARN__'} = sub { ok(0, "Warning: $_[0]"); };

sub foo { }
sub baz { 42 }

my $bthr;
BEGIN {
    $SIG{'__WARN__'} = sub { ok(0, "BEGIN: $_[0]"); };

    threads->create('foo')->join();
    threads->create(\&foo)->join();
    threads->create(sub {})->join();

    threads->create('foo')->detach();
    threads->create(\&foo)->detach();
    threads->create(sub {})->detach();

    $bthr = threads->create('baz');
}

my $mthr;
MAIN: {
    threads->create('foo')->join();
    threads->create(\&foo)->join();
    threads->create(sub {})->join();

    threads->create('foo')->detach();
    threads->create(\&foo)->detach();
    threads->create(sub {})->detach();

    $mthr = threads->create('baz');
}

ok($mthr, 'Main thread');
ok($bthr, 'BEGIN thread');

ok($mthr->join() == 42, 'Main join');
ok($bthr->join() == 42, 'BEGIN join');

# EOF
