print "1..2\n";

use strict;
use HTML::Parser ();

my $dtext = "";
my $text  = "";

sub append
{
    $dtext .= shift;
    $text .= shift;
}

my $p = HTML::Parser->new(text_h    => [\&append, "dtext, text"],
			  default_h => [\&append, "text,  text" ],
			 );

my $doc = <<'EOT';
<a href="foo&aring">&aring&aring;&#65&#65;&lt&#65&gt;&#x41&#X41;</a>
<?&aring>
&xyzzy
&xyzzy;
<!-- &#0; -->
&#1;
&#255;
<!-- &#256; -->
&#40000000000000000000000000000;
&#x400000000000000000000000000000000;
&
<xmp>&aring</xmp>
<script>&aring</script>
<ScRIPT>&aring</scRIPT>
<skript>&aring</script>
EOT

$p->parse($doc)->eof;

print "not " unless $text eq $doc;
print "ok 1\n";

print $dtext;

print "not " unless $dtext eq <<"EOT"; print "ok 2\n";
<a href="foo&aring">ÂÂAA<A>AA</a>
<?&aring>
&xyzzy
&xyzzy;
<!-- &#0; -->
\1
\377
<!-- &#256; -->
&#40000000000000000000000000000;
&#x400000000000000000000000000000000;
&
<xmp>&aring</xmp>
<script>&aring</script>
<ScRIPT>&aring</scRIPT>
<skript>Â</script>
EOT
