#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest tests => 53;

use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );

use DistGen;
my $dist = DistGen->new( dir => $tmp );
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";

#########################

use Module::Build;
ok 1;

# Here we make sure actions are only called once per dispatch()
$::x = 0;
my $mb = Module::Build->subclass
  (
   code => "sub ACTION_loop { die 'recursed' if \$::x++; shift->depends_on('loop'); }"
  )->new( module_name => $dist->name );
ok $mb;

$mb->dispatch('loop');
ok $::x;

$mb->dispatch('realclean');

# Make sure the subclass can be subclassed
my $build2class = ref($mb)->subclass
  (
   code => "sub ACTION_loop2 {}",
   class => 'MBB',
  );
can_ok( $build2class, 'ACTION_loop' );
can_ok( $build2class, 'ACTION_loop2' );


{ # Make sure globbing works in filenames
  $dist->add_file( 'script', <<'---' );
#!perl -w
print "Hello, World!\n";
---
  $dist->regen;

  $mb->test_files('*t*');
  my $files = $mb->test_files;
  ok  grep {$_ eq 'script'}    @$files;
  ok  grep {$_ eq File::Spec->catfile('t', 'basic.t')} @$files;
  ok !grep {$_ eq 'Build.PL' } @$files;

  # Make sure order is preserved
  $mb->test_files('foo', 'bar');
  $files = $mb->test_files;
  is @$files, 2;
  is $files->[0], 'foo';
  is $files->[1], 'bar';

  $dist->remove_file( 'script' );
  $dist->regen( clean => 1 );
}


{
  # Make sure we can add new kinds of stuff to the build sequence

  $dist->add_file( 'test.foo', "content\n" );
  $dist->regen;

  my $mb = Module::Build->new( module_name => $dist->name,
			       foo_files => {'test.foo', 'lib/test.foo'} );
  ok $mb;

  $mb->add_build_element('foo');
  $mb->add_build_element('foo');
  is_deeply $mb->build_elements, [qw(PL support pm xs pod script foo)],
      'The foo element should be in build_elements only once';

  $mb->dispatch('build');
  ok -e File::Spec->catfile($mb->blib, 'lib', 'test.foo');

  $mb->dispatch('realclean');

  # revert distribution to a pristine state
  $dist->remove_file( 'test.foo' );
  $dist->regen( clean => 1 );
}


{
  package MBSub;
  use Test::More;
  use vars qw($VERSION @ISA);
  @ISA = qw(Module::Build);
  $VERSION = 0.01;
  
  # Add a new property.
  ok(__PACKAGE__->add_property('foo'));
  # Add a new property with a default value.
  ok(__PACKAGE__->add_property('bar', 'hey'));
  # Add a hash property.
  ok(__PACKAGE__->add_property('hash', {}));
  
  
  # Catch an exception adding an existing property.
  eval { __PACKAGE__->add_property('module_name')};
  like "$@", qr/already exists/;
}

{
  package MBSub2;
  use Test::More;
  use vars qw($VERSION @ISA);
  @ISA = qw(Module::Build);
  $VERSION = 0.01;
  
  # Add a new property with a different default value than MBSub has.
  ok(__PACKAGE__->add_property('bar', 'yow'));
}


{
  ok my $mb = MBSub->new( module_name => $dist->name );
  isa_ok $mb, 'Module::Build';
  isa_ok $mb, 'MBSub';
  ok $mb->valid_property('foo');
  can_ok $mb, 'module_name';
  
  # Check foo property.
  can_ok $mb, 'foo';
  ok ! $mb->foo;
  ok $mb->foo(1);
  ok $mb->foo;
  
  # Check bar property.
  can_ok $mb, 'bar';
  is $mb->bar, 'hey';
  ok $mb->bar('you');
  is $mb->bar, 'you';
  
  # Check hash property.
  ok $mb = MBSub->new(
		       module_name => $dist->name,
		       hash        => { foo => 'bar', bin => 'foo'}
		     );
  
  can_ok $mb, 'hash';
  isa_ok $mb->hash, 'HASH';
  is $mb->hash->{foo}, 'bar';
  is $mb->hash->{bin}, 'foo';
  
  # Check hash property passed via the command-line.
  {
    local @ARGV = (
		   '--hash', 'foo=bar',
		   '--hash', 'bin=foo',
		  );
    ok $mb = MBSub->new( module_name => $dist->name );
  }

  can_ok $mb, 'hash';
  isa_ok $mb->hash, 'HASH';
  is $mb->hash->{foo}, 'bar';
  is $mb->hash->{bin}, 'foo';
  
  # Make sure that a different subclass with the same named property has a
  # different default.
  ok $mb = MBSub2->new( module_name => $dist->name );
  isa_ok $mb, 'Module::Build';
  isa_ok $mb, 'MBSub2';
  ok $mb->valid_property('bar');
  can_ok $mb, 'bar';
  is $mb->bar, 'yow';
}

{
  # Test the meta_add and meta_merge stuff
  ok my $mb = Module::Build->new(
				  module_name => $dist->name,
				  license => 'perl',
				  meta_add => {foo => 'bar'},
				  conflicts => {'Foo::Barxx' => 0},
			        );
  my %data;
  $mb->prepare_metadata( \%data );
  is $data{foo}, 'bar';

  $mb->meta_merge(foo => 'baz');
  $mb->prepare_metadata( \%data );
  is $data{foo}, 'baz';

  $mb->meta_merge(conflicts => {'Foo::Fooxx' => 0});
  $mb->prepare_metadata( \%data );
  is_deeply $data{conflicts}, {'Foo::Barxx' => 0, 'Foo::Fooxx' => 0};

  $mb->meta_add(conflicts => {'Foo::Bazxx' => 0});
  $mb->prepare_metadata( \%data );
  is_deeply $data{conflicts}, {'Foo::Bazxx' => 0, 'Foo::Fooxx' => 0};
}


# cleanup
chdir( $cwd ) or die "Can''t chdir to '$cwd': $!";
$dist->remove;

use File::Path;
rmtree( $tmp );
