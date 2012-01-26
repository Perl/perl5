#!./perl -w
use strict;

# Tests for the Copy overlap checker.
use Test::More;
use XS::APItest 'Copy';

my @tests = (["ABCD", 0, 2, 2, "ABAB"],
	     ["ABCD", 0, 2, 1, "ABAD"],
	     ["ABCD", 2, 0, 2, "CDCD"],
	     ["ABCD", 2, 0, 1, "CBCD"],
	     ["ABCD", 2, 1, 2, qr/^Copy.*From.*To/],
	     ["ABCD", 0, 1, 2, qr/^Copy.*To.*From/],
	    );

plan (tests => 2 * @tests);

foreach (@tests) {
    my ($buffer, $src, $dest, $len, $want) = @$_;
    my $name = "Copy('$buffer', $src, $dest, $len)";
    if (ref $want) {
	is(eval {
	    Copy($buffer, $src, $dest, $len);
	    1;
	}, undef, "$name should fail");
	like($@, $want, "$name gave expected error");
    } else {
	is(eval {
	    Copy($buffer, $src, $dest, $len);
	    1;
	}, 1, "$name should not fail")
	    or diag("\$@ = $@");
	is($buffer, $want, "$name gave expected result");
    }
}
