use Unicode::UCD;

use Test;
use strict;

BEGIN { plan tests => 103 };

use Unicode::UCD 'charinfo';

my %charinfo;

%charinfo = charinfo(0x41);

ok($charinfo{code},           '0041');
ok($charinfo{name},           'LATIN CAPITAL LETTER A');
ok($charinfo{category},       'Lu');
ok($charinfo{combining},      '0');
ok($charinfo{bidi},           'L');
ok($charinfo{decomposition},  '');
ok($charinfo{decimal},        '');
ok($charinfo{digit},          '');
ok($charinfo{numeric},        '');
ok($charinfo{mirrored},       'N');
ok($charinfo{unicode10},      '');
ok($charinfo{comment},        '');
ok($charinfo{upper},          '');
ok($charinfo{lower},          '0061');
ok($charinfo{title},          '');
ok($charinfo{block},          'Basic Latin');
ok($charinfo{script},         'LATIN');

%charinfo = charinfo(0x100);

ok($charinfo{code},           '0100');
ok($charinfo{name},           'LATIN CAPITAL LETTER A WITH MACRON');
ok($charinfo{category},       'Lu');
ok($charinfo{combining},      '0');
ok($charinfo{bidi},           'L');
ok($charinfo{decomposition},  '0041 0304');
ok($charinfo{decimal},        '');
ok($charinfo{digit},          '');
ok($charinfo{numeric},        '');
ok($charinfo{mirrored},       'N');
ok($charinfo{unicode10},      'LATIN CAPITAL LETTER A MACRON');
ok($charinfo{comment},        '');
ok($charinfo{upper},          '');
ok($charinfo{lower},          '0101');
ok($charinfo{title},          '');
ok($charinfo{block},          'Latin Extended-A');
ok($charinfo{script},         'LATIN');

# 0x0590 is in the Hebrew block but unused.

%charinfo = charinfo(0x590);

ok($charinfo{code},          undef);
ok($charinfo{name},          undef);
ok($charinfo{category},      undef);
ok($charinfo{combining},     undef);
ok($charinfo{bidi},          undef);
ok($charinfo{decomposition}, undef);
ok($charinfo{decimal},       undef);
ok($charinfo{digit},         undef);
ok($charinfo{numeric},       undef);
ok($charinfo{mirrored},      undef);
ok($charinfo{unicode10},     undef);
ok($charinfo{comment},       undef);
ok($charinfo{upper},         undef);
ok($charinfo{lower},         undef);
ok($charinfo{title},         undef);
ok($charinfo{block},         undef);
ok($charinfo{script},        undef);

# 0x05d0 is in the Hebrew block and used.

%charinfo = charinfo(0x5d0);

ok($charinfo{code},           '05D0');
ok($charinfo{name},           'HEBREW LETTER ALEF');
ok($charinfo{category},       'Lo');
ok($charinfo{combining},      '0');
ok($charinfo{bidi},           'R');
ok($charinfo{decomposition},  '');
ok($charinfo{decimal},        '');
ok($charinfo{digit},          '');
ok($charinfo{numeric},        '');
ok($charinfo{mirrored},       'N');
ok($charinfo{unicode10},      '');
ok($charinfo{comment},        '');
ok($charinfo{upper},          '');
ok($charinfo{lower},          '');
ok($charinfo{title},          '');
ok($charinfo{block},          'Hebrew');
ok($charinfo{script},         'Hebrew');

use Unicode::UCD qw(charblock charscript);

# 0x0590 is in the Hebrew block but unused.

ok(charblock(0x590),          'Hebrew');
ok(charscript(0x590),         undef);

%charinfo = charinfo(0xbe);

ok($charinfo{code},           '00BE');
ok($charinfo{name},           'VULGAR FRACTION THREE QUARTERS');
ok($charinfo{category},       'No');
ok($charinfo{combining},      '0');
ok($charinfo{bidi},           'ON');
ok($charinfo{decomposition},  '<fraction> 0033 2044 0034');
ok($charinfo{decimal},        '');
ok($charinfo{digit},          '');
ok($charinfo{numeric},        '3/4');
ok($charinfo{mirrored},       'N');
ok($charinfo{unicode10},      'FRACTION THREE QUARTERS');
ok($charinfo{comment},        '');
ok($charinfo{upper},          '');
ok($charinfo{lower},          '');
ok($charinfo{title},          '');
ok($charinfo{block},          'Latin-1 Supplement');
ok($charinfo{script},         undef);

use Unicode::UCD qw(charblocks charscripts);

my %charblocks = charblocks();

ok(exists $charblocks{Thai});
ok($charblocks{Thai}->[0]->[0], hex('0e00'));
ok(!exists $charblocks{PigLatin});

my %charscripts = charscripts();

ok(exists $charscripts{Armenian});
ok($charscripts{Armenian}->[0]->[0], hex('0531'));
ok(!exists $charscripts{PigLatin});

my $charscript;

$charscript = charscript("12ab");
ok($charscript, 'Ethiopic');

$charscript = charscript("0x12ab");
ok($charscript, 'Ethiopic');

$charscript = charscript("U+12ab");
ok($charscript, 'Ethiopic');

my $ranges;

$ranges = charscript('Ogham');
ok($ranges->[0]->[0], hex('1681'));
ok($ranges->[0]->[1], hex('169a'));

use Unicode::UCD qw(charinrange);

$ranges = charscript('Cherokee');
ok(!charinrange($ranges, "139f"));
ok( charinrange($ranges, "13a0"));
ok( charinrange($ranges, "13f4"));
ok(!charinrange($ranges, "13f5"));

ok(Unicode::UCD::UnicodeVersion, 3.1);
