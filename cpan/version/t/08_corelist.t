#! /usr/local/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 2;
use_ok("version", 0.9904);

# do strict lax tests in a sub to isolate a package to test importing
SKIP: {
    eval "use Module::CoreList 2.76";
    skip 'No tied hash in Modules::CoreList in Perl', 1
	if $@;

    my $foo = version->parse($Module::CoreList::version{5.008_000}{base});

    is $foo, $Module::CoreList::version{5.008_000}{base},
    	'Correctly handle tied hash';
}
