use strict;

use Test::More tests => 12;

my $pi;
my $orig;

use HTML::Parser ();
my $p = HTML::Parser->new(process_h => [sub { $pi = shift; $orig = shift; },
				        "token0,text"]
	                 );

$p->parse("<a><?foo><a>");

is($pi, "foo");
is($orig, "<?foo>");

$p->parse("<a><?><a>");
is($pi, "");
is($orig, "<?>");

$p->parse("<a><?
foo
><a>");
is($pi, "\nfoo\n");
is($orig, "<?\nfoo\n>");

for (qw(< a > < ? b a r > < a >)) {
   $p->parse($_);
}

is($pi, "bar");
is($orig, "<?bar>");

$p->xml_mode(1);

$p->parse("<a><?foo>bar??><a>");
is($pi, "foo>bar?");
is($orig, "<?foo>bar??>");

$p->parse("<a><??></a>");
is($pi, "");
is($orig, "<??>");
