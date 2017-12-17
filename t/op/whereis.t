#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
use strict;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

plan tests => 19;

foreach(3) {
    CORE::whereis(qr/\A3\z/) {
	pass "CORE::whereis without feature flag";
    }
}

use feature 'switch';

foreach(3) {
    CORE::whereis(qr/\A3\z/) {
	pass "CORE::whereis with feature flag";
    }
}

foreach(3) {
    whereis(qr/\A3\z/) {
	pass "whereis with feature flag";
    }
}

package MatchAbc { use overload "~~" => sub { $_[1] eq "abc" }, fallback => 1; }
my $matchabc = bless({}, "MatchAbc");
my $regexpabc = qr/\Aabc\z/;

foreach("abc") {
    my $x = "foo";
    is($x, "foo", "whereis lexical scope not started yet");
    whereis(my $x = $matchabc) {
	is($x, $matchabc, "whereis lexical scope starts");
    }
    is($x, "foo", "whereis lexical scope ends");
}

foreach my $matcher (undef, 0, 1, [], {}, sub { 1 }) {
    my $res = eval {
	my $r;
	foreach("abc") {
	    whereis($matcher) {
		$r = 1;
	    }
	    $r = 0;
	}
	$r;
    };
    like $@, qr/\ACannot smart match without a matcher object /;
}

foreach my $matcher ($matchabc, $regexpabc) {
    foreach my $matchee (qw(abc xyz)) {
	my $res = eval {
	    my $r;
	    foreach($matchee) {
		whereis($matcher) {
		    $r = 1;
		}
		$r = 0;
	    }
	    $r;
	};
	is $@, "";
	is !!$res, $matchee eq "abc";
    }
}

1;
