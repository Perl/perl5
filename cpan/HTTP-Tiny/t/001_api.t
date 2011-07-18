#!perl

use strict;
use warnings;

use Test::More tests => 2;
use HTTP::Tiny;

my @accessors = qw(agent default_headers max_redirect max_size proxy timeout);
my @methods   = qw(new get request mirror);

my %api;
@api{@accessors} = (1) x @accessors;
@api{@methods} = (1) x @accessors;

can_ok('HTTP::Tiny', @methods, @accessors);

my @extra =
  grep {! $api{$_} }
  grep { $_ !~ /\A_/ }
  grep {; no strict 'refs'; *{"HTTP::Tiny::$_"}{CODE} }
  sort keys %HTTP::Tiny::;

ok( ! scalar @extra, "No unexpected subroutines defined" )
  or diag "Found: @extra";

