# test if our own version numbers meet expectations

BEGIN {
  if (! eval { require warnings; 1 }) {
    printf "1..1\nok 1 # warnings not available: skipping %s\n", __FILE__;
    exit;
  }
}

use strict;
use warnings;
my @m = qw(CPAN CPAN::Admin CPAN::FirstTime CPAN::Nox CPAN::Version);

use Test::More;
plan(tests => scalar @m);

for my $m (@m) {
  local $^W = 0;
  eval "require $m";
  ok($m->VERSION >= 1.76, sprintf "%20s: %s", $m, $m->VERSION);
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 2
# End:
