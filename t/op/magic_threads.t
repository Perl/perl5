#!./perl

BEGIN {
    $| = 1;
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    skip_all_if_miniperl();
    require Config; import Config;

    $Config{useithreads} && $Config{i_pthread}
        or skip_all("No pthreads or no useithreads");
}

use threads;
use Thread::Semaphore;
use strict;
use POSIX qw(SIGINT sigaction);
use XS::APItest;

watchdog(60);

++$|;

my $got_int = 0;
$SIG{INT} = sub {
  print "# main thread handler\n";
  ++$got_int;
};

# used for synchronization
my $child_ready  = Thread::Semaphore->new(0);
my $parent_ready = Thread::Semaphore->new(0);

# signals across threads, see [perl #81074]
# if the child doesn't set a handler, it's delivered to the parent
{
    note "signals sent to a child that doesn't set a handler are sent to the parent\n";
    my $thread = threads->create(
        sub {
	    $child_ready->up;
	    $parent_ready->down;
	    1; # anything
        });
    $child_ready->down;
    my $sent_error = XS::APItest::pthread_kill($thread->_handle, "INT");
    $parent_ready->up;
    ok(!$sent_error, "send a signal to the child thread")
      or diag "Signal send error: $sent_error";
    $thread->join();
    is($got_int, 1, "signal handled by main thread");
}

# if the child resets its handler, it's delivered to the parent
{
    note "signals sent to a child that resets its handler are sent to the parent\n";
    for my $reset (qw(IGNORE DEFAULT)) {
        $got_int = 0;
        my $thread = threads->create(
            sub {
	        my $got_int;
		$SIG{INT} = sub {
		    print "# child thread handler\n";
		    ++$got_int;
		};
		$SIG{INT} = $reset;
		$child_ready->up;
		$parent_ready->down;
		#sleep 1; # give ourselves a chance to deliver some signals
		ok(!$got_int, "signal not received by child after $reset reset");
	    });
	$child_ready->down;
	my $sent_error = XS::APItest::pthread_kill($thread->_handle, "INT");
	$parent_ready->up;
	$thread->join();
	curr_test(curr_test()+1);
	ok(!$sent_error, "send a signal to the child thread ($reset)")
	  or diag "Signal send error: $sent_error";
	is($got_int, 1, "signal handled by main thread after child reset with $reset");
    }
}

# send to child handler
{
    note "signals sent to a child that sets a handler are sent to the child\n";
    $got_int = 0;
    my $thread = threads->create(
        sub {
	    my $got_int;
	    $SIG{INT} = sub {
	        print "# child thread handler\n";
	        ++$got_int;
	    };
	    $child_ready->up;
	    $parent_ready->down;
	    ok($got_int, "signal received by child");
	});
    $child_ready->down;
    my $sent_error = XS::APItest::pthread_kill($thread->_handle, "INT");
    $parent_ready->up;
    $thread->join();
    curr_test(curr_test()+1);
    ok(!$sent_error, "send a signal to the child thread")
      or diag "Signal send error: $sent_error";
    is(!$got_int, 1, "signal not seen by main thread");
}

$SIG{INT} = "DEFAULT";

# child handler set via sigaction
{
    note "child handler set by sigaction\n";
    # catch any warnings in case we attempt to deliver the signal to
    # the parent which won't be able to find sub "DEFAULT".
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= "@_"; print STDERR @_; };
    my $thread = threads->create(
        sub {
	    my $got_int;
	    my $handler = sub {
		print "# action handler\n";
		++$got_int;
	    };
	    my $sigset = POSIX::SigSet->new(SIGINT);
	    my $handler_action = POSIX::SigAction->new
	      (
	       $handler,
	       $sigset,
	       0
	      );
	    my $default_action = POSIX::SigAction->new
	      (
	       "DEFAULT",
	       $sigset,
	       0
	      );
	    $handler_action->safe(1);
	    sigaction(SIGINT, $handler_action);
	    $child_ready->up();
	    $parent_ready->down();
	    sigaction(SIGINT, $default_action);
	    ok($got_int, "child received signal");
	    is($warn, "", "no warnings raised in child");
	});
    $child_ready->down;
    my $sent_error = XS::APItest::pthread_kill($thread->_handle, "INT");
    $parent_ready->up;
    $thread->join();
    curr_test(curr_test()+2);
    ok(!$sent_error, "send a signal to the child thread")
      or diag "Signal send error: $sent_error";
    is($warn, "", "no warnings raised in parent");
}

# signal arriving at perl's signal handler in a non-perl thread, see
# [perl #120951]
SKIP:
{
    $^O eq 'netbsd'
	and skip "NetBSD 5.1.2 didn't initialize the thread specific storage to NULL", 2;
    local $SIG{INT} = sub {
        print "# main thread handler\n";
	++$got_int;
    };
    $got_int = 0;
    my $handle = XS::APItest::create_dummy_thread()
      or skip("Can't create non-perl thread", 2);
    sleep 1; # wait for child to initialize
    my $sent_error = XS::APItest::pthread_kill($handle, "INT");
    XS::APItest::join_dummy_thread();
    ok(!$sent_error, "sent signal to non-perl thread")
      or diag("signal send error $sent_error");
    ok($got_int, "signal should have been delivered to main thread");
}


# signal arriving at the main thread because a finished child used
# sigaction to set up a handler.
{
    note "child handler set with sigaction, but child finished";
    # catch any warnings in case we attempt to deliver the signal to
    # the parent which won't be able to find sub "DEFAULT".
    my $warn = '';
    local $SIG{INT} = "IGNORE";
    local $SIG{__WARN__} = sub { $warn .= "@_"; print STDERR @_; };
    my $thread = threads->create(
        sub {
	    my $got_int;
	    my $handler = sub {
		print "# action handler\n";
		++$got_int;
	    };
	    my $sigset = POSIX::SigSet->new(SIGINT);
	    my $handler_action = POSIX::SigAction->new
	      (
	       $handler,
	       $sigset,
	       0
	      );
	    $handler_action->safe(1);
	    ok(sigaction(SIGINT, $handler_action), "set signal handler in child")
	      or diag("sigaction: $!");
	    # fall off the end without removing our handler
	});
    $thread->join();
    my $sent_ok = kill "INT", $$;
    my $sigset = POSIX::SigSet->new(SIGINT);
    my $default_action = POSIX::SigAction->new
      (
       "DEFAULT",
       $sigset,
       0
      );
    sigaction(SIGINT, $default_action);
    curr_test(curr_test()+1);
    ok($sent_ok, "send a signal to the main thread");
    is($warn, "", "no warnings raised in parent");
}

done_testing();

