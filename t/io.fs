#!./perl

# $Header: io.fs,v 1.0 87/12/18 13:12:48 root Exp $

print "1..18\n";

chdir '/tmp';
`/bin/rm -rf a b c x`;

umask(022);

if (umask(0) == 022) {print "ok 1\n";} else {print "not ok 1\n";}
open(fh,'>x') || die "Can't create x";
close(fh);
open(fh,'>a') || die "Can't create a";
close(fh);

if (link('a','b')) {print "ok 2\n";} else {print "not ok 2\n";}

if (link('b','c')) {print "ok 3\n";} else {print "not ok 3\n";}

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('c');

if ($nlink == 3) {print "ok 4\n";} else {print "not ok 4\n";}
if (($mode & 0777) == 0666) {print "ok 5\n";} else {print "not ok 5\n";}

if ((chmod 0777,'a') == 1) {print "ok 6\n";} else {print "not ok 6\n";}

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('c');
if (($mode & 0777) == 0777) {print "ok 7\n";} else {print "not ok 7\n";}

if ((chmod 0700,'c','x') == 2) {print "ok 8\n";} else {print "not ok 8\n";}

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('c');
if (($mode & 0777) == 0700) {print "ok 9\n";} else {print "not ok 9\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('x');
if (($mode & 0777) == 0700) {print "ok 10\n";} else {print "not ok 10\n";}

if ((unlink 'b','x') == 2) {print "ok 11\n";} else {print "not ok 11\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('b');
if ($ino == 0) {print "ok 12\n";} else {print "not ok 12\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('x');
if ($ino == 0) {print "ok 13\n";} else {print "not ok 13\n";}

if (rename('a','b')) {print "ok 14\n";} else {print "not ok 14\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('a');
if ($ino == 0) {print "ok 15\n";} else {print "not ok 15\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('b');
if ($ino) {print "ok 16\n";} else {print "not ok 16\n";}

if ((unlink 'b') == 1) {print "ok 17\n";} else {print "not ok 17\n";}
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat('b');
if ($ino == 0) {print "ok 18\n";} else {print "not ok 18\n";}
unlink 'c';
