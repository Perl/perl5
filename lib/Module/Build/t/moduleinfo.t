#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest tests => 66;

use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );

use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";

#########################


use_ok( 'Module::Build::ModuleInfo' );

# class method C<find_module_by_name>
my $module = Module::Build::ModuleInfo->find_module_by_name(
               'Module::Build::ModuleInfo' );
ok( -e $module, 'find_module_by_name() succeeds' );


# fail on invalid module name
my $pm_info = Module::Build::ModuleInfo->new_from_module(
		'Foo::Bar', inc => [] );
ok( !defined( $pm_info ), 'fail if can\'t find module by module name' );


# fail on invalid filename
my $file = File::Spec->catfile( 'Foo', 'Bar.pm' );
$pm_info = Module::Build::ModuleInfo->new_from_file( $file, inc => [] );
ok( !defined( $pm_info ), 'fail if can\'t find module by file name' );


# construct from module filename
$file = File::Spec->catfile( 'lib', split( /::/, $dist->name ) ) . '.pm';
$pm_info = Module::Build::ModuleInfo->new_from_file( $file );
ok( defined( $pm_info ), 'new_from_file() succeeds' );

# construct from module name, using custom include path
$pm_info = Module::Build::ModuleInfo->new_from_module(
	     $dist->name, inc => [ 'lib', @INC ] );
ok( defined( $pm_info ), 'new_from_module() succeeds' );


# parse various module $VERSION lines
my @modules = (
  <<'---', # declared & defined on same line with 'our'
package Simple;
our $VERSION = '1.23';
---
  <<'---', # declared & defined on seperate lines with 'our'
package Simple;
our $VERSION;
$VERSION = '1.23';
---
  <<'---', # use vars
package Simple;
use vars qw( $VERSION );
$VERSION = '1.23';
---
  <<'---', # choose the right default package based on package/file name
package Simple::_private;
$VERSION = '0';
package Simple;
$VERSION = '1.23'; # this should be chosen for version
---
  <<'---', # just read the first $VERSION line
package Simple;
$VERSION = '1.23'; # we should see this line
$VERSION = eval $VERSION; # and ignore this one
---
  <<'---', # just read the first $VERSION line in reopened package (1)
package Simple;
$VERSION = '1.23';
package Error::Simple;
$VERSION = '2.34';
package Simple;
---
  <<'---', # just read the first $VERSION line in reopened package (2)
package Simple;
package Error::Simple;
$VERSION = '2.34';
package Simple;
$VERSION = '1.23';
---
  <<'---', # mentions another module's $VERSION
package Simple;
$VERSION = '1.23';
if ( $Other::VERSION ) {
    # whatever
}
---
  <<'---', # mentions another module's $VERSION in a different package
package Simple;
$VERSION = '1.23';
package Simple2;
if ( $Simple::VERSION ) {
    # whatever
}
---
  <<'---', # $VERSION checked only in assignments, not regexp ops
package Simple;
$VERSION = '1.23';
if ( $VERSION =~ /1\.23/ ) {
    # whatever
}
---
  <<'---', # $VERSION checked only in assignments, not relational ops
package Simple;
$VERSION = '1.23';
if ( $VERSION == 3.45 ) {
    # whatever
}
---
  <<'---', # $VERSION checked only in assignments, not relational ops
package Simple;
$VERSION = '1.23';
package Simple2;
if ( $Simple::VERSION == 3.45 ) {
    # whatever
}
---
  <<'---', # Fully qualified $VERSION declared in package
package Simple;
$Simple::VERSION = 1.23;
---
  <<'---', # Differentiate fully qualified $VERSION in a package
package Simple;
$Simple2::VERSION = '999';
$Simple::VERSION = 1.23;
---
  <<'---', # Differentiate fully qualified $VERSION and unqualified
package Simple;
$Simple2::VERSION = '999';
$VERSION = 1.23;
---
  <<'---', # $VERSION declared as package variable from within 'main' package
$Simple::VERSION = '1.23';
{
  package Simple;
  $x = $y, $cats = $dogs;
}
---
  <<'---', # $VERSION wrapped in parens - space inside
package Simple;
( $VERSION ) = '1.23';
---
  <<'---', # $VERSION wrapped in parens - no space inside
package Simple;
($VERSION) = '1.23';
---
  <<'---', # $VERSION follows a spurious 'package' in a quoted construct
package Simple;
__PACKAGE__->mk_accessors(qw(
    program socket proc
    package filename line codeline subroutine finished));

our $VERSION = "1.23";
---
);

my( $i, $n ) = ( 1, scalar( @modules ) );
foreach my $module ( @modules ) {
 SKIP: {
    skip( "No our() support until perl 5.6", 2 )
	if $] < 5.006 && $module =~ /\bour\b/;

    $dist->change_file( 'lib/Simple.pm', $module );
    $dist->regen;

    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_ for @_ };
    my $pm_info = Module::Build::ModuleInfo->new_from_file( $file );

    is( $pm_info->version, '1.23',
	"correct module version ($i of $n)" );
    is( $warnings, '', 'no warnings from parsing' );
    $i++;
  }
}

# revert to pristine state
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;
$dist = DistGen->new( dir => $tmp );
$dist->regen;
chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";


# Find each package only once
$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '1.23';
package Error::Simple;
$VERSION = '2.34';
package Simple;
---

$dist->regen;

$pm_info = Module::Build::ModuleInfo->new_from_file( $file );

my @packages = $pm_info->packages_inside;
is( @packages, 2, 'record only one occurence of each package' );


# Module 'Simple.pm' does not contain package 'Simple';
# constructor should not complain, no default module name or version
$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple::Not;
$VERSION = '1.23';
---

$dist->regen;
$pm_info = Module::Build::ModuleInfo->new_from_file( $file );

is( $pm_info->name, undef, 'no default package' );
is( $pm_info->version, undef, 'no version w/o default package' );


# revert to pristine state
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;
$dist = DistGen->new( dir => $tmp );
$dist->regen;
chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";


# parse $VERSION lines scripts for package main
my @scripts = (
  <<'---', # package main declared
#!perl -w
package main;
$VERSION = '0.01';
---
  <<'---', # on first non-comment line, non declared package main
#!perl -w
$VERSION = '0.01';
---
  <<'---', # after non-comment line
#!perl -w
use strict;
$VERSION = '0.01';
---
  <<'---', # 1st declared package
#!perl -w
package main;
$VERSION = '0.01';
package _private;
$VERSION = '999';
---
  <<'---', # 2nd declared package
#!perl -w
package _private;
$VERSION = '999';
package main;
$VERSION = '0.01';
---
  <<'---', # split package
#!perl -w
package main;
package _private;
$VERSION = '999';
package main;
$VERSION = '0.01';
---
  <<'---', # define 'main' version from other package
package _private;
$::VERSION = 0.01;
$VERSION = '999';
---
  <<'---', # define 'main' version from other package
package _private;
$VERSION = '999';
$::VERSION = 0.01;
---
);

( $i, $n ) = ( 1, scalar( @scripts ) );
foreach my $script ( @scripts ) {
  $dist->change_file( 'bin/simple.plx', $script );
  $dist->regen;
  $pm_info = Module::Build::ModuleInfo->new_from_file(
	       File::Spec->catfile( 'bin', 'simple.plx' ) );

  is( $pm_info->version, '0.01', "correct script version ($i of $n)" );
  $i++;
}


# examine properties of a module: name, pod, etc
$dist->change_file( 'lib/Simple.pm', <<'---' );
package Simple;
$VERSION = '0.01';
package Simple::Ex;
$VERSION = '0.02';
=head1 NAME

Simple - It's easy.

=head1 AUTHOR

Simple Simon

=cut
---
$dist->regen;

$pm_info = Module::Build::ModuleInfo->new_from_module(
             $dist->name, inc => [ 'lib', @INC ] );

is( $pm_info->name, 'Simple', 'found default package' );

is( $pm_info->version, '0.01', 'version for default package' );

# got correct version for secondary package
is( $pm_info->version( 'Simple::Ex' ), '0.02',
    'version for secondary package' );

my $filename = $pm_info->filename;
ok( defined( $filename ) && -e $filename,
    'filename() returns valid path to module file' );

@packages = $pm_info->packages_inside;
is( @packages, 2, 'found correct number of packages' );
is( $packages[0], 'Simple', 'packages stored in order found' );

# we can detect presence of pod regardless of whether we are collecting it
ok( $pm_info->contains_pod, 'contains_pod() succeeds' );

my @pod = $pm_info->pod_inside;
is_deeply( \@pod, [qw(NAME AUTHOR)], 'found all pod sections' );

is( $pm_info->pod('NONE') , undef,
    'return undef() if pod section not present' );

is( $pm_info->pod('NAME'), undef,
    'return undef() if pod section not collected' );


# collect_pod
$pm_info = Module::Build::ModuleInfo->new_from_module(
             $dist->name, inc => [ 'lib', @INC ], collect_pod => 1 );

my $name = $pm_info->pod('NAME');
if ( $name ) {
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
}
is( $name, q|Simple - It's easy.|, 'collected pod section' );


# cleanup
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;

use File::Path;
rmtree( $tmp );
