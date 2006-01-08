# test if our own version numbers meet expectations

use strict;
eval 'use warnings';
my @m = qw(CPAN CPAN::FirstTime CPAN::Nox CPAN::Version);
push @m, 'CPAN::Admin' unless $ENV{PERL_CORE};

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
