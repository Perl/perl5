#!./perl -Tw

print "1..610\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;
use warnings;
use Config;

my $Is_EBCDIC = (defined $Config{ebcdic} && $Config{ebcdic} eq 'define');

my $test = 1;
# Using Test considered bad plan in op/*.t ?

sub encode {
  my @result = @_;
  foreach (@result) {
    s/([[:cntrl:]\177 ])/sprintf "\\%03o", ord $1/ge if defined;
  }
  @result;
}

sub encode_list {
  my @result = @_;
  foreach (@result) {
    if (defined) {
      s/([[:cntrl:]\177])/sprintf "\\%03o", ord $1/ge;
      $_ = qq("$_");
    } else {
      $_ = 'undef';
    }
  }
  if (@result == 1) {
    return @result;
  }
  return '(' . join (', ', @result) . ')';
}

sub ok {
  my ($pass, $wrong, $err) = @_;
  if ($pass) {
    print "ok $test\n";
    $test++;
    return 1;
  } else {
    if ($err) {
      chomp $err;
      print "not ok $test # \$\@ = $err\n";
    } else {
      if (defined $wrong) {
        $wrong = ", got $wrong";
      } else {
        $wrong = '';
      }
      printf "not ok $test # line %d$wrong\n", (caller)[2];
    }
  }
  $test++;
  return;
}

sub list_eq ($$) {
  my ($l, $r) = @_;
  return unless @$l == @$r;
  for my $i (0..$#$l) {
    if (defined $l->[$i]) {
      return unless defined ($r->[$i]) && $l->[$i] eq $r->[$i];
    } else {
      return if defined $r->[$i]
    }
  }
  return 1;
}

##############################################################################
#
# Here starteth the tests
#

{
my $format = "c2 x5 C C x s d i l a6";
# Need the expression in here to force ary[5] to be numeric.  This avoids
# test2 failing because ary2 goes str->numeric->str and ary doesn't.
my @ary = (1,-100,127,128,32767,987.654321098 / 100.0,12345,123456,"abcdef");
my $foo = pack($format,@ary);
my @ary2 = unpack($format,$foo);

ok($#ary == $#ary2);

my $out1=join(':',@ary);
my $out2=join(':',@ary2);
# Using long double NVs may introduce greater accuracy than wanted.
$out1 =~ s/:9\.87654321097999\d*:/:9.87654321098:/;
$out2 =~ s/:9\.87654321097999\d*:/:9.87654321098:/;
ok($out1 eq $out2);

ok($foo =~ /def/);
}
# How about counting bits?

{
my $x;
ok( ($x = unpack("%32B*", "\001\002\004\010\020\040\100\200\377")) == 16 );

ok( ($x = unpack("%32b69", "\001\002\004\010\020\040\100\200\017")) == 12 );

ok( ($x = unpack("%32B69", "\001\002\004\010\020\040\100\200\017")) == 9 );
}

{
my $sum = 129; # ASCII
$sum = 103 if $Is_EBCDIC;

my $x;
ok( ($x = unpack("%32B*", "Now is the time for all good blurfl")) == $sum );

my $foo;
open(BIN, "./perl") || open(BIN, "./perl.exe") || open(BIN, $^X)
    || die "Can't open ../perl or ../perl.exe: $!\n";
sysread BIN, $foo, 8192;
close BIN;

$sum = unpack("%32b*", $foo);
my $longway = unpack("b*", $foo);
ok( $sum == $longway =~ tr/1/1/ );
}

{
  my $x;
  ok( ($x = unpack("I",pack("I", 0xFFFFFFFF))) == 0xFFFFFFFF );
}

{
# check 'w'
my @x = (5,130,256,560,32000,3097152,268435455,1073741844, 2**33,
         '4503599627365785','23728385234614992549757750638446');
my $x = pack('w*', @x);
my $y = pack 'H*', '0581028200843081fa0081bd8440ffffff7f8480808014A08080800087ffffffffffdb19caefe8e1eeeea0c2e1e3e8ede1ee6e';

ok ($x eq $y, unpack 'H*', $x);
my @y = unpack('w*', $y);
my $a;
while ($a = pop @x) {
  my $b = pop @y;
  ok ($a eq $b, "\$a='$a' \$b='$b'");
}

@y = unpack('w2', $x);

ok (scalar(@y) == 2);
ok ($y[1] == 130, $y[1]);
}

{
  # test exeptions
  my $x;
  eval { $x = unpack 'w', pack 'C*', 0xff, 0xff};
  ok ($@ =~ /^Unterminated compressed integer/, undef, $@);

  eval { $x = unpack 'w', pack 'C*', 0xff, 0xff, 0xff, 0xff};
  ok ($@ =~ /^Unterminated compressed integer/, undef, $@);

  eval { $x = unpack 'w', pack 'C*', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  ok ($@ =~ /^Unterminated compressed integer/, undef, $@);
}

#
# test the "p" template

# literals
ok(unpack("p",pack("p","foo")) eq "foo");

# scalars
ok(unpack("p",pack("p",$test)) == $test);

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
ok (pack("p", undef) =~ /^\0+/);

# Check for optimizer bug (e.g.  Digital Unix GEM cc with -O4 on DU V4.0B gives
#                                4294967295 instead of -1)
#				 see #ifdef __osf__ in pp.c pp_unpack
# Test 30:
ok((unpack("i",pack("i",-1))) == -1, "__osf__ like bug seems to exist");

# 31..36: test the pack lengths of s S i I l L
# 37..40: test the pack lengths of n N v V
my @lengths = qw(s 2 S 2 i -4 I -4 l 4 L 4 n 2 N 4 v 2 V 4);
while (my ($format, $expect) = splice @lengths, 0, 2) {
  my $len = length(pack($format, 0));
  if ($expect > 0) {
    ok ($expect == $len, "format '$format' has length $len, expected $expect");
  } else {
    $expect = -$expect;
    ok ($len >= $expect,
        "format '$format' has length $len, expected >= $expect");
  }
}

# 41..56: test unpack-pack lengths

my @templates = qw(c C i I s S l L n N v V f d);

# quads not supported everywhere: if not, retest floats/doubles
# to preserve the test count...
eval { my $q = pack("q",0) };
push @templates, $@ !~ /Invalid type in pack/ ? qw(q Q) : qw(f d);

foreach my $t (@templates) {
    my @t = unpack("$t*", pack("$t*", 12, 34));
    ok ((@t == 2 and (($t[0] == 12 and $t[1] == 34) or ($t =~ /[nv]/i))),
        "unpack-pack length for '$t' failed; \@t=@t");
}

{
# 57..60: uuencode/decode

# Note that first uuencoding known 'text' data and then checking the
# binary values of the uuencoded version would not be portable between
# character sets.  Uuencoding is meant for encoding binary data, not
# text data.

my $in = pack 'C*', 0 .. 255;

# just to be anal, we do some random tr/`/ /
my $uu = <<'EOUU';
M` $"`P0%!@<("0H+# T.#Q`1$A,4%187&!D:&QP='A\@(2(C)"4F)R@I*BLL
M+2XO,#$R,S0U-C<X.3H[/#T^/T!!0D-$149'2$E*2TQ-3D]045)35%565UA9
M6EM<75Y?8&%B8V1E9F=H:6IK;&UN;W!Q<G-T=79W>'EZ>WQ]?G^`@8*#A(6&
MAXB)BHN,C8Z/D)&2DY25EI>8F9J;G)V>GZ"AHJ.DI::GJ*FJJZRMKJ^PL;*S
MM+6VM[BYNKN\O;Z_P,'"P\3%QL?(R<K+S,W.S]#1TM/4U=;7V-G:V]S=WM_@
?X>+CY.7FY^CIZNOL[>[O\/'R\_3U]O?X^?K[_/W^_P `
EOUU

$_ = $uu;
tr/ /`/;

ok (pack('u', $in) eq $_);

ok (unpack('u', $uu) eq $in);

$in = "\x1f\x8b\x08\x08\x58\xdc\xc4\x35\x02\x03\x4a\x41\x50\x55\x00\xf3\x2a\x2d\x2e\x51\x48\xcc\xcb\x2f\xc9\x48\x2d\x52\x08\x48\x2d\xca\x51\x28\x2d\x4d\xce\x4f\x49\x2d\xe2\x02\x00\x64\x66\x60\x5c\x1a\x00\x00\x00";
$uu = <<'EOUU';
M'XL("%C<Q#4"`TI!4%4`\RHM+E%(S,LOR4@M4@A(+<I1*"U-SD])+>("`&1F
&8%P:````
EOUU

ok unless unpack('u', $uu);

# 60 identical to 59 except that backquotes have been changed to spaces

$uu = <<'EOUU';
M'XL("%C<Q#4" TI!4%4 \RHM+E%(S,LOR4@M4@A(+<I1*"U-SD])+>(" &1F
&8%P:
EOUU

# ' # Grr
ok (unpack('u', $uu) eq $in);

}

# 61..73: test the ascii template types (A, a, Z)

foreach (
['p', 'A*', "foo\0bar\0 ", "foo\0bar\0 "],
['p', 'A11', "foo\0bar\0 ", "foo\0bar\0   "],
['u', 'A*', "foo\0bar \0", "foo\0bar"],
['u', 'A8', "foo\0bar \0", "foo\0bar"],
['p', 'a*', "foo\0bar\0 ", "foo\0bar\0 "],
['p', 'a11', "foo\0bar\0 ", "foo\0bar\0 \0\0"],
['u', 'a*', "foo\0bar \0", "foo\0bar \0"],
['u', 'a8', "foo\0bar \0", "foo\0bar "],
['p', 'Z*', "foo\0bar\0 ", "foo\0bar\0 \0"],
['p', 'Z11', "foo\0bar\0 ", "foo\0bar\0 \0\0"],
['p', 'Z3', "foo", "fo\0"],
['u', 'Z*', "foo\0bar \0", "foo"],
['u', 'Z8', "foo\0bar \0", "foo"],
) {
  my ($what, $template, $in, $out) = @$_;
  my $got = $what eq 'u' ? (unpack $template, $in) : (pack $template, $in);
  unless (ok ($got eq $out)) {
    ($in, $out, $got) = encode ($in, $out, $got);
    my $un = $what eq 'u' ? 'un' : '';
    print "# ${un}pack ('$template', \"$in\") gave $out not $got\n";
  }
}

# 74..79: packing native shorts/ints/longs

ok (length(pack("s!", 0)) == $Config{shortsize});
ok (length(pack("i!", 0)) == $Config{intsize});
ok (length(pack("l!", 0)) == $Config{longsize});
ok (length(pack("s!", 0)) <= length(pack("i!", 0)));
ok (length(pack("i!", 0)) <= length(pack("l!", 0)));
ok (length(pack("i!", 0)) == length(pack("i", 0)));

sub numbers {
  my $format = shift;
  return numbers_with_total ($format, undef, @_);
}

sub numbers_with_total {
  my $format = shift;
  my $total = shift;
  if (!defined $total) {
    foreach (@_) {
      $total += $_;
    }
  }
  foreach (@_) {
    my $out = eval {unpack($format, pack($format, $_))};
    if ($@ =~ /Invalid type in pack: '$format'/) {
      print "ok $test # skip cannot pack '$format' on this perl\n";
    } elsif ($out == $_) {
      print "ok $test\n";
    } else {
      print "not ok $test # unpack '$format', pack '$format', $_ gives $out\n";
      print "# \$\@='$@'\n" if $@;
    }
    $test++;
  }

  my $skip_if_longer_than = ~0; # "Infinity"
  if (~0 - 1 == ~0) {
    # If we're running with -DNO_PERLPRESERVE_IVUV and NVs don't preserve all
    # UVs (in which case ~0 is NV, ~0-1 will be the same NV) then we can't
    # correctly in perl calculate UV totals for long checksums, as pp_unpack
    # is using UV maths, and we've only got NVs.
    $skip_if_longer_than = $Config{d_nv_preserves_uv_bits};
  }

  foreach ('', 1, 2, 3, 15, 16, 17, 31, 32, 33, 53, 54, 63, 64, 65) {
    my $sum = eval {unpack "%$_$format*", pack "$format*", @_};
    if (!defined $sum) {
      if ($@ =~ /Invalid type in pack: '$format'/) {
        print "ok $test # skip cannot pack '$format' on this perl\n";
      } else {
        print "not ok $test # \$\@='$@'\n" if $@;
      }
      next;
    }
    my $len = $_; # Copy, so that we can reassign ''
    $len = 16 unless length $len;

    if ($len > $skip_if_longer_than) {
      print "ok $test # skip cannot test checksums over $skip_if_longer_than "
        ."bits for this perl (compiled with -DNO_PERLPRESERVE_IVUV)\n";
      next;
    }

    # Our problem with testing this portably is that the checksum code in
    # pp_unpack is able to cast signed to unsigned, and do modulo 2**n
    # arithmetic in unsigned ints, which perl has no operators to do.
    # (use integer; does signed ints, which won't wrap on UTS, which is just
    # fine with ANSI, but not with most people's assumptions.
    # This is why we need to supply the totals for 'Q' as there's no way in
    # perl to calculate them, short of unpack '%0Q' (is that documented?)
    # ** returns NVs; make sure it's IV.
    my $max = 1 + 2 * (int (2 ** ($len-1))-1); # The maximum possible checksum
    my $max_p1 = $max + 1;
    my ($max_is_integer, $max_p1_is_integer);
    $max_p1_is_integer = 1 unless $max_p1 + 1 == $max_p1;
    $max_is_integer = 1 if $max - 1 < ~0;

    my $calc_sum;
    if ($total =~ /^0b[01]*?([01]{1,$len})/) {
      no warnings qw(overflow portable);
      $calc_sum = oct "0b$1";
    } else {
      $calc_sum = $total;
      # Shift into range by some multiple of the total
      my $mult = int ($total / $max_p1);
      # Need this to make sure that -1 + (~0+1) is ~0 (ie still integer)
      $calc_sum = $total - $mult;
      $calc_sum -= $mult * $max;
      if ($calc_sum < 0) {
        $calc_sum += 1;
        $calc_sum += $max;
      }
    }
    if ($calc_sum == $calc_sum - 1 && $calc_sum == $max_p1) {
      # we're into floating point (either by getting out of the range of
      # UV arithmetic, or because we're doing a floating point checksum) and
      # our calculation of the checksum has become rounded up to
      # max_checksum + 1
      $calc_sum = 0;
    }

    if ($calc_sum == $sum) {
      print "ok $test # unpack '%$_$format' gave $sum\n";
    } else {
      my $delta = 1.000001;
      if ($format =~ tr /dDfF//
          && ($calc_sum <= $sum * $delta && $calc_sum >= $sum / $delta)) {
        print "ok $test # unpack '%$_$format' gave $sum,"
          . " expected $calc_sum\n";
      } else {
        print "not ok $test # For list (" . join (", ", @_) . ") (total $total)"
          . " packed with $format unpack '%$_$format' gave $sum,"
            . " expected $calc_sum\n";
      }
    }
  } continue {
    $test++;
  }
}

numbers ('c', -128, -1, 0, 1, 127);
numbers ('C', 0, 1, 127, 128, 255);
numbers ('s', -32768, -1, 0, 1, 32767);
numbers ('S', 0, 1, 32767, 32768, 65535);
numbers ('i', -2147483648, -1, 0, 1, 2147483647);
numbers ('I', 0, 1, 2147483647, 2147483648, 4294967295);
numbers ('l', -2147483648, -1, 0, 1, 2147483647);
numbers ('L', 0, 1, 2147483647, 2147483648, 4294967295);
numbers ('s!', -32768, -1, 0, 1, 32767);
numbers ('S!', 0, 1, 32767, 32768, 65535);
numbers ('i!', -2147483648, -1, 0, 1, 2147483647);
numbers ('I!', 0, 1, 2147483647, 2147483648, 4294967295);
numbers ('l!', -2147483648, -1, 0, 1, 2147483647);
numbers ('L!', 0, 1, 2147483647, 2147483648, 4294967295);
numbers ('n', 0, 1, 32767, 32768, 65535);
numbers ('v', 0, 1, 32767, 32768, 65535);
numbers ('N', 0, 1, 2147483647, 2147483648, 4294967295);
numbers ('V', 0, 1, 2147483647, 2147483648, 4294967295);
# All these should have exact binary representations:
numbers ('f', -1, 0, 0.5, 42, 2**34);
numbers ('d', -(2**34), -1, 0, 1, 2**34);
## These don't, but 'd' is NV.  XXX wrong, it's double
#numbers ('d', -1, 0, 1, 1-exp(-1), -exp(1));

numbers_with_total ('q', -1,
                    -9223372036854775808, -1, 0, 1,9223372036854775807);
# This total is icky, but need a way to express 2**65-1 that is going to
# work independant of whether NVs can preserve 65 bits.
# (long double is 128 bits on sparc, so they certianly can)
numbers_with_total ('Q', "0b" . "1" x 65,
                    0, 1,9223372036854775807, 9223372036854775808,
                    18446744073709551615);

# pack nvNV byteorders

ok (pack("n", 0xdead) eq "\xde\xad");
ok (pack("v", 0xdead) eq "\xad\xde");
ok (pack("N", 0xdeadbeef) eq "\xde\xad\xbe\xef");
ok (pack("V", 0xdeadbeef) eq "\xef\xbe\xad\xde");

{
  # /

  my ($x, $y, $z);
  eval { ($x) = unpack '/a*','hello' };
  ok ($@ =~ m!/ must follow a numeric type!, undef, $@);
  eval { ($z,$x,$y) = unpack 'a3/A C/a* C/Z', "003ok \003yes\004z\000abc" };
  ok ($z eq 'ok');
  ok ($x eq 'yes');
  ok ($y eq 'z');
  ok ($@ eq '', undef, $@);

  eval { ($x) = pack '/a*','hello' };
  ok ($@ =~ m!Invalid type in pack: '/'!, undef, $@);

  $z = pack 'n/a* N/Z* w/A*','string','hi there ','etc';
  my $expect = "\000\006string\0\0\0\012hi there \000\003etc";
  unless (ok ($z eq $expect)) {
    printf "# got '%s'\n", encode $z;
  }

  $expect = 'hello world';
  eval { ($x) = unpack ("w/a", chr (11) . "hello world!")};
  ok ($x eq $expect);
  ok ($@ eq '', undef, $@);
  # Doing this in scalar context used to fail.
  eval { $x = unpack ("w/a", chr (11) . "hello world!")};
  unless (ok ($x eq $expect, undef, $@)) {
    printf "# expected '$expect' got '%s'\n", encode $x;
  }
  ok ($@ eq '', undef, $@);

  foreach (
['a/a*/a*', '212ab345678901234567','ab3456789012'],
['a/a*/a*', '3012ab345678901234567', 'ab3456789012'],
['a/a*/b*', '212ab', $Is_EBCDIC ? '100000010100' : '100001100100'],
) {
    my ($pat, $in, $expect) = @$_;
    eval { ($x) = unpack $pat, $in };
    ok ($@ eq '' && $x eq $expect, undef, $@)
      or printf "# list unpack ('$pat', '$in') gave %s, expected '$expect'\n",
      encode_list ($x);
    eval { $x = unpack $pat, $in };
    ok ($@ eq '' && $x eq $expect, undef, $@)
      or printf "# scalar unpack ('$pat', '$in') gave %s, expected '$expect'\n",
      encode_list ($x);
  }

# / with #

eval { ($z,$x,$y) = unpack <<EOU, "003ok \003yes\004z\000abc" };
 a3/A			# Count in ASCII
 C/a*			# Count in a C char
 C/Z			# Count in a C char but skip after \0
EOU
  ok ($z eq 'ok');
  ok ($x eq 'yes');
  ok ($y eq 'z');
  ok ($@ eq '', undef, $@);

$z = pack <<EOP,'string','etc';
  n/a*			# Count as network short
  w/A*			# Count a  BER integer
EOP
  $expect = "\000\006string\003etc";
unless (ok ($z eq $expect)) {
  $z = encode $z;
  print "# got '$z', expected '$expect'\n";
}
}

ok ("1.20.300.4000" eq sprintf "%vd", pack("U*",1,20,300,4000));
ok ("1.20.300.4000" eq sprintf "%vd", pack("  U*",1,20,300,4000));
ok (v1.20.300.4000 ne sprintf "%vd", pack("C0U*",1,20,300,4000));

ok (join(" ", unpack("C*", chr(0x1e2))) eq ((ord("A") == 193) ? "156 67"
                                            : "199 162"));

# does pack U create Unicode?
ok (ord(pack('U', 300)) == 300);

# does unpack U deref Unicode?
ok ((unpack('U', chr(300)))[0] == 300);

# is unpack U the reverse of pack U for Unicode string?
ok ("@{[unpack('U*', pack('U*', 100, 200, 300))]}" eq "100 200 300");

# is unpack U the reverse of pack U for byte string?
ok ("@{[unpack('U*', pack('U*', 100, 200))]}" eq "100 200");

# does unpack C unravel pack U?
ok ("@{[unpack('C*', pack('U*', 100, 200))]}" eq "100 195 136");

# does pack U0C create Unicode?
ok ("@{[pack('U0C*', 100, 195, 136)]}" eq v100.v200);

# does pack C0U create characters?
ok ("@{[pack('C0U*', 100, 200)]}" eq pack("C*", 100, 195, 136));

# does unpack U0U on byte data warn?
{
    local $SIG{__WARN__} = sub { $@ = "@_" };
    my @null = unpack('U0U', chr(255));
    ok ($@ =~ /^Malformed UTF-8 character /, undef, $@);
}

{
  my $p = pack 'i*', -2147483648, ~0, 0, 1, 2147483647;
  my (@a);
  # bug - % had to be at the start of the pattern, no leading whitespace or
  # comments. %i! didn't work at all.
  foreach my $pat ('%32i*', ' %32i*', "# Muhahahaha\n%32i*", '%32i*  ',
                   '%32i!*', ' %32i!*', "\n#\n#\n\r \t\f%32i!*", '%32i!*#') {
    @a = unpack $pat, $p;
    ok ($a[0] == 0xFFFFFFFF, "$pat failed");
    @a = scalar unpack $pat, $p;
    ok ($a[0] == 0xFFFFFFFF, "$pat failed in scalar context");
  }


  $p = pack 'I*', 42, 12;
  # Multiline patterns in scalar context failed.
  foreach my $pat ('I', <<EOPOEMSNIPPET, 'I#I', 'I # I', 'I # !!!') {
# On the Ning Nang Nong
# Where the Cows go Bong!
# And the Monkeys all say Boo!
I
EOPOEMSNIPPET
  @a = unpack $pat, $p;
  ok (@a == 1 && $a[0] == 42);
  @a = scalar unpack $pat, $p;
  ok (@a == 1 && $a[0] == 42);
}

  # shorts (of all flavours) didn't calculate checksums > 32 bits with floating
  # point, so a pathologically long pattern would wrap at 32 bits.
  my $pat = "\xff\xff"x65538; # Start with it long, to save any copying.
  foreach (4,3,2,1,0) {
    my $len = 65534 + $_;
    ok (unpack ("%33n$len", $pat) == 65535 * $len);
  }
}


# pack x X @
foreach (
['x', "N", "\0"],
['x4', "N", "\0"x4],
['xX', "N", ""],
['xXa*', "Nick", "Nick"],
['a5Xa5', "cameL", "llama", "camellama"],
['@4', 'N', "\0"x4],
['a*@8a*', 'Camel', 'Dromedary', "Camel\0\0\0Dromedary"],
['a*@4a', 'Perl rules', '!', 'Perl!'],
) {
  my ($template, @in) = @$_;
  my $out = pop @in;
  my $got = eval {pack $template, @in};
  ok ($@ eq '' and $out eq $got, '', $@)
    or printf "# pack ('$template', %s) gave %s expected %s\n",
    encode_list (@in), encode_list ($got), encode_list ($out);
}

# unpack x X @
foreach (
['x', "N"],
['xX', "N"],
['xXa*', "Nick", "Nick"],
['a5Xa5', "camellama", "camel", "llama"],
['@3', "ice"],
['@2a2', "water", "te"],
['a*@1a3', "steam", "steam", "tea"],
) {
  my ($template, $in, @out) = @$_;
  my @got = eval {unpack $template, $in};
  ok (($@ eq '' and list_eq (\@got, \@out)), undef, $@)
    or printf "# list unpack ('$template', \"%s\") gave %s expected %s\n",
    encode ($in), encode_list (@got), encode_list (@out);

  my $got = eval {unpack $template, $in};
  ok (($@ eq '' and @out ? $got eq $out[0] # 1 or more items; should get first
       : !defined $got) # 0 items; should get undef
      , "", $@)
    or printf "# scalar unpack ('$template', \"%s\") gave %s expected %s\n",
    encode ($in), encode_list ($got), encode_list ($out[0]);
}
