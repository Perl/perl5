#!./perl

# tests 51 onwards aren't all warnings clean. (intentionally)

require './test.pl';

plan(tests => 77);

sub test ($$$) {
  my ($act, $string, $value) = @_;
  my $result;
  if ($act eq 'oct') {
    $result = oct $string;
  } elsif ($act eq 'hex') {
    $result = hex $string;
  } else {
    die "Unknown action 'act'";
  }
  my $desc = ($^O ne 'VMS' || length $string <= 256) && "$act \"$string\"";

  unless (cmp_ok($value, '==', $result, $desc)) {
    my ($valstr, $resstr);
    if ($act eq 'hex' or $string =~ /x/i) {
      $valstr = sprintf "0x%X", $value;
      $resstr = sprintf "0x%X", $result;
    } elsif ($string =~ /b/i) {
      $valstr = sprintf "0b%b", $value;
      $resstr = sprintf "0b%b", $result;
    } else {
      $valstr = sprintf "0%o", $value;
      $resstr = sprintf "0%o", $result;
    }
    diag("$act \"$string\" gives \"$result\" ($resstr), not $value ($valstr)\n");
  }
}

test ('oct', '0b1_0101', 0b101_01);
test ('oct', '0b10_101', 0_2_5);
test ('oct', '0b101_01', 2_1);
test ('oct', '0b1010_1', 0x1_5);

test ('oct', 'b1_0101', 0b10101);
test ('oct', 'b10_101', 025);
test ('oct', 'b101_01', 21);
test ('oct', 'b1010_1', 0x15);

test ('oct', '01_234', 0b10_1001_1100);
test ('oct', '012_34', 01234);
test ('oct', '0123_4', 668);
test ('oct', '01234', 0x29c);

test ('oct', '0x1_234', 0b10010_00110100);
test ('oct', '0x12_34', 01_1064);
test ('oct', '0x123_4', 4660);
test ('oct', '0x1234', 0x12_34);

test ('oct', 'x1_234', 0b100100011010_0);
test ('oct', 'x12_34', 0_11064);
test ('oct', 'x123_4', 4660);
test ('oct', 'x1234', 0x_1234);

test ('hex', '01_234', 0b_1001000110100);
test ('hex', '012_34', 011064);
test ('hex', '0123_4', 4660);
test ('hex', '01234_', 0x1234);

test ('hex', '0x_1234', 0b1001000110100);
test ('hex', '0x1_234', 011064);
test ('hex', '0x12_34', 4660);
test ('hex', '0x1234_', 0x1234);

test ('hex', 'x_1234', 0b1001000110100);
test ('hex', 'x12_34', 011064);
test ('hex', 'x123_4', 4660);
test ('hex', 'x1234_', 0x1234);

test ('oct', '0b1111_1111_1111_1111_1111_1111_1111_1111', 4294967295);
test ('oct', '037_777_777_777', 4294967295);
test ('oct', '0xffff_ffff', 4294967295);
test ('hex', '0xff_ff_ff_ff', 4294967295);

$_ = "\0_7_7";
is(length, 5);
is($_, "\0"."_"."7"."_"."7");
chop, chop, chop, chop;
is($_, "\0");
if (ord("\t") != 9) {
    # question mark is 111 in 1047, 037, && POSIX-BC
    is("\157_", "?_");
}
else {
    is("\077_", "?_");
}

$_ = "\x_7_7";
is(length, 5);
is($_, "\0"."_"."7"."_"."7");
chop, chop, chop, chop;
is($_, "\0");
if (ord("\t") != 9) {
    # / is 97 in 1047, 037, && POSIX-BC
    is("\x61_", "/_");
}
else {
    is("\x2F_", "/_");
}

test ('oct', '0b'.(  '0'x10).'1_0101', 0b101_01);
test ('oct', '0b'.( '0'x100).'1_0101', 0b101_01);
test ('oct', '0b'.('0'x1000).'1_0101', 0b101_01);

test ('hex', (  '0'x10).'01234', 0x1234);
test ('hex', ( '0'x100).'01234', 0x1234);
test ('hex', ('0'x1000).'01234', 0x1234);

# Things that perl 5.6.1 and 5.7.2 did wrong (plus some they got right)
test ('oct', "b00b0101", 0);
test ('oct', "bb0101",	 0);
test ('oct', "0bb0101",	 0);

test ('oct', "0x0x3A",	 0);
test ('oct', "0xx3A",	 0);
test ('oct', "x0x3A",	 0);
test ('oct', "xx3A",	 0);
test ('oct', "0x3A",	 0x3A);
test ('oct', "x3A",	 0x3A);

test ('oct', "0x0x4",	 0);
test ('oct', "0xx4",	 0);
test ('oct', "x0x4",	 0);
test ('oct', "xx4",	 0);
test ('oct', "0x4",	 4);
test ('oct', "x4",	 4);

test ('hex', "0x3A",	 0x3A);
test ('hex', "x3A",	 0x3A);

test ('hex', "0x4",	 4);
test ('hex', "x4",	 4);

eval '$a = oct "10\x{100}"';
like($@, qr/Wide character/);

eval '$a = hex "ab\x{100}"';
like($@, qr/Wide character/);

# Allow uppercase base markers (#76296)

test ('hex', "0XCAFE",   0xCAFE);
test ('hex', "XCAFE",    0xCAFE);
test ('oct', "0XCAFE",   0xCAFE);
test ('oct', "XCAFE",    0xCAFE);
test ('oct', "0B101001", 0b101001);
test ('oct', "B101001",  0b101001);
