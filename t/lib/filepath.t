#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..2\n";

use File::Path;

mkpath("foo/bar");

print "not " unless -d "foo" && -d "foo/bar";
print "ok 1\n";

rmtree("foo");

print "not " if -e "foo";
print "ok 2\n";
