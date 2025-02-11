#!./perl
use v5.36;

# This test checks for RT #123878/GH #14527, keeping the die handler still
# disabled into goto'd function. And the other documented
# exceptions to enable dying from a die handler.

print "1..6\n";

eval {
    sub f1 { die "ok 1\n" }
    $SIG{__DIE__} = \&f1;
    die;
};
print $@;

eval {
    sub loopexit { for (0..2) { next if $_ } }
    $SIG{__DIE__} = \&loopexit;
    die "ok 2\n";
};
print $@;

eval {
    sub foo1 { die "ok 3\n" }
    sub bar1 { foo1() }
    $SIG{__DIE__} = \&bar1;
    die;
};
print $@;

# GH #14527
eval {
    sub foo2 { die "ok 4\n" }
    sub bar2 { goto &foo2 }
    $SIG{__DIE__} = \&bar2;
    die;
};
print $@;
# Deep recursion on subroutine "main::foo2" at t/op/die_goto.t line 35.
# Segmentation fault (core dumped)

# GH #22987 (die)
eval {
    sub foo3 { die "ok 5\n" }
    sub bar3 { { local $SIG{__DIE__}; } goto &foo3 }
    $SIG{__DIE__} = \&bar3;
    die;
};
print $@;
# Deep recursion on subroutine "main::foo3" at t/op/die_goto.t line 46.
# Segmentation fault (core dumped)

# GH #22984
eval {
    my $called = 0;
    sub hybrid {
        $called++;
        die "$called\n";
    }
    $SIG{__DIE__} = \&hybrid;
    hybrid;
};
print $@ eq "2\n" ? "ok 6\n" : "not ok 6\n" . "\$\@ = $@" =~ s/^/# /mgr;
