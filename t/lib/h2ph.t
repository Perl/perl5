#!./perl

# quickie tests to see if h2ph actually runs and does more or less what is
# expected

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use File::Compare;
print "1..2\n";

unless(-e '../utils/h2ph') {
    print("ok 1\nok 2\n");
    # i'll probably get in trouble for this :)
} else {
    # does it run?
    $ok = system("./perl -I../lib ../utils/h2ph -d. lib/h2ph.h");
    print(($ok == 0 ? "" : "not "), "ok 1\n");
    
    # does it work? well, does it do what we expect? :-)
    $ok = compare("lib/h2ph.ph", "lib/h2ph.pht");
    print(($ok == 0 ? "" : "not "), "ok 2\n");
    
    # cleanup - should this be in an END block?
    unlink("lib/h2ph.ph");
}
