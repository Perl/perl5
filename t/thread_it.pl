#!perl
use strict;
use warnings;

# As perlfunc.pod says:
# Note that the file will not be included twice under the same specified name.
# So ensure that this, textually, is the same name as all the loaded tests use.
# Otherwise if we require 'test.pl' and they require './test.pl', it is loaded
# twice.
require './test.pl';
skip_all_without_config('useithreads');
skip_all_if_miniperl("no dynamic loading on miniperl, no threads");

require threads;

sub thread_it {
    # Generate things like './op/regexp.t', './t/op/regexp.t', ':op:regexp.t'
    my @paths
	= (join ('/', '.', @_), join ('/', '.', 't', @_), join (':', @_));
		 
    for my $file (@paths) {
	if (-r $file) {
	    print "# found tests in $file\n";
	    $::running_as_thread = "running tests in a new thread";
	    do $file or die $@;
	    print "# running tests in a new thread\n";
	    my $curr = threads->create(sub {
		run_tests();
		return defined &curr_test ? curr_test() : ()
	    })->join();
	    curr_test($curr) if defined $curr;
	    exit;
	}
    }
    die "Cannot find " . join (" or ", @paths) . "\n";
}

1;
