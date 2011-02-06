package ExtUtils::ParseXS::Utilities;
use strict;
use warnings;
use Exporter;
our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
  standard_typemap_locations
);

sub standard_typemap_locations {
  my $include_ref = shift;
  # Add all the default typemap locations to the search path
  my @tm = qw(typemap);

  my $updir = File::Spec->updir;
  foreach my $dir (File::Spec->catdir(($updir) x 1), File::Spec->catdir(($updir) x 2),
           File::Spec->catdir(($updir) x 3), File::Spec->catdir(($updir) x 4)) {

    unshift @tm, File::Spec->catfile($dir, 'typemap');
    unshift @tm, File::Spec->catfile($dir, lib => ExtUtils => 'typemap');
  }
  foreach my $dir (@{ $include_ref}) {
    my $file = File::Spec->catfile($dir, ExtUtils => 'typemap');
    unshift @tm, $file if -e $file;
  }
  return @tm;
}

1;
