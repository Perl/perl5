#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use File::Compare; 

print "1..2\n";
$ok = system("./perl -I../lib ../utils/h2ph -d. lib/h2ph.h");
print(($ok == 0 ? "" : "not "), "ok 1\n");
$ok = compare("lib/h2ph.ph", "lib/h2ph.pht");
print(($ok == 0 ? "" : "not "), "ok 2\n");
#system("diff -c lib/h2ph.pht lib/h2ph.ph 1>&2");
unlink("lib/h2ph.ph");
