#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}

# Test for File::Temp - tempfile function

use strict;
use Test;
BEGIN { plan tests => 10}
use File::Spec;
use File::Temp qw/ tempfile tempdir/;

# Will need to check that all files were unlinked correctly
# Set up an END block here to do it (since the END blocks
# set up by File::Temp will be evaluated in reverse order we
# set ours up first....

# Loop over an array hoping that the files dont exist
my @files;
eval q{ END { foreach (@files) { ok( !(-e $_) )} } 1; } || die; 

# And a test for directories
my @dirs;
eval q{ END { foreach (@dirs) { ok( !(-d $_) )} } 1; } || die; 


# Tempfile
# Open tempfile in some directory, unlink at end
my ($fh, $tempfile) = tempfile(
			       UNLINK => 1,
			       SUFFIX => '.txt',
			      );

ok( (-f $tempfile) );
push(@files, $tempfile);

# TEMPDIR test
# Create temp directory in current dir
my $template = 'tmpdirXXXXXX';
print "# Template: $template\n";
my $tempdir = tempdir( $template ,
		       DIR => File::Spec->curdir,
		       CLEANUP => 1,
		     );

print "# TEMPDIR: $tempdir\n";

ok( (-d $tempdir) );
push(@dirs, $tempdir);

# Create file in the temp dir
($fh, $tempfile) = tempfile(
			    DIR => $tempdir,
			    UNLINK => 1,
			    SUFFIX => '.dat',
			   );

print "# TEMPFILE: Created $tempfile\n";

ok( (-f $tempfile));
push(@files, $tempfile);

# Test tempfile
# ..and again
($fh, $tempfile) = tempfile(
			    DIR => $tempdir,
			   );


ok( (-f $tempfile ));
push(@files, $tempfile);

print "# TEMPFILE: Created $tempfile\n";

# and another (with template)

($fh, $tempfile) = tempfile( 'helloXXXXXXX',
			    DIR => $tempdir,
			    UNLINK => 1,
			    SUFFIX => '.dat',
			   );

print "# TEMPFILE: Created $tempfile\n";

ok( (-f $tempfile) );
push(@files, $tempfile);

# no tests yet to make sure that the END{} blocks correctly remove
# the files
