print "1..2\n";

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

print "not " unless "@start" eq "a href abc b";
print "ok 1\n";

print "not " unless join("", @text) eq "Hi\nFoo:-)\n";
print "ok 2\n";


