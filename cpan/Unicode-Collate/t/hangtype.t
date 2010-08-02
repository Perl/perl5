BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	print "1..0 # Unicode::Collate " .
	    "cannot stringify a Unicode code point\n";
	exit 0;
    }
}

use Test;
BEGIN { plan tests => 70 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

##### 2..35
ok(Unicode::Collate::getHST(0x0000), '');
ok(Unicode::Collate::getHST(0x0100), '');
ok(Unicode::Collate::getHST(0x1000), '');
ok(Unicode::Collate::getHST(0x10FF), '');
ok(Unicode::Collate::getHST(0x1100), 'L');
ok(Unicode::Collate::getHST(0x1101), 'L');
ok(Unicode::Collate::getHST(0x1159), 'L');
ok(Unicode::Collate::getHST(0x115A), '');
ok(Unicode::Collate::getHST(0x115A, 18), '');
ok(Unicode::Collate::getHST(0x115A, 20), 'L');
ok(Unicode::Collate::getHST(0x115E), '');
ok(Unicode::Collate::getHST(0x115E, 18), '');
ok(Unicode::Collate::getHST(0x115E, 20), 'L');
ok(Unicode::Collate::getHST(0x115F), 'L');
ok(Unicode::Collate::getHST(0x1160), 'V');
ok(Unicode::Collate::getHST(0x1161), 'V');
ok(Unicode::Collate::getHST(0x11A0), 'V');
ok(Unicode::Collate::getHST(0x11A2), 'V');
ok(Unicode::Collate::getHST(0x11A3), '');
ok(Unicode::Collate::getHST(0x11A3, 18), '');
ok(Unicode::Collate::getHST(0x11A3, 20), 'V');
ok(Unicode::Collate::getHST(0x11A7), '');
ok(Unicode::Collate::getHST(0x11A7, 18), '');
ok(Unicode::Collate::getHST(0x11A7, 20), 'V');
ok(Unicode::Collate::getHST(0x11A8), 'T');
ok(Unicode::Collate::getHST(0x11AF), 'T');
ok(Unicode::Collate::getHST(0x11E0), 'T');
ok(Unicode::Collate::getHST(0x11F9), 'T');
ok(Unicode::Collate::getHST(0x11FA), '');
ok(Unicode::Collate::getHST(0x11FA, 18), '');
ok(Unicode::Collate::getHST(0x11FA, 20), 'T');
ok(Unicode::Collate::getHST(0x11FF), '');
ok(Unicode::Collate::getHST(0x11FF, 18), '');
ok(Unicode::Collate::getHST(0x11FF, 20), 'T');

##### 36..44
ok(Unicode::Collate::getHST(0x3011), '');
ok(Unicode::Collate::getHST(0xABFF), '');
ok(Unicode::Collate::getHST(0xAC00), 'LV');
ok(Unicode::Collate::getHST(0xAC01), 'LVT');
ok(Unicode::Collate::getHST(0xAC1B), 'LVT');
ok(Unicode::Collate::getHST(0xAC1C), 'LV');
ok(Unicode::Collate::getHST(0xD7A3), 'LVT');
ok(Unicode::Collate::getHST(0xD7A4), '');
ok(Unicode::Collate::getHST(0xFFFF), '');

##### 45..57
ok(Unicode::Collate::getHST(0xA960, 18), '');
ok(Unicode::Collate::getHST(0xA961, 18), '');
ok(Unicode::Collate::getHST(0xA97C, 18), '');
ok(Unicode::Collate::getHST(0xD7B0, 18), '');
ok(Unicode::Collate::getHST(0xD7C0, 18), '');
ok(Unicode::Collate::getHST(0xD7C6, 18), '');
ok(Unicode::Collate::getHST(0xD7C7, 18), '');
ok(Unicode::Collate::getHST(0xD7CA, 18), '');
ok(Unicode::Collate::getHST(0xD7CB, 18), '');
ok(Unicode::Collate::getHST(0xD7DD, 18), '');
ok(Unicode::Collate::getHST(0xD7FB, 18), '');
ok(Unicode::Collate::getHST(0xD7FC, 18), '');
ok(Unicode::Collate::getHST(0xD7FF, 18), '');

##### 58..70
ok(Unicode::Collate::getHST(0xA960, 20), 'L');
ok(Unicode::Collate::getHST(0xA961, 20), 'L');
ok(Unicode::Collate::getHST(0xA97C, 20), 'L');
ok(Unicode::Collate::getHST(0xD7B0, 20), 'V');
ok(Unicode::Collate::getHST(0xD7C0, 20), 'V');
ok(Unicode::Collate::getHST(0xD7C6, 20), 'V');
ok(Unicode::Collate::getHST(0xD7C7, 20), '');
ok(Unicode::Collate::getHST(0xD7CA, 20), '');
ok(Unicode::Collate::getHST(0xD7CB, 20), 'T');
ok(Unicode::Collate::getHST(0xD7DD, 20), 'T');
ok(Unicode::Collate::getHST(0xD7FB, 20), 'T');
ok(Unicode::Collate::getHST(0xD7FC, 20), '');
ok(Unicode::Collate::getHST(0xD7FF, 20), '');
