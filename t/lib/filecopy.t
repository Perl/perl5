#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..11\n";

$| = 1;

use File::Copy;

# First we create a file
open(F, ">file-$$") or die;
print F "ok 3\n";
close F;

copy "file-$$", "copy-$$";

open(F, "copy-$$") or die;
$foo = <F>;
close(F);

print "not " if -s "file-$$" != -s "copy-$$";
print "ok 1\n";

print "not " unless $foo eq "ok 3\n";
print "ok 2\n";

copy "copy-$$", \*STDOUT;
unlink "copy-$$";

open(F,"file-$$");
copy(*F, "copy-$$");
open(R, "copy-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 4\n";
unlink "copy-$$";
open(F,"file-$$");
copy(\*F, "copy-$$");
open(R, "copy-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 5\n";
unlink "copy-$$";

require IO::File;
$fh = IO::File->new(">copy-$$") or die "Cannot open copy-$$:$!";
copy("file-$$",$fh);
$fh->close;
open(R, "copy-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 6\n";
unlink "copy-$$";
require FileHandle;
my $fh = FileHandle->new(">copy-$$") or die "Cannot open copy-$$:$!";
copy("file-$$",$fh);
$fh->close;
open(R, "copy-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 7\n";
unlink "file-$$";

print "not " if move("file-$$", "copy-$$") or not -e "copy-$$";
print "ok 8\n";

move "copy-$$", "file-$$";
print "not " unless -e "file-$$" and not -e "copy-$$";
open(R, "file-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 9\n";

copy "file-$$", "lib";
open(R, "lib/file-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n";
print "ok 10\n";
unlink "lib/file-$$";

move "file-$$", "lib";
open(R, "lib/file-$$") or die; $foo = <R>; close(R);
print "not " unless $foo eq "ok 3\n" and not -e "file-$$";;
print "ok 11\n";
unlink "lib/file-$$";

