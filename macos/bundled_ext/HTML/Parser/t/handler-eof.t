print "1..6\n";

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

$p->handler(start => sub { my $attr = shift; print "ok $attr->{testno}\n" },
		     "attr");
$p->handler(end => sub { shift->eof }, "self");
my $text;
$p->handler(text => sub { $text = shift }, "text");

print "not " unless $p->parse("<foo testno=1>") == $p;
print "ok 2\n";

$text = '';
print "not " if $p->parse("</foo><foo testno=999>");
print "ok 3\n";
print "not " if $text;
print "ok 4\n";

$p->handler(end => sub { $p->parse("foo"); }, "");
eval {
    $p->parse("</foo>");
};
print "not " unless $@ && $@ =~ /Parse loop not allowed/;
print "ok 5\n";

# We used to get into an infinite loop if the eof triggered
# handler called ->eof

use HTML::Parser;
$p = HTML::Parser->new(api_version => 3);

my $i;
$p->handler("default" =>
	    sub {
		my $p=shift;
	        #++$i; print "$i @_\n";
		$p->eof;
	    }, "self, event");
$p->parse("Foo");
$p->eof;

print "ok 6\n";
