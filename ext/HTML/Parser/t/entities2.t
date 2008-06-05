#!perl -w

use strict;
use Test::More tests => 9;

use HTML::Entities qw(_decode_entities);

eval {
    _decode_entities("&lt;", undef);
};
like($@, qr/^Can't inline decode readonly string/);

eval {
    my $a = "";
    _decode_entities($a, $a);
};
like($@, qr/^2nd argument must be hash reference/);

eval {
    my $a = "";
    _decode_entities($a, []);
};
like($@, qr/^2nd argument must be hash reference/);

$a = "&lt;";
_decode_entities($a, undef);
is($a, "&lt;");

_decode_entities($a, { "lt" => "<" });
is($a, "<");

my $x = "x" x 20;

my $err;
for (":", ":a", "a:", "a:a", "a:a:a", "a:::a") {
    my $a = $_;
    $a =~ s/:/&a;/g;
    my $b = $_;
    $b =~ s/:/$x/g;
    _decode_entities($a, { "a" => $x });
    if ($a ne $b) {
	diag "Something went wrong with '$_'";
	$err++;
    }
}
ok(!$err);

$a = "foo&nbsp;bar";
_decode_entities($a, \%HTML::Entities::entity2char);
is($a, "foo\xA0bar");

$a = "foo&nbspbar";
_decode_entities($a, \%HTML::Entities::entity2char);
is($a, "foo&nbspbar");

_decode_entities($a, \%HTML::Entities::entity2char, 1);
is($a, "foo\xA0bar");
