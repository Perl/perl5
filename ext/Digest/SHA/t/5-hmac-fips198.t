use Test;
use strict;
use integer;
use Digest::SHA qw(hmac_sha1_hex);

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

my(@vec);

BEGIN {
	@vec = (
		"Sample #1",
		"Sample #2",
		"Sample #3",
		"Sample #4"
	);
	plan tests => scalar(@vec);
}

my @keys = ("", "", "", "");

my $i = 0;
$keys[0] .= chr($i++) while (length($keys[0]) < 64);

$i = 0x30;
$keys[1] .= chr($i++) while (length($keys[1]) < 20);

$i = 0x50;
$keys[2] .= chr($i++) while (length($keys[2]) < 100);

$i = 0x70;
$keys[3] .= chr($i++) while (length($keys[3]) < 49);

my @hmac1rsp = (
	"4f4ca3d5d68ba7cc0a1208c9c61e9c5da0403c0a",
	"0922d3405faa3d194f82a45830737d5cc6c75d24",
	"bcf41eab8bb2d802f3d05caf7cb092ecf8d1a3aa",
	"9ea886efe268dbecce420c7524df32e0751a2a26"
);

for ($i = 0; $i < @vec; $i++) {
	ok(
		hmac_sha1_hex($vec[$i], $keys[$i]),
		$hmac1rsp[$i]
	);
}
