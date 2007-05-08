#!/usr/bin/perl -w

use strict;
use lib $ENV{PERL_CORE} ? '../lib/Module/Build/t/lib' : 't/lib';
use MBTest;
use Module::Build;
use Module::Build::ConfigData;

{
  my ($have_c_compiler, $C_support_feature) = check_compiler();
  if (! $C_support_feature) {
    plan skip_all => 'C_support not enabled';
  } elsif ( ! $have_c_compiler ) {
    plan skip_all => 'C_support enabled, but no compiler found';
  } elsif ( ! eval {require PAR::Dist; PAR::Dist->VERSION(0.17)} ) {
    plan skip_all => "PAR::Dist 0.17 or up not installed to check .par's.";
  } elsif ( ! eval {require Archive::Zip} ) {
    plan skip_all => "Archive::Zip required.";
  } else {
    plan tests => 3;
  }
}


use Cwd ();
my $cwd = Cwd::cwd;
my $tmp = File::Spec->catdir( $cwd, 't', '_tmp' );


use DistGen;
my $dist = DistGen->new( dir => $tmp, xs => 1 );
$dist->add_file( 'hello', <<'---' );
#!perl -w
print "Hello, World!\n";
__END__

=pod

=head1 NAME

hello

=head1 DESCRIPTION

Says "Hello"

=cut
---
$dist->change_file( 'Build.PL', <<"---" );

my \$build = new Module::Build(
  module_name => @{[$dist->name]},
  version => '0.01',
  license     => 'perl',
  scripts     => [ 'hello' ],
);

\$build->create_build_script;
---
$dist->regen;

chdir( $dist->dirname ) or die "Can't chdir to '@{[$dist->dirname]}': $!";

use File::Spec::Functions qw(catdir);

use Module::Build;
my @installstyle = qw(lib perl5);
my $mb = Module::Build->new_from_context(
  verbose => 0,
  quiet   => 1,

  installdirs => 'site',
);

my $filename = $mb->dispatch('pardist');

ok( -f $filename, '.par distributions exists' );
my $distname = $dist->name;
ok( $filename =~ /^\Q$distname\E/, 'Distribution name seems correct' );

my $meta;
eval { $meta = PAR::Dist::get_meta($filename) };

ok(
  (not $@ and defined $meta and not $meta eq ''),
  'Distribution contains META.yml'
);

$dist->clean();

chdir( $cwd );
use File::Path;
rmtree( $tmp );

