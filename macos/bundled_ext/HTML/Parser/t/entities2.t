print "1..6\n";

use strict;
use HTML::Entities qw(_decode_entities);

eval {
    _decode_entities("&lt;", undef);
};
print "not " unless $@ && $@ =~ /^Can't inline decode readonly string/;
print "ok 1\n";

eval {
    my $a = "";
    _decode_entities($a, $a);
};
print "not " unless $@ && $@ =~ /^2nd argument must be hash reference/;
print "ok 2\n";

eval {
    my $a = "";
    _decode_entities($a, []);
};
print "not " unless $@ && $@ =~ /^2nd argument must be hash reference/;
print "ok 3\n";

$a = "&lt;";
_decode_entities($a, undef);
print "not " unless $a eq "&lt;";
print "ok 4\n";

_decode_entities($a, { "lt" => "<" });
print "not " unless $a eq "<";
print "ok 5\n";

my $x = "x" x 20;

my $err;
for (":", ":a", "a:", "a:a", "a:a:a", "a:::a") {
    my $a = $_;
    $a =~ s/:/&a;/g;
    my $b = $_;
    $b =~ s/:/$x/g;
    _decode_entities($a, { "a" => $x });
    if ($a ne $b) {
	print "Something went wrong with '$_'\n";
	$err++;
    }
}
print "not " if $err;
print "ok 6\n";
