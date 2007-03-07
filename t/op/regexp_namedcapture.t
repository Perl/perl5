#!./perl
#
# Tests to make sure the regexp engine doesn't run into limits too soon.
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..1\n";
*X = *-;
print eval '*X{HASH}{X} || 1' ? "ok\n" :"not ok\n";
