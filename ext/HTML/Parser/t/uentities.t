# Test Unicode entities

use HTML::Entities;

use Test::More tests => 27;

SKIP: {
skip "This perl does not support Unicode or Unicode entities not selected",
  27 if $] < 5.008 || !&HTML::Entities::UNICODE_SUPPORT;

is(decode_entities("&euro"), "&euro");
is(decode_entities("&euro;"), "\x{20AC}");

is(decode_entities("&aring"), "е");
is(decode_entities("&aring;"), "е");

is(decode_entities("&#500000"), chr(500000));

is(decode_entities("&#x10FFFD"), "\x{10FFFD}");

is(decode_entities("&#xFFFC"), "\x{FFFC}");


is(decode_entities("&#xFDD0"), "\x{FFFD}");
is(decode_entities("&#xFDD1"), "\x{FFFD}");
is(decode_entities("&#xFDE0"), "\x{FFFD}");
is(decode_entities("&#xFDEF"), "\x{FFFD}");
is(decode_entities("&#xFFFF"), "\x{FFFD}");
is(decode_entities("&#x10FFFF"), "\x{FFFD}");
is(decode_entities("&#x110000"), chr(0xFFFD));
is(decode_entities("&#XFFFFFFFF"), chr(0xFFFD));

is(decode_entities("&#0"), "\0");
is(decode_entities("&#0;"), "\0");
is(decode_entities("&#x0"), "\0");
is(decode_entities("&#X0;"), "\0");

is(decode_entities("&#&aring&#229&#229;&#xFFF"), "&#еее\x{FFF}");

# This might fail when we get more than 64 bit UVs
is(decode_entities("&#0009999999999999999999999999999;"), "&#0009999999999999999999999999999;");
is(decode_entities("&#xFFFF0000FFFF0000FFFF1"), "&#xFFFF0000FFFF0000FFFF1");

my $err;
for ([32, 48], [120, 169], [240, 250], [250, 260], [965, 975], [3000, 3005]) {
    my $a = join("", map chr, $_->[0] .. $_->[1]);

    my $e = encode_entities($a);
    my $d = decode_entities($e);

    unless ($d eq $a) {
	diag "Wrong decoding in range $_->[0] .. $_->[1]";
	# use Devel::Peek; Dump($a); Dump($d);
	$err++;
    }
}
ok(!$err);


is(decode_entities("&#56256;&#56453;"), chr(0x100085));

is(decode_entities("&#56256;&#56453;"), chr(0x100085));

is(decode_entities("&#56256"), chr(0xFFFD));

is(decode_entities("\260&rsquo;\260"), "\x{b0}\x{2019}\x{b0}");
}
