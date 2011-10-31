#!perl -w
BEGIN {
    if (ord("A") != 65) {
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built; Unicode::UCD uses Storable\n";
        exit 0;
    }
}

use strict;
use Unicode::UCD;
use Test::More;

use Unicode::UCD 'charinfo';

my $charinfo;

is(charinfo(0x110000), undef, "Verify charinfo() of non-unicode is undef");

$charinfo = charinfo(0);    # Null is often problematic, so test it.

is($charinfo->{code},           '0000', '<control>');
is($charinfo->{name},           '<control>');
is($charinfo->{category},       'Cc');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'BN');
is($charinfo->{decomposition},  '');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      'NULL');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Basic Latin');
is($charinfo->{script},         'Common');

$charinfo = charinfo(0x41);

is($charinfo->{code},           '0041', 'LATIN CAPITAL LETTER A');
is($charinfo->{name},           'LATIN CAPITAL LETTER A');
is($charinfo->{category},       'Lu');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '0061');
is($charinfo->{title},          '');
is($charinfo->{block},          'Basic Latin');
is($charinfo->{script},         'Latin');

$charinfo = charinfo(0x100);

is($charinfo->{code},           '0100', 'LATIN CAPITAL LETTER A WITH MACRON');
is($charinfo->{name},           'LATIN CAPITAL LETTER A WITH MACRON');
is($charinfo->{category},       'Lu');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '0041 0304');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      'LATIN CAPITAL LETTER A MACRON');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '0101');
is($charinfo->{title},          '');
is($charinfo->{block},          'Latin Extended-A');
is($charinfo->{script},         'Latin');

# 0x0590 is in the Hebrew block but unused.

$charinfo = charinfo(0x590);

is($charinfo->{code},          undef,	'0x0590 - unused Hebrew');
is($charinfo->{name},          undef);
is($charinfo->{category},      undef);
is($charinfo->{combining},     undef);
is($charinfo->{bidi},          undef);
is($charinfo->{decomposition}, undef);
is($charinfo->{decimal},       undef);
is($charinfo->{digit},         undef);
is($charinfo->{numeric},       undef);
is($charinfo->{mirrored},      undef);
is($charinfo->{unicode10},     undef);
is($charinfo->{comment},       undef);
is($charinfo->{upper},         undef);
is($charinfo->{lower},         undef);
is($charinfo->{title},         undef);
is($charinfo->{block},         undef);
is($charinfo->{script},        undef);

# 0x05d0 is in the Hebrew block and used.

$charinfo = charinfo(0x5d0);

is($charinfo->{code},           '05D0', '05D0 - used Hebrew');
is($charinfo->{name},           'HEBREW LETTER ALEF');
is($charinfo->{category},       'Lo');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'R');
is($charinfo->{decomposition},  '');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Hebrew');
is($charinfo->{script},         'Hebrew');

# An open syllable in Hangul.

$charinfo = charinfo(0xAC00);

is($charinfo->{code},           'AC00', 'HANGUL SYLLABLE U+AC00');
is($charinfo->{name},           'HANGUL SYLLABLE GA');
is($charinfo->{category},       'Lo');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '1100 1161');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Hangul Syllables');
is($charinfo->{script},         'Hangul');

# A closed syllable in Hangul.

$charinfo = charinfo(0xAE00);

is($charinfo->{code},           'AE00', 'HANGUL SYLLABLE U+AE00');
is($charinfo->{name},           'HANGUL SYLLABLE GEUL');
is($charinfo->{category},       'Lo');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  "1100 1173 11AF");
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Hangul Syllables');
is($charinfo->{script},         'Hangul');

$charinfo = charinfo(0x1D400);

is($charinfo->{code},           '1D400', 'MATHEMATICAL BOLD CAPITAL A');
is($charinfo->{name},           'MATHEMATICAL BOLD CAPITAL A');
is($charinfo->{category},       'Lu');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '<font> 0041');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Mathematical Alphanumeric Symbols');
is($charinfo->{script},         'Common');

$charinfo = charinfo(0x9FBA);	#Bug 58428

is($charinfo->{code},           '9FBA', 'U+9FBA');
is($charinfo->{name},           'CJK UNIFIED IDEOGRAPH-9FBA');
is($charinfo->{category},       'Lo');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'CJK Unified Ideographs');
is($charinfo->{script},         'Han');

use Unicode::UCD qw(charblock charscript);

# 0x0590 is in the Hebrew block but unused.

is(charblock(0x590),          'Hebrew', '0x0590 - Hebrew unused charblock');
is(charscript(0x590),         'Unknown',    '0x0590 - Hebrew unused charscript');
is(charblock(0x1FFFF),        'No_Block', '0x1FFFF - unused charblock');

$charinfo = charinfo(0xbe);

is($charinfo->{code},           '00BE', 'VULGAR FRACTION THREE QUARTERS');
is($charinfo->{name},           'VULGAR FRACTION THREE QUARTERS');
is($charinfo->{category},       'No');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'ON');
is($charinfo->{decomposition},  '<fraction> 0033 2044 0034');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '3/4');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      'FRACTION THREE QUARTERS');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '');
is($charinfo->{title},          '');
is($charinfo->{block},          'Latin-1 Supplement');
is($charinfo->{script},         'Common');

# This is to test a case where both simple and full lowercases exist and
# differ
$charinfo = charinfo(0x130);

is($charinfo->{code},           '0130', 'LATIN CAPITAL LETTER I WITH DOT ABOVE');
is($charinfo->{name},           'LATIN CAPITAL LETTER I WITH DOT ABOVE');
is($charinfo->{category},       'Lu');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '0049 0307');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      'LATIN CAPITAL LETTER I DOT');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '');
is($charinfo->{lower},          '0069');
is($charinfo->{title},          '');
is($charinfo->{block},          'Latin Extended-A');
is($charinfo->{script},         'Latin');

# This is to test a case where both simple and full uppercases exist and
# differ
$charinfo = charinfo(0x1F80);

is($charinfo->{code},           '1F80', 'GREEK SMALL LETTER ALPHA WITH PSILI AND YPOGEGRAMMENI');
is($charinfo->{name},           'GREEK SMALL LETTER ALPHA WITH PSILI AND YPOGEGRAMMENI');
is($charinfo->{category},       'Ll');
is($charinfo->{combining},      '0');
is($charinfo->{bidi},           'L');
is($charinfo->{decomposition},  '1F00 0345');
is($charinfo->{decimal},        '');
is($charinfo->{digit},          '');
is($charinfo->{numeric},        '');
is($charinfo->{mirrored},       'N');
is($charinfo->{unicode10},      '');
is($charinfo->{comment},        '');
is($charinfo->{upper},          '1F88');
is($charinfo->{lower},          '');
is($charinfo->{title},          '1F88');
is($charinfo->{block},          'Greek Extended');
is($charinfo->{script},         'Greek');

use Unicode::UCD qw(charblocks charscripts);

my $charblocks = charblocks();

ok(exists $charblocks->{Thai}, 'Thai charblock exists');
is($charblocks->{Thai}->[0]->[0], hex('0e00'));
ok(!exists $charblocks->{PigLatin}, 'PigLatin charblock does not exist');

my $charscripts = charscripts();

ok(exists $charscripts->{Armenian}, 'Armenian charscript exists');
is($charscripts->{Armenian}->[0]->[0], hex('0531'));
ok(!exists $charscripts->{PigLatin}, 'PigLatin charscript does not exist');

my $charscript;

$charscript = charscript("12ab");
is($charscript, 'Ethiopic', 'Ethiopic charscript');

$charscript = charscript("0x12ab");
is($charscript, 'Ethiopic');

$charscript = charscript("U+12ab");
is($charscript, 'Ethiopic');

my $ranges;

$ranges = charscript('Ogham');
is($ranges->[0]->[0], hex('1680'), 'Ogham charscript');
is($ranges->[0]->[1], hex('169C'));

use Unicode::UCD qw(charinrange);

$ranges = charscript('Cherokee');
ok(!charinrange($ranges, "139f"), 'Cherokee charscript');
ok( charinrange($ranges, "13a0"));
ok( charinrange($ranges, "13f4"));
ok(!charinrange($ranges, "13f5"));

use Unicode::UCD qw(general_categories);

my $gc = general_categories();

ok(exists $gc->{L}, 'has L');
is($gc->{L}, 'Letter', 'L is Letter');
is($gc->{Lu}, 'UppercaseLetter', 'Lu is UppercaseLetter');

use Unicode::UCD qw(bidi_types);

my $bt = bidi_types();

ok(exists $bt->{L}, 'has L');
is($bt->{L}, 'Left-to-Right', 'L is Left-to-Right');
is($bt->{AL}, 'Right-to-Left Arabic', 'AL is Right-to-Left Arabic');

# If this fails, then maybe one should look at the Unicode changes to see
# what else might need to be updated.
is(Unicode::UCD::UnicodeVersion, '6.0.0', 'UnicodeVersion');

use Unicode::UCD qw(compexcl);

ok(!compexcl(0x0100), 'compexcl');
ok(!compexcl(0xD801), 'compexcl of surrogate');
ok(!compexcl(0x110000), 'compexcl of non-Unicode code point');
ok( compexcl(0x0958));

use Unicode::UCD qw(casefold);

my $casefold;

$casefold = casefold(0x41);

is($casefold->{code}, '0041', 'casefold 0x41 code');
is($casefold->{status}, 'C', 'casefold 0x41 status');
is($casefold->{mapping}, '0061', 'casefold 0x41 mapping');
is($casefold->{full}, '0061', 'casefold 0x41 full');
is($casefold->{simple}, '0061', 'casefold 0x41 simple');
is($casefold->{turkic}, "", 'casefold 0x41 turkic');

$casefold = casefold(0xdf);

is($casefold->{code}, '00DF', 'casefold 0xDF code');
is($casefold->{status}, 'F', 'casefold 0xDF status');
is($casefold->{mapping}, '0073 0073', 'casefold 0xDF mapping');
is($casefold->{full}, '0073 0073', 'casefold 0xDF full');
is($casefold->{simple}, "", 'casefold 0xDF simple');
is($casefold->{turkic}, "", 'casefold 0xDF turkic');

# Do different tests depending on if version <= 3.1, or not.
(my $version = Unicode::UCD::UnicodeVersion) =~ /^(\d+)\.(\d+)/;
if (defined $1 && ($1 <= 2 || $1 == 3 && defined $2 && $2 <= 1)) {
	$casefold = casefold(0x130);

	is($casefold->{code}, '0130', 'casefold 0x130 code');
	is($casefold->{status}, 'I' , 'casefold 0x130 status');
	is($casefold->{mapping}, '0069', 'casefold 0x130 mapping');
	is($casefold->{full}, '0069', 'casefold 0x130 full');
	is($casefold->{simple}, "0069", 'casefold 0x130 simple');
	is($casefold->{turkic}, "0069", 'casefold 0x130 turkic');

	$casefold = casefold(0x131);

	is($casefold->{code}, '0131', 'casefold 0x131 code');
	is($casefold->{status}, 'I' , 'casefold 0x131 status');
	is($casefold->{mapping}, '0069', 'casefold 0x131 mapping');
	is($casefold->{full}, '0069', 'casefold 0x131 full');
	is($casefold->{simple}, "0069", 'casefold 0x131 simple');
	is($casefold->{turkic}, "0069", 'casefold 0x131 turkic');
} else {
	$casefold = casefold(0x49);

	is($casefold->{code}, '0049', 'casefold 0x49 code');
	is($casefold->{status}, 'C' , 'casefold 0x49 status');
	is($casefold->{mapping}, '0069', 'casefold 0x49 mapping');
	is($casefold->{full}, '0069', 'casefold 0x49 full');
	is($casefold->{simple}, "0069", 'casefold 0x49 simple');
	is($casefold->{turkic}, "0131", 'casefold 0x49 turkic');

	$casefold = casefold(0x130);

	is($casefold->{code}, '0130', 'casefold 0x130 code');
	is($casefold->{status}, 'F' , 'casefold 0x130 status');
	is($casefold->{mapping}, '0069 0307', 'casefold 0x130 mapping');
	is($casefold->{full}, '0069 0307', 'casefold 0x130 full');
	is($casefold->{simple}, "", 'casefold 0x130 simple');
	is($casefold->{turkic}, "0069", 'casefold 0x130 turkic');
}

$casefold = casefold(0x1F88);

is($casefold->{code}, '1F88', 'casefold 0x1F88 code');
is($casefold->{status}, 'S' , 'casefold 0x1F88 status');
is($casefold->{mapping}, '1F80', 'casefold 0x1F88 mapping');
is($casefold->{full}, '1F00 03B9', 'casefold 0x1F88 full');
is($casefold->{simple}, '1F80', 'casefold 0x1F88 simple');
is($casefold->{turkic}, "", 'casefold 0x1F88 turkic');

ok(!casefold(0x20));

use Unicode::UCD qw(casespec);

my $casespec;

ok(!casespec(0x41));

$casespec = casespec(0xdf);

ok($casespec->{code} eq '00DF' &&
   $casespec->{lower} eq '00DF'  &&
   $casespec->{title} eq '0053 0073'  &&
   $casespec->{upper} eq '0053 0053' &&
   !defined $casespec->{condition}, 'casespec 0xDF');

$casespec = casespec(0x307);

ok($casespec->{az}->{code} eq '0307' &&
   !defined $casespec->{az}->{lower} &&
   $casespec->{az}->{title} eq '0307'  &&
   $casespec->{az}->{upper} eq '0307' &&
   $casespec->{az}->{condition} eq 'az After_I',
   'casespec 0x307');

# perl #7305 UnicodeCD::compexcl is weird

for (1) {my $a=compexcl $_}
ok(1, 'compexcl read-only $_: perl #7305');
map {compexcl $_} %{{1=>2}};
ok(1, 'compexcl read-only hash: perl #7305');

is(Unicode::UCD::_getcode('123'),     123, "_getcode(123)");
is(Unicode::UCD::_getcode('0123'),  0x123, "_getcode(0123)");
is(Unicode::UCD::_getcode('0x123'), 0x123, "_getcode(0x123)");
is(Unicode::UCD::_getcode('0X123'), 0x123, "_getcode(0X123)");
is(Unicode::UCD::_getcode('U+123'), 0x123, "_getcode(U+123)");
is(Unicode::UCD::_getcode('u+123'), 0x123, "_getcode(u+123)");
is(Unicode::UCD::_getcode('U+1234'),   0x1234, "_getcode(U+1234)");
is(Unicode::UCD::_getcode('U+12345'), 0x12345, "_getcode(U+12345)");
is(Unicode::UCD::_getcode('123x'),    undef, "_getcode(123x)");
is(Unicode::UCD::_getcode('x123'),    undef, "_getcode(x123)");
is(Unicode::UCD::_getcode('0x123x'),  undef, "_getcode(x123)");
is(Unicode::UCD::_getcode('U+123x'),  undef, "_getcode(x123)");

{
    my $r1 = charscript('Latin');
    my $n1 = @$r1;
    is($n1, 30, "number of ranges in Latin script (Unicode 6.0.0)");
    shift @$r1 while @$r1;
    my $r2 = charscript('Latin');
    is(@$r2, $n1, "modifying results should not mess up internal caches");
}

{
	is(charinfo(0xdeadbeef), undef, "[perl #23273] warnings in Unicode::UCD");
}

use Unicode::UCD qw(namedseq);

is(namedseq("KATAKANA LETTER AINU P"), "\x{31F7}\x{309A}", "namedseq");
is(namedseq("KATAKANA LETTER AINU Q"), undef);
is(namedseq(), undef);
is(namedseq(qw(foo bar)), undef);
my @ns = namedseq("KATAKANA LETTER AINU P");
is(scalar @ns, 2);
is($ns[0], 0x31F7);
is($ns[1], 0x309A);
my %ns = namedseq();
is($ns{"KATAKANA LETTER AINU P"}, "\x{31F7}\x{309A}");
@ns = namedseq(42);
is(@ns, 0);

use Unicode::UCD qw(num);
use charnames ":full";

is(num("0"), 0, 'Verify num("0") == 0');
is(num("98765"), 98765, 'Verify num("98765") == 98765');
ok(! defined num("98765\N{FULLWIDTH DIGIT FOUR}"), 'Verify num("98765\N{FULLWIDTH DIGIT FOUR}") isnt defined');
is(num("\N{NEW TAI LUE DIGIT TWO}\N{NEW TAI LUE DIGIT ONE}"), 21, 'Verify num("\N{NEW TAI LUE DIGIT TWO}\N{NEW TAI LUE DIGIT ONE}") == 21');
ok(! defined num("\N{NEW TAI LUE DIGIT TWO}\N{NEW TAI LUE THAM DIGIT ONE}"), 'Verify num("\N{NEW TAI LUE DIGIT TWO}\N{NEW TAI LUE THAM DIGIT ONE}") isnt defined');
is(num("\N{CHAM DIGIT ZERO}\N{CHAM DIGIT THREE}"), 3, 'Verify num("\N{CHAM DIGIT ZERO}\N{CHAM DIGIT THREE}") == 3');
ok(! defined num("\N{CHAM DIGIT ZERO}\N{JAVANESE DIGIT NINE}"), 'Verify num("\N{CHAM DIGIT ZERO}\N{JAVANESE DIGIT NINE}") isnt defined');
is(num("\N{SUPERSCRIPT TWO}"), 2, 'Verify num("\N{SUPERSCRIPT TWO} == 2');
is(num("\N{ETHIOPIC NUMBER TEN THOUSAND}"), 10000, 'Verify num("\N{ETHIOPIC NUMBER TEN THOUSAND}") == 10000');
is(num("\N{NORTH INDIC FRACTION ONE HALF}"), .5, 'Verify num("\N{NORTH INDIC FRACTION ONE HALF}") == .5');
is(num("\N{U+12448}"), 9, 'Verify num("\N{U+12448}") == 9');

# Create a user-defined property
sub InKana {<<'END'}
3040    309F
30A0    30FF
END

use Unicode::UCD qw(prop_aliases);

is(prop_aliases(undef), undef, "prop_aliases(undef) returns <undef>");
is(prop_aliases("unknown property"), undef,
                "prop_aliases(<unknown property>) returns <undef>");
is(prop_aliases("InKana"), undef,
                "prop_aliases(<user-defined property>) returns <undef>");
is(prop_aliases("Perl_Decomposition_Mapping"), undef, "prop_aliases('Perl_Decomposition_Mapping') returns <undef> since internal-Perl-only");
is(prop_aliases("Perl_Charnames"), undef,
    "prop_aliases('Perl_Charnames') returns <undef> since internal-Perl-only");
is(prop_aliases("isgc"), undef,
    "prop_aliases('isgc') returns <undef> since is not covered Perl extension");
is(prop_aliases("Is_Is_Any"), undef,
                "prop_aliases('Is_Is_Any') returns <undef> since two is's");

require 'utf8_heavy.pl';
require "unicore/Heavy.pl";

# Keys are lists of properties. Values are defined if have been tested.
my %props;

# To test for loose matching, add in the characters that are ignored there.
my $extra_chars = "-_ ";

# The one internal property we accept
$props{'Perl_Decimal_Digit'} = 1;
my @list = prop_aliases("perldecimaldigit");
is_deeply(\@list,
          [ "Perl_Decimal_Digit",
            "Perl_Decimal_Digit"
          ], "prop_aliases('perldecimaldigit') returns Perl_Decimal_Digit as both short and full names");

# Get the official Unicode property name synonyms and test them.
open my $props, "<", "../lib/unicore/PropertyAliases.txt"
                or die "Can't open Unicode PropertyAliases.txt";
while (<$props>) {
    s/\s*#.*//;           # Remove comments
    next if /^\s* $/x;    # Ignore empty and comment lines

    chomp;
    my $count = 0;  # 0th field in line is short name; 1th is long name
    my $short_name;
    my $full_name;
    my @names_via_short;
    foreach my $alias (split /\s*;\s*/) {    # Fields are separated by
                                             # semi-colons
        # Add in the characters that are supposed to be ignored, to test loose
        # matching, which the tested function does on all inputs.
        my $mod_name = "$extra_chars$alias";

        my $loose = utf8::_loose_name(lc $alias);

        # Indicate we have tested this.
        $props{$loose} = 1;

        my @all_names = prop_aliases($mod_name);
        if (grep { $_ eq $loose } @Unicode::UCD::suppressed_properties) {
            is(@all_names, 0, "prop_aliases('$mod_name') returns undef since $alias is not installed");
            next;
        }
        elsif (! @all_names) {
            fail("prop_aliases('$mod_name')");
            diag("'$alias' is unknown to prop_aliases()");
            next;
        }

        if ($count == 0) {  # Is short name

            @names_via_short = prop_aliases($mod_name);

            # If the 0th test fails, no sense in continuing with the others
            last unless is($names_via_short[0], $alias,
                    "prop_aliases: '$alias' is the short name for '$mod_name'");
            $short_name = $alias;
        }
        elsif ($count == 1) {   # Is full name

            # Some properties have the same short and full name; no sense
            # repeating the test if the same.
            if ($alias ne $short_name) {
                my @names_via_full = prop_aliases($mod_name);
                is_deeply(\@names_via_full, \@names_via_short, "prop_aliases() returns the same list for both '$short_name' and '$mod_name'");
            }

            # Tests scalar context
            is(prop_aliases($short_name), $alias,
                "prop_aliases: '$alias' is the long name for '$short_name'");
        }
        else {  # Is another alias
            is_deeply(\@all_names, \@names_via_short, "prop_aliases() returns the same list for both '$short_name' and '$mod_name'");
            ok((grep { $_ =~ /^$alias$/i } @all_names),
                "prop_aliases: '$alias' is listed as an alias for '$mod_name'");
        }

        $count++;
    }
}

# Now test anything we can find that wasn't covered by the tests of the
# official properties.  We have no way of knowing if mktables omitted a Perl
# extension or not, but we do the best we can from its generated lists

foreach my $alias (keys %utf8::loose_to_file_of) {
    next if $alias =~ /=/;
    my $lc_name = lc $alias;
    my $loose = utf8::_loose_name($lc_name);
    next if exists $props{$loose};  # Skip if already tested
    $props{$loose} = 1;
    my $mod_name = "$extra_chars$alias";    # Tests loose matching
    my @aliases = prop_aliases($mod_name);
    my $found_it = grep { utf8::_loose_name(lc $_) eq $lc_name } @aliases;
    if ($found_it) {
        pass("prop_aliases: '$lc_name' is listed as an alias for '$mod_name'");
    }
    elsif ($lc_name =~ /l[_&]$/) {

        # These two names are special in that they don't appear in the
        # returned list because they are discouraged from use.  Verify
        # that they return the same list as a non-discouraged version.
        my @LC = prop_aliases('Is_LC');
        is_deeply(\@aliases, \@LC, "prop_aliases: '$lc_name' returns the same list as 'Is_LC'");
    }
    else {
        my $stripped = $lc_name =~ s/^is//;

        # Could be that the input includes a prefix 'is', which is rarely
        # returned as an alias, so having successfully stripped it off above,
        # try again.
        if ($stripped) {
            $found_it = grep { utf8::_loose_name(lc $_) eq $lc_name } @aliases;
        }

        # If that didn't work, it could be that it's a block, which is always
        # returned with a leading 'In_' to avoid ambiguity.  Try comparing
        # with that stripped off.
        if (! $found_it) {
            $found_it = grep { utf8::_loose_name(s/^In_(.*)/\L$1/r) eq $lc_name }
                              @aliases;
            # Could check that is a real block, but tests for invmap will
            # likely pickup any errors, since this will be tested there.
            $lc_name = "in$lc_name" if $found_it;   # Change for message below
        }
        my $message = "prop_aliases: '$lc_name' is listed as an alias for '$mod_name'";
        ($found_it) ? pass($message) : fail($message);
    }
}

my $done_equals = 0;
foreach my $alias (keys %utf8::stricter_to_file_of) {
    if ($alias =~ /=/) {    # Only test one case where there is an equals
        next if $done_equals;
        $done_equals = 1;
    }
    my $lc_name = lc $alias;
    my @list = prop_aliases($alias);
    if ($alias =~ /^_/) {
        is(@list, 0, "prop_aliases: '$lc_name' returns an empty list since it is internal_only");
    }
    elsif ($alias =~ /=/) {
        is(@list, 0, "prop_aliases: '$lc_name' returns an empty list since is illegal property name");
    }
    else {
        ok((grep { lc $_ eq $lc_name } @list),
                "prop_aliases: '$lc_name' is listed as an alias for '$alias'");
    }
}

use Unicode::UCD qw(prop_value_aliases);

is(prop_value_aliases("unknown property", "unknown value"), undef,
    "prop_value_aliases(<unknown property>, <unknown value>) returns <undef>");
is(prop_value_aliases(undef, undef), undef,
                           "prop_value_aliases(undef, undef) returns <undef>");
is((prop_value_aliases("na", "A")), "A", "test that prop_value_aliases returns its input for properties that don't have synonyms");
is(prop_value_aliases("isgc", "C"), undef, "prop_value_aliases('isgc', 'C') returns <undef> since is not covered Perl extension");
is(prop_value_aliases("gc", "isC"), undef, "prop_value_aliases('gc', 'isC') returns <undef> since is not covered Perl extension");

# We have no way of knowing if mktables omitted a Perl extension that it
# shouldn't have, but we can check if it omitted an official Unicode property
# name synonym.  And for those, we can check if the short and full names are
# correct.

my %pva_tested;   # List of things already tested.
open my $propvalues, "<", "../lib/unicore/PropValueAliases.txt"
     or die "Can't open Unicode PropValueAliases.txt";
while (<$propvalues>) {
    s/\s*#.*//;           # Remove comments
    next if /^\s* $/x;    # Ignore empty and comment lines
    chomp;

    my @fields = split /\s*;\s*/; # Fields are separated by semi-colons
    my $prop = shift @fields;   # 0th field is the property,
    my $count = 0;  # 0th field in line (after shifting off the property) is
                    # short name; 1th is long name
    my $short_name;
    my @names_via_short;    # Saves the values between iterations

    # The property on the lhs of the = is always loosely matched.  Add in
    # characters that are ignored under loose matching to test that
    my $mod_prop = "$extra_chars$prop";

    if ($fields[0] eq 'n/a') {  # See comments in input file, essentially
                                # means full name and short name are identical
        $fields[0] = $fields[1];
    }
    elsif ($fields[0] ne $fields[1]
           && utf8::_loose_name(lc $fields[0])
               eq utf8::_loose_name(lc $fields[1])
           && $fields[1] !~ /[[:upper:]]/)
    {
        # Also, there is a bug in the file in which "n/a" is omitted, and
        # the two fields are identical except for case, and the full name
        # is all lower case.  Copy the "short" name unto the full one to
        # give it some upper case.

        $fields[1] = $fields[0];
    }

    # The ccc property in the file is special; has an extra numeric field
    # (0th), which should go at the end, since we use the next two fields as
    # the short and full names, respectively.  See comments in input file.
    splice (@fields, 0, 0, splice(@fields, 1, 2)) if $prop eq 'ccc';

    my $loose_prop = utf8::_loose_name(lc $prop);
    my $suppressed = grep { $_ eq $loose_prop }
                          @Unicode::UCD::suppressed_properties;
    foreach my $value (@fields) {
        if ($suppressed) {
            is(prop_value_aliases($prop, $value), undef, "prop_value_aliases('$prop', '$value') returns undef for suppressed property $prop");
            next;
        }
        elsif (grep { $_ eq ("$loose_prop=" . utf8::_loose_name(lc $value)) } @Unicode::UCD::suppressed_properties) {
            is(prop_value_aliases($prop, $value), undef, "prop_value_aliases('$prop', '$value') returns undef for suppressed property $prop=$value");
            next;
        }

        # Add in test for loose matching.
        my $mod_value = "$extra_chars$value";

        # If the value is a number, optionally negative, including a floating
        # point or rational numer, it should be only strictly matched, so the
        # loose matching should fail.
        if ($value =~ / ^ -? \d+ (?: [\/.] \d+ )? $ /x) {
            is(prop_value_aliases($mod_prop, $mod_value), undef, "prop_value_aliases('$mod_prop', '$mod_value') returns undef because '$mod_value' should be strictly matched");

            # And reset so below tests just the strict matching.
            $mod_value = $value;
        }

        if ($count == 0) {

            @names_via_short = prop_value_aliases($mod_prop, $mod_value);

            # If the 0th test fails, no sense in continuing with the others
            last unless is($names_via_short[0], $value, "prop_value_aliases: In '$prop', '$value' is the short name for '$mod_value'");
            $short_name = $value;
        }
        elsif ($count == 1) {

            # Some properties have the same short and full name; no sense
            # repeating the test if the same.
            if ($value ne $short_name) {
                my @names_via_full =
                            prop_value_aliases($mod_prop, $mod_value);
                is_deeply(\@names_via_full, \@names_via_short, "In '$prop', prop_value_aliases() returns the same list for both '$short_name' and '$mod_value'");
            }

            # Tests scalar context
            is(prop_value_aliases($prop, $short_name), $value, "'$value' is the long name for prop_value_aliases('$prop', '$short_name')");
        }
        else {
            my @all_names = prop_value_aliases($mod_prop, $mod_value);
            is_deeply(\@all_names, \@names_via_short, "In '$prop', prop_value_aliases() returns the same list for both '$short_name' and '$mod_value'");
            ok((grep { utf8::_loose_name(lc $_) eq utf8::_loose_name(lc $value) } prop_value_aliases($prop, $short_name)), "'$value' is listed as an alias for prop_value_aliases('$prop', '$short_name')");
        }

        $pva_tested{utf8::_loose_name(lc $prop) . "=" . utf8::_loose_name(lc $value)} = 1;
        $count++;
    }
}

# And test as best we can, the non-official pva's that mktables generates.
foreach my $hash (\%utf8::loose_to_file_of, \%utf8::stricter_to_file_of) {
    foreach my $test (keys %$hash) {
        next if exists $pva_tested{$test};  # Skip if already tested

        my ($prop, $value) = split "=", $test;
        next unless defined $value; # prop_value_aliases() requires an input
                                    # 'value'
        my $mod_value;
        if ($hash == \%utf8::loose_to_file_of) {

            # Add extra characters to test loose-match rhs value
            $mod_value = "$extra_chars$value";
        }
        else { # Here value is strictly matched.

            # Extra elements are added by mktables to this hash so that
            # something like "age=6.0" has a synonym of "age=6".  It's not
            # clear to me (khw) if we should be encouraging those synonyms, so
            # don't test for them.
            next if $value !~ /\D/ && exists $hash->{"$prop=$value.0"};

            # Verify that loose matching fails when only strict is called for.
            next unless is(prop_value_aliases($prop, "$extra_chars$value"), undef,
                        "prop_value_aliases('$prop', '$extra_chars$value') returns undef since '$value' should be strictly matched"),

            # Strict matching does allow for underscores between digits.  Test
            # for that.
            $mod_value = $value;
            while ($mod_value =~ s/(\d)(\d)/$1_$2/g) {}
        }

        # The lhs property is always loosely matched, so add in extra
        # characters to test that.
        my $mod_prop = "$extra_chars$prop";

        if ($prop eq 'gc' && $value =~ /l[_&]$/) {
            # These two names are special in that they don't appear in the
            # returned list because they are discouraged from use.  Verify
            # that they return the same list as a non-discouraged version.
            my @LC = prop_value_aliases('gc', 'lc');
            my @l_ = prop_value_aliases($mod_prop, $mod_value);
            is_deeply(\@l_, \@LC, "prop_value_aliases('$mod_prop', '$mod_value) returns the same list as prop_value_aliases('gc', 'lc')");
        }
        else {
            ok((grep { utf8::_loose_name(lc $_) eq utf8::_loose_name(lc $value) }
                prop_value_aliases($mod_prop, $mod_value)),
                "'$value' is listed as an alias for prop_value_aliases('$mod_prop', '$mod_value')");
        }
    }
}

undef %pva_tested;

done_testing();
