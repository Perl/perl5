#!./perl -w
# This test checks for RT #123878/GH #14527, keeping the die handler still
# disabled into goto'd function. And the other documented
# exceptions to enable dying from a die handler.

print "1..4\n";

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

eval {
  sub foo2 { die "ok 4\n" }
  sub bar2 { goto &foo2 }
  $SIG{__DIE__} = \&bar2;
  die;
};
print $@;

# Deep recursion on subroutine "main::foo2" at t/op/die_goto.t line 32.
# Segmentation fault (core dumped)
