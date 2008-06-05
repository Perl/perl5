use strict;
use Test::More tests => 8;

use HTML::Parser ();
my $p = HTML::Parser->new(xml_mode => 1,
			 );

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
$p->handler(end =>
	     sub {
		 $text .= "E[" . shift() . "]";
	     }, "tagname");
$p->handler(process => 
	     sub {
		 $text .= "PI[" . shift() . "]";
	     }, "token0");
$p->handler(text =>
	     sub {
		 $text .= shift;
	     }, "text");

my $xml = <<'EOT';
<?xml version="1.0"?>
<?IS10744:arch name="html"?><!-- comment -->
<DOC>
<title html="h1">My first architectual document</title>
<author html="address">Geir Ove Gronmo, grove@infotek.no</author>
<para>This is the first paragraph in this document</para>
<para html="p">This is the second paragraph</para>
<para/>
<xmp><foo></foo></xmp>
</DOC>
EOT

$p->parse($xml)->eof;

is($text, <<'EOT');
PI[xml version="1.0"]
PI[IS10744:arch name="html"]
S[DOC]
S[title html=h1]My first architectual documentE[title]
S[author html=address]Geir Ove Gronmo, grove@infotek.noE[author]
S[para]This is the first paragraph in this documentE[para]
S[para html=p]This is the second paragraphE[para]
S[para]E[para]
S[xmp]S[foo]E[foo]E[xmp]
E[DOC]
EOT

$text = "";
$p->xml_mode(0);
$p->parse($xml)->eof;

is($text, <<'EOT');
PI[xml version="1.0"?]
PI[IS10744:arch name="html"?]
S[doc]
S[title html=h1]My first architectual documentE[title]
S[author html=address]Geir Ove Gronmo, grove@infotek.noE[author]
S[para]This is the first paragraph in this documentE[para]
S[para html=p]This is the second paragraphE[para]
S[para/]
S[xmp]<foo></foo>E[xmp]
E[doc]
EOT

# Test that we get an empty tag back
$p = HTML::Parser->new(api_version => 3,
	               xml_mode => 1);

$p->handler("end" =>
	    sub {
		my($tagname, $text) = @_;
		is($tagname, "Xyzzy");
	        ok(!length($text));
	    }, "tagname,text");
$p->parse("<Xyzzy foo=bar/>and some more")->eof;

# Test that we get an empty tag back
$p = HTML::Parser->new(api_version => 3,
	               empty_element_tags => 1);

$p->handler("end" =>
	    sub {
		my($tagname, $text) = @_;
		is($tagname, "xyzzy");
	        ok(!length($text));
	    }, "tagname,text");
$p->parse("<Xyzzy foo=bar/>and some more")->eof;

$p = HTML::Parser->new(
    api_version => 3,
    xml_pic => 1,
);

$p->handler(
    "process" => sub {
	my($text, $t0) = @_;
	is($text, "<?foo > bar?>");
	is($t0, "foo > bar");
    }, "text, token0");
$p->parse("<?foo > bar?> and then")->eof;
