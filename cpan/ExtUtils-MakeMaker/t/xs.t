#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib/';
}
chdir 't';

use strict;

use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::XS;
use Test::More
    have_compiler()
    ? (tests => 5)
    : (skip_all => "ExtUtils::CBuilder not installed or couldn't find a compiler");
use File::Spec;

my $Is_VMS = $^O eq 'VMS';
my $perl = which_perl();

chdir 't';

perl_lib;

$| = 1;

ok( setup_xs(), 'setup' );
END {
    chdir File::Spec->updir or die;
    teardown_xs(), 'teardown' or die;
}

ok( chdir('XS-Test'), "chdir'd to XS-Test" ) ||
  diag("chdir failed: $!");

my @mpl_out = run(qq{$perl Makefile.PL});
SKIP: {
  unless (cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' )) {
    diag(@mpl_out);
    skip 'perl Makefile.PL failed', 2;
  }

  # now simulate what Module::Install does, and edit $(PERL) to add flags
  open my $fh, '<', 'Makefile';
  my $mtext = join '', <$fh>;
  close $fh;
  $mtext =~ s/^(\s*PERL\s*=.*)$/$1 -Mstrict/m;
  open $fh, '>', 'Makefile';
  print $fh $mtext;
  close $fh;

  my $make = make_run();
  my $make_out = run("$make");
  unless (is( $?, 0, '  make exited normally' )) {
      diag $make_out;
      skip 'Make failed - skipping test', 1;
  }

  my $test_out = run("$make test");
  is( $?, 0,                                 '  make test exited normally' ) ||
      diag $test_out;
}
