print "1..1\n";

use strict;
use HTML::Parser;

my $html = <<'EOT';
<html>
<!--comment-->
<script language="perl">while (<DATA>) { &amp; }</script>

<FORM>

<textarea name="foo" cols=50 rows=10>

foo
<foo>
<!--comment-->
&amp;
foo
</FORM>

</textarea>

</FORM>

</html>
EOT

my $dump = "";
sub tdump {
   my @a = @_;
   for (@a) {
      $_ = "<undef>" unless defined;
      s/\n/\\n/g;
   }
   $dump .= join("|", @a) . "\n";
}

my $p = HTML::Parser->new(default_h => [\&tdump, "event,text,is_cdata"]);
$p->parse($html)->eof;

#print $dump;

print "not " unless $dump eq <<'EOT'; print "ok 1\n";
start_document||<undef>
start|<html>|<undef>
text|\n|
comment|<!--comment-->|<undef>
text|\n|
start|<script language="perl">|<undef>
text|while (<DATA>) { &amp; }|1
end|</script>|<undef>
text|\n\n|
start|<FORM>|<undef>
text|\n\n|
start|<textarea name="foo" cols=50 rows=10>|<undef>
text|\n\nfoo\n<foo>\n<!--comment-->\n&amp;\nfoo\n</FORM>\n\n|
end|</textarea>|<undef>
text|\n\n|
end|</FORM>|<undef>
text|\n\n|
end|</html>|<undef>
text|\n|
end_document||<undef>
EOT
