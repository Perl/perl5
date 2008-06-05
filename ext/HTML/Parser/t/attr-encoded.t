use strict;
use Test::More tests => 2;

use HTML::Parser ();
my $p = HTML::Parser->new();
$p->attr_encoded(1);

my $text = "";
$p->handler(start =>
	    sub {
		 my($tag, $attr) = @_;
		 $text .= "S[$tag";
		 for my $k (sort keys %$attr) {
		     my $v =  $attr->{$k};
		     $text .= " $k=$v";
		 }
		 $text .= "]";
	     }, "tagname,attr");

my $html = <<'EOT';
<tag arg="&amp;&lt;&gt">
EOT

$p->parse($html)->eof;

is($text, 'S[tag arg=&amp;&lt;&gt]');

$text = "";
$p->attr_encoded(0);
$p->parse($html)->eof;

is($text, 'S[tag arg=&<>]');
