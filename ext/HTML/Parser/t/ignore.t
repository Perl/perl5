
use Test::More tests => 4;

use strict;
use HTML::Parser ();

my $html = '<A href="foo">text</A>';

my $text = '';
my $p = HTML::Parser->new(default_h => [sub {$text .= shift;}, 'text']);
$p->parse($html)->eof;
is($text, $html);

$text = '';
$p->handler(start => "");
$p->parse($html)->eof;
is($text, 'text</A>');

$text = '';
$p->handler(end => 0);
$p->parse($html)->eof;
is($text, 'text');

$text = '';
$p->handler(start => undef);
$p->parse($html)->eof;
is($text, '<A href="foo">text');
