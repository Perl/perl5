#!./perl

#
# test the bit operators '&', '|', '^', '~', '<<', and '>>'
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..145\n";

# numerics
print ((0xdead & 0xbeef) == 0x9ead ? "ok 1\n" : "not ok 1\n");
print ((0xdead | 0xbeef) == 0xfeef ? "ok 2\n" : "not ok 2\n");
print ((0xdead ^ 0xbeef) == 0x6042 ? "ok 3\n" : "not ok 3\n");
print ((~0xdead & 0xbeef) == 0x2042 ? "ok 4\n" : "not ok 4\n");

# shifts
print ((257 << 7) == 32896 ? "ok 5\n" : "not ok 5\n");
print ((33023 >> 7) == 257 ? "ok 6\n" : "not ok 6\n");

# signed vs. unsigned
print ((~0 > 0 && do { use integer; ~0 } == -1)
       ? "ok 7\n" : "not ok 7\n");

my $bits = 0;
for (my $i = ~0; $i; $i >>= 1) { ++$bits; }
my $cusp = 1 << ($bits - 1);

print ((($cusp & -1) > 0 && do { use integer; $cusp & -1 } < 0)
       ? "ok 8\n" : "not ok 8\n");
print ((($cusp | 1) > 0 && do { use integer; $cusp | 1 } < 0)
       ? "ok 9\n" : "not ok 9\n");
print ((($cusp ^ 1) > 0 && do { use integer; $cusp ^ 1 } < 0)
       ? "ok 10\n" : "not ok 10\n");
print (((1 << ($bits - 1)) == $cusp &&
	do { use integer; 1 << ($bits - 1) } == -$cusp)
       ? "ok 11\n" : "not ok 11\n");
print ((($cusp >> 1) == ($cusp / 2) &&
       do { use integer; abs($cusp >> 1) } == ($cusp / 2))
       ? "ok 12\n" : "not ok 12\n");

$Aaz = chr(ord("A") & ord("z"));
$Aoz = chr(ord("A") | ord("z"));
$Axz = chr(ord("A") ^ ord("z"));

# short strings
print (("AAAAA" & "zzzzz") eq ($Aaz x 5) ? "ok 13\n" : "not ok 13\n");
print (("AAAAA" | "zzzzz") eq ($Aoz x 5) ? "ok 14\n" : "not ok 14\n");
print (("AAAAA" ^ "zzzzz") eq ($Axz x 5) ? "ok 15\n" : "not ok 15\n");

# long strings
$foo = "A" x 150;
$bar = "z" x 75;
$zap = "A" x 75;
# & truncates
print (($foo & $bar) eq ($Aaz x 75 ) ? "ok 16\n" : "not ok 16\n");
# | does not truncate
print (($foo | $bar) eq ($Aoz x 75 . $zap) ? "ok 17\n" : "not ok 17\n");
# ^ does not truncate
print (($foo ^ $bar) eq ($Axz x 75 . $zap) ? "ok 18\n" : "not ok 18\n");

#
print "ok \xFF\xFF\n" & "ok 19\n";
print "ok 20\n" | "ok \0\0\n";
print "o\000 \0001\000" ^ "\000k\0002\000\n";

#
print "ok \x{FF}\x{FF}\n" & "ok 22\n";
print "ok 23\n" | "ok \x{0}\x{0}\n";
print "o\x{0} \x{0}4\x{0}" ^ "\x{0}k\x{0}2\x{0}\n";

#
print "ok 25\n" if sprintf("%vd", v4095 & v801) eq 801;
print "ok 26\n" if sprintf("%vd", v4095 | v801) eq 4095;
print "ok 27\n" if sprintf("%vd", v4095 ^ v801) eq 3294;

#
print "ok 28\n" if sprintf("%vd", v4095.801.4095 & v801.4095) eq '801.801';
print "ok 29\n" if sprintf("%vd", v4095.801.4095 | v801.4095) eq '4095.4095.4095';
print "ok 30\n" if sprintf("%vd", v801.4095 ^ v4095.801.4095) eq '3294.3294.4095';
#
print "ok 31\n" if sprintf("%vd", v120.300 & v200.400) eq '72.256';
print "ok 32\n" if sprintf("%vd", v120.300 | v200.400) eq '248.444';
print "ok 33\n" if sprintf("%vd", v120.300 ^ v200.400) eq '176.188';
#
my $a = v120.300;
my $b = v200.400;
$a ^= $b;
print "ok 34\n" if sprintf("%vd", $a) eq '176.188';
my $a = v120.300;
my $b = v200.400;
$a |= $b;
print "ok 35\n" if sprintf("%vd", $a) eq '248.444';

#
# UTF8 ~ behaviour
#

my $Is_EBCDIC = (ord('A') == 193) ? 1 : 0;

my @not36;

for (0x100...0xFFF) {
  $a = ~(chr $_);
  if ($Is_EBCDIC) {
      push @not36, sprintf("%#03X", $_)
          if $a ne chr(~$_) or length($a) != 1;
  }
  else {
      push @not36, sprintf("%#03X", $_)
          if $a ne chr(~$_) or length($a) != 1 or ~$a ne chr($_);
  }
}
if (@not36) {
    print "# test 36 failed\n";
    print "not ";
}
print "ok 36\n";

my @not37;

for my $i (0xEEE...0xF00) {
  for my $j (0x0..0x120) {
    $a = ~(chr ($i) . chr $j);
    if ($Is_EBCDIC) {
        push @not37, sprintf("%#03X %#03X", $i, $j)
	    if $a ne chr(~$i).chr(~$j) or
	       length($a) != 2;
    }
    else {
        push @not37, sprintf("%#03X %#03X", $i, $j)
	    if $a ne chr(~$i).chr(~$j) or
	       length($a) != 2 or 
               ~$a ne chr($i).chr($j);
    }
  }
}
if (@not37) {
    print "# test 37 failed\n";
    print "not ";
}
print "ok 37\n";

print "not " unless ~chr(~0) eq "\0" or $Is_EBCDIC;
print "ok 38\n";

my @not39;

for my $i (0x100..0x120) {
    for my $j (0x100...0x120) {
	push @not39, sprintf("%#03X %#03X", $i, $j)
	    if ~(chr($i)|chr($j)) ne (~chr($i)&~chr($j));
    }
}
if (@not39) {
    print "# test 39 failed\n";
    print "not ";
}
print "ok 39\n";

my @not40;

for my $i (0x100..0x120) {
    for my $j (0x100...0x120) {
	push @not40, sprintf("%#03X %#03X", $i, $j)
	    if ~(chr($i)&chr($j)) ne (~chr($i)|~chr($j));
    }
}
if (@not40) {
    print "# test 40 failed\n";
    print "not ";
}
print "ok 40\n";

# More variations on 19 and 22.
print "ok \xFF\x{FF}\n" & "ok 41\n";
print "ok \x{FF}\xFF\n" & "ok 42\n";

# Tests to see if you really can do casts negative floats to unsigned properly
$neg1 = -1.0;
print ((~ $neg1 == 0) ? "ok 43\n" : "not ok 43\n");
$neg7 = -7.0;
print ((~ $neg7 == 6) ? "ok 44\n" : "not ok 44\n");

require "./test.pl";
curr_test(45);

# double magic tests

sub TIESCALAR { bless { value => $_[1], orig => $_[1] } }
sub STORE { $_[0]{store}++; $_[0]{value} = $_[1] }
sub FETCH { $_[0]{fetch}++; $_[0]{value} }
sub stores { tied($_[0])->{value} = tied($_[0])->{orig};
             delete(tied($_[0])->{store}) || 0 }
sub fetches { delete(tied($_[0])->{fetch}) || 0 }

# numeric double magic tests

tie $x, "main", 1;
tie $y, "main", 3;

is(($x | $y), 3);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x & $y), 1);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x ^ $y), 2);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x |= $y), 3);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x &= $y), 1);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x ^= $y), 2);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(~~$y, 3);
is(fetches($y), 1);
is(stores($y), 0);

{ use integer;

is(($x | $y), 3);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x & $y), 1);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x ^ $y), 2);
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x |= $y), 3);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x &= $y), 1);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x ^= $y), 2);
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(~$y, -4);
is(fetches($y), 1);
is(stores($y), 0);

} # end of use integer;

# stringwise double magic tests

tie $x, "main", "a";
tie $y, "main", "c";

is(($x | $y), ("a" | "c"));
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x & $y), ("a" & "c"));
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x ^ $y), ("a" ^ "c"));
is(fetches($x), 1);
is(fetches($y), 1);
is(stores($x), 0);
is(stores($y), 0);

is(($x |= $y), ("a" | "c"));
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x &= $y), ("a" & "c"));
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(($x ^= $y), ("a" ^ "c"));
is(fetches($x), 2);
is(fetches($y), 1);
is(stores($x), 1);
is(stores($y), 0);

is(~~$y, "c");
is(fetches($y), 1);
is(stores($y), 0);

$a = "\0\x{100}"; chop($a);
ok(utf8::is_utf8($a)); # make sure UTF8 flag is still there
$a = ~$a;
is($a, "\xFF", "~ works with utf-8");
