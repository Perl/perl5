use Test::More tests => 1;

use strict;
use HTML::Parser;

my $p = HTML::Parser->new(api_version => 3);
my @com;
$p->handler(comment => sub { push(@com, shift) }, "token0");
$p->handler(default => sub { push(@com, shift() . "[" . shift() . "]") }, "event, text");

$p->parse("<foo><><!><!-><!--><!---><!----><!-----><!------>");
$p->parse("<!--+--");
$p->parse("\n\n");
$p->parse(">");
$p->parse("<!a'b>");
$p->parse("<!--foo--->");
$p->parse("<!--foo---->");
$p->parse("<!--foo----->-->");
$p->parse("<foo>");
$p->parse("<!3453><!-3456><!FOO><>");
$p->eof;

my $com = join(":", @com);
is($com, "start_document[]:start[<foo>]:text[<>]::-:><!-::-:--:+:a'b:foo-:foo--:foo---:text[-->]:start[<foo>]:3453:-3456:FOO:text[<>]:end_document[]");
