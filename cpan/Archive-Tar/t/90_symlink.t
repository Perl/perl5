BEGIN { chdir 't' if -d 't' }

use lib '../lib';

use strict;
use File::Spec;
use File::Path;
use Test::More;
use Config;

my $win32_symlink_enabled = 0;

if($^O =~ /MSWin32/i && $Config{d_symlink}) {
  # Creation of symlinks is available to this system,
  # but might not have been enabled. We check on this
  # by checking whether symlink() actually works.

  if(-e '../Makefile.PL') {
    symlink '../Makefile.PL', 'make.sym';
    if(-e 'make.sym') {
      $win32_symlink_enabled = 1;
      unlink 'make.sym';
    }
  }
  else {
    warn "Cannot establish whether symlink() is enabled as Makefile.PL was not found";
    $win32_symlink_enabled = 1; # We have no reason to assume otherwise.
  }
}

### developer tests mostly
if (($^O !~ /(linux|bsd|darwin|solaris|hpux|aix|
              sunos|dynixptx|haiku|irix|next|dec_osf|svr4|sco_sv|unicos|
            cygwin)/x and !$Config{d_symlink})
            ||
            ($^O =~ /MSWin/i and !$win32_symlink_enabled)) {
  plan skip_all => "Skipping tests on this platform";
}
plan 'no_plan';

my $Class   = 'Archive::Tar';
my $Dir     = File::Spec->catdir( qw[src linktest] );
my %Map     = (
    File::Spec->catfile( $Dir, "linktest_with_dir.tar" ) => [
        [ 0, qr/SECURE EXTRACT MODE/ ],
        [ 1, qr/^$/ ]
    ],
    File::Spec->catfile( $Dir, "linktest_missing_dir.tar" ) => [
        [ 0, qr/SECURE EXTRACT MODE/ ],
        [ 0, qr/Could not create directory/ ],
    ],
);

use_ok( $Class );

{   while( my($file, $aref) = each %Map ) {

        for my $mode ( 0, 1 ) {
            my $expect = $aref->[$mode]->[0];
            my $regex  = $aref->[$mode]->[1];

            my $tar  = $Class->new( $file );
            ok( $tar,                   "Object created from $file" );

            ### damn warnings
            local $Archive::Tar::INSECURE_EXTRACT_MODE = $mode;
            local $Archive::Tar::INSECURE_EXTRACT_MODE = $mode;

            ok( 1,                  "   Extracting with insecure mode: $mode" );

            my $warning;
            local $SIG{__WARN__} = sub { $warning .= "@_" };

            my $rv = eval { $tar->extract } || 0;
            ok( !$@,                "       No fatal error" );
            is( !!$rv, !!$expect,   "       RV as expected" );
            like( $warning, $regex, "       Error matches $regex" );

            rmtree( 'linktest' );
        }
    }
}
