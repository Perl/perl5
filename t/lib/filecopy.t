#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..5\n";

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

unlink "file-$$";

print "not " if move("file-$$", "copy-$$") or not -e "copy-$$";
print "ok 4\n";

move "copy-$$", "file-$$";

print "not " unless -e "file-$$" and not -e "copy-$$";
print "ok 5\n";

unlink "file-$$";
