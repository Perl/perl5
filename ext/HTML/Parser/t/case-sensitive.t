use strict;
use Test::More tests => 8;

use HTML::Parser ();
my $p = HTML::Parser->new();
$p->case_sensitive(1);

my $text = "";
$p->handler(start =>
	    sub {
		 my($tag, $attr, $attrseq) = @_;
		 $text .= "S[$tag";
		 for my $k (sort keys %$attr) {
		     my $v =  $attr->{$k};
		     $text .= " $k=$v";
		 }
		 if (@$attrseq) { $text.=" Order:" ; }
		 for my $k (@$attrseq) {
		     $text .= " $k";
		 }
		 $text .= "]";
	     }, "tagname,attr,attrseq");
$p->handler(end =>
	    sub {
		 my ($tag) = @_;
		 $text .= "E[$tag]";
	     }, "tagname");

my $html = <<'EOT';
<tAg aRg="Value" arg="other value"></tAg>
EOT
my $cs = 'S[tAg aRg=Value arg=other value Order: aRg arg]E[tAg]';
my $ci = 'S[tag arg=Value Order: arg arg]E[tag]';

$p->parse($html)->eof;
is($text, $cs);

$text = "";
$p->case_sensitive(0);
$p->parse($html)->eof;
is($text, $ci);

$text = "";
$p->case_sensitive(1);
$p->xml_mode(1);
$p->parse($html)->eof;
is($text, $cs);

$text = "";
$p->case_sensitive(0);
$p->parse($html)->eof;
is($text, $cs);

$html = <<'EOT';
<tAg aRg="Value" arg="other value"></tAg>
<iGnOrE></ignore>
EOT
$p->ignore_tags('ignore');
$cs = 'S[tAg aRg=Value arg=other value Order: aRg arg]E[tAg]S[iGnOrE]';
$ci = 'S[tag arg=Value Order: arg arg]E[tag]';

$text = "";
$p->case_sensitive(0);
$p->xml_mode(0);
$p->parse($html)->eof;
is($text, $ci);
 
$text = "";
$p->case_sensitive(1);
$p->xml_mode(0);
$p->parse($html)->eof;
is($text, $cs);

$text = "";
$p->case_sensitive(0);
$p->xml_mode(1);
$p->parse($html)->eof;
is($text, $cs);
 
$text = "";
$p->case_sensitive(1);
$p->xml_mode(1);
$p->parse($html)->eof;
is($text, $cs);
 
