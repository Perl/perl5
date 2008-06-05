#!perl -w

use strict;
use Test;
plan tests => 1;

use HTML::Parser;

my $TEXT = "";
sub h
{
    my($event, $tagname, $text) = @_;
    for ($event, $tagname, $text) {
        if (defined) {
	    s/([\n\r\t])/sprintf "\\%03o", ord($1)/ge;
	}
	else {
	    $_ = "<undef>";
	}
    }

    $TEXT .= "[$event,$tagname,$text]\n";
}

my $p = HTML::Parser->new(default_h => [\&h, "event,tagname,text"], empty_element_tags => 1);
$p->parse(q(<tr><td align="center" height="100"><script src="whatever"/><SCRIPT language="JavaScript1.1">bust = Math.floor(1000000*Math.random());document.write('<SCR' + 'IPT LANGUAGE="JavaScript1.1" SRC="http://adv.virgilio.it/js.ng/site=virg&adsize=728x90&subsite=mail&sez=comfree&pos=43&bust='+bust+'?">\n');document.write('</SCR' + 'IPT>\n');</SCRIPT></td></tr>));
$p->eof;

ok($TEXT, <<'EOT');
[start_document,<undef>,]
[start,tr,<tr>]
[start,td,<td align="center" height="100">]
[start,script,<script src="whatever"/>]
[end,script,]
[start,script,<SCRIPT language="JavaScript1.1">]
[text,<undef>,bust = Math.floor(1000000*Math.random());document.write('<SCR' + 'IPT LANGUAGE="JavaScript1.1" SRC="http://adv.virgilio.it/js.ng/site=virg&adsize=728x90&subsite=mail&sez=comfree&pos=43&bust='+bust+'?">\n');document.write('</SCR' + 'IPT>\n');]
[end,script,</SCRIPT>]
[end,td,</td>]
[end,tr,</tr>]
[end_document,<undef>,]
EOT
