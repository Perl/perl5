package B::Deparse;
use strict;
use B qw(peekop class main_root);

my $debug;

sub compile {
    my $opt = shift;
    if ($opt eq "-d") {
	$debug = 1;
    }
    return sub { print deparse(main_root), "\n" }
}

sub ppname {
    my $op = shift;
    my $ppname = $op->ppaddr;
    warn sprintf("ppname %s\n", peekop($op)) if $debug;
    no strict "refs";
    return defined(&$ppname) ? &$ppname($op) : 0;
}

sub deparse {
    my $op = shift;
    my $expr;
    warn sprintf("deparse %s\n", peekop($op)) if $debug;
    while (ref($expr = ppname($op))) {
	$op = $expr;
	warn sprintf("Redirecting to %s\n", peekop($op)) if $debug;
    }
    return $expr;
}

sub pp_leave {
    my $op = shift;
    my ($child, $expr);
    for ($child = $op->first; !$expr; $child = $child->sibling) {
	$expr = ppname($child);
    }
    return $expr;
}

sub SWAP_CHILDREN () { 1 }

sub binop {
    my ($op, $opname, $flags) = @_;
    my $left = $op->first;
    my $right = $op->last;
    if ($flags & SWAP_CHILDREN) {
	($left, $right) = ($right, $left);
    }
    warn sprintf("binop deparsing first %s\n", peekop($op->first)) if $debug;
    $left = deparse($left);
    warn sprintf("binop deparsing last %s\n", peekop($op->last)) if $debug;
    $right = deparse($right);
    return "($left $opname $right)";
}

sub pp_add { binop($_[0], "+") }
sub pp_multiply { binop($_[0], "*") }
sub pp_subtract { binop($_[0], "-") }
sub pp_divide { binop($_[0], "/") }
sub pp_modulo { binop($_[0], "%") }
sub pp_eq { binop($_[0], "==") }
sub pp_ne { binop($_[0], "!=") }
sub pp_lt { binop($_[0], "<") }
sub pp_gt { binop($_[0], ">") }
sub pp_ge { binop($_[0], ">=") }

sub pp_sassign { binop($_[0], "=", SWAP_CHILDREN) }

sub pp_null {
    my $op = shift;
    warn sprintf("Skipping null op %s\n", peekop($op)) if $debug;
    return $op->first;
}

sub pp_const {
    my $op = shift;
    my $sv = $op->sv;
    if (class($sv) eq "IV") {
	return $sv->IV;
    } elsif (class($sv) eq "NV") {
	return $sv->NV;
    } else {
	return $sv->PV;
    }
}

sub pp_gvsv {
    my $op = shift;
    my $gv = $op->gv;
    my $stash = $gv->STASH->NAME;
    if ($stash eq "main") {
	$stash = "";
    } else {
	$stash = $stash . "::";
    }
    return sprintf('$%s%s', $stash, $gv->NAME);
}

1;
