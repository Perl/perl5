#!perl -w
#-----------------------------------------------------------------#
#  installme.plx
#  http://pudge.net/
#
#  Created:       Chris Nandor (pudge@pobox.com)       24 Jan 1999
#  Last Modified: Chris Nandor (pudge@pobox.com)       28 Jul 1999
#-----------------------------------------------------------------#
# This script installs distributions.  It will unpack and install
# .tar.gz or .tgz archives if they are dropped on it, or install
# the contents of a folder.
#
# Edit $verbose and $switch variables to customize for verbosity
# and conversion behavior.
#-----------------------------------------------------------------#
use Archive::Tar;
use File::Basename;
use Mac::Conversions ();
use Mac::BuildTools ();
use strict;
local $| = 1;

my $verbose = 1;
my $re = '\.t(ar\.)?gz$';

my $archive = my $dir = $ARGV[0];

if ($archive =~ /$re/) {
    my $switch = MacPerl::Answer(
        'Convert all text and MacBinary files?', 'Yes', 'No');
    my $conv = Mac::Conversions->new(Remove=>1);

    my $tar = Archive::Tar->new($archive, 1) or die $!;
    chdir(dirname($archive)) or die "Can't chdir: $!";

    my @files = $tar->list_files;

    foreach my $file (@files) {
        $file .= "/" unless $file =~ /\//;
        my $dir = ':' . dirname(Archive::Tar::_munge_file($file));
        die "$dir already exists, will not overwrite\n"
            if -e $dir;
    }

    print "Unpacking archive ...\n";
    $tar->extract(@files);

    print "Converting files ...\n";
    Mac::BuildTools::convert_files(\@files, $verbose) if $switch;

    $dir =~ s/$re//;
}

chdir $dir or die "Can't chdir $dir: $!\n";
Mac::BuildTools::make({});
Mac::BuildTools::make_install({});

print "Done.\n";

__END__
