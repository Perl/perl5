# Exercise the tokenpos buffer allocation routines by feeding it
# very large tags.

print "1..2\n";

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

$p->handler("start" =>
	    sub {
		my $tp = shift;
		#print int(@$tp), " - ", join(", ", @$tp), "\n";
		print "not " unless @$tp == 2 + 26 * 6 * 4;
		print "ok 1\n";
	    }, "tokenpos");

$p->handler("declaration" =>
	    sub {
		my $t = shift;
		#print int(@$t), " - @$t\n";
		print "not " unless @$t == 26 * 6 * 2 + 1;
		print "ok 2\n";
	    }, "tokens");

$p->parse("<a ");
for ("aa" .. "fz") {
    $p->parse("$_=1 ");
}
$p->parse(">");

$p->parse("<!DOCTYPE ");
for ("aa" .. "fz") {
    $p->parse("$_ -- $_ -- ");
}
$p->parse(">");
$p->eof;
exit;

