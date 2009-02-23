#!/usr/bin/perl

# this is just a first crack and it uses File::Fu because I'm lazy.

=head1 using

This installs from a fresh Module::Build to your inc/inc_Module-Build
directory.  Use it from within your dist:

  perl /path/to/Module-Build/scripts/bundle.pl

You still need to manually add the following to your Build.PL

  use lib 'inc';
  use latest 'Module::Build';

You also need to regen your manifest.

  perl Build.PL
  ./Build distmeta; >MANIFEST; ./Build manifest; svn diff MANIFEST

=cut

use warnings;
use strict;

use File::Fu;
use File::Copy ();

my $inc_dir = shift(@ARGV);
$inc_dir = File::Fu->dir($inc_dir || 'inc/inc_Module-Build');
$inc_dir->create unless($inc_dir->e);
$inc_dir = $inc_dir->absolutely;


my $mb_dir = File::Fu->program_dir->dirname;

$mb_dir->chdir_for(sub {
  my $temp = File::Fu->temp_dir('mb_bundle');
  local @INC = @INC;
  unshift(@INC, 'lib', 'inc');
  require Module::Build;
  my $builder = Module::Build->new_from_context;
  $builder->dispatch(install =>
    install_base => $temp,
    install_path => {lib => $inc_dir},
  );
});

my $latest = $mb_dir/'inc'+'latest.pm';
File::Copy::copy($latest, 'inc');

# vim:ts=2:sw=2:et:sta
