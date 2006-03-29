#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest tests => 43;

use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );


use Module::Build;
use Module::Build::ConfigData;
my $has_YAML = Module::Build::ConfigData->feature('YAML_support');


use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->change_file( 'Build.PL', <<"---" );

my \$builder = Module::Build->new(
    module_name   => '@{[$dist->name]}',
    dist_version  => '3.14159265',
    dist_author   => [ 'Simple Simon <ss\@somewhere.priv>' ],
    dist_abstract => 'Something interesting',
    license       => 'perl',
);

\$builder->create_build_script();
---
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";

use Module::Build;
my $mb = Module::Build->new_from_context;

##################################################
#
# Test for valid META.yml

SKIP: {
  skip( 'YAML_support feature is not enabled', 8 ) unless $has_YAML;

  require YAML;
  require YAML::Node;
  my $node = YAML::Node->new({});
  $node = $mb->prepare_metadata( $node );

  # exists() doesn't seem to work here
  ok defined( $node->{name} ),     "'name' field present in META.yml";
  ok defined( $node->{version} ),  "'version' field present in META.yml";
  ok defined( $node->{abstract} ), "'abstract' field present in META.yml";
  ok defined( $node->{author} ),   "'author' field present in META.yml";
  ok defined( $node->{license} ),  "'license' field present in META.yml";
  ok defined( $node->{generated_by} ),
      "'generated_by' field present in META.yml";
  ok defined( $node->{'meta-spec'}{version} ),
      "'meta-spec' -> 'version' field present in META.yml";
  ok defined( $node->{'meta-spec'}{url} ),
      "'meta-spec' -> 'url' field present in META.yml";

  # TODO : find a way to test for failure when above fields are not present
}

$dist->clean;


##################################################
#
# Tests to ensure that the correct packages and versions are
# recorded for the 'provides' field of META.yml

my $provides; # Used a bunch of times below

sub new_build { return Module::Build->new_from_context( quiet => 1, @_ ) }

############################## Single Module

# File with corresponding package (w/ or w/o version)
# Simple.pm => Simple v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => {file => 'lib/Simple.pm',
			version => '1.23'}});

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => {file => 'lib/Simple.pm'}});

# File with no corresponding package (w/ or w/o version)
# Simple.pm => Foo::Bar v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo::Bar;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Foo::Bar' => { file => 'lib/Simple.pm',
			   version => '1.23' }});

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo::Bar;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Foo::Bar' => { file => 'lib/Simple.pm'}});


# Single file with multiple differing packages (w/ or w/o version)
# Simple.pm => Simple
# Simple.pm => Foo::Bar

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
package Foo::Bar;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple'   => { file => 'lib/Simple.pm',
			   version => '1.23' },
	   'Foo::Bar' => { file => 'lib/Simple.pm',
			   version => '1.23' }});


# Single file with multiple differing packages, no corresponding package
# Simple.pm => Foo
# Simple.pm => Foo::Bar

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
$VERSION = '1.23';
package Foo::Bar;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Foo'      => { file => 'lib/Simple.pm',
			   version => '1.23' },
	   'Foo::Bar' => { file => 'lib/Simple.pm',
			   version => '1.23' }});


# Single file with same package appearing multiple times, no version
#   only record a single instance
# Simple.pm => Simple
# Simple.pm => Simple

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
package Simple;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm' }});


# Single file with same package appearing multiple times, single
# version 1st package:
# Simple.pm => Simple v1.23
# Simple.pm => Simple

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
package Simple;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});


# Single file with same package appearing multiple times, single
# version 2nd package
# Simple.pm => Simple
# Simple.pm => Simple v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
package Simple;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});


# Single file with same package appearing multiple times, conflicting versions
# Simple.pm => Simple v1.23
# Simple.pm => Simple v2.34

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
package Simple;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
my $err = '';
$err = stderr_of( sub { $mb = new_build() } );
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }}); # XXX should be 2.34?
like( $err, qr/already declared/, '  with conflicting versions reported' );


# (Same as above three cases except with no corresponding package)
# Simple.pm => Foo v1.23
# Simple.pm => Foo v2.34

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
$VERSION = '1.23';
package Foo;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
$err = stderr_of( sub { $mb = new_build() } );
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Foo' => { file => 'lib/Simple.pm',
		      version => '1.23' }}); # XXX should be 2.34?
like( $err, qr/already declared/, '  with conflicting versions reported' );



############################## Multiple Modules

# Multiple files with same package, no version
# Simple.pm  => Simple
# Simple2.pm => Simple

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm' }});
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, single version in corresponding package
# Simple.pm  => Simple v1.23
# Simple2.pm => Simple

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package,
#   single version in non-corresponding package
# Simple.pm  => Simple
# Simple2.pm => Simple v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple2.pm',
			 version => '1.23' }});
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, conflicting versions
# Simple.pm  => Simple v1.23
# Simple2.pm => Simple v2.34

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
$mb = new_build();
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});
like( $err, qr/Found conflicting versions for package/,
      '  with conflicting versions reported' );
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, multiple agreeing versions
# Simple.pm  => Simple v1.23
# Simple2.pm => Simple v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});
$dist->remove_file( 'lib/Simple2.pm' );


############################################################
#
# (Same as above five cases except with non-corresponding package)
#

# Multiple files with same package, no version
# Simple.pm  => Foo
# Simple2.pm => Foo

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Foo;
---
$dist->regen( clean => 1 );
$mb = new_build();
$provides = $mb->find_dist_packages;
ok( exists( $provides->{Foo} ) ); # it exist, can't predict which file
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, version in first file
# Simple.pm  => Foo v1.23
# Simple2.pm => Foo

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Foo;
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Foo' => { file => 'lib/Simple.pm',
		      version => '1.23' }});
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, version in second file
# Simple.pm  => Foo
# Simple2.pm => Foo v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Foo;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Foo' => { file => 'lib/Simple2.pm',
		      version => '1.23' }});
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, conflicting versions
# Simple.pm  => Foo v1.23
# Simple2.pm => Foo v2.34

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Foo;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
$mb = new_build();
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
# XXX Should 'Foo' exist ??? Can't predict values for file & version
ok( exists( $provides->{Foo} ) );
like( $err, qr/Found conflicting versions for package/,
      '  with conflicting versions reported' );
$dist->remove_file( 'lib/Simple2.pm' );


# Multiple files with same package, multiple agreeing versions
# Simple.pm  => Foo v1.23
# Simple2.pm => Foo v1.23

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Foo;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Foo;
$VERSION = '1.23';
---
$dist->regen( clean => 1 );
$mb = new_build();
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
ok( exists( $provides->{Foo} ) );
is( $provides->{Foo}{version}, '1.23' );
ok( exists( $provides->{Foo}{file} ) ); # Can't predict which file
is( $err, '', '  no conflicts reported' );
$dist->remove_file( 'lib/Simple2.pm' );

############################################################
# Conflicts among primary & multiple alternatives

# multiple files, conflicting version in corresponding file
$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
$VERSION = '2.34';
---
$dist->add_file( 'lib/Simple3.pm', <<'---' );
package Simple;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
$err = stderr_of( sub {
  $mb = new_build();
} );
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});
like( $err, qr/Found conflicting versions for package/,
      '  corresponding package conflicts with multiple alternatives' );
$dist->remove_file( 'lib/Simple2.pm' );
$dist->remove_file( 'lib/Simple3.pm' );

# multiple files, conflicting version in non-corresponding file
$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple2.pm', <<'---' );
package Simple;
$VERSION = '1.23';
---
$dist->add_file( 'lib/Simple3.pm', <<'---' );
package Simple;
$VERSION = '2.34';
---
$dist->regen( clean => 1 );
$err = stderr_of( sub {
  $mb = new_build();
} );
$err = stderr_of( sub { $provides = $mb->find_dist_packages } );
is_deeply($provides,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});
like( $err, qr/Found conflicting versions for package/,
      '  only one alternative conflicts with corresponding package' );
$dist->remove_file( 'lib/Simple2.pm' );
$dist->remove_file( 'lib/Simple3.pm' );


############################################################
# Don't record private packages (beginning with underscore)
# Simple.pm => Simple::_private
# Simple.pm => Simple::_private::too

$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
package Simple::_private;
$VERSION = '2.34';
package Simple::_private::too;
$VERSION = '3.45';
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages,
	  {'Simple' => { file => 'lib/Simple.pm',
			 version => '1.23' }});


############################################################
# Files with no packages?

# Simple.pm => <empty>

$dist->change_file( 'lib/Simple.pm', '' );
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply( $mb->find_dist_packages, {} );

# Simple.pm => =pod..=cut (no package declaration)
$dist->change_file( 'lib/Simple.pm', <<'---' );
=pod

=head1 NAME

Simple - Pure Documentation

=head1 DESCRIPTION

Doesn't do anything.

=cut
---
$dist->regen( clean => 1 );
$mb = new_build();
is_deeply($mb->find_dist_packages, {});

############################################################
# cleanup
chdir( $cwd ) or die "Can't chdir to '$cwd': $!";
$dist->remove;

use File::Path;
rmtree( $tmp );
