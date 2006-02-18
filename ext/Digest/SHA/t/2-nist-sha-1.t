use Test;
use strict;
use integer;
use Digest::SHA qw(sha1_hex);

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
"a9993e364706816aba3e25717850c26c9cd0d89d",
"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
"34aa973cd4c4daa4f61eeb2bdbad27316534016f"
	);

	plan tests => scalar(@vec);
}

for (my $i = 0; $i < @vec; $i++) {
	ok(sha1_hex($vec[$i]), $rsp[$i]);
}
