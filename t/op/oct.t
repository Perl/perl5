#!./perl

# $RCSfile: oct.t,v $$Revision: 4.1 $$Date: 92/08/07 18:28:08 $

print "1..3\n";

if (oct('01234') == 01234) {print "ok 1\n";} else {print "not ok 1\n";}
if (oct('0x1234') == 0x1234) {print "ok 2\n";} else {print "not ok 2\n";}
if (hex('01234') == 0x1234) {print "ok 3\n";} else {print "not ok 3\n";}
