BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..4\n";

use Time::Piece;
print "ok 1\n";

my $t = gmtime(315532800); # 00:00:00 1/1/1980

print "not " unless $t->year == 1980;
print "ok 2\n";

print "not " unless $t->hour == 0;
print "ok 3\n";

print "not " unless $t->mon == 1;
print "ok 4\n";
