#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest;
use File::Spec;
use Config;

# Don't let our own verbosity/test_file get mixed up with our subprocess's
my @makefile_keys = qw(TEST_VERBOSE HARNESS_VERBOSE TEST_FILES MAKEFLAGS);
local  @ENV{@makefile_keys};
delete @ENV{@makefile_keys};

my @makefile_types = qw(small passthrough traditional);
my $tests_per_type = 10;
if ( $Config{make} && find_in_path($Config{make}) ) {
    plan tests => 30 + @makefile_types*$tests_per_type;
} else {
    plan skip_all => "Don't know how to invoke 'make'";
}
ok(1);  # Loaded


#########################

use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );

use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";


#########################

use Module::Build;
use Module::Build::Compat;

use Carp;  $SIG{__WARN__} = \&Carp::cluck;

my @make = $Config{make} eq 'nmake' ? ('nmake', '-nologo') : ($Config{make});

#########################


my $mb = Module::Build->new_from_context;
ok $mb;

foreach my $type (@makefile_types) {
  Module::Build::Compat->create_makefile_pl($type, $mb);
  test_makefile_creation($mb);
  
  ok $mb->do_system(@make);
  
  # Can't let 'test' STDOUT go to our STDOUT, or it'll confuse Test::Harness.
  my $success;
  my $output = stdout_of( sub {
			    $success = $mb->do_system(@make, 'test');
			  } );
  ok $success;
  like uc $output, qr{DONE\.|SUCCESS};
  
  ok $mb->do_system(@make, 'realclean');
  
  # Try again with some Makefile.PL arguments
  test_makefile_creation($mb, [], 'INSTALLDIRS=vendor', 1);
  
  1 while unlink 'Makefile.PL';
  ok ! -e 'Makefile.PL';
}

{
  # Make sure fake_makefile() can run without 'build_class', as it may be
  # in older-generated Makefile.PLs
  my $warning = '';
  local $SIG{__WARN__} = sub { $warning = shift; };
  my $maketext = eval { Module::Build::Compat->fake_makefile(makefile => 'Makefile') };
  is $@, '';
  like $maketext, qr/^realclean/m;
  like $warning, qr/build_class/;
}

{
  # Make sure custom builder subclass is used in the created
  # Makefile.PL - make sure it fails in the right way here.
  local @Foo::Builder::ISA = qw(Module::Build);
  my $foo_builder = Foo::Builder->new_from_context;
  foreach my $style ('passthrough', 'small') {
    Module::Build::Compat->create_makefile_pl($style, $foo_builder);
    ok -e 'Makefile.PL';
    
    # Should fail with "can't find Foo/Builder.pm"
    my $warning = stderr_of
      (sub {
	 my $result = $mb->run_perl_script('Makefile.PL');
	 ok ! $result;
       });
    like $warning, qr{Foo/Builder.pm};
  }
  
  # Now make sure it can actually work.
  my $bar_builder = Module::Build->subclass( class => 'Bar::Builder' )->new_from_context;
  foreach my $style ('passthrough', 'small') {
    Module::Build::Compat->create_makefile_pl($style, $bar_builder);
    ok -e 'Makefile.PL';
    ok $mb->run_perl_script('Makefile.PL');
  }
}

{
  # Make sure various Makefile.PL arguments are supported
  Module::Build::Compat->create_makefile_pl('passthrough', $mb);

  my $libdir = File::Spec->catdir( $cwd, 't', 'libdir' );
  my $result = $mb->run_perl_script('Makefile.PL', [],
				     [
				      "LIB=$libdir",
				      'TEST_VERBOSE=1',
				      'INSTALLDIRS=perl',
				      'POLLUTE=1',
				     ]
				   );
  ok $result;
  ok -e 'Build.PL';

  my $new_build = Module::Build->resume();
  is $new_build->installdirs, 'core';
  is $new_build->verbose, 1;
  is $new_build->install_destination('lib'), $libdir;
  is $new_build->extra_compiler_flags->[0], '-DPERL_POLLUTE';

  # Make sure those switches actually had an effect
  my ($ran_ok, $output);
  $output = stdout_of( sub { $ran_ok = $new_build->do_system(@make, 'test') } );
  ok $ran_ok;
  $output =~ s/^/# /gm;  # Don't confuse our own test output
  like $output, qr/(?:# ok \d+\s+)+/, 'Should be verbose';

  # Make sure various Makefile arguments are supported
  $output = stdout_of( sub { $ran_ok = $mb->do_system(@make, 'test', 'TEST_VERBOSE=0') } );
  ok $ran_ok;
  $output =~ s/^/# /gm;  # Don't confuse our own test output
  like $output, qr/(?:# .+basic\.+ok\s+(?:[\d.]+\s*m?s\s*)?)# All tests/,
      'Should be non-verbose';

  $mb->delete_filetree($libdir);
  ok ! -e $libdir, "Sample installation directory should be cleaned up";

  $mb->do_system(@make, 'realclean');
  ok ! -e 'Makefile', "Makefile shouldn't exist";

  1 while unlink 'Makefile.PL';
  ok ! -e 'Makefile.PL';
}

{ # Make sure tilde-expansion works

  # C<glob> on MSWin32 uses $ENV{HOME} if defined to do tilde-expansion
  local $ENV{HOME} = 'C:/' if $^O =~ /MSWin/ && !exists( $ENV{HOME} );

  Module::Build::Compat->create_makefile_pl('passthrough', $mb);

  $mb->run_perl_script('Makefile.PL', [], ['INSTALL_BASE=~/foo']);
  my $b2 = Module::Build->current;
  ok $b2->install_base;
  unlike $b2->install_base, qr/^~/, "Tildes should be expanded";
  
  $mb->do_system(@make, 'realclean');
  1 while unlink 'Makefile.PL';
}
#########################################################

sub test_makefile_creation {
  my ($build, $preargs, $postargs, $cleanup) = @_;
  
  my $result = $build->run_perl_script('Makefile.PL', $preargs, $postargs);
  ok $result;
  ok -e 'Makefile', "Makefile should exist";
  
  if ($cleanup) {
    $build->do_system(@make, 'realclean');
    ok ! -e 'Makefile', "Makefile shouldn't exist";
  }
}


# cleanup
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;

use File::Path;
rmtree( $tmp );
