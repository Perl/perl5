use strict;
use warnings;
use Test::More tests => 1;

use File::Spec;
use FindBin '$Bin';
use Archive::Tar;

# filenames
my $tartest = File::Spec->catfile("t", "tartest");
my $foo = File::Spec->catfile("t", "tartest", "foo");
my $tarfile = File::Spec->catfile("t", "tartest.tar");
my $ptargrep = File::Spec->catfile($Bin, "..", "bin", "ptargrep");
my $cmd = "$^X $ptargrep --list-only 'file foo' $tarfile";

# create directory/files
mkdir $tartest;
open my $fh, ">", $foo or die $!;
print $fh "file foo\n";
close $fh;

# create archive
my $tar = Archive::Tar->new;
$tar->add_files($foo);
$tar->write($tarfile);

# see if ptargrep matches
my $out = qx{$cmd};
cmp_ok($out, '=~', qr{^t.*tartest.*foo$}m, "ptargrep shows matched file");

# cleanup
END {
    unlink $tarfile;
    unlink $foo or die $!;
    rmdir $tartest or die $!;
}
