use Test;
use strict;
use integer;
use Digest::SHA qw(sha256_hex);

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

my(@vec, @rsp);

BEGIN {
	@vec = (
"abc",
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
"a" x 1000000
	);

	@rsp = (
"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
	);

	plan tests => scalar(@vec);
}

for (my $i = 0; $i < @vec; $i++) {
	ok(sha256_hex($vec[$i]), $rsp[$i]);
}
