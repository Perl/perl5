#!perl -w

BEGIN {
    eval {
	require Perl::API;
    };
    if ($@) {
	print "1..0 # skipped: Perl::API needed for this test\n";
	print $@;
	exit;
    }
}

use strict;
use Test qw(plan ok);
use Perl::API qw(SvCUR SvCUR_set SvLEN);
use MIME::Base64 qw(encode_base64 decode_base64);
use MIME::QuotedPrint qw(encode_qp decode_qp);

plan tests => 6;

my $a = "abc";

ok(SvCUR($a), 3);
ok(SvLEN($a), 4);

# Make sure that encode_base64 does not look beyond SvCUR().
# This was fixed in v2.21.  Valgrind would also show some
# illegal reads on this.

SvCUR_set($a, 1);
ok(encode_base64($a), "YQ==\n");

SvCUR_set($a, 4);
ok(encode_base64($a), "YWJjAA==\n");

ok(encode_qp($a), "abc=00");

$a = "ab\n";

SvCUR_set($a, 2);
ok(encode_qp($a), "ab");
