print "1..1\n";

use strict;
use HTML::Parser;

my $p = HTML::Parser->new;
my @com;
$p->handler(comment => sub { push(@com, shift) }, "token0");

$p->parse("<!><!-><!--><!---><!----><!-----><!------>");
$p->parse("<!--+--");
$p->parse("\n\n");
$p->parse(">");
$p->parse("<!--foo--->");
$p->parse("<!--foo---->");
$p->parse("<!--foo----->");
$p->eof;

my $com = join(":", @com);
print "not " unless $com eq ":><!-::-:--:+:foo-:foo--:foo---";
print "ok 1\n";
