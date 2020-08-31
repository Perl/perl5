#!./perl

print "1..53\n";

# First test whether the number stringification works okay.
# (Testing with == would exercise the IV/NV part, not the PV.)

my $alpha = 1; "$alpha";
print $alpha eq "1"       ? "ok 1\n"  : "not ok 1 # $alpha\n";

$alpha = -1; "$alpha";
print $alpha eq "-1"      ? "ok 2\n"  : "not ok 2 # $alpha\n";

$alpha = 1.; "$alpha";
print $alpha eq "1"       ? "ok 3\n"  : "not ok 3 # $alpha\n";

$alpha = -1.; "$alpha";
print $alpha eq "-1"      ? "ok 4\n"  : "not ok 4 # $alpha\n";

$alpha = 0.1; "$alpha";
print $alpha eq "0.1"     ? "ok 5\n"  : "not ok 5 # $alpha\n";

$alpha = -0.1; "$alpha";
print $alpha eq "-0.1"    ? "ok 6\n"  : "not ok 6 # $alpha\n";

$alpha = .1; "$alpha";
print $alpha eq "0.1"     ? "ok 7\n"  : "not ok 7 # $alpha\n";

$alpha = -.1; "$alpha";
print $alpha eq "-0.1"    ? "ok 8\n"  : "not ok 8 # $alpha\n";

$alpha = 10.01; "$alpha";
print $alpha eq "10.01"   ? "ok 9\n"  : "not ok 9 # $alpha\n";

$alpha = 1e3; "$alpha";
print $alpha eq "1000"    ? "ok 10\n" : "not ok 10 # $alpha\n";

$alpha = 10.01e3; "$alpha";
print $alpha eq "10010"   ? "ok 11\n"  : "not ok 11 # $alpha\n";

$alpha = 0b100; "$alpha";
print $alpha eq "4"       ? "ok 12\n"  : "not ok 12 # $alpha\n";

$alpha = 0100; "$alpha";
print $alpha eq "64"      ? "ok 13\n"  : "not ok 13 # $alpha\n";

$alpha = 0x100; "$alpha";
print $alpha eq "256"     ? "ok 14\n" : "not ok 14 # $alpha\n";

$alpha = 1000; "$alpha";
print $alpha eq "1000"    ? "ok 15\n" : "not ok 15 # $alpha\n";

# more hex and binary tests below starting at 51

# Okay, now test the numerics.
# We may be assuming too much, given the painfully well-known floating
# point sloppiness, but the following are still quite reasonable
# assumptions which if not working would confuse people quite badly.

$alpha = 1; "$alpha"; # Keep the stringification as a potential troublemaker.
print $alpha + 1 == 2     ? "ok 16\n" : "not ok 16 #" . $alpha + 1 . "\n";
# Don't know how useful printing the stringification of $alpha + 1 really is.

$alpha = -1; "$alpha";
print $alpha + 1 == 0     ? "ok 17\n" : "not ok 17 #" . $alpha + 1 . "\n";

$alpha = 1.; "$alpha";
print $alpha + 1 == 2     ? "ok 18\n" : "not ok 18 #" . $alpha + 1 . "\n";

$alpha = -1.; "$alpha";
print $alpha + 1 == 0     ? "ok 19\n" : "not ok 19 #" . $alpha + 1 . "\n";

sub ok { # Can't assume too much of floating point numbers.
    my ($alpha, $b, $c) = @_;
    abs($alpha - $b) <= $c;
}

$alpha = 0.1; "$alpha";
print ok($alpha + 1,  1.1,  0.05)   ? "ok 20\n" : "not ok 20 #" . $alpha + 1 . "\n";

$alpha = -0.1; "$alpha";
print ok($alpha + 1,  0.9,  0.05)   ? "ok 21\n" : "not ok 21 #" . $alpha + 1 . "\n";

$alpha = .1; "$alpha";
print ok($alpha + 1,  1.1,  0.005)  ? "ok 22\n" : "not ok 22 #" . $alpha + 1 . "\n";

$alpha = -.1; "$alpha";
print ok($alpha + 1,  0.9,  0.05)   ? "ok 23\n" : "not ok 23 #" . $alpha + 1 . "\n";

$alpha = 10.01; "$alpha";
print ok($alpha + 1, 11.01, 0.005) ? "ok 24\n" : "not ok 24 #" . $alpha + 1 . "\n";

$alpha = 1e3; "$alpha";
print $alpha + 1 == 1001  ? "ok 25\n" : "not ok 25 #" . $alpha + 1 . "\n";

$alpha = 10.01e3; "$alpha";
print $alpha + 1 == 10011 ? "ok 26\n" : "not ok 26 #" . $alpha + 1 . "\n";

$alpha = 0b100; "$alpha";
print $alpha + 1 == 0b101 ? "ok 27\n" : "not ok 27 #" . $alpha + 1 . "\n";

$alpha = 0100; "$alpha";
print $alpha + 1 == 0101  ? "ok 28\n" : "not ok 28 #" . $alpha + 1 . "\n";

$alpha = 0x100; "$alpha";
print $alpha + 1 == 0x101 ? "ok 29\n" : "not ok 29 #" . $alpha + 1 . "\n";

$alpha = 1000; "$alpha";
print $alpha + 1 == 1001  ? "ok 30\n" : "not ok 30 #" . $alpha + 1 . "\n";

# back to some basic stringify tests
# we expect NV stringification to work according to C sprintf %.*g rules

if ($^O eq 'os2') { # In the long run, fix this.  For 5.8.0, deal.
    $alpha = 0.01; "$alpha";
    print $alpha eq "0.01"   || $alpha eq '1e-02' ? "ok 31\n" : "not ok 31 # $alpha\n";

    $alpha = 0.001; "$alpha";
    print $alpha eq "0.001"  || $alpha eq '1e-03' ? "ok 32\n" : "not ok 32 # $alpha\n";

    $alpha = 0.0001; "$alpha";
    print $alpha eq "0.0001" || $alpha eq '1e-04' ? "ok 33\n" : "not ok 33 # $alpha\n";
} else {
    $alpha = 0.01; "$alpha";
    print $alpha eq "0.01"    ? "ok 31\n" : "not ok 31 # $alpha\n";

    $alpha = 0.001; "$alpha";
    print $alpha eq "0.001"   ? "ok 32\n" : "not ok 32 # $alpha\n";

    $alpha = 0.0001; "$alpha";
    print $alpha eq "0.0001"  ? "ok 33\n" : "not ok 33 # $alpha\n";
}

$alpha = 0.00009; "$alpha";
print $alpha eq "9e-05" || $alpha eq "9e-005" ? "ok 34\n"  : "not ok 34 # $alpha\n";

$alpha = 1.1; "$alpha";
print $alpha eq "1.1"     ? "ok 35\n" : "not ok 35 # $alpha\n";

$alpha = 1.01; "$alpha";
print $alpha eq "1.01"    ? "ok 36\n" : "not ok 36 # $alpha\n";

$alpha = 1.001; "$alpha";
print $alpha eq "1.001"   ? "ok 37\n" : "not ok 37 # $alpha\n";

$alpha = 1.0001; "$alpha";
print $alpha eq "1.0001"  ? "ok 38\n" : "not ok 38 # $alpha\n";

$alpha = 1.00001; "$alpha";
print $alpha eq "1.00001" ? "ok 39\n" : "not ok 39 # $alpha\n";

$alpha = 1.000001; "$alpha";
print $alpha eq "1.000001" ? "ok 40\n" : "not ok 40 # $alpha\n";

$alpha = 0.; "$alpha";
print $alpha eq "0"       ? "ok 41\n" : "not ok 41 # $alpha\n";

$alpha = 100000.; "$alpha";
print $alpha eq "100000"  ? "ok 42\n" : "not ok 42 # $alpha\n";

$alpha = -100000.; "$alpha";
print $alpha eq "-100000" ? "ok 43\n" : "not ok 43 # $alpha\n";

$alpha = 123.456; "$alpha";
print $alpha eq "123.456" ? "ok 44\n" : "not ok 44 # $alpha\n";

$alpha = 1e34; "$alpha";
unless ($^O eq 'posix-bc')
{ print $alpha eq "1e+34" || $alpha eq "1e+034" ? "ok 45\n" : "not ok 45 # $alpha\n"; }
else
{ print "ok 45 # skipped on $^O\n"; }

# see bug #15073

$alpha = 0.00049999999999999999999999999999999999999;
$b = 0.0005000000000000000104;
print $alpha <= $b ? "ok 46\n" : "not ok 46\n";

if ($^O eq 'ultrix' || $^O eq 'VMS' ||
    (pack("d", 1) =~ /^[\x80\x10]\x40/)  # VAX D_FLOAT, G_FLOAT.
    ) {
  # Ultrix enters looong nirvana over this. VMS blows up when configured with
  # D_FLOAT (but with G_FLOAT or IEEE works fine).  The test should probably
  # make the number of 0's a function of NV_DIG, but that's not in Config and 
  # we probably don't want to suck Config into a base test anyway.
  print "ok 47 # skipped on $^O\n";
} else {
  $alpha = 0.00000000000000000000000000000000000000000000000000000000000000000001;
  print $alpha > 0 ? "ok 47\n" : "not ok 47\n";
}

$alpha = 80000.0000000000000000000000000;
print $alpha == 80000.0 ? "ok 48\n" : "not ok 48\n";

$alpha = 1.0000000000000000000000000000000000000000000000000000000000000000000e1;
print $alpha == 10.0 ? "ok 49\n" : "not ok 49\n";

# From Math/Trig - number has to be long enough to exceed at least DBL_DIG

$alpha = 57.295779513082320876798154814169;
print ok($alpha*10,572.95779513082320876798154814169,1e-10) ? "ok 50\n" :
  "not ok 50 # $alpha\n";

# Allow uppercase base markers (#76296)

$alpha = 0Xabcdef; "$alpha";
print $alpha eq "11259375"     ? "ok 51\n" : "not ok 51 # $alpha\n";

$alpha = 0XFEDCBA; "$alpha";
print $alpha eq "16702650"     ? "ok 52\n" : "not ok 52 # $alpha\n";

$alpha = 0B1101; "$alpha";
print $alpha eq "13"           ? "ok 53\n" : "not ok 53 # $alpha\n";
