#!perl -w

use strict;
use HTML::Parser;

use Test::More tests => 2;

my $TEXT = "";
sub h
{
    my($event, $tagname, $text) = @_;
    for ($event, $tagname, $text) {
        if (defined) {
	    s/([\n\r\t])/sprintf "\\%03o", ord($1)/ge;
	}
	else {
	    $_ = "<undef>";
	}
    }

    $TEXT .= "[$event,$tagname,$text]\n";
}

my $p = HTML::Parser->new(default_h => [\&h, "event,tagname,text"]);
$p->parse("<a>");
$p->parse("</a f>");
$p->parse("</a 'foo<>' 'bar>' x>");
$p->parse("</a \"foo<>\"");
$p->parse(" \"bar>\" x>");
$p->parse("</ foo bar>");
$p->parse("</ \"<>\" >");
$p->parse("<!--comment>text<!--comment><p");
$p->eof;

is($TEXT, <<'EOT');
[start_document,<undef>,]
[start,a,<a>]
[end,a,</a f>]
[end,a,</a 'foo<>' 'bar>' x>]
[end,a,</a "foo<>" "bar>" x>]
[comment, foo bar,</ foo bar>]
[comment, "<>" ,</ "<>" >]
[comment,comment,<!--comment>]
[text,<undef>,text]
[comment,comment,<!--comment>]
[comment,p,<p]
[end_document,<undef>,]
EOT

$TEXT = "";
$p->parse("<!comment>");
$p->eof;

is($TEXT, <<'EOT');
[start_document,<undef>,]
[comment,comment,<!comment>]
[end_document,<undef>,]
EOT
