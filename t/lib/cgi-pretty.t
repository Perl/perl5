#!./perl

# Test ability to retrieve HTTP request info
######################### We start with some black magic to print on failure.
BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
}

BEGIN {$| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Pretty (':standard','-no_debug','*h3','start_table');
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# all the automatic tags
test(2,h1() eq '<H1>',"single tag");
test(3,ol(li('fred'),li('ethel')) eq "<OL>\n\t<LI>\n\t\tfred\n\t</LI>\n\t <LI>\n\t\tethel\n\t</LI>\n</OL>\n","basic indentation");
test(4,p('hi',pre('there'),'frog') eq 
'<P>
	hi <PRE>there</PRE>
	 frog
</P>
',"<pre> tags");
test(5,p('hi',a({-href=>'frog'},'there'),'frog') eq 
'<P>
	hi <A HREF="frog">there</A>
	 frog
</P>
',"as-is");
