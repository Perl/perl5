
print "1..4\n";

use strict;
use HTML::Parser ();

my $html = '<A href="foo">text</A>';

my $text = '';
my $p = HTML::Parser->new(default_h => [sub {$text .= shift;}, 'text']);
$p->parse($html)->eof;
print "not " if $text ne $html;
print "ok 1\n";

$text = '';
$p->handler(start => "");
$p->parse($html)->eof;
print "not " if $text ne 'text</A>';
print "ok 2\n";

$text = '';
$p->handler(end => 0);
$p->parse($html)->eof;
print "not " if $text ne 'text';
print "ok 3\n";

$text = '';
$p->handler(start => undef);
$p->parse($html)->eof;
print "not " if $text ne '<A href="foo">text';
print "ok 4\n";
