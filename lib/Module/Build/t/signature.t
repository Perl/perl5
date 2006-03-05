#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest;

if ( $ENV{TEST_SIGNATURE} ) {
  if ( have_module( 'Module::Signature' ) ) {
    plan tests => 7;
  } else {
    plan skip_all => '$ENV{TEST_SIGNATURE} is set, but Module::Signature not found';
  }
} else {
  plan skip_all => '$ENV{TEST_SIGNATURE} is not set';
}

#########################

use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );

use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->change_file( 'Build.PL', <<"---" );
use Module::Build;

my \$build = new Module::Build(
  module_name => @{[$dist->name]},
  license     => 'perl',
  sign        => 1,
);
\$build->create_build_script;
---
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";

#########################

use Module::Build;

my $mb = Module::Build->new_from_context;


{
  eval {$mb->dispatch('distdir')};
  is $@, '';
  chdir( $mb->dist_dir ) or die "Can't chdir to '@{[$mb->dist_dir]}': $!";
  ok -e 'SIGNATURE';
  
  # Make sure the signature actually verifies
  ok Module::Signature::verify() == Module::Signature::SIGNATURE_OK();
  chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";
}

{
  # Fake out Module::Signature and Module::Build - the first one to
  # run should be distmeta.
  my @run_order;
  {
    local $^W; # Skip 'redefined' warnings
    local *Module::Signature::sign              = sub { push @run_order, 'sign' };
    local *Module::Build::Base::ACTION_distmeta = sub { push @run_order, 'distmeta' };
    eval { $mb->dispatch('distdir') };
  }
  is $@, '';
  is $run_order[0], 'distmeta';
  is $run_order[1], 'sign';
}

eval { $mb->dispatch('realclean') };
is $@, '';


# cleanup
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;

use File::Path;
rmtree( $tmp );
