use strict;
use warnings;
package GeneratePackage;
# vim:ts=8:sw=2:et:sta:sts=2

our @ISA = ('Exporter');
our @EXPORT = qw(tmpdir generate_file);

use Cwd;
use File::Spec;
use File::Path;
use File::Temp;
use IO::File;

BEGIN {
  my $cwd = File::Spec->rel2abs(Cwd::cwd);
  sub _original_cwd { return $cwd }
}

sub tmpdir {
  my (@args) = @_;
  File::Temp::tempdir(
    'MMD-XXXXXXXX',
    CLEANUP => 0,
    DIR => ($ENV{PERL_CORE} ? _original_cwd : File::Spec->tmpdir),
    @args,
  );
}

my $tmp;
BEGIN { $tmp = tmpdir; Test::More::note "using temp dir $tmp"; }

sub generate_file {
  my ($dir, $rel_filename, $content) = @_;

  File::Path::mkpath($dir) or die "failed to create '$dir'";
  my $abs_filename = File::Spec->catfile($dir, $rel_filename);

  Test::More::note("working on $abs_filename");

  my $fh = IO::File->new(">$abs_filename") or die "Can't write '$abs_filename'\n";
  print $fh $content;
  close $fh;

  return $abs_filename;
}

END {
  die "tests failed; leaving temp dir $tmp behind"
    if $ENV{AUTHOR_TESTING} and not Test::Builder->new->is_passing;
  Test::More::note "removing temp dir $tmp";
  chdir _original_cwd;
  File::Path::rmtree($tmp);
}

1;
