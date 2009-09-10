#! perl -w

use File::Spec;
my $perl;
BEGIN {
  $perl = File::Spec->rel2abs($^X);
}

use strict;
use Test::More;
BEGIN { 
  if ($^O eq 'VMS') {
    # So we can get the return value of system()
    require vmsish;
    import vmsish;
  }
}

plan tests => 4;

require_ok "ExtUtils::CBuilder";

my $b = eval { ExtUtils::CBuilder->new(quiet => 1) };
ok( $b, "got CBuilder object" ) or diag $@;

# test missing compiler
$b->{config}{cc} = 'djaadjfkadjkfajdf';
$b->{config}{ld} = 'djaadjfkadjkfajdf';
is( $b->have_compiler, 0, "have_compiler: fake missing cc" );

# test found compiler
$b->{have_compiler} = undef;
$b->{config}{cc} = "$perl -e1 --";
$b->{config}{ld} = "$perl -e1 --";
is( $b->have_compiler, 1, "have_compiler: fake present cc" );


