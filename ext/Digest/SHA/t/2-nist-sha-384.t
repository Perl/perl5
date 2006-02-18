use Test;
use strict;
use integer;
use Digest::SHA qw(sha384_hex);

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
"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
"a" x 1000000
	);

	@rsp = (
"cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7",
"09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039",
"9d0e1809716474cb086e834e310a4a1ced149e9c00f248527972cec5704c2a5b07b8b3dc38ecc4ebae97ddd87f3d8985"
	);

	plan tests => scalar(@vec);
}

my $skip = sha384_hex("") ? 0 : 1;

for (my $i = 0; $i < @vec; $i++) {
	skip($skip, sha384_hex($vec[$i]), $rsp[$i]);
}
