print "1..2\n";

use strict;

use LWP::UserAgent;
use HTML::Form;

my $uri = "http://validator.w3.org/file-upload.html";

my $ua = LWP::UserAgent->new(keep_alive => 1);
my($req, $res);

$req = HTTP::Request->new(GET => $uri);
$res = $ua->request($req);

my $f = HTML::Form->parse($res->content, $res->base);

#$f->dump;

my $file = <<'EOT';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<title>Hi</title>
<h1>Heading</h1>
Some text.
EOT

#$file .= "<b>Hi</b>\n" x 20000;
$file .= "</html>\n";

$f->value("uploaded_file", [undef, "x.html", Content => $file]);

$req = $f->click;
#print $req->as_string;
$req->header(Connection => "close");

$res = $ua->request($req);
#print $res->as_string;

unless ($res->content =~ /No errors found!/) {
    print $res->as_string;
    print "\nnot ";
}
print "ok 1\n";

#$res->content(""); print $res->as_string;

print "not " unless $res->header("Client-Response-Num") == 2 &&
                    $res->header("Connection") eq "close";
print "ok 2\n";
