use Unicode::UCD 3.1.0;

use Test;
use strict;

BEGIN { plan tests => 81 };

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

use Unicode::UCD 'charblock';

ok(charblock(0x590),          'Hebrew');

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

