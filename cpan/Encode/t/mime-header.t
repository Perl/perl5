#
# $Id: mime-header.t,v 2.12 2016/04/11 07:17:02 dankogai Exp dankogai $
# This script is written in utf8
#
BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    if (ord("A") == 193) {
    print "1..0 # Skip: EBCDIC\n";
    exit 0;
    }
    $| = 1;
}

use strict;

use utf8;
use charnames ":full";

use Test::More tests => 130;
use_ok("Encode::MIME::Header");

my @decode_tests = (
    # RFC2047 p.5
    "=?iso-8859-1?q?this=20is=20some=20text?=" => "this is some text",
    # RFC2047 p.10
    "=?US-ASCII?Q?Keith_Moore?=" => "Keith Moore",
    "=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=" => "Keld Jørn Simonsen",
    "=?ISO-8859-1?Q?Andr=E9?= Pirard" => "André Pirard",
    "=?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=\r\n =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=" => "If you can read this you understand the example.",
    "=?ISO-8859-1?Q?Olle_J=E4rnefors?=" => "Olle Järnefors",
    "=?ISO-8859-1?Q?Patrik_F=E4ltstr=F6m?=" => "Patrik Fältström",
    # RFC2047 p.11
    "(=?iso-8859-8?b?7eXs+SDv4SDp7Oj08A==?=)" => "(םולש ןב ילטפנ)",
    "(=?ISO-8859-1?Q?a?=)" => "(a)",
    "(=?ISO-8859-1?Q?a?= b)" => "(a b)",
    "(=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?b?=)" => "(ab)",
    "(=?ISO-8859-1?Q?a?=  =?ISO-8859-1?Q?b?=)" => "(ab)",
    "(=?ISO-8859-1?Q?a?=\r\n\t=?ISO-8859-1?Q?b?=)" => "(ab)",
    # RFC2047 p.12
    "(=?ISO-8859-1?Q?a_b?=)" => '(a b)',
    "(=?ISO-8859-1?Q?a?= =?ISO-8859-2?Q?_b?=)" => "(a b)",
    # RFC2231 p.6
    "=?US-ASCII*EN?Q?Keith_Moore?=" => "Keith Moore",
    # others
    "=?US-ASCII*en-US?Q?Keith_Moore?=" => "Keith Moore",
    "=?ISO-8859-1*da-DK?Q?Keld_J=F8rn_Simonsen?=" => "Keld Jørn Simonsen",
    "=?ISO-8859-1*fr-BE?Q?Andr=E9?= Pirard" => "André Pirard",
    "=?ISO-8859-1*en?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?= =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=" => "If you can read this you understand the example.",
    # RT67569
    "foo =?us-ascii?q?bar?=" => "foo bar",
    "foo\r\n =?us-ascii?q?bar?=" => "foo bar",
    "=?us-ascii?q?foo?= bar" => "foo bar",
    "=?us-ascii?q?foo?=\r\n bar" => "foo bar",
    "foo bar" => "foo bar",
    "foo\r\n bar" => "foo bar",
    "=?us-ascii?q?foo?= =?us-ascii?q?bar?=" => "foobar",
    "=?us-ascii?q?foo?=\r\n =?us-ascii?q?bar?=" => "foobar",
    "=?us-ascii?q?foo bar?=" => "=?us-ascii?q?foo bar?=",
    "=?us-ascii?q?foo\r\n bar?=" => "=?us-ascii?q?foo bar?=",
    # RT40027
    "a: b\r\n c" => "a: b c",
    # RT104422
    "=?utf-8?Q?pre?= =?utf-8?B?IGZvbw==?=\r\n =?utf-8?Q?bar?=" => "pre foobar",
);

my @decode_default_tests = (
    @decode_tests,
    '=?us-ascii?q?foo=20=3cbar=40baz=2efoo=3e=20bar?=' => 'foo <bar@baz.foo> bar',
    '"=?us-ascii?q?foo=20=3cbar=40baz=2efoo=3e=20bar?="' => '"foo <bar@baz.foo> bar"',
    "=?us-ascii?q?foo?==?us-ascii?q?bar?=" => "foobar",
    "foo=?us-ascii?q?bar?=" => "foobar",
    "foo =?us-ascii?q?=20?==?us-ascii?q?bar?=" => "foo  bar",
    # Encode::MIME::Header pre 2.83
    "[=?UTF-8?B?ZsOzcnVt?=]=?UTF-8?B?IHNwcsOhdmE=?=" => "[fórum] správa",
    "test:=?UTF-8?B?IHNwcsOhdmE=?=" => "test: správa",
    "=?UTF-8?B?dMOpc3Q=?=:=?UTF-8?B?IHNwcsOhdmE=?=", "tést: správa",
);

my @decode_strict_tests = (
    @decode_tests,
    '=?us-ascii?q?foo=20=3cbar=40baz=2efoo=3e=20bar?=' => 'foo <bar@baz.foo> bar',
    '"=?us-ascii?q?foo=20=3cbar=40baz=2efoo=3e=20bar?="' => '"=?us-ascii?q?foo=20=3cbar=40baz=2efoo=3e=20bar?="',
);

my @encode_tests = (
    "小飼 弾" => "=?UTF-8?B?5bCP6aO8IOW8vg==?=", "=?UTF-8?Q?=E5=B0=8F=E9=A3=BC_=E5=BC=BE?=",
    "漢字、カタカナ、ひらがなを含む、非常に長いタイトル行が一体全体どのようにしてEncodeされるのか？" => "=?UTF-8?B?5ryi5a2X44CB44Kr44K/44Kr44OK44CB44Gy44KJ44GM44Gq44KS5ZCr44KA?=\r\n =?UTF-8?B?44CB6Z2e5bi444Gr6ZW344GE44K/44Kk44OI44Or6KGM44GM5LiA5L2T5YWo?=\r\n =?UTF-8?B?5L2T44Gp44Gu44KI44GG44Gr44GX44GmRW5jb2Rl44GV44KM44KL44Gu44GL?=\r\n =?UTF-8?B?77yf?=", "=?UTF-8?Q?=E6=BC=A2=E5=AD=97=E3=80=81=E3=82=AB=E3=82=BF=E3=82=AB=E3=83=8A?=\r\n =?UTF-8?Q?=E3=80=81=E3=81=B2=E3=82=89=E3=81=8C=E3=81=AA=E3=82=92=E5=90=AB?=\r\n =?UTF-8?Q?=E3=82=80=E3=80=81=E9=9D=9E=E5=B8=B8=E3=81=AB=E9=95=B7=E3=81=84?=\r\n =?UTF-8?Q?=E3=82=BF=E3=82=A4=E3=83=88=E3=83=AB=E8=A1=8C=E3=81=8C=E4=B8=80?=\r\n =?UTF-8?Q?=E4=BD=93=E5=85=A8=E4=BD=93=E3=81=A9=E3=81=AE=E3=82=88=E3=81=86?=\r\n =?UTF-8?Q?=E3=81=AB=E3=81=97=E3=81=A6Encode=E3=81=95=E3=82=8C=E3=82=8B?=\r\n =?UTF-8?Q?=E3=81=AE=E3=81=8B=EF=BC=9F?=",
    # double encode
    "What is =?UTF-8?B?w4RwZmVs?= ?" => "=?UTF-8?B?V2hhdCBpcyA9P1VURi04P0I/dzRSd1ptVnM/PSA/?=", "=?UTF-8?Q?What_is_=3D=3FUTF-8=3FB=3Fw4RwZmVs=3F=3D_=3F?=",
    # pound 1024
    "\N{POUND SIGN}1024" => "=?UTF-8?B?wqMxMDI0?=", "=?UTF-8?Q?=C2=A31024?=",
    # latin1 characters
    "\x{fc}" => "=?UTF-8?B?w7w=?=", "=?UTF-8?Q?=C3=BC?=",
    # RT42627
    Encode::decode_utf8("\x{c2}\x{a3}xxxxxxxxxxxxxxxxxxx0") => "=?UTF-8?B?wqN4eHh4eHh4eHh4eHh4eHh4eHh4MA==?=", "=?UTF-8?Q?=C2=A3xxxxxxxxxxxxxxxxxxx0?=",
    # RT87831
    "0" => "=?UTF-8?B?MA==?=", "=?UTF-8?Q?0?=",
    # RT88717
    "Hey foo\x{2024}bar:whee" => "=?UTF-8?B?SGV5IGZvb+KApGJhcjp3aGVl?=", "=?UTF-8?Q?Hey_foo=E2=80=A4bar=3Awhee?=",
    # valid q chars
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz !*+-/" => "=?UTF-8?B?MDEyMzQ1Njc4OUFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaYWJjZGVmZ2hpams=?=\r\n =?UTF-8?B?bG1ub3BxcnN0dXZ3eHl6ICEqKy0v?=", "=?UTF-8?Q?0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_?=\r\n =?UTF-8?Q?!*+-/?=",
    # invalid q chars
    "." => "=?UTF-8?B?Lg==?=", "=?UTF-8?Q?=2E?=",
    "," => "=?UTF-8?B?LA==?=", "=?UTF-8?Q?=2C?=",
);

sub info {
    my ($str) = @_;
    $str = Encode::encode_utf8($str);
    $str =~ s/\r/\\r/gs;
    $str =~ s/\n/\\n/gs;
    return $str;
}

my @splice;

@splice = @encode_tests;
while (my ($d, $b, $q) = splice @splice, 0, 3) {
    is Encode::encode('MIME-Header', $d) => $b, info("encode default: $d => $b");
    is Encode::encode('MIME-B', $d) => $b, info("encode base64: $d => $b");
    is Encode::encode('MIME-Q', $d) => $q, info("encode qp: $d => $q");
    is Encode::decode('MIME-B', $b) => $d, info("decode base64: $b => $d");
    is Encode::decode('MIME-Q', $q) => $d, info("decode qp: $b => $d");
}

@splice = @decode_default_tests;
while (my ($e, $d) = splice @splice, 0, 2) {
    is Encode::decode('MIME-Header', $e) => $d, info("decode default: $e => $d");
}

local $Encode::MIME::Header::STRICT_DECODE = 1;

@splice = @decode_strict_tests;
while (my ($e, $d) = splice @splice, 0, 2) {
    is Encode::decode('MIME-Header', $e) => $d, info("decode strict: $e => $d");
}

__END__
