# Exercise the tokenpos buffer allocation routines by feeding it
# very large tags.

use Test::More tests => 2;

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

$p->handler("start" =>
	    sub {
		my $tp = shift;
		#diag int(@$tp), " - ", join(", ", @$tp);
		is(@$tp, 2 + 26 * 6 * 4);
	    }, "tokenpos");

$p->handler("declaration" =>
	    sub {
		my $t = shift;
		#diag int(@$t), " - @$t";
		is(@$t, 26 * 6 * 2 + 1);
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

