use strict;

print "1..6\n";

my $pi;
my $orig;

use HTML::Parser ();
my $p = HTML::Parser->new(process_h => [sub { $pi = shift; $orig = shift; },
				        "token0,text"]
	                 );

$p->parse("<a><?foo><a>");

print "not " unless $pi eq "foo" && $orig eq "<?foo>";
print "ok 1\n";

$p->parse("<a><?><a>");
print "not " unless $pi eq "" && $orig eq "<?>";
print "ok 2\n";

$p->parse("<a><?
foo
><a>");
print "not "  unless $pi eq "\nfoo\n" && $orig eq "<?\nfoo\n>";
print "ok 3\n";

for (qw(< a > < ? b a r > < a >)) {
   $p->parse($_);
}

print "not " unless $pi eq "bar" && $orig eq "<?bar>";
print "ok 4\n";

$p->xml_mode(1);

$p->parse("<a><?foo>bar??><a>");
print "not " unless $pi eq "foo>bar?" && $orig eq "<?foo>bar??>";
print "ok 5\n";

$p->parse("<a><??></a>");
print "not " unless $pi eq "" && $orig eq "<??>";
print "ok 6\n";
