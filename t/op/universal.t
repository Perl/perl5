#!./perl
#
# check UNIVERSAL
#

print "1..4\n";

# explicit bless

$a = {};
bless $a, "Bob";
if ($a->class eq "Bob") {print "ok 1\n";} else {print "not ok 1\n";}

# bless through a package

package Fred;

$b = {};
bless $b;
if ($b->class eq "Fred") {print "ok 2\n";} else {print "not ok 2\n";}

package main;

# same as test 1 and 2, but with other object syntax

# explicit bless

$a = {};
bless $a, "Bob";
if (class $a eq "Bob") {print "ok 3\n";} else {print "not ok 3\n";}

# bless through a package

package Fred;

$b = {};
bless $b;
if (class $b eq "Fred") {print "ok 4\n";} else {print "not ok 4\n";}
