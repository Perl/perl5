#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;
no warnings 'experimental::smartmatch';

plan tests => 42;

foreach(3) {
    CORE::when(3) {
	pass "CORE::when without feature flag";
    }
}

use feature 'switch';

foreach(3) {
    CORE::when(3) {
	pass "CORE::when with feature flag";
    }
}

foreach(3) {
    when(3) {
	pass "when with feature flag";
    }
}

foreach(0, 1) {
    my $x = "foo";
    is($x, "foo", "when lexical scope not started yet");
    when(my $x = ($_ && "bar")) {
	is($x, "bar", "when lexical scope starts");
    }
    is($x, "foo", "when lexical scope ends");
}

foreach(3) {
    when($_ == 2) { fail; }
    pass;
}

foreach(3) {
    when($_ == 3) { pass; }
    fail;
}

foreach(3) {
    when($_ == 2) { fail; }
    when($_ == 3) { pass; }
    when($_ == 4) { fail; }
    when($_ == 3) { fail; }
}

foreach(undef, 3) {
    when(undef) { fail; }
    pass;
}

foreach(undef, 1, 3) {
    when(0) { fail; }
    pass;
}

foreach(undef, 1, 3) {
    when(1) { pass; }
    fail;
}

sub is_list_context { wantarray }
sub is_scalar_context { !wantarray && defined(wantarray) }
sub is_void_context { !defined(wantarray) }
foreach(3) {
    when(is_list_context()) { fail; }
    pass;
}
foreach(3) {
    when(is_scalar_context()) { pass; }
    fail;
}
foreach(3) {
    when(is_void_context()) { fail; }
    pass;
}
foreach(3) {
    when(is_list_context) { fail; }
    pass;
}
foreach(3) {
    when(is_scalar_context) { pass; }
    fail;
}
foreach(3) {
    when(is_void_context) { fail; }
    pass;
}

my $ps = "foo";
foreach(3) {
    when($ps) { pass; }
    fail;
}
$ps = "";
foreach(3) {
    when($ps) { fail; }
    pass;
}
our $gs = "bar";
foreach(3) {
    when($gs) { pass; }
    fail;
}
$gs = "";
foreach(3) {
    when($gs) { fail; }
    pass;
}
my @pa = qw(a b c d e);
foreach(3) {
    when(@pa) { pass; }
    fail;
}
@pa = ();
foreach(3) {
    when(@pa) { fail; }
    pass;
}
our @ga = qw(a b c d e);
foreach(3) {
    when(@ga) { pass; }
    fail;
}
@ga = ();
foreach(3) {
    when(@ga) { fail; }
    pass;
}
my %ph = qw(a b c d e f g h i j);
foreach(3) {
    when(%ph) { pass; }
    fail;
}
%ph = ();
foreach(3) {
    when(%ph) { fail; }
    pass;
}
our %gh = qw(a b c d e f g h i j);
foreach(3) {
    when(%gh) { pass; }
    fail;
}
%gh = ();
foreach(3) {
    when(%gh) { fail; }
    pass;
}

my $one = 1;
foreach(3) {
    when($one + 3) { pass; }
    fail;
}
foreach(3) {
    when($one - 1) { fail; }
    pass;
}

foreach(3) {
    when(()) { fail; }
    pass;
}

foreach my $z (3) {
    when(1) { pass; }
    fail;
}

my @a = qw(x y z);
my $act = "";
while(@a) {
    $act .= "[a@{[0+@a]}]";
    when(shift(@a) eq "y") {
	$act .= "[b]";
    }
    $act .= "[c]";
}
is $act, "[a3][c][a2][b][a1][c]";

$act = "";
{
    $act .= "[a]";
    when(0) { $act .= "[b]"; }
    $act .= "[c]";
    when(1) { $act .= "[d]"; }
    $act .= "[e]";
    when(1) { $act .= "[f]"; }
}
is $act, "[a][c][d]";

1;
