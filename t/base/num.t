#!./perl

print "1..30\n";

# First test whether the number stringification works okay.
# (Testing with == would exercize the IV/NV part, not the PV.)

$a = 1; "$a";
print $a eq "1"       ? "ok 1\n"  : "not ok 1 # $a\n";

$a = -1; "$a";
print $a eq "-1"      ? "ok 2\n"  : "not ok 2 # $a\n";

$a = 1.; "$a";
print $a eq "1"       ? "ok 3\n"  : "not ok 3 # $a\n";

$a = -1.; "$a";
print $a eq "-1"      ? "ok 4\n"  : "not ok 4 # $a\n";

$a = 0.1; "$a";
print $a eq "0.1"     ? "ok 5\n"  : "not ok 5 # $a\n";

$a = -0.1; "$a";
print $a eq "-0.1"    ? "ok 6\n"  : "not ok 6 # $a\n";

$a = .1; "$a";
print $a eq "0.1"     ? "ok 7\n"  : "not ok 7 # $a\n";

$a = -.1; "$a";
print $a eq "-0.1"    ? "ok 8\n"  : "not ok 8 # $a\n";

$a = 10.01; "$a";
print $a eq "10.01"   ? "ok 9\n"  : "not ok 9 # $a\n";

$a = 1e3; "$a";
print $a eq "1000"    ? "ok 10\n" : "not ok 10 # $a\n";

$a = 10.01e3; "$a";
print $a eq "10010"   ? "ok 11\n"  : "not ok 11 # $a\n";

$a = 0b100; "$a";
print $a eq "4"       ? "ok 12\n"  : "not ok 12 # $a\n";

$a = 0100; "$a";
print $a eq "64"      ? "ok 13\n"  : "not ok 13 # $a\n";

$a = 0x100; "$a";
print $a eq "256"     ? "ok 14\n" : "not ok 14 # $a\n";

$a = 1000; "$a";
print $a eq "1000"    ? "ok 15\n" : "not ok 15 # $a\n";

# Okay, now test the numerics.
# We may be assuming too much, given the painfully well-known floating
# point sloppiness, but the following are still quite reasonable
# assumptions which if not working would confuse people quite badly.

$a = 1; "$a"; # Keep the stringification as a potential troublemaker.
print $a + 1 == 2     ? "ok 16\n" : "not ok 16 #" . $a + 1 . "\n";
# Don't know how useful printing the stringification of $a + 1 really is.

$a = -1; "$a";
print $a + 1 == 0     ? "ok 17\n" : "not ok 17 #" . $a + 1 . "\n";

$a = 1.; "$a";
print $a + 1 == 2     ? "ok 18\n" : "not ok 18 #" . $a + 1 . "\n";

$a = -1.; "$a";
print $a + 1 == 0     ? "ok 19\n" : "not ok 19 #" . $a + 1 . "\n";

sub ok { # Can't assume too much of floating point numbers.
    my ($a, $b, $c);
    abs($a - $b) <= $c;
}

$a = 0.1; "$a";
print ok($a + 1,  1.1,  0.05)   ? "ok 20\n" : "not ok 20 #" . $a + 1 . "\n";

$a = -0.1; "$a";
print ok($a + 1,  0.9,  0.05)   ? "ok 21\n" : "not ok 21 #" . $a + 1 . "\n";

$a = .1; "$a";
print ok($a + 1,  1.1,  0.005)  ? "ok 22\n" : "not ok 22 #" . $a + 1 . "\n";

$a = -.1; "$a";
print ok($a + 1,  0.9,  0.05)   ? "ok 23\n" : "not ok 23 #" . $a + 1 . "\n";

$a = 10.01; "$a";
print ok($a + 1, 11.01, 0.005) ? "ok 24\n" : "not ok 24 #" . $a + 1 . "\n";

$a = 1e3; "$a";
print $a + 1 == 1001  ? "ok 25\n" : "not ok 25 #" . $a + 1 . "\n";

$a = 10.01e3; "$a";
print $a + 1 == 10011 ? "ok 26\n" : "not ok 26 #" . $a + 1 . "\n";

$a = 0b100; "$a";
print $a + 1 == 0b101 ? "ok 27\n" : "not ok 27 #" . $a + 1 . "\n";

$a = 0100; "$a";
print $a + 1 == 0101  ? "ok 28\n" : "not ok 28 #" . $a + 1 . "\n";

$a = 0x100; "$a";
print $a + 1 == 0x101 ? "ok 29\n" : "not ok 29 #" . $a + 1 . "\n";

$a = 1000; "$a";
print $a + 1 == 1001  ? "ok 30\n" : "not ok 30 #" . $a + 1 . "\n";
