#!perl -w
#-----------------------------------------------------------------#
#  untarzipme.plx
#  http://pudge.net/
#
#  Created:       Chris Nandor (pudge@pobox.com)       04 Jan 1999
#  Last Modified: Chris Nandor (pudge@pobox.com)       28 Jul 1999
#-----------------------------------------------------------------#
# This script unpacks tar.gz archives.  It converts all files
# that test true with -T to Mac newlines, and converts files
# that test true with -B and have the ending .bin from
# macbinary to regular Mac files.
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

my $switch = MacPerl::Answer(
    'Convert all text and MacBinary files?', 'Yes', 'No');
my $conv = Mac::Conversions->new(Remove=>1);

foreach my $archive (@ARGV) {
    print "Unpacking archive:\n    $archive\n";
    my $tar = Archive::Tar->new($archive, 1) or die $!;
    chdir(dirname($archive)) or die "Can't chdir: $!";

    my @files = $tar->list_files;

    foreach my $file (@files) {
      $file .= "/" unless $file =~ /\//;
      my $dir = ':' . dirname(Archive::Tar::_munge_file($file));
      die "$dir already exists, will not overwrite\n"
          if -e $dir;
    }

    print "Unpacking ...\n";
    $tar->extract(@files);

    print "Converting files ...\n";
    Mac::BuildTools::convert_files(\@files, $verbose) if $switch;
}

print "Done.\n";

__END__
