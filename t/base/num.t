#!./perl

print "1..30\n";

# First test whether the number stringification works okay.
# (Testing with == would exercize the IV/NV part, not the PV.)

$a = 1; "$a";
print $a eq "1"       ? "ok 1\n"  : "not ok 1\n";

$a = -1; "$a";
print $a eq "-1"      ? "ok 2\n"  : "not ok 2\n";

$a = 1.; "$a";
print $a eq "1"       ? "ok 3\n"  : "not ok 3\n";

$a = -1.; "$a";
print $a eq "-1"      ? "ok 4\n"  : "not ok 4\n";

$a = 0.1; "$a";
print $a eq "0.1"     ? "ok 5\n"  : "not ok 5\n";

$a = -0.1; "$a";
print $a eq "-0.1"    ? "ok 6\n"  : "not ok 6\n";

$a = .1; "$a";
print $a eq "0.1"     ? "ok 7\n"  : "not ok 7\n";

$a = -.1; "$a";
print $a eq "-0.1"    ? "ok 8\n"  : "not ok 8\n";

$a = 10.01; "$a";
print $a eq "10.01"   ? "ok 9\n"  : "not ok 9\n";

$a = 1e3; "$a";
print $a eq "1000"    ? "ok 10\n" : "not ok 10\n";

$a = 10.01e3; "$a";
print $a eq "10010"   ? "ok 11\n"  : "not ok 11\n";

$a = 0b100; "$a";
print $a eq "4"       ? "ok 12\n"  : "not ok 12\n";

$a = 0100; "$a";
print $a eq "64"      ? "ok 13\n"  : "not ok 13\n";

$a = 0x100; "$a";
print $a eq "256"     ? "ok 14\n" : "not ok 14\n";

$a = 1000; "$a";
print $a eq "1000"    ? "ok 15\n" : "not ok 15\n";

# Okay, now test the numerics.
# We may be assuming too much, given the painfully well-known floating
# point sloppiness, but the following are still quite reasonable
# assumptions which if not working would confuse people quite badly.

$a = 1; "$a"; # Keep the stringification as a potential troublemaker.
print $a + 1 == 2     ? "ok 16\n" : "not ok 16\n";

$a = -1; "$a";
print $a + 1 == 0     ? "ok 17\n" : "not ok 17\n";

$a = 1.; "$a";
print $a + 1 == 2     ? "ok 18\n" : "not ok 18\n";

$a = -1.; "$a";
print $a + 1 == 0     ? "ok 19\n" : "not ok 19\n";

$a = 0.1; "$a";
print $a + 1 == 1.1   ? "ok 20\n" : "not ok 20\n";

$a = -0.1; "$a";
print $a + 1 == 0.9   ? "ok 21\n" : "not ok 21\n";

$a = .1; "$a";
print $a + 1 == 1.1   ? "ok 22\n" : "not ok 22\n";

$a = -.1; "$a";
print $a + 1 == 0.9   ? "ok 23\n" : "not ok 23\n";

$a = 10.01; "$a";
print $a + 1 == 11.01 ? "ok 24\n" : "not ok 24\n";

$a = 1e3; "$a";
print $a + 1 == 1001  ? "ok 25\n" : "not ok 25\n";

$a = 10.01e3; "$a";
print $a + 1 == 10011 ? "ok 26\n" : "not ok 26\n";

$a = 0b100; "$a";
print $a + 1 == 0b101 ? "ok 27\n" : "not ok 27\n";

$a = 0100; "$a";
print $a + 1 == 0101  ? "ok 28\n" : "not ok 28\n";

$a = 0x100; "$a";
print $a + 1 == 0x101 ? "ok 29\n" : "not ok 29\n";

$a = 1000; "$a";
print $a + 1 == 1001  ? "ok 30\n" : "not ok 30\n";
