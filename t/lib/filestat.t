#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    our $hasst;
    eval { my @n = stat "TEST" };
    $hasst = 1 unless $@ && $@ =~ /unimplemented/;
    unless ($hasst) { print "1..0 # Skip: no stat\n"; exit 0 }
    use Config;
    $hasst = 0 unless $Config{'i_sysstat'} eq 'define';
    unless ($hasst) { print "1..0 # Skip: no sys/stat.h\n"; exit 0 }
}

BEGIN {
    our @stat = stat "TEST"; # This is the function stat.
    unless (@stat) { print "1..0 # Skip: no file TEST\n"; exit 0 }
}

print "1..14\n";

use File::stat;

print "ok 1\n";

my $stat = stat "TEST"; # This is the OO stat.

print "not " unless $stat->dev     == $stat[ 0];
print "ok 2\n";

print "not " unless $stat->ino     == $stat[ 1];
print "ok 3\n";

print "not " unless $stat->mode    == $stat[ 2];
print "ok 4\n";

print "not " unless $stat->nlink   == $stat[ 3];
print "ok 5\n";

print "not " unless $stat->uid     == $stat[ 4];
print "ok 6\n";

print "not " unless $stat->gid     == $stat[ 5];
print "ok 7\n";

print "not " unless $stat->rdev    == $stat[ 6];
print "ok 8\n";

print "not " unless $stat->size    == $stat[ 7];
print "ok 9\n";

print "not " unless $stat->atime   == $stat[ 8];
print "ok 10\n";

print "not " unless $stat->mtime   == $stat[ 9];
print "ok 11\n";

print "not " unless $stat->ctime   == $stat[10];
print "ok 12\n";

print "not " unless $stat->blksize == $stat[11];
print "ok 13\n";

print "not " unless $stat->blocks  == $stat[12];
print "ok 14\n";

# Testing pretty much anything else is unportable.
