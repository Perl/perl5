# test if our own version numbers meet expectations

my [at]m = qw(CPAN CPAN::FirstTime CPAN::Nox);

use Test::More;
plan(tests => scalar [at]m);

for my $m (@m) {
  eval "require $m";
  ok($m->VERSION >= 1.76, sprintf "%20s: %s", $m, $m->VERSION);
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
