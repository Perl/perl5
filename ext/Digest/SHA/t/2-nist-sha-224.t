use Test;
use strict;
use integer;
use Digest::SHA qw(sha224_hex);

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
"23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
"75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525",
"20794655980c91d8bbb4c1ea97618a4bf03f42581948b2ee4ee7ad67"
	);

	plan tests => scalar(@vec);
}

for (my $i = 0; $i < @vec; $i++) {
	ok(sha224_hex($vec[$i]), $rsp[$i]);
}
