use Test::More tests => 1;

use strict;
use HTML::Parser;

my $html = <<'EOT';
<html>
<title>This is a <nice> title</title>
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

my $p = HTML::Parser->new(default_h => [\&tdump, "event,text,dtext,is_cdata"]);
$p->parse($html)->eof;

#diag $dump;

is($dump, <<'EOT');
start_document||<undef>|<undef>
start|<html>|<undef>|<undef>
text|\n|\n|
start|<title>|<undef>|<undef>
text|This is a <nice> title|This is a <nice> title|
end|</title>|<undef>|<undef>
text|\n|\n|
comment|<!--comment-->|<undef>|<undef>
text|\n|\n|
start|<script language="perl">|<undef>|<undef>
text|while (<DATA>) { &amp; }|while (<DATA>) { &amp; }|1
end|</script>|<undef>|<undef>
text|\n\n|\n\n|
start|<FORM>|<undef>|<undef>
text|\n\n|\n\n|
start|<textarea name="foo" cols=50 rows=10>|<undef>|<undef>
text|\n\nfoo\n<foo>\n<!--comment-->\n&amp;\nfoo\n</FORM>\n\n|\n\nfoo\n<foo>\n<!--comment-->\n&\nfoo\n</FORM>\n\n|
end|</textarea>|<undef>|<undef>
text|\n\n|\n\n|
end|</FORM>|<undef>|<undef>
text|\n\n|\n\n|
end|</html>|<undef>|<undef>
text|\n|\n|
end_document||<undef>|<undef>
EOT
