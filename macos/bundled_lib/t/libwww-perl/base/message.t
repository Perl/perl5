print "1..16\n";

require HTTP::Request;
require HTTP::Response;

require Time::Local if $^O eq "MacOS";
my $offset = ($^O eq "MacOS") ? Time::Local::timegm(0,0,0,1,0,70) : 0;

$req = new HTTP::Request 'GET', "http://www.sn.no/";
$req->header(
	"if-modified-since" => "Thu, 03 Feb 1994 00:00:00 GMT",
	"mime-version"      => "1.0");

$str = $req->as_string;

print $str;

$str =~ /^GET/m || print "not ";
print "ok 1\n";

$req->header("MIME-Version") eq "1.0" || print "not ";
print "ok 2\n";

$req->content("gisle");
$req->add_content(" aas");
$req->add_content(\ " old interface is depreciated");

${$req->content_ref} =~ s/\s+is\s+depreciated//;

print "Content is: ", $req->content, "\n";

$req->content eq "gisle aas old interface" || print "not ";
print "ok 3\n";

$req->if_modified_since == ((760233600 + $offset) | 0) || print "not ";
print "ok 4\n";

$time = time;

$req->date($time);
$timestr = gmtime($time);
($month) = ($timestr =~ /^\S+\s+(\S+)/);  # extract month;

print "These should represent the same time:\n\t", $req->header('Date'), "\n\t$timestr\n";

$req->header('Date') =~ /\Q$month/ || print "not ";
print "ok 5\n";

$req->authorization_basic("gisle", "passwd");
$auth = $req->header("Authorization");

print "$auth\n";
$auth =~ /Z2lzbGU6cGFzc3dk/ || print "not ";
print "ok 6\n";

($user, $pass) = $req->authorization_basic;
($user eq "gisle" && $pass eq "passwd") || print "not ";
print "ok 7\n";

# Check the response
$res = new HTTP::Response 200, "This message";

$html = $res->error_as_HTML;
print $html;

($html =~ /<head>/i && $html =~ /This message/) || print "not ";
print "ok 8\n";

$res->is_success || print "not ";
print "ok 9\n";

$res->content_type("text/html;version=3.0");
$res->content("<html>...</html>\n");

$res2 = $res->clone;

print $res2->as_string;

$res2->header("cOntent-TYPE") eq "text/html;version=3.0" || print "not ";
print "ok 10\n";

$res2->code == 200 || print "not ";
print "ok 11\n";

$res2->content =~ />\.\.\.</ || print "not ";
print "ok 12\n";

# Check the base method:

$res = new HTTP::Response 200, "This message";
$res->request($req);
$res->content_type("image/gif");

$res->base eq "http://www.sn.no/" || print "not ";
print "ok 13\n";

$res->header('Base', 'http://www.sn.no/xxx/');

$res->base eq "http://www.sn.no/xxx/" || print "not ";
print "ok 14\n";

# Check the AUTLOAD delegate method with regular expressions
"This string contains text/html" =~ /(\w+\/\w+)/;
$res->content_type($1);

$res->content_type eq "text/html" || print "not ";
print "ok 15\n";

# Check what happens when passed a new URI object
require URI;
$req = HTTP::Request->new(GET => URI->new("http://localhost"));
print "not " unless $req->uri eq "http://localhost";
print "ok 16\n";

