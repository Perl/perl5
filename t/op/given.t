#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;
no warnings 'experimental::smartmatch';

plan tests => 39;

CORE::given(3) {
    pass "CORE::given without feature flag";
}

use feature 'switch';

CORE::given(3) {
    pass "CORE::given with feature flag";
}

given(3) {
    pass "given with feature flag";
}

{
    my $x = "foo";
    is($x, "foo", "given lexical scope not started yet");
    given(my $x = "bar") {
	is($x, "bar", "given lexical scope starts");
    }
    is($x, "foo", "given lexical scope ends");
}

sub topic_is ($@) { is $_, shift, @_ }
{
    local $_ = "foo";
    is $_, "foo", "given dynamic scope not started yet";
    topic_is "foo", "given dynamic scope not started yet";
    given("bar") {
	is $_, "bar", "given dynamic scope starts";
	topic_is "bar", "given dynamic scope starts";
    }
    is $_, "foo", "given dynamic scope ends";
    topic_is "foo", "given dynamic scope ends";
}

given(undef) {
    is $_, undef, "folded undef topic value";
    is \$_, \undef, "folded undef topic identity";
}
given(1 < 3) {
    is $_, !!1, "folded true topic value";
    is \$_, \!!1, "folded true topic identity";
}
given(1 > 3) {
    is $_, !!0, "folded false topic value";
    is \$_, \!!0, "folded false topic identity";
}
my $one = 1;
given($one && undef) {
    is $_, undef, "computed undef topic value";
    is \$_, \undef, "computed undef topic identity";
}
given($one < 3) {
    is $_, !!1, "computed true topic value";
    is \$_, \!!1, "computed true topic identity";
}
given($one > 3) {
    is $_, !!0, "computed false topic value";
    is \$_, \!!0, "computed false topic identity";
}

sub which_context {
    return wantarray ? "list" : defined(wantarray) ? "scalar" : "void";
}
given(which_context) {
    is $_, "scalar", "topic sub called without parens";
}
given(which_context()) {
    is $_, "scalar", "topic sub called with parens";
}

my $ps = "foo";
given($ps) {
    is $_, "foo", "padsv topic value";
    is \$_, \$ps, "padsv topic identity";
}
our $gs = "bar";
given($gs) {
    is $_, "bar", "gvsv topic value";
    is \$_, \$gs, "gvsv topic identity";
}
my @pa = qw(a b c d e);
given(@pa) {
    is $_, 5, "padav topic";
}
our @ga = qw(x y z);
given(@ga) {
    is $_, 3, "gvav topic";
}
my %ph = qw(a b c d e f g h i j);
given(%ph) {
    is $_, 5, "padhv topic";
}
our %gh = qw(u v w x y z);
given(%gh) {
    is $_, 3, "gvhv topic";
}

given($one + 3) {
    is $_, 4, "general computed topic";
}

is join(",", 111, 222,
    do {
	no warnings "void";
	given($one, 22, $one, 33) {
	    is $_, 33, "list topic";
	    (1111, 2222);
	}
    },
    333, 444,
), "111,222,1111,2222,333,444", "stack discipline";

given(()) {
    is $_, undef, "stub topic value";
    is \$_, \undef, "stub topic identity";
}

1;
