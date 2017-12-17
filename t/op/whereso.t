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
    CORE::whereso(3) {
	pass "CORE::whereso without feature flag";
    }
}

use feature 'switch';

foreach(3) {
    CORE::whereso(3) {
	pass "CORE::whereso with feature flag";
    }
}

foreach(3) {
    whereso(3) {
	pass "whereso with feature flag";
    }
}

foreach(0, 1) {
    my $x = "foo";
    is($x, "foo", "whereso lexical scope not started yet");
    whereso(my $x = ($_ && "bar")) {
	is($x, "bar", "whereso lexical scope starts");
    }
    is($x, "foo", "whereso lexical scope ends");
}

foreach(3) {
    whereso($_ == 2) { fail; }
    pass;
}

foreach(3) {
    whereso($_ == 3) { pass; }
    fail;
}

foreach(3) {
    whereso($_ == 2) { fail; }
    whereso($_ == 3) { pass; }
    whereso($_ == 4) { fail; }
    whereso($_ == 3) { fail; }
}

foreach(undef, 3) {
    whereso(undef) { fail; }
    pass;
}

foreach(undef, 1, 3) {
    whereso(0) { fail; }
    pass;
}

foreach(undef, 1, 3) {
    whereso(1) { pass; }
    fail;
}

sub is_list_context { wantarray }
sub is_scalar_context { !wantarray && defined(wantarray) }
sub is_void_context { !defined(wantarray) }
foreach(3) {
    whereso(is_list_context()) { fail; }
    pass;
}
foreach(3) {
    whereso(is_scalar_context()) { pass; }
    fail;
}
foreach(3) {
    whereso(is_void_context()) { fail; }
    pass;
}
foreach(3) {
    whereso(is_list_context) { fail; }
    pass;
}
foreach(3) {
    whereso(is_scalar_context) { pass; }
    fail;
}
foreach(3) {
    whereso(is_void_context) { fail; }
    pass;
}

my $ps = "foo";
foreach(3) {
    whereso($ps) { pass; }
    fail;
}
$ps = "";
foreach(3) {
    whereso($ps) { fail; }
    pass;
}
our $gs = "bar";
foreach(3) {
    whereso($gs) { pass; }
    fail;
}
$gs = "";
foreach(3) {
    whereso($gs) { fail; }
    pass;
}
my @pa = qw(a b c d e);
foreach(3) {
    whereso(@pa) { pass; }
    fail;
}
@pa = ();
foreach(3) {
    whereso(@pa) { fail; }
    pass;
}
our @ga = qw(a b c d e);
foreach(3) {
    whereso(@ga) { pass; }
    fail;
}
@ga = ();
foreach(3) {
    whereso(@ga) { fail; }
    pass;
}
my %ph = qw(a b c d e f g h i j);
foreach(3) {
    whereso(%ph) { pass; }
    fail;
}
%ph = ();
foreach(3) {
    whereso(%ph) { fail; }
    pass;
}
our %gh = qw(a b c d e f g h i j);
foreach(3) {
    whereso(%gh) { pass; }
    fail;
}
%gh = ();
foreach(3) {
    whereso(%gh) { fail; }
    pass;
}

my $one = 1;
foreach(3) {
    whereso($one + 3) { pass; }
    fail;
}
foreach(3) {
    whereso($one - 1) { fail; }
    pass;
}

foreach(3) {
    whereso(()) { fail; }
    pass;
}

foreach my $z (3) {
    whereso(1) { pass; }
    fail;
}

my @a = qw(x y z);
my $act = "";
while(@a) {
    $act .= "[a@{[0+@a]}]";
    whereso(shift(@a) eq "y") {
	$act .= "[b]";
    }
    $act .= "[c]";
}
is $act, "[a3][c][a2][b][a1][c]";

$act = "";
{
    $act .= "[a]";
    whereso(0) { $act .= "[b]"; }
    $act .= "[c]";
    whereso(1) { $act .= "[d]"; }
    $act .= "[e]";
    whereso(1) { $act .= "[f]"; }
}
is $act, "[a][c][d]";

1;
