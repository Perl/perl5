# Test Unicode entities

BEGIN {
    if ($] < 5.006) {
	print "This perl does not support Unicode\n";
	print "1..0\n";
	exit;
    }
}

use HTML::Entities;

unless (&HTML::Entities::UNICODE_SUPPORT) {
    print "Unicode entities not selected\n";
    print "1..0\n";
    exit;
}

print "1..10\n";

print "not " unless decode_entities("&euro") eq "\x{20AC}";
print "ok 1\n";

print "not " unless decode_entities("&aring") eq "е";
print "ok 2\n";

print "not " unless decode_entities("&#500000") eq chr(500000);
print "ok 3\n";

print "not " unless decode_entities("&#xFFFF") eq "\x{FFFF}";
print "ok 4\n";

print "not " unless decode_entities("&#x10FFFF") eq chr(0x10FFFF);
print "ok 5\n";

print "not " unless decode_entities("&#XFFFFFFFF") eq chr(0xFFFF_FFFF);
print "ok 6\n";

print "not " unless decode_entities("&#0") eq "\0" &&
                    decode_entities("&#0;") eq "\0" &&
                    decode_entities("&#x0") eq "\0" &&
                    decode_entities("&#X0;") eq "\0";
print "ok 7\n";

print "not " unless decode_entities("&#&aring&#229&#229;&#xFFF") eq
                                    "&#еее\x{FFF}";
print "ok 8\n";

# This might fail when we get more than 64 bit UVs
print "not " unless decode_entities("&#0009999999999999999999999999999;") eq
                                    "&#0009999999999999999999999999999;"
                and decode_entities("&#xFFFF0000FFFF0000FFFF1") eq
                                    "&#xFFFF0000FFFF0000FFFF1";
print "ok 9\n";

my $err;
for ([32, 48], [120, 169], [240, 250], [250, 260], [965, 975], [3000, 3005]) {
    my $a = join("", map chr, $_->[0] .. $_->[1]);

    #print join(", ", unpack("U*", $a)), "\n";

    my $e = encode_entities($a);
    my $d = decode_entities($e);

    print "\n$_->[0] .. $_->[1]\n";
    #print "$a\n";
    print "$e\n";

    unless ($d eq $a) {
	print "Wrong decoding in range $_->[0] .. $_->[1]\n";
	# use Devel::Peek; Dump($a); Dump($d);
	$err++;
    }
}
print "not " if $err;
print "ok 10\n";


