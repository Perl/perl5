# test if our own version numbers meet expectations

use strict;
eval 'use warnings';

my @m;
if ($ENV{PERL_CORE}){
  @m = ("CPAN", map { "CPAN::$_" } qw(Debug FirstTime Nox Tarzip Version));
} else {
  opendir DH, "lib/CPAN" or die;
  @m = ("CPAN", map { "CPAN::$_" } grep { s/\.pm$// } readdir DH);
}

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
