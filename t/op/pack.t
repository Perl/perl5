#!./perl -Tw

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;

$Is_EBCDIC = (defined $Config{ebcdic} && $Config{ebcdic} eq 'define');

my $test = 1;
sub ok {
    my($ok) = @_;

    # You have to do it this way or VMS will get confused.
    my $out = '';
    $out =  "not " unless $ok;
    $out .= "ok $test\n";
    print $out;

    $test++;
    return $ok;
}


print "1..161\n";

# Note: All test numbers in comments are off by 1 after the comment below..

$format = "c2 x5 C C x s d i l a6";
# Need the expression in here to force ary[5] to be numeric.  This avoids
# test2 failing because ary2 goes str->numeric->str and ary doesn't.
@ary = (1,-100,127,128,32767,987.654321098 / 100.0,12345,123456,"abcdef");
$foo = pack($format,@ary);
@ary2 = unpack($format,$foo);

ok($#ary == $#ary2);

$out1=join(':',@ary);
$out2=join(':',@ary2);
# Using long double NVs may introduce greater accuracy than wanted.
$out1 =~ s/:9\.87654321097999\d*:/:9.87654321098:/;
$out2 =~ s/:9\.87654321097999\d*:/:9.87654321098:/;
ok($out1 eq $out2);

ok($foo =~ /def/);

# How about counting bits?

ok( ($x = unpack("%32B*", "\001\002\004\010\020\040\100\200\377")) == 16 );

ok( ($x = unpack("%32b69", "\001\002\004\010\020\040\100\200\017")) == 12 );

ok( ($x = unpack("%32B69", "\001\002\004\010\020\040\100\200\017")) == 9 );

my $sum = 129; # ASCII
$sum = 103 if $Is_EBCDIC;

ok( ($x = unpack("%32B*", "Now is the time for all good blurfl")) == $sum );

open(BIN, "./perl") || open(BIN, "./perl.exe") || open(BIN, $^X)
    || die "Can't open ../perl or ../perl.exe: $!\n";
sysread BIN, $foo, 8192;
close BIN;

$sum = unpack("%32b*", $foo);
$longway = unpack("b*", $foo);
ok( $sum == $longway =~ tr/1/1/ );

ok( ($x = unpack("I",pack("I", 0xFFFFFFFF))) == 0xFFFFFFFF );

# check 'w'
my @x = (5,130,256,560,32000,3097152,268435455,1073741844, 2**33,
         '4503599627365785','23728385234614992549757750638446');
my $x = pack('w*', @x);
my $y = pack 'H*', '0581028200843081fa0081bd8440ffffff7f8480808014A08080800087ffffffffffdb19caefe8e1eeeea0c2e1e3e8ede1ee6e';

if ($x eq $y) {
  print "ok $test\n";
} else {
  printf "not ok $test # %s\n", unpack 'H*', $x;
}
$test++;

@y = unpack('w*', $y);
my $a;
while ($a = pop @x) {
  my $b = pop @y;
  print $a eq $b ? "ok $test\n" : "not ok $test\n$a\n$b\n"; $test++;
}

# XXX All test numbers in comments are off by 1 after this point.

@y = unpack('w2', $x);

print scalar(@y) == 2 ? "ok $test\n" : "not ok $test\n"; $test++;
print $y[1] == 130 ? "ok $test\n" : "not ok $test # $y[1]\n"; $test++;

# test exeptions
eval { $x = unpack 'w', pack 'C*', 0xff, 0xff};
print $@ ne '' ? "ok $test\n" : "not ok $test\n"; $test++;

eval { $x = unpack 'w', pack 'C*', 0xff, 0xff, 0xff, 0xff};
print $@ ne '' ? "ok $test\n" : "not ok $test\n"; $test++;

eval { $x = unpack 'w', pack 'C*', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
print $@ ne '' ? "ok $test\n" : "not ok $test\n"; $test++;

#
# test the "p" template

# literals
print((unpack("p",pack("p","foo")) eq "foo" ? "ok " : "not ok "),$test++,"\n");

# scalars
print((unpack("p",pack("p",$test)) == $test ? "ok " : "not ok "),$test++,"\n");

# temps
sub foo { my $a = "a"; return $a . $a++ . $a++ }
{
  use warnings;
  my $last = $test;
  local $SIG{__WARN__} = sub {
	print "ok ",$test++,"\n" if $_[0] =~ /temporary val/
  };
  my $junk = pack("p", &foo);
  print "not ok ", $test++, "\n" if $last == $test;
}

# undef should give null pointer
print((pack("p", undef) =~ /^\0+/ ? "ok " : "not ok "),$test++,"\n");

# Check for optimizer bug (e.g.  Digital Unix GEM cc with -O4 on DU V4.0B gives
#                                4294967295 instead of -1)
#				 see #ifdef __osf__ in pp.c pp_unpack
# Test 30:
print( ((unpack("i",pack("i",-1))) == -1 ? "ok " : "not ok "),$test++,"\n");

# 31..36: test the pack lengths of s S i I l L
print "not " unless length(pack("s", 0)) == 2;
print "ok ", $test++, "\n";

print "not " unless length(pack("S", 0)) == 2;
print "ok ", $test++, "\n";

print "not " unless length(pack("i", 0)) >= 4;
print "ok ", $test++, "\n";

print "not " unless length(pack("I", 0)) >= 4;
print "ok ", $test++, "\n";

print "not " unless length(pack("l", 0)) == 4;
print "ok ", $test++, "\n";

print "not " unless length(pack("L", 0)) == 4;
print "ok ", $test++, "\n";

# 37..40: test the pack lengths of n N v V

print "not " unless length(pack("n", 0)) == 2;
print "ok ", $test++, "\n";

print "not " unless length(pack("N", 0)) == 4;
print "ok ", $test++, "\n";

print "not " unless length(pack("v", 0)) == 2;
print "ok ", $test++, "\n";

print "not " unless length(pack("V", 0)) == 4;
print "ok ", $test++, "\n";

# 41..56: test unpack-pack lengths

my @templates = qw(c C i I s S l L n N v V f d);

# quads not supported everywhere: if not, retest floats/doubles
# to preserve the test count...
eval { my $q = pack("q",0) };
push @templates, $@ !~ /Invalid type in pack/ ? qw(q Q) : qw(f d);

foreach my $t (@templates) {
    my @t = unpack("$t*", pack("$t*", 12, 34));
    print "not "
      unless @t == 2 and (($t[0] == 12 and $t[1] == 34) or ($t =~ /[nv]/i));
    print "ok ", $test++, "\n";
}

# 57..60: uuencode/decode

# Note that first uuencoding known 'text' data and then checking the
# binary values of the uuencoded version would not be portable between
# character sets.  Uuencoding is meant for encoding binary data, not
# text data.

$in = pack 'C*', 0 .. 255;

# just to be anal, we do some random tr/`/ /
$uu = <<'EOUU';
M` $"`P0%!@<("0H+# T.#Q`1$A,4%187&!D:&QP='A\@(2(C)"4F)R@I*BLL
M+2XO,#$R,S0U-C<X.3H[/#T^/T!!0D-$149'2$E*2TQ-3D]045)35%565UA9
M6EM<75Y?8&%B8V1E9F=H:6IK;&UN;W!Q<G-T=79W>'EZ>WQ]?G^`@8*#A(6&
MAXB)BHN,C8Z/D)&2DY25EI>8F9J;G)V>GZ"AHJ.DI::GJ*FJJZRMKJ^PL;*S
MM+6VM[BYNKN\O;Z_P,'"P\3%QL?(R<K+S,W.S]#1TM/4U=;7V-G:V]S=WM_@
?X>+CY.7FY^CIZNOL[>[O\/'R\_3U]O?X^?K[_/W^_P `
EOUU

$_ = $uu;
tr/ /`/;
print "not " unless pack('u', $in) eq $_;
print "ok ", $test++, "\n";

print "not " unless unpack('u', $uu) eq $in;
print "ok ", $test++, "\n";

$in = "\x1f\x8b\x08\x08\x58\xdc\xc4\x35\x02\x03\x4a\x41\x50\x55\x00\xf3\x2a\x2d\x2e\x51\x48\xcc\xcb\x2f\xc9\x48\x2d\x52\x08\x48\x2d\xca\x51\x28\x2d\x4d\xce\x4f\x49\x2d\xe2\x02\x00\x64\x66\x60\x5c\x1a\x00\x00\x00";
$uu = <<'EOUU';
M'XL("%C<Q#4"`TI!4%4`\RHM+E%(S,LOR4@M4@A(+<I1*"U-SD])+>("`&1F
&8%P:````
EOUU

print "not " unless unpack('u', $uu) eq $in;
print "ok ", $test++, "\n";

# 60 identical to 59 except that backquotes have been changed to spaces

$uu = <<'EOUU';
M'XL("%C<Q#4" TI!4%4 \RHM+E%(S,LOR4@M4@A(+<I1*"U-SD])+>(" &1F
&8%P:
EOUU

print "not " unless unpack('u', $uu) eq $in;
print "ok ", $test++, "\n";

# 61..73: test the ascii template types (A, a, Z)

print "not " unless pack('A*', "foo\0bar\0 ") eq "foo\0bar\0 ";
print "ok ", $test++, "\n";

print "not " unless pack('A11', "foo\0bar\0 ") eq "foo\0bar\0   ";
print "ok ", $test++, "\n";

print "not " unless unpack('A*', "foo\0bar \0") eq "foo\0bar";
print "ok ", $test++, "\n";

print "not " unless unpack('A8', "foo\0bar \0") eq "foo\0bar";
print "ok ", $test++, "\n";

print "not " unless pack('a*', "foo\0bar\0 ") eq "foo\0bar\0 ";
print "ok ", $test++, "\n";

print "not " unless pack('a11', "foo\0bar\0 ") eq "foo\0bar\0 \0\0";
print "ok ", $test++, "\n";

print "not " unless unpack('a*', "foo\0bar \0") eq "foo\0bar \0";
print "ok ", $test++, "\n";

print "not " unless unpack('a8', "foo\0bar \0") eq "foo\0bar ";
print "ok ", $test++, "\n";

print "not " unless pack('Z*', "foo\0bar\0 ") eq "foo\0bar\0 \0";
print "ok ", $test++, "\n";

print "not " unless pack('Z11', "foo\0bar\0 ") eq "foo\0bar\0 \0\0";
print "ok ", $test++, "\n";

print "not " unless pack('Z3', "foo") eq "fo\0";
print "ok ", $test++, "\n";

print "not " unless unpack('Z*', "foo\0bar \0") eq "foo";
print "ok ", $test++, "\n";

print "not " unless unpack('Z8', "foo\0bar \0") eq "foo";
print "ok ", $test++, "\n";

# 74..79: packing native shorts/ints/longs

print "not " unless length(pack("s!", 0)) == $Config{shortsize};
print "ok ", $test++, "\n";

print "not " unless length(pack("i!", 0)) == $Config{intsize};
print "ok ", $test++, "\n";

print "not " unless length(pack("l!", 0)) == $Config{longsize};
print "ok ", $test++, "\n";

print "not " unless length(pack("s!", 0)) <= length(pack("i!", 0));
print "ok ", $test++, "\n";

print "not " unless length(pack("i!", 0)) <= length(pack("l!", 0));
print "ok ", $test++, "\n";

print "not " unless length(pack("i!", 0)) == length(pack("i", 0));
print "ok ", $test++, "\n";

# 80..139: pack <-> unpack bijectionism

#  80.. 84 c
foreach my $c (-128, -1, 0, 1, 127) {
    print "not " unless unpack("c", pack("c", $c)) == $c;
    print "ok ", $test++, "\n";
}

#  85.. 89: C
foreach my $C (0, 1, 127, 128, 255) {
    print "not " unless unpack("C", pack("C", $C)) == $C;
    print "ok ", $test++, "\n";
}

#  90.. 94: s
foreach my $s (-32768, -1, 0, 1, 32767) {
    print "not " unless unpack("s", pack("s", $s)) == $s;
    print "ok ", $test++, "\n";
}

#  95.. 99: S
foreach my $S (0, 1, 32767, 32768, 65535) {
    print "not " unless unpack("S", pack("S", $S)) == $S;
    print "ok ", $test++, "\n";
}

#  100..104: i
foreach my $i (-2147483648, -1, 0, 1, 2147483647) {
    print "not " unless unpack("i", pack("i", $i)) == $i;
    print "ok ", $test++, "\n";
}

# 105..109: I
foreach my $I (0, 1, 2147483647, 2147483648, 4294967295) {
    print "not " unless unpack("I", pack("I", $I)) == $I;
    print "ok ", $test++, "\n";
}

# 110..114: l
foreach my $l (-2147483648, -1, 0, 1, 2147483647) {
    print "not " unless unpack("l", pack("l", $l)) == $l;
    print "ok ", $test++, "\n";
}

# 115..119: L
foreach my $L (0, 1, 2147483647, 2147483648, 4294967295) {
    print "not " unless unpack("L", pack("L", $L)) == $L;
    print "ok ", $test++, "\n";
}

# 120..124: n
foreach my $n (0, 1, 32767, 32768, 65535) {
    print "not " unless unpack("n", pack("n", $n)) == $n;
    print "ok ", $test++, "\n";
}

# 125..129: v
foreach my $v (0, 1, 32767, 32768, 65535) {
    print "not " unless unpack("v", pack("v", $v)) == $v;
    print "ok ", $test++, "\n";
}

# 130..134: N
foreach my $N (0, 1, 2147483647, 2147483648, 4294967295) {
    print "not " unless unpack("N", pack("N", $N)) == $N;
    print "ok ", $test++, "\n";
}

# 135..139: V
foreach my $V (0, 1, 2147483647, 2147483648, 4294967295) {
    print "not " unless unpack("V", pack("V", $V)) == $V;
    print "ok ", $test++, "\n";
}

# 140..143: pack nvNV byteorders

print "not " unless pack("n", 0xdead) eq "\xde\xad";
print "ok ", $test++, "\n";

print "not " unless pack("v", 0xdead) eq "\xad\xde";
print "ok ", $test++, "\n";

print "not " unless pack("N", 0xdeadbeef) eq "\xde\xad\xbe\xef";
print "ok ", $test++, "\n";

print "not " unless pack("V", 0xdeadbeef) eq "\xef\xbe\xad\xde";
print "ok ", $test++, "\n";

# 144..152: /

# Using Test considered bad plan in op/*.t ?

sub report {
  my ($pass, $test, $err, $wrong) = @_;
  if ($pass) {
    print "ok $test\n"
  } else {
    if ($err) {
      chomp $err;
      print "not ok $test # \$\@ = $err\n";
    } else {
      $wrong =~ s/([[:cntrl:]\177 ])/sprintf "\\%03o", ord $1/ge;
      print "not ok $test # got $wrong\n";
    }
  }
}

my $z;
eval { ($x) = unpack '/a*','hello' };
print 'not ' unless $@; print "ok $test\n"; $test++;
eval { ($z,$x,$y) = unpack 'a3/A C/a* C/Z', "003ok \003yes\004z\000abc" };
print $@ eq '' && $z eq 'ok' ? "ok $test\n" : "not ok $test\n"; $test++;
print $@ eq '' && $x eq 'yes' ? "ok $test\n" : "not ok $test\n"; $test++;
print $@ eq '' && $y eq 'z' ? "ok $test\n" : "not ok $test\n"; $test++;

eval { ($x) = pack '/a*','hello' };
print 'not ' unless $@; print "ok $test\n"; $test++;
$z = pack 'n/a* N/Z* w/A*','string','hi there ','etc';
my $expect = "\000\006string\0\0\0\012hi there \000\003etc";
report ($z eq $expect, $test++, '', $z);

eval { ($x) = unpack 'a/a*/a*', '212ab345678901234567' };
print $@ eq '' && $x eq 'ab3456789012' ? "ok $test\n" : "#$x,$@\nnot ok $test\n";
$test++;

eval { ($x) = unpack 'a/a*/a*', '3012ab345678901234567' };
print $@ eq '' && $x eq 'ab3456789012' ? "ok $test\n" : "not ok $test\n";
$test++;

eval { ($x) = unpack 'a/a*/b*', '212ab' };
my $expected_x = '100001100100';
if ($Is_EBCDIC) { $expected_x = '100000010100'; }
print $@ eq '' && $x eq $expected_x ? "ok $test\n" : "#$x,$@\nnot ok $test\n";
$test++;

# 153..156: / with #

eval { ($z,$x,$y) = unpack <<EOU, "003ok \003yes\004z\000abc" };
 a3/A			# Count in ASCII
 C/a*			# Count in a C char
 C/Z			# Count in a C char but skip after \0
EOU
print $@ eq '' && $z eq 'ok' ? "ok $test\n" : "not ok $test\n"; $test++;
print $@ eq '' && $x eq 'yes' ? "ok $test\n" : "not ok $test\n"; $test++;
print $@ eq '' && $y eq 'z' ? "ok $test\n" : "not ok $test\n"; $test++;

$z = pack <<EOP,'string','etc';
  n/a*			# Count as network short
  w/A*			# Count a  BER integer
EOP
$expect = "\000\006string\003etc";
report ($z eq $expect, $test++, '', $z);

print 'not ' unless "1.20.300.4000" eq sprintf "%vd", pack("U*",1,20,300,4000);
print "ok $test\n"; $test++;
print 'not ' unless "1.20.300.4000" eq
                    sprintf "%vd", pack("  U*",1,20,300,4000);
print "ok $test\n"; $test++;
print 'not ' unless v1.20.300.4000 ne
                    sprintf "%vd", pack("C0U*",1,20,300,4000);
print "ok $test\n"; $test++;

# 160
print "not " unless join(" ", unpack("C*", chr(0x1e2)))
        eq ((ord(A) == 193) ? "156 67" : "199 162");
print "ok $test\n"; $test++;
