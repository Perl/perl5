#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..1\n";

use FindBin qw($Bin);

print "# $Bin\n";

print "not " unless $Bin =~ m,[/.]lib\]?$,;
print "ok 1\n";
