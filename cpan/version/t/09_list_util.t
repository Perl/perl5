# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test::More tests => 3;
use_ok("version", 0.9905);

# do strict lax tests in a sub to isolate a package to test importing
SKIP: {
    eval "use List::Util qw(reduce);";
    skip 'No reduce() in List::Util', 2
	if $@;

    # use again to get the import()
    use List::Util qw(reduce);
    {
	my $fail = 0;
	my $ret = reduce {
	    version->parse($a);
	    $fail++ unless defined $a;
	    1
	} "0.039", "0.035";
	is $fail, 0, 'reduce() with parse';
    }

    {
	my $fail = 0;
	my $ret = reduce {
	    version->qv($a);
	    $fail++ unless defined $a;
	    1
	} "0.039", "0.035";
	is $fail, 0, 'reduce() with qv';
    }
}
