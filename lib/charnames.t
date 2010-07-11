#!./perl
use strict;

# Because \N{} is compile time, any warnings will get generated before
# execution, so have to have an array, and arrange things so no warning
# is generated twice to verify that in fact a warning did happen
my @WARN;

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
    $SIG{__WARN__} = sub { push @WARN, @_ };
}

our $local_tests = 514;

# ---- For the alias extensions
require "../t/lib/common.pl";

use charnames ':full';

is("Here\N{EXCLAMATION MARK}?", "Here!?");

{
    use bytes;			# TEST -utf8 can switch utf8 on

    my $res = eval <<'EOE';
use charnames ":full";
"Here: \N{CYRILLIC SMALL LETTER BE}!";
1
EOE

    like($@, "above 0xFF");
    ok(! defined $res);

    $res = eval <<'EOE';
use charnames 'cyrillic';
"Here: \N{Be}!";
1
EOE
    like($@, "CYRILLIC CAPITAL LETTER BE.*above 0xFF");

    $res = eval <<'EOE';
use charnames ':full', ":alias" => { BOM => "LATIN SMALL LETTER B" };
"\N{BOM}";
EOE
    is ($@, "");
    is ($res, 'b', "Verify that can redefine a standard alias");
}

{

    use charnames ':full', ":alias" => { mychar1 => "0xE8000",
                                         mychar2 => 983040,  # U+F0000
                                         mychar3 => "U+100000",
                                         myctrl => 0x80,
                                         mylarge => "U+111000",
                                       };
    is ("\N{mychar1}", chr(0xE8000), "Verify that can define hex alias");
    is (charnames::viacode(0xE8000), "mychar1", "And that can get the alias back");
    is ("\N{mychar2}", chr(0xF0000), "Verify that can define decimal alias");
    is (charnames::viacode(0xF0000), "mychar2", "And that can get the alias back");
    is ("\N{mychar3}", chr(0x100000), "Verify that can define U+... alias");
    is (charnames::viacode(0x100000), "mychar3", "And that can get the alias back");
    is ("\N{mylarge}", chr(0x111000), "Verify that can define alias beyond Unicode");
    is (charnames::viacode(0x111000), "mylarge", "And that can get the alias back");
    is (charnames::viacode(0x80), "myctrl", "Verify that can name a nameless control");

}

my $encoded_be;
my $encoded_alpha;
my $encoded_bet;
my $encoded_deseng;

# If octal representation of unicode char is \0xyzt, then the utf8 is \3xy\2zt
if (ord('A') == 65) { # as on ASCII or UTF-8 machines
    $encoded_be = "\320\261";
    $encoded_alpha = "\316\261";
    $encoded_bet = "\327\221";
    $encoded_deseng = "\360\220\221\215";
}
else { # EBCDIC where UTF-EBCDIC may be used (this may be 1047 specific since
       # UTF-EBCDIC is codepage specific)
    $encoded_be = "\270\102\130";
    $encoded_alpha = "\264\130";
    $encoded_bet = "\270\125\130";
    $encoded_deseng = "\336\102\103\124";
}

sub to_bytes {
    unpack"U0a*", shift;
}

{
  use charnames ':full';

  is(to_bytes("\N{CYRILLIC SMALL LETTER BE}"), $encoded_be);

  use charnames qw(cyrillic greek :short);

  is(to_bytes("\N{be},\N{alpha},\N{hebrew:bet}"),
                                    "$encoded_be,$encoded_alpha,$encoded_bet");
}

{
    use charnames ':full';
    is("\x{263a}", "\N{WHITE SMILING FACE}");
    cmp_ok(length("\x{263a}"), '==', 1);
    cmp_ok(length("\N{WHITE SMILING FACE}"), '==', 1);
    is(sprintf("%vx", "\x{263a}"), "263a");
    is(sprintf("%vx", "\N{WHITE SMILING FACE}"), "263a");
    is(sprintf("%vx", "\xFF\N{WHITE SMILING FACE}"), "ff.263a");
    is(sprintf("%vx", "\x{ff}\N{WHITE SMILING FACE}"), "ff.263a");
}

{
    use charnames qw(:full);
    use utf8;

    my $x = "\x{221b}";
    my $named = "\N{CUBE ROOT}";

    cmp_ok(ord($x), '==', ord($named));
}

{
    use charnames qw(:full);
    use utf8;
    is("\x{100}\N{CENT SIGN}", "\x{100}"."\N{CENT SIGN}");
}

{
    use charnames ':full';

    is(to_bytes("\N{DESERET SMALL LETTER ENG}"), $encoded_deseng);
}

{
    # 20001114.001

    no utf8; # naked Latin-1

    use charnames ':full';
    my $text = "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}";
    is($text, latin1_to_native("\xc4"));

    # I'm not sure that this tests anything different from the above.
    cmp_ok(ord($text), '==', ord(latin1_to_native("\xc4")));
}

{
    is(charnames::viacode(0x1234), "ETHIOPIC SYLLABLE SEE");

    # No name
    ok(! defined charnames::viacode(0xFFFF));
}

{
    cmp_ok(charnames::vianame("GOTHIC LETTER AHSA"), "==", 0x10330, "Verify vianame \\N{name} returns an ord");
    is(charnames::vianame("U+10330"), "\x{10330}", "Verify vianame \\N{U+hex} returns a chr");
    use warnings;
    my $warning_count = @WARN;
    ok (! defined charnames::vianame("NONE SUCH"));
    cmp_ok($warning_count, '==', scalar @WARN, "Verify vianame doesn't warn on unknown names");

    use bytes;
    is(charnames::vianame("GOTHIC LETTER AHSA"), 0x10330, "Verify vianame \\N{name} is unaffected by 'use bytes'");
    is(charnames::vianame("U+FF"), chr(0xFF), "Verify vianame \\N{U+FF} is unaffected by 'use bytes'");
    cmp_ok($warning_count, '==', scalar @WARN, "Verify vianame doesn't warn on legal inputs");
    ok(! defined charnames::vianame("U+100"), "Verify vianame \\N{U+100} is undef under 'use bytes'");
    ok($warning_count == scalar @WARN - 1 && $WARN[-1] =~ /above 0xFF/, "Verify vianame gives appropriate warning for previous test");
}

{
    # check that caching at least hasn't broken anything

    is(charnames::viacode(0x1234), "ETHIOPIC SYLLABLE SEE");

    is(sprintf("%04X", charnames::vianame("GOTHIC LETTER AHSA")), "10330");

}

is("\N{CHARACTER TABULATION}", "\t");

is("\N{ESCAPE}", "\e");
is("\N{NULL}", "\c@");
is("\N{LINE FEED (LF)}", "\n");
is("\N{LINE FEED}", "\n");
is("\N{LF}", "\n");

my $nel = latin1_to_native("\x85");
$nel = qr/^$nel$/;

like("\N{NEXT LINE (NEL)}", $nel);
like("\N{NEXT LINE}", $nel);
like("\N{NEL}", $nel);
is("\N{BYTE ORDER MARK}", chr(0xFEFF));
is("\N{BOM}", chr(0xFEFF));

{
    use warnings 'deprecated';

    is("\N{HORIZONTAL TABULATION}", "\t");

    ok(grep { /"HORIZONTAL TABULATION" is deprecated.*CHARACTER TABULATION/ } @WARN);

    no warnings 'deprecated';

    is("\N{VERTICAL TABULATION}", "\013");

    ok(! grep { /"VERTICAL TABULATION" is deprecated/ } @WARN);
}

is(charnames::viacode(0xFEFF), "ZERO WIDTH NO-BREAK SPACE");

{
    use warnings;
    cmp_ok(ord("\N{BOM}"), '==', 0xFEFF);
}

cmp_ok(ord("\N{ZWNJ}"), '==', 0x200C);

cmp_ok(ord("\N{ZWJ}"), '==', 0x200D);

is("\N{U+263A}", "\N{WHITE SMILING FACE}");

{
    cmp_ok( 0x3093, '==', charnames::vianame("HIRAGANA LETTER N"));
    cmp_ok(0x0397, '==', charnames::vianame("GREEK CAPITAL LETTER ETA"));
}

ok(! defined charnames::viacode(0x110000));
ok(! grep { /you asked for U+110000/ } @WARN);

is(charnames::viacode(0), "NULL");
is(charnames::viacode("BE"), "VULGAR FRACTION THREE QUARTERS");
is(charnames::viacode("U+00000000000FEED"), "ARABIC LETTER WAW ISOLATED FORM");

{
    no warnings 'deprecated';
    is("\N{LINE FEED}", "\N{LINE FEED (LF)}");
    is("\N{FORM FEED}", "\N{FORM FEED (FF)}");
    is("\N{CARRIAGE RETURN}", "\N{CARRIAGE RETURN (CR)}");
    is("\N{NEXT LINE}", "\N{NEXT LINE (NEL)}");
    is("\N{NUL}", "\N{NULL}");
    is("\N{SOH}", "\N{START OF HEADING}");
    is("\N{STX}", "\N{START OF TEXT}");
    is("\N{ETX}", "\N{END OF TEXT}");
    is("\N{EOT}", "\N{END OF TRANSMISSION}");
    is("\N{ENQ}", "\N{ENQUIRY}");
    is("\N{ACK}", "\N{ACKNOWLEDGE}");
    is("\N{BEL}", "\N{BELL}");
    is("\N{BS}", "\N{BACKSPACE}");
    is("\N{HT}", "\N{HORIZONTAL TABULATION}");
    is("\N{LF}", "\N{LINE FEED (LF)}");
    is("\N{VT}", "\N{VERTICAL TABULATION}");
    is("\N{FF}", "\N{FORM FEED (FF)}");
    is("\N{CR}", "\N{CARRIAGE RETURN (CR)}");
    is("\N{SO}", "\N{SHIFT OUT}");
    is("\N{SI}", "\N{SHIFT IN}");
    is("\N{DLE}", "\N{DATA LINK ESCAPE}");
    is("\N{DC1}", "\N{DEVICE CONTROL ONE}");
    is("\N{DC2}", "\N{DEVICE CONTROL TWO}");
    is("\N{DC3}", "\N{DEVICE CONTROL THREE}");
    is("\N{DC4}", "\N{DEVICE CONTROL FOUR}");
    is("\N{NAK}", "\N{NEGATIVE ACKNOWLEDGE}");
    is("\N{SYN}", "\N{SYNCHRONOUS IDLE}");
    is("\N{ETB}", "\N{END OF TRANSMISSION BLOCK}");
    is("\N{CAN}", "\N{CANCEL}");
    is("\N{EOM}", "\N{END OF MEDIUM}");
    is("\N{SUB}", "\N{SUBSTITUTE}");
    is("\N{ESC}", "\N{ESCAPE}");
    is("\N{FS}", "\N{FILE SEPARATOR}");
    is("\N{GS}", "\N{GROUP SEPARATOR}");
    is("\N{RS}", "\N{RECORD SEPARATOR}");
    is("\N{US}", "\N{UNIT SEPARATOR}");
    is("\N{DEL}", "\N{DELETE}");
    is("\N{BPH}", "\N{BREAK PERMITTED HERE}");
    is("\N{NBH}", "\N{NO BREAK HERE}");
    is("\N{NEL}", "\N{NEXT LINE (NEL)}");
    is("\N{SSA}", "\N{START OF SELECTED AREA}");
    is("\N{ESA}", "\N{END OF SELECTED AREA}");
    is("\N{HTS}", "\N{CHARACTER TABULATION SET}");
    is("\N{HTJ}", "\N{CHARACTER TABULATION WITH JUSTIFICATION}");
    is("\N{VTS}", "\N{LINE TABULATION SET}");
    is("\N{PLD}", "\N{PARTIAL LINE FORWARD}");
    is("\N{PLU}", "\N{PARTIAL LINE BACKWARD}");
    is("\N{RI }", "\N{REVERSE LINE FEED}");
    is("\N{SS2}", "\N{SINGLE SHIFT TWO}");
    is("\N{SS3}", "\N{SINGLE SHIFT THREE}");
    is("\N{DCS}", "\N{DEVICE CONTROL STRING}");
    is("\N{PU1}", "\N{PRIVATE USE ONE}");
    is("\N{PU2}", "\N{PRIVATE USE TWO}");
    is("\N{STS}", "\N{SET TRANSMIT STATE}");
    is("\N{CCH}", "\N{CANCEL CHARACTER}");
    is("\N{MW }", "\N{MESSAGE WAITING}");
    is("\N{SPA}", "\N{START OF GUARDED AREA}");
    is("\N{EPA}", "\N{END OF GUARDED AREA}");
    is("\N{SOS}", "\N{START OF STRING}");
    is("\N{SCI}", "\N{SINGLE CHARACTER INTRODUCER}");
    is("\N{CSI}", "\N{CONTROL SEQUENCE INTRODUCER}");
    is("\N{ST }", "\N{STRING TERMINATOR}");
    is("\N{OSC}", "\N{OPERATING SYSTEM COMMAND}");
    is("\N{PM }", "\N{PRIVACY MESSAGE}");
    is("\N{APC}", "\N{APPLICATION PROGRAM COMMAND}");
    is("\N{PADDING CHARACTER}", "\N{PAD}");
    is("\N{HIGH OCTET PRESET}","\N{HOP}");
    is("\N{INDEX}", "\N{IND}");
    is("\N{SINGLE GRAPHIC CHARACTER INTRODUCER}", "\N{SGC}");
    is("\N{BOM}", "\N{BYTE ORDER MARK}");
    is("\N{CGJ}", "\N{COMBINING GRAPHEME JOINER}");
    is("\N{FVS1}", "\N{MONGOLIAN FREE VARIATION SELECTOR ONE}");
    is("\N{FVS2}", "\N{MONGOLIAN FREE VARIATION SELECTOR TWO}");
    is("\N{FVS3}", "\N{MONGOLIAN FREE VARIATION SELECTOR THREE}");
    is("\N{LRE}", "\N{LEFT-TO-RIGHT EMBEDDING}");
    is("\N{LRM}", "\N{LEFT-TO-RIGHT MARK}");
    is("\N{LRO}", "\N{LEFT-TO-RIGHT OVERRIDE}");
    is("\N{MMSP}", "\N{MEDIUM MATHEMATICAL SPACE}");
    is("\N{MVS}", "\N{MONGOLIAN VOWEL SEPARATOR}");
    is("\N{NBSP}", "\N{NO-BREAK SPACE}");
    is("\N{NNBSP}", "\N{NARROW NO-BREAK SPACE}");
    is("\N{PDF}", "\N{POP DIRECTIONAL FORMATTING}");
    is("\N{RLE}", "\N{RIGHT-TO-LEFT EMBEDDING}");
    is("\N{RLM}", "\N{RIGHT-TO-LEFT MARK}");
    is("\N{RLO}", "\N{RIGHT-TO-LEFT OVERRIDE}");
    is("\N{SHY}", "\N{SOFT HYPHEN}");
    is("\N{WJ}", "\N{WORD JOINER}");
    is("\N{ZWJ}", "\N{ZERO WIDTH JOINER}");
    is("\N{ZWNJ}", "\N{ZERO WIDTH NON-JOINER}");
    is("\N{ZWSP}", "\N{ZERO WIDTH SPACE}");
    is("\N{HORIZONTAL TABULATION}", "\N{CHARACTER TABULATION}");
    is("\N{VERTICAL TABULATION}", "\N{LINE TABULATION}");
    is("\N{FILE SEPARATOR}", "\N{INFORMATION SEPARATOR FOUR}");
    is("\N{GROUP SEPARATOR}", "\N{INFORMATION SEPARATOR THREE}");
    is("\N{RECORD SEPARATOR}", "\N{INFORMATION SEPARATOR TWO}");
    is("\N{UNIT SEPARATOR}", "\N{INFORMATION SEPARATOR ONE}");
    is("\N{HORIZONTAL TABULATION SET}", "\N{CHARACTER TABULATION SET}");
    is("\N{HORIZONTAL TABULATION WITH JUSTIFICATION}", "\N{CHARACTER TABULATION WITH JUSTIFICATION}");
    is("\N{PARTIAL LINE DOWN}", "\N{PARTIAL LINE FORWARD}");
    is("\N{PARTIAL LINE UP}", "\N{PARTIAL LINE BACKWARD}");
    is("\N{VERTICAL TABULATION SET}", "\N{LINE TABULATION SET}");
    is("\N{REVERSE INDEX}", "\N{REVERSE LINE FEED}");
    is("\N{SINGLE-SHIFT 2}", "\N{SINGLE SHIFT TWO}");
    is("\N{SINGLE-SHIFT 3}", "\N{SINGLE SHIFT THREE}");
    is("\N{PRIVATE USE 1}", "\N{PRIVATE USE ONE}");
    is("\N{PRIVATE USE 2}", "\N{PRIVATE USE TWO}");
    is("\N{START OF PROTECTED AREA}", "\N{START OF GUARDED AREA}");
    is("\N{END OF PROTECTED AREA}", "\N{END OF GUARDED AREA}");
    is("\N{VS1}", "\N{VARIATION SELECTOR-1}");
    is("\N{VS2}", "\N{VARIATION SELECTOR-2}");
    is("\N{VS3}", "\N{VARIATION SELECTOR-3}");
    is("\N{VS4}", "\N{VARIATION SELECTOR-4}");
    is("\N{VS5}", "\N{VARIATION SELECTOR-5}");
    is("\N{VS6}", "\N{VARIATION SELECTOR-6}");
    is("\N{VS7}", "\N{VARIATION SELECTOR-7}");
    is("\N{VS8}", "\N{VARIATION SELECTOR-8}");
    is("\N{VS9}", "\N{VARIATION SELECTOR-9}");
    is("\N{VS10}", "\N{VARIATION SELECTOR-10}");
    is("\N{VS11}", "\N{VARIATION SELECTOR-11}");
    is("\N{VS12}", "\N{VARIATION SELECTOR-12}");
    is("\N{VS13}", "\N{VARIATION SELECTOR-13}");
    is("\N{VS14}", "\N{VARIATION SELECTOR-14}");
    is("\N{VS15}", "\N{VARIATION SELECTOR-15}");
    is("\N{VS16}", "\N{VARIATION SELECTOR-16}");
    is("\N{VS17}", "\N{VARIATION SELECTOR-17}");
    is("\N{VS18}", "\N{VARIATION SELECTOR-18}");
    is("\N{VS19}", "\N{VARIATION SELECTOR-19}");
    is("\N{VS20}", "\N{VARIATION SELECTOR-20}");
    is("\N{VS21}", "\N{VARIATION SELECTOR-21}");
    is("\N{VS22}", "\N{VARIATION SELECTOR-22}");
    is("\N{VS23}", "\N{VARIATION SELECTOR-23}");
    is("\N{VS24}", "\N{VARIATION SELECTOR-24}");
    is("\N{VS25}", "\N{VARIATION SELECTOR-25}");
    is("\N{VS26}", "\N{VARIATION SELECTOR-26}");
    is("\N{VS27}", "\N{VARIATION SELECTOR-27}");
    is("\N{VS28}", "\N{VARIATION SELECTOR-28}");
    is("\N{VS29}", "\N{VARIATION SELECTOR-29}");
    is("\N{VS30}", "\N{VARIATION SELECTOR-30}");
    is("\N{VS31}", "\N{VARIATION SELECTOR-31}");
    is("\N{VS32}", "\N{VARIATION SELECTOR-32}");
    is("\N{VS33}", "\N{VARIATION SELECTOR-33}");
    is("\N{VS34}", "\N{VARIATION SELECTOR-34}");
    is("\N{VS35}", "\N{VARIATION SELECTOR-35}");
    is("\N{VS36}", "\N{VARIATION SELECTOR-36}");
    is("\N{VS37}", "\N{VARIATION SELECTOR-37}");
    is("\N{VS38}", "\N{VARIATION SELECTOR-38}");
    is("\N{VS39}", "\N{VARIATION SELECTOR-39}");
    is("\N{VS40}", "\N{VARIATION SELECTOR-40}");
    is("\N{VS41}", "\N{VARIATION SELECTOR-41}");
    is("\N{VS42}", "\N{VARIATION SELECTOR-42}");
    is("\N{VS43}", "\N{VARIATION SELECTOR-43}");
    is("\N{VS44}", "\N{VARIATION SELECTOR-44}");
    is("\N{VS45}", "\N{VARIATION SELECTOR-45}");
    is("\N{VS46}", "\N{VARIATION SELECTOR-46}");
    is("\N{VS47}", "\N{VARIATION SELECTOR-47}");
    is("\N{VS48}", "\N{VARIATION SELECTOR-48}");
    is("\N{VS49}", "\N{VARIATION SELECTOR-49}");
    is("\N{VS50}", "\N{VARIATION SELECTOR-50}");
    is("\N{VS51}", "\N{VARIATION SELECTOR-51}");
    is("\N{VS52}", "\N{VARIATION SELECTOR-52}");
    is("\N{VS53}", "\N{VARIATION SELECTOR-53}");
    is("\N{VS54}", "\N{VARIATION SELECTOR-54}");
    is("\N{VS55}", "\N{VARIATION SELECTOR-55}");
    is("\N{VS56}", "\N{VARIATION SELECTOR-56}");
    is("\N{VS57}", "\N{VARIATION SELECTOR-57}");
    is("\N{VS58}", "\N{VARIATION SELECTOR-58}");
    is("\N{VS59}", "\N{VARIATION SELECTOR-59}");
    is("\N{VS60}", "\N{VARIATION SELECTOR-60}");
    is("\N{VS61}", "\N{VARIATION SELECTOR-61}");
    is("\N{VS62}", "\N{VARIATION SELECTOR-62}");
    is("\N{VS63}", "\N{VARIATION SELECTOR-63}");
    is("\N{VS64}", "\N{VARIATION SELECTOR-64}");
    is("\N{VS65}", "\N{VARIATION SELECTOR-65}");
    is("\N{VS66}", "\N{VARIATION SELECTOR-66}");
    is("\N{VS67}", "\N{VARIATION SELECTOR-67}");
    is("\N{VS68}", "\N{VARIATION SELECTOR-68}");
    is("\N{VS69}", "\N{VARIATION SELECTOR-69}");
    is("\N{VS70}", "\N{VARIATION SELECTOR-70}");
    is("\N{VS71}", "\N{VARIATION SELECTOR-71}");
    is("\N{VS72}", "\N{VARIATION SELECTOR-72}");
    is("\N{VS73}", "\N{VARIATION SELECTOR-73}");
    is("\N{VS74}", "\N{VARIATION SELECTOR-74}");
    is("\N{VS75}", "\N{VARIATION SELECTOR-75}");
    is("\N{VS76}", "\N{VARIATION SELECTOR-76}");
    is("\N{VS77}", "\N{VARIATION SELECTOR-77}");
    is("\N{VS78}", "\N{VARIATION SELECTOR-78}");
    is("\N{VS79}", "\N{VARIATION SELECTOR-79}");
    is("\N{VS80}", "\N{VARIATION SELECTOR-80}");
    is("\N{VS81}", "\N{VARIATION SELECTOR-81}");
    is("\N{VS82}", "\N{VARIATION SELECTOR-82}");
    is("\N{VS83}", "\N{VARIATION SELECTOR-83}");
    is("\N{VS84}", "\N{VARIATION SELECTOR-84}");
    is("\N{VS85}", "\N{VARIATION SELECTOR-85}");
    is("\N{VS86}", "\N{VARIATION SELECTOR-86}");
    is("\N{VS87}", "\N{VARIATION SELECTOR-87}");
    is("\N{VS88}", "\N{VARIATION SELECTOR-88}");
    is("\N{VS89}", "\N{VARIATION SELECTOR-89}");
    is("\N{VS90}", "\N{VARIATION SELECTOR-90}");
    is("\N{VS91}", "\N{VARIATION SELECTOR-91}");
    is("\N{VS92}", "\N{VARIATION SELECTOR-92}");
    is("\N{VS93}", "\N{VARIATION SELECTOR-93}");
    is("\N{VS94}", "\N{VARIATION SELECTOR-94}");
    is("\N{VS95}", "\N{VARIATION SELECTOR-95}");
    is("\N{VS96}", "\N{VARIATION SELECTOR-96}");
    is("\N{VS97}", "\N{VARIATION SELECTOR-97}");
    is("\N{VS98}", "\N{VARIATION SELECTOR-98}");
    is("\N{VS99}", "\N{VARIATION SELECTOR-99}");
    is("\N{VS100}", "\N{VARIATION SELECTOR-100}");
    is("\N{VS101}", "\N{VARIATION SELECTOR-101}");
    is("\N{VS102}", "\N{VARIATION SELECTOR-102}");
    is("\N{VS103}", "\N{VARIATION SELECTOR-103}");
    is("\N{VS104}", "\N{VARIATION SELECTOR-104}");
    is("\N{VS105}", "\N{VARIATION SELECTOR-105}");
    is("\N{VS106}", "\N{VARIATION SELECTOR-106}");
    is("\N{VS107}", "\N{VARIATION SELECTOR-107}");
    is("\N{VS108}", "\N{VARIATION SELECTOR-108}");
    is("\N{VS109}", "\N{VARIATION SELECTOR-109}");
    is("\N{VS110}", "\N{VARIATION SELECTOR-110}");
    is("\N{VS111}", "\N{VARIATION SELECTOR-111}");
    is("\N{VS112}", "\N{VARIATION SELECTOR-112}");
    is("\N{VS113}", "\N{VARIATION SELECTOR-113}");
    is("\N{VS114}", "\N{VARIATION SELECTOR-114}");
    is("\N{VS115}", "\N{VARIATION SELECTOR-115}");
    is("\N{VS116}", "\N{VARIATION SELECTOR-116}");
    is("\N{VS117}", "\N{VARIATION SELECTOR-117}");
    is("\N{VS118}", "\N{VARIATION SELECTOR-118}");
    is("\N{VS119}", "\N{VARIATION SELECTOR-119}");
    is("\N{VS120}", "\N{VARIATION SELECTOR-120}");
    is("\N{VS121}", "\N{VARIATION SELECTOR-121}");
    is("\N{VS122}", "\N{VARIATION SELECTOR-122}");
    is("\N{VS123}", "\N{VARIATION SELECTOR-123}");
    is("\N{VS124}", "\N{VARIATION SELECTOR-124}");
    is("\N{VS125}", "\N{VARIATION SELECTOR-125}");
    is("\N{VS126}", "\N{VARIATION SELECTOR-126}");
    is("\N{VS127}", "\N{VARIATION SELECTOR-127}");
    is("\N{VS128}", "\N{VARIATION SELECTOR-128}");
    is("\N{VS129}", "\N{VARIATION SELECTOR-129}");
    is("\N{VS130}", "\N{VARIATION SELECTOR-130}");
    is("\N{VS131}", "\N{VARIATION SELECTOR-131}");
    is("\N{VS132}", "\N{VARIATION SELECTOR-132}");
    is("\N{VS133}", "\N{VARIATION SELECTOR-133}");
    is("\N{VS134}", "\N{VARIATION SELECTOR-134}");
    is("\N{VS135}", "\N{VARIATION SELECTOR-135}");
    is("\N{VS136}", "\N{VARIATION SELECTOR-136}");
    is("\N{VS137}", "\N{VARIATION SELECTOR-137}");
    is("\N{VS138}", "\N{VARIATION SELECTOR-138}");
    is("\N{VS139}", "\N{VARIATION SELECTOR-139}");
    is("\N{VS140}", "\N{VARIATION SELECTOR-140}");
    is("\N{VS141}", "\N{VARIATION SELECTOR-141}");
    is("\N{VS142}", "\N{VARIATION SELECTOR-142}");
    is("\N{VS143}", "\N{VARIATION SELECTOR-143}");
    is("\N{VS144}", "\N{VARIATION SELECTOR-144}");
    is("\N{VS145}", "\N{VARIATION SELECTOR-145}");
    is("\N{VS146}", "\N{VARIATION SELECTOR-146}");
    is("\N{VS147}", "\N{VARIATION SELECTOR-147}");
    is("\N{VS148}", "\N{VARIATION SELECTOR-148}");
    is("\N{VS149}", "\N{VARIATION SELECTOR-149}");
    is("\N{VS150}", "\N{VARIATION SELECTOR-150}");
    is("\N{VS151}", "\N{VARIATION SELECTOR-151}");
    is("\N{VS152}", "\N{VARIATION SELECTOR-152}");
    is("\N{VS153}", "\N{VARIATION SELECTOR-153}");
    is("\N{VS154}", "\N{VARIATION SELECTOR-154}");
    is("\N{VS155}", "\N{VARIATION SELECTOR-155}");
    is("\N{VS156}", "\N{VARIATION SELECTOR-156}");
    is("\N{VS157}", "\N{VARIATION SELECTOR-157}");
    is("\N{VS158}", "\N{VARIATION SELECTOR-158}");
    is("\N{VS159}", "\N{VARIATION SELECTOR-159}");
    is("\N{VS160}", "\N{VARIATION SELECTOR-160}");
    is("\N{VS161}", "\N{VARIATION SELECTOR-161}");
    is("\N{VS162}", "\N{VARIATION SELECTOR-162}");
    is("\N{VS163}", "\N{VARIATION SELECTOR-163}");
    is("\N{VS164}", "\N{VARIATION SELECTOR-164}");
    is("\N{VS165}", "\N{VARIATION SELECTOR-165}");
    is("\N{VS166}", "\N{VARIATION SELECTOR-166}");
    is("\N{VS167}", "\N{VARIATION SELECTOR-167}");
    is("\N{VS168}", "\N{VARIATION SELECTOR-168}");
    is("\N{VS169}", "\N{VARIATION SELECTOR-169}");
    is("\N{VS170}", "\N{VARIATION SELECTOR-170}");
    is("\N{VS171}", "\N{VARIATION SELECTOR-171}");
    is("\N{VS172}", "\N{VARIATION SELECTOR-172}");
    is("\N{VS173}", "\N{VARIATION SELECTOR-173}");
    is("\N{VS174}", "\N{VARIATION SELECTOR-174}");
    is("\N{VS175}", "\N{VARIATION SELECTOR-175}");
    is("\N{VS176}", "\N{VARIATION SELECTOR-176}");
    is("\N{VS177}", "\N{VARIATION SELECTOR-177}");
    is("\N{VS178}", "\N{VARIATION SELECTOR-178}");
    is("\N{VS179}", "\N{VARIATION SELECTOR-179}");
    is("\N{VS180}", "\N{VARIATION SELECTOR-180}");
    is("\N{VS181}", "\N{VARIATION SELECTOR-181}");
    is("\N{VS182}", "\N{VARIATION SELECTOR-182}");
    is("\N{VS183}", "\N{VARIATION SELECTOR-183}");
    is("\N{VS184}", "\N{VARIATION SELECTOR-184}");
    is("\N{VS185}", "\N{VARIATION SELECTOR-185}");
    is("\N{VS186}", "\N{VARIATION SELECTOR-186}");
    is("\N{VS187}", "\N{VARIATION SELECTOR-187}");
    is("\N{VS188}", "\N{VARIATION SELECTOR-188}");
    is("\N{VS189}", "\N{VARIATION SELECTOR-189}");
    is("\N{VS190}", "\N{VARIATION SELECTOR-190}");
    is("\N{VS191}", "\N{VARIATION SELECTOR-191}");
    is("\N{VS192}", "\N{VARIATION SELECTOR-192}");
    is("\N{VS193}", "\N{VARIATION SELECTOR-193}");
    is("\N{VS194}", "\N{VARIATION SELECTOR-194}");
    is("\N{VS195}", "\N{VARIATION SELECTOR-195}");
    is("\N{VS196}", "\N{VARIATION SELECTOR-196}");
    is("\N{VS197}", "\N{VARIATION SELECTOR-197}");
    is("\N{VS198}", "\N{VARIATION SELECTOR-198}");
    is("\N{VS199}", "\N{VARIATION SELECTOR-199}");
    is("\N{VS200}", "\N{VARIATION SELECTOR-200}");
    is("\N{VS201}", "\N{VARIATION SELECTOR-201}");
    is("\N{VS202}", "\N{VARIATION SELECTOR-202}");
    is("\N{VS203}", "\N{VARIATION SELECTOR-203}");
    is("\N{VS204}", "\N{VARIATION SELECTOR-204}");
    is("\N{VS205}", "\N{VARIATION SELECTOR-205}");
    is("\N{VS206}", "\N{VARIATION SELECTOR-206}");
    is("\N{VS207}", "\N{VARIATION SELECTOR-207}");
    is("\N{VS208}", "\N{VARIATION SELECTOR-208}");
    is("\N{VS209}", "\N{VARIATION SELECTOR-209}");
    is("\N{VS210}", "\N{VARIATION SELECTOR-210}");
    is("\N{VS211}", "\N{VARIATION SELECTOR-211}");
    is("\N{VS212}", "\N{VARIATION SELECTOR-212}");
    is("\N{VS213}", "\N{VARIATION SELECTOR-213}");
    is("\N{VS214}", "\N{VARIATION SELECTOR-214}");
    is("\N{VS215}", "\N{VARIATION SELECTOR-215}");
    is("\N{VS216}", "\N{VARIATION SELECTOR-216}");
    is("\N{VS217}", "\N{VARIATION SELECTOR-217}");
    is("\N{VS218}", "\N{VARIATION SELECTOR-218}");
    is("\N{VS219}", "\N{VARIATION SELECTOR-219}");
    is("\N{VS220}", "\N{VARIATION SELECTOR-220}");
    is("\N{VS221}", "\N{VARIATION SELECTOR-221}");
    is("\N{VS222}", "\N{VARIATION SELECTOR-222}");
    is("\N{VS223}", "\N{VARIATION SELECTOR-223}");
    is("\N{VS224}", "\N{VARIATION SELECTOR-224}");
    is("\N{VS225}", "\N{VARIATION SELECTOR-225}");
    is("\N{VS226}", "\N{VARIATION SELECTOR-226}");
    is("\N{VS227}", "\N{VARIATION SELECTOR-227}");
    is("\N{VS228}", "\N{VARIATION SELECTOR-228}");
    is("\N{VS229}", "\N{VARIATION SELECTOR-229}");
    is("\N{VS230}", "\N{VARIATION SELECTOR-230}");
    is("\N{VS231}", "\N{VARIATION SELECTOR-231}");
    is("\N{VS232}", "\N{VARIATION SELECTOR-232}");
    is("\N{VS233}", "\N{VARIATION SELECTOR-233}");
    is("\N{VS234}", "\N{VARIATION SELECTOR-234}");
    is("\N{VS235}", "\N{VARIATION SELECTOR-235}");
    is("\N{VS236}", "\N{VARIATION SELECTOR-236}");
    is("\N{VS237}", "\N{VARIATION SELECTOR-237}");
    is("\N{VS238}", "\N{VARIATION SELECTOR-238}");
    is("\N{VS239}", "\N{VARIATION SELECTOR-239}");
    is("\N{VS240}", "\N{VARIATION SELECTOR-240}");
    is("\N{VS241}", "\N{VARIATION SELECTOR-241}");
    is("\N{VS242}", "\N{VARIATION SELECTOR-242}");
    is("\N{VS243}", "\N{VARIATION SELECTOR-243}");
    is("\N{VS244}", "\N{VARIATION SELECTOR-244}");
    is("\N{VS245}", "\N{VARIATION SELECTOR-245}");
    is("\N{VS246}", "\N{VARIATION SELECTOR-246}");
    is("\N{VS247}", "\N{VARIATION SELECTOR-247}");
    is("\N{VS248}", "\N{VARIATION SELECTOR-248}");
    is("\N{VS249}", "\N{VARIATION SELECTOR-249}");
    is("\N{VS250}", "\N{VARIATION SELECTOR-250}");
    is("\N{VS251}", "\N{VARIATION SELECTOR-251}");
    is("\N{VS252}", "\N{VARIATION SELECTOR-252}");
    is("\N{VS253}", "\N{VARIATION SELECTOR-253}");
    is("\N{VS254}", "\N{VARIATION SELECTOR-254}");
    is("\N{VS255}", "\N{VARIATION SELECTOR-255}");
    is("\N{VS256}", "\N{VARIATION SELECTOR-256}");
}

# [perl #30409] charnames.pm clobbers default variable
$_ = 'foobar';
eval "use charnames ':full';";
is($_, 'foobar');

# Unicode slowdown noted by Phil Pennock, traced to a bug fix in index
# SADAHIRO Tomoyuki's suggestion is to ensure that the UTF-8ness of both
# arguments are indentical before calling index.
# To do this can take advantage of the fact that unicore/Name.pl is 7 bit
# (or at least should be). So assert that that it's true here.  EBCDIC
# may be a problem (khw).

my $names = do "unicore/Name.pl";
ok(defined $names);
my $non_ascii = native_to_latin1($names) =~ tr/\0-\177//c;
ok(! $non_ascii, "Verify all official names are ASCII-only");

# Verify that charnames propagate to eval("")
my $evaltry = eval q[ "Eval: \N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" ];
if ($@) {
    fail('charnames failed to propagate to eval("")');
    fail('next test also fails to make the same number of tests');
} else {
    pass('charnames propagated to eval("")');
    is($evaltry, "Eval: \N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}");
}

# Verify that db includes the normative NameAliases.txt names
is("\N{U+1D0C5}", "\N{BYZANTINE MUSICAL SYMBOL FTHORA SKLIRON CHROMA VASIS}");

# [perl #73174] use of \N{FOO} used to reset %^H

{
    use charnames ":full";
    my $res;
    BEGIN { $^H{73174} = "foo" }
    BEGIN { $res = ($^H{73174} // "") }
    # forces loading of utf8.pm, which used to reset %^H
    $res .= '-1' if ":" =~ /\N{COLON}/i;
    BEGIN { $res .= '-' . ($^H{73174} // "") }
    $res .= '-' . ($^H{73174} // "");
    $res .= '-2' if ":" =~ /\N{COLON}/;
    $res .= '-3' if ":" =~ /\N{COLON}/i;
    is($res, "foo-foo-1--2-3");
}

{
    # Test scoping.  Outer block sets up some things; inner blocks
    # override them, and then see if get restored.

    use charnames ":full",
                  ":alias" => {
                            mychar1 => "LATIN SMALL LETTER E",
                            mychar2 => "LATIN CAPITAL LETTER A",
                            myprivate1 => 0xE8000,  # Private use area
                            myprivate2 => 0x100000,  # Private use area
                    },
                  ":short",
                  qw( katakana ),
                ;

    my $hiragana_be = "\N{HIRAGANA LETTER BE}";

    is("\N{mychar1}", "e", "Outer block: verify that \\N{mychar1} works");
    is(charnames::vianame("mychar1"), ord("e"), "Outer block: verify that vianame(mychar1) works");
    is("\N{mychar2}", "A", "Outer block: verify that \\N{mychar2} works");
    is(charnames::vianame("mychar2"), ord("A"), "Outer block: verify that vianame(mychar2) works");
    is("\N{myprivate1}", "\x{E8000}", "Outer block: verify that \\N{myprivate1} works");
    cmp_ok(charnames::vianame("myprivate1"), "==", 0xE8000, "Outer block: verify that vianame(myprivate1) works");
    is(charnames::viacode(0xE8000), "myprivate1", "Outer block: verify that myprivate1 viacode works");
    is("\N{myprivate2}", "\x{100000}", "Outer block: verify that \\N{myprivate2} works");
    cmp_ok(charnames::vianame("myprivate2"), "==", 0x100000, "Outer block: verify that vianame(myprivate2) works");
    is(charnames::viacode(0x100000), "myprivate2", "Outer block: verify that myprivate2 viacode works");
    is("\N{BE}", "\N{KATAKANA LETTER BE}", "Outer block: verify that \\N uses the correct script ");
    cmp_ok(charnames::vianame("BE"), "==", ord("\N{KATAKANA LETTER BE}"), "Outer block: verify that vianame uses the correct script");
    is("\N{Hiragana: BE}", $hiragana_be, "Outer block: verify that :short works with \\N");
    cmp_ok(charnames::vianame("Hiragana: BE"), "==", ord($hiragana_be), "Outer block: verify that :short works with vianame");

    {
        use charnames ":full",
                      ":alias" => {
                                    mychar1 => "LATIN SMALL LETTER F",
                                    myprivate1 => 0xE8001,  # Private use area
                                },

                      # BE is in both hiragana and katakana; see if
                      # different default script delivers different
                      # letter.
                      qw( hiragana ),
            ;
        is("\N{mychar1}", "f", "Inner block: verify that \\N{mychar1} is redefined");
        is(charnames::vianame("mychar1"), ord("f"), "Inner block: verify that vianame(mychar1) is redefined");
        is("\N{mychar2}", "\x{FFFD}", "Inner block: verify that \\N{mychar2} outer definition didn't leak");
        ok( ! defined charnames::vianame("mychar2"), "Inner block: verify that vianame(mychar2) outer definition didn't leak");
        is("\N{myprivate1}", "\x{E8001}", "Inner block: verify that \\N{myprivate1} is redefined ");
        cmp_ok(charnames::vianame("myprivate1"), "==", 0xE8001, "Inner block: verify that vianame(myprivate1) is redefined");
        is(charnames::viacode(0xE8001), "myprivate1", "Inner block: verify that myprivate1 viacode is redefined");
        ok(! defined charnames::viacode(0xE8000), "Inner block: verify that outer myprivate1 viacode didn't leak");
        is("\N{myprivate2}", "\x{FFFD}", "Inner block: verify that \\N{myprivate2} outer definition didn't leak");
        ok(! defined charnames::vianame("myprivate2"), "Inner block: verify that vianame(myprivate2) outer definition didn't leak");
        ok(! defined charnames::viacode(0x100000), "Inner block: verify that myprivate2 viacode outer definition didn't leak");
        is("\N{BE}", $hiragana_be, "Inner block: verify that \\N uses the correct script");
        cmp_ok(charnames::vianame("BE"), "==", ord($hiragana_be), "Inner block: verify that vianame uses the correct script");
        is("\N{Hiragana: BE}", "\x{FFFD}", "Inner block without :short: \\N with short doesn't work");
        ok(! defined charnames::vianame("Hiragana: BE"), "Inner block without :short: verify that vianame with short doesn't work");

        {   # An inner block where only :short definitions are valid.
            use charnames ":short";
            is("\N{mychar1}", "\x{FFFD}", "Inner inner block: verify that mychar1 outer definition didn't leak with \\N");
            ok( ! defined charnames::vianame("mychar1"), "Inner inner block: verify that mychar1 outer definition didn't leak with vianame");
            is("\N{mychar2}", "\x{FFFD}", "Inner inner block: verify that mychar2 outer definition didn't leak with \\N");
            ok( ! defined charnames::vianame("mychar2"), "Inner inner block: verify that mychar2 outer definition didn't leak with vianame");
            is("\N{myprivate1}", "\x{FFFD}", "Inner inner block: verify that myprivate1 outer definition didn't leak with \\N");
            ok(! defined charnames::vianame("myprivate1"), "Inner inner block: verify that myprivate1 outer definition didn't leak with vianame");
            is("\N{myprivate2}", "\x{FFFD}", "Inner inner block: verify that myprivate2 outer definition didn't leak with \\N");
            ok(! defined charnames::vianame("myprivate2"), "Inner inner block: verify that myprivate2 outer definition didn't leak with vianame");
            ok(! defined charnames::viacode(0xE8000), "Inner inner block: verify that mychar1 outer outer definition didn't leak with viacode");
            ok(! defined charnames::viacode(0xE8001), "Inner inner block: verify that mychar1 outer definition didn't leak with viacode");
            ok(! defined charnames::viacode(0x100000), "Inner inner block: verify that mychar2 outer definition didn't leak with viacode");
            is("\N{BE}", "\x{FFFD}", "Inner inner block without script: verify that outer :script didn't leak with \\N");
            ok(! defined charnames::vianame("BE"), "Inner inner block without script: verify that outer :script didn't leak with vianames");
            is("\N{HIRAGANA LETTER BE}", "\x{FFFD}", "Inner inner block without :full: verify that outer :full didn't leak with \\N");
            is("\N{Hiragana: BE}", $hiragana_be, "Inner inner block with :short: verify that \\N works with :short");
            cmp_ok(charnames::vianame("Hiragana: BE"), "==", ord($hiragana_be), "Inner inner block with :short: verify that vianame works with :short");
        }

        # Back to previous block.  All previous tests should work again.
        is("\N{mychar1}", "f", "Inner block: verify that \\N{mychar1} is redefined");
        is(charnames::vianame("mychar1"), ord("f"), "Inner block: verify that vianame(mychar1) is redefined");
        is("\N{mychar2}", "\x{FFFD}", "Inner block: verify that \\N{mychar2} outer definition didn't leak");
        ok( ! defined charnames::vianame("mychar2"), "Inner block: verify that vianame(mychar2) outer definition didn't leak");
        is("\N{myprivate1}", "\x{E8001}", "Inner block: verify that \\N{myprivate1} is redefined ");
        cmp_ok(charnames::vianame("myprivate1"), "==", 0xE8001, "Inner block: verify that vianame(myprivate1) is redefined");
        is(charnames::viacode(0xE8001), "myprivate1", "Inner block: verify that myprivate1 viacode is redefined");
        ok(! defined charnames::viacode(0xE8000), "Inner block: verify that outer myprivate1 viacode didn't leak");
        is("\N{myprivate2}", "\x{FFFD}", "Inner block: verify that \\N{myprivate2} outer definition didn't leak");
        ok(! defined charnames::vianame("myprivate2"), "Inner block: verify that vianame(myprivate2) outer definition didn't leak");
        ok(! defined charnames::viacode(0x100000), "Inner block: verify that myprivate2 viacode outer definition didn't leak");
        is("\N{BE}", $hiragana_be, "Inner block: verify that \\N uses the correct script");
        cmp_ok(charnames::vianame("BE"), "==", ord($hiragana_be), "Inner block: verify that vianame uses the correct script");
        is("\N{Hiragana: BE}", "\x{FFFD}", "Inner block without :short: \\N with short doesn't work");
        ok(! defined charnames::vianame("Hiragana: BE"), "Inner block without :short: verify that vianame with short doesn't work");
    }

    # Back to previous block.  All tests from that block should work again.
    is("\N{mychar1}", "e", "Outer block: verify that \\N{mychar1} works");
    is(charnames::vianame("mychar1"), ord("e"), "Outer block: verify that vianame(mychar1) works");
    is("\N{mychar2}", "A", "Outer block: verify that \\N{mychar2} works");
    is(charnames::vianame("mychar2"), ord("A"), "Outer block: verify that vianame(mychar2) works");
    is("\N{myprivate1}", "\x{E8000}", "Outer block: verify that \\N{myprivate1} works");
    cmp_ok(charnames::vianame("myprivate1"), "==", 0xE8000, "Outer block: verify that vianame(myprivate1) works");
    is(charnames::viacode(0xE8000), "myprivate1", "Outer block: verify that myprivate1 viacode works");
    is("\N{myprivate2}", "\x{100000}", "Outer block: verify that \\N{myprivate2} works");
    cmp_ok(charnames::vianame("myprivate2"), "==", 0x100000, "Outer block: verify that vianame(myprivate2) works");
    is(charnames::viacode(0x100000), "myprivate2", "Outer block: verify that myprivate2 viacode works");
    is("\N{BE}", "\N{KATAKANA LETTER BE}", "Outer block: verify that \\N uses the correct script ");
    cmp_ok(charnames::vianame("BE"), "==", ord("\N{KATAKANA LETTER BE}"), "Outer block: verify that vianame uses the correct script");
    is("\N{Hiragana: BE}", $hiragana_be, "Outer block: verify that :short works with \\N");
    cmp_ok(charnames::vianame("Hiragana: BE"), "==", ord($hiragana_be), "Outer block: verify that :short works with vianame");
}
