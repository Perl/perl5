#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use File::Spec::Functions;
use File::Path;
use strict;

my $count = 0;
use warnings;

print "1..4\n";

# first check for stupid permissions second for full, so we clean up
# behind ourselves
for my $perm (0111,0777) {
    my $one = catdir(curdir(), "foo");
    my $two = catdir(curdir(), "foo", "bar");

    mkpath($two);
    chmod $perm, $one, $two;

    print "not " unless -d $one && -d $two;
    print "ok ", ++$count, "\n";

    rmtree($one);
    print "not " if -e $one;
    print "ok ", ++$count, "\n";
}
