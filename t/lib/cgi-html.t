#!./perl

# Test ability to retrieve HTTP request info
######################### We start with some black magic to print on failure.

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
    require Config; import Config;
}

BEGIN {$| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI (':standard','-no_debug','*h3','start_table');
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $Is_EBCDIC = $Config{'ebcdic'} eq 'define';

# util
sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# all the automatic tags
test(2,h1() eq '<H1>',"single tag");
test(3,h1('fred') eq '<H1>fred</H1>',"open/close tag");
test(4,h1('fred','agnes','maura') eq '<H1>fred agnes maura</H1>',"open/close tag multiple");
test(5,h1({-align=>'CENTER'},'fred') eq '<H1 ALIGN="CENTER">fred</H1>',"open/close tag with attribute");
test(6,h1({-align=>undef},'fred') eq '<H1 ALIGN>fred</H1>',"open/close tag with orphan attribute");
test(7,h1({-align=>'CENTER'},['fred','agnes']) eq 
     '<H1 ALIGN="CENTER">fred</H1> <H1 ALIGN="CENTER">agnes</H1>',
     "distributive tag with attribute");
{
    local($") = '-'; 
    test(8,h1('fred','agnes','maura') eq '<H1>fred-agnes-maura</H1>',"open/close tag \$\" interpolation");
}
if (!$Is_EBCDIC) {
test(9,header() eq "Content-Type: text/html\015\012\015\012","header()");
test(10,header(-type=>'image/gif') eq "Content-Type: image/gif\015\012\015\012","header()");
test(11,header(-type=>'image/gif',-status=>'500 Sucks') eq "Status: 500 Sucks\015\012Content-Type: image/gif\015\012\015\012","header()");
test(12,header(-nph=>1) eq "HTTP/1.0 200 OK\015\012Content-Type: text/html\015\012\015\012","header()");
} else {
test(9,header() eq "Content-Type: text/html\r\n\r\n","header()");
test(10,header(-type=>'image/gif') eq "Content-Type: image/gif\r\n\r\n","header()");
test(11,header(-type=>'image/gif',-status=>'500 Sucks') eq "Status: 500 Sucks\r\nContent-Type: image/gif\r\n\r\n","header()");
test(12,header(-nph=>1) eq "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n","header()");
}
test(13,start_html() ."\n" eq <<END,"start_html()");
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML><HEAD><TITLE>Untitled Document</TITLE>
</HEAD><BODY>
END
    ;
test(14,start_html(-dtd=>"-//IETF//DTD HTML 3.2//FR") ."\n" eq <<END,"start_html()");
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 3.2//FR">
<HTML><HEAD><TITLE>Untitled Document</TITLE>
</HEAD><BODY>
END
    ;
test(15,start_html(-Title=>'The world of foo') ."\n" eq <<END,"start_html()");
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML><HEAD><TITLE>The world of foo</TITLE>
</HEAD><BODY>
END
    ;
test(16,($cookie=cookie(-name=>'fred',-value=>['chocolate','chip'],-path=>'/')) eq 
     'fred=chocolate&chip; domain=localhost; path=/',"cookie()");
if (!$Is_EBCDIC) {
test(17,header(-Cookie=>$cookie) =~ m!^Set-Cookie: fred=chocolate&chip\; domain=localhost; path=/\015\012Date:.*\015\012Content-Type: text/html\015\012\015\012!s,
     "header(-cookie)");
} else {
test(17,header(-Cookie=>$cookie) =~ m!^Set-Cookie: fred=chocolate&chip\; domain=localhost; path=/\r\nDate:.*\r\nContent-Type: text/html\r\n\r\n!s,
     "header(-cookie)");
}
test(18,start_h3 eq '<H3>');
test(19,end_h3 eq '</H3>');
test(20,start_table({-border=>undef}) eq '<TABLE BORDER>');
