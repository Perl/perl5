use Test::More tests => 2;

use strict;
use HTML::Parser;

my @start;
my @text;

my $p = HTML::Parser->new(api_version => 3);
$p->handler(start => \@start, '@{tagname, @attr}');
$p->handler(text  => \@text,  '@{dtext}');
$p->parse(<<EOT)->eof;
Hi
<a href="abc">Foo</a><b>:-)</b>
EOT

is("@start", "a href abc b");

is(join("", @text), "Hi\nFoo:-)\n");


