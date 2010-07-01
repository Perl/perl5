#!./perl
use strict;

my @WARN;

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
    $SIG{__WARN__} = sub { push @WARN, @_ };
}

our $pragma_name = "charnames";
our $local_tests = 58;

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
    is($res, undef);

    $res = eval <<'EOE';
use charnames 'cyrillic';
"Here: \N{Be}!";
1
EOE
    like($@, "CYRILLIC CAPITAL LETTER BE.*above 0xFF");
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

    # Unused Hebrew.
    ok(! defined charnames::viacode(0x0590));
}

{
    is(sprintf("%04X", charnames::vianame("GOTHIC LETTER AHSA")), "10330");
    ok (! defined charnames::vianame("NONE SUCH"));
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

    ok(grep { /"HORIZONTAL TABULATION" is deprecated/ } @WARN);

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
ok(! $non_ascii, "Make sure all names are ASCII-only");

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
