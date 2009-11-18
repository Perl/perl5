#!/usr/bin/perl -w

use strict;
use lib 't/lib';
use MBTest tests => 3;

blib_load('Module::Build');

my $tmp = MBTest->tmpdir;

use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->regen;
$dist->chdir_in;

#########################

# Test MYMETA generation
{
  ok( ! -e "MYMETA.yml", "MYMETA.yml doesn't exist before Build.PL runs" );
  my $output;
  $output = stdout_of sub { $dist->run_build_pl };
  like($output, qr/Creating new 'MYMETA.yml' with configuration results/,
    "Saw MYMETA.yml creation message"
  );
  ok( -e "MYMETA.yml", "MYMETA.yml exists" );
}

#########################

