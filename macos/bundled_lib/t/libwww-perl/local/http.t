if ($^O eq "MacOS") {
    print "1..0\n";
    exit(0);
}

$| = 1; # autoflush

require IO::Socket;  # make sure this work before we try to make a HTTP::Daemon

# First we make ourself a daemon in another process
my $D = shift || '';
if ($D eq 'daemon') {

    require HTTP::Daemon;

    my $d = HTTP::Daemon->new(Timeout => 10);

    print "Please to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while ($c = $d->accept) {
	$r = $c->get_request;
	if ($r) {
	    my $p = ($r->url->path_segments)[1];
	    my $func = lc("httpd_" . $r->method . "_$p");
	    if (defined &$func) {
		&$func($c, $r);
	    } else {
		$c->send_error(404);
	    }
	}
	$c = undef;  # close connection
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}
else {
    use Config;
    my $perl = $Config{'perlpath'};
    $perl = $^X if $^O eq 'VMS';
    open(DAEMON, "$perl local/http.t daemon |") or die "Can't exec daemon: $!";
}

print "1..18\n";


my $greeting = <DAEMON>;
$greeting =~ /(<[^>]+>)/;

require URI;
my $base = URI->new($1);
sub url {
   my $u = URI->new(@_);
   $u = $u->abs($_[1]) if @_ > 1;
   $u->as_string;
}

print "Will access HTTP server at $base\n";

require LWP::UserAgent;
require HTTP::Request;
$ua = new LWP::UserAgent;
$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('gisle@aas.no');

#----------------------------------------------------------------
print "Bad request...\n";
$req = new HTTP::Request GET => url("/not_found", $base);
$req->header(X_Foo => "Bar");
$res = $ua->request($req);

print "not " unless $res->is_error
                and $res->code == 404
                and $res->message =~ /not\s+found/i;
print "ok 1\n";
# we also expect a few headers
print "not " if !$res->server and !$res->date;
print "ok 2\n";

#----------------------------------------------------------------
print "Simple echo...\n";
sub httpd_get_echo
{
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: text/plain\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}

$req = new HTTP::Request GET => url("/echo/path_info?query", $base);
$req->push_header(Accept => 'text/html');
$req->push_header(Accept => 'text/plain; q=0.9');
$req->push_header(Accept => 'image/*');
$req->if_modified_since(time - 300);
$req->header(Long_text => 'This is a very long header line
which is broken between
more than one line.');
$req->header(X_Foo => "Bar");

$res = $ua->request($req);
#print $res->as_string;

print "not " unless $res->is_success
               and  $res->code == 200 && $res->message eq "OK";
print "ok 3\n";

$_ = $res->content;
@accept = /^Accept:\s*(.*)/mg;

print "not " unless /^From:\s*gisle\@aas\.no$/m
                and /^Host:/m
                and @accept == 3
	        and /^Accept:\s*text\/html/m
	        and /^Accept:\s*text\/plain/m
	        and /^Accept:\s*image\/\*/m
		and /^If-Modified-Since:\s*\w{3},\s+\d+/m
                and /^Long-Text:\s*This.*broken between/m
		and /^X-Foo:\s*Bar$/m
		and /^User-Agent:\s*Mozilla\/0.01/m;
print "ok 4\n";

#----------------------------------------------------------------
print "Send file...\n";

my $file = "test-$$.html";
open(FILE, ">$file") or die "Can't create $file: $!";
binmode FILE or die "Can't binmode $file: $!";
print FILE <<EOT;
<html><title>En prøve</title>
<h1>Dette er en testfil</h1>
Jeg vet ikke hvor stor fila behøver å være heller, men dette
er sikkert nok i massevis.
EOT
close(FILE);

sub httpd_get_file
{
    my($c, $r) = @_;
    my %form = $r->url->query_form;
    my $file = $form{'name'};
    $c->send_file_response($file);
    unlink($file) if $file =~ /^test-/;
}

$req = new HTTP::Request GET => url("/file?name=$file", $base);
$res = $ua->request($req);
#print $res->as_string;

print "not " unless $res->is_success
                and $res->content_type eq 'text/html'
		and $res->content_length == 147
		and $res->title eq 'En prøve'
		and $res->content =~ /å være/;
print "ok 5\n";		


# A second try on the same file, should fail because we unlink it
$res = $ua->request($req);
#print $res->as_string;
print "not " unless $res->is_error
                and $res->code == 404;   # not found
print "ok 6\n";
		
# Then try to list current directory
$req = new HTTP::Request GET => url("/file?name=.", $base);
$res = $ua->request($req);
#print $res->as_string;
print "not " unless $res->code == 501;   # NYI
print "ok 7\n";


#----------------------------------------------------------------
print "Check redirect...\n";
sub httpd_get_redirect
{
   my($c) = @_;
   $c->send_redirect("/echo/redirect");
}

$req = new HTTP::Request GET => url("/redirect/foo", $base);
$res = $ua->request($req);
#print $res->as_string;

print "not " unless $res->is_success
                and $res->content =~ m|/echo/redirect|;
print "ok 8\n";
print "not " unless $res->previous->is_redirect
                and $res->previous->code == 301;
print "ok 9\n";

# Let's test a redirect loop too
sub httpd_get_redirect2 { shift->send_redirect("/redirect3/") }
sub httpd_get_redirect3 { shift->send_redirect("/redirect4/") }
sub httpd_get_redirect4 { shift->send_redirect("/redirect5/") }
sub httpd_get_redirect5 { shift->send_redirect("/redirect6/") }
sub httpd_get_redirect6 { shift->send_redirect("/redirect2/") }

$req->url(url("/redirect2", $base));
$res = $ua->request($req);
#print $res->as_string;
print "not " unless $res->is_redirect
                and $res->header("Client-Warning") =~ /loop detected/i;
print "ok 10\n";
$i = 1;
while ($res->previous) {
   $i++;
   $res = $res->previous;
}
print "not " unless $i == 6;
print "ok 11\n";

#----------------------------------------------------------------
print "Check basic authorization...\n";
sub httpd_get_basic
{
    my($c, $r) = @_;
    #print STDERR $r->as_string;
    my($u,$p) = $r->authorization_basic;
    if (defined($u) && $u eq 'ok 12' && $p eq 'xyzzy') {
        $c->send_basic_header(200);
	print $c "Content-Type: text/plain";
	$c->send_crlf;
	$c->send_crlf;
	$c->print("$u\n");
    } else {
        $c->send_basic_header(401);
	$c->print("WWW-Authenticate: Basic realm=\"libwww-perl\"\015\012");
	$c->send_crlf;
    }
}

{
   package MyUA; @ISA=qw(LWP::UserAgent);
   sub get_basic_credentials {
      my($self, $realm, $uri, $proxy) = @_;
      if ($realm eq "libwww-perl" && $uri->rel($base) eq "basic") {
	  return ("ok 12", "xyzzy");
      } else {
          return undef;
      }
   }
}
$req = new HTTP::Request GET => url("/basic", $base);
$res = MyUA->new->request($req);
#print $res->as_string;

print "not " unless $res->is_success;
print $res->content;

# Let's try with a $ua that does not pass out credentials
$res = $ua->request($req);
print "not " unless $res->code == 401;
print "ok 13\n";

# Let's try to set credentials for this realm
$ua->credentials($req->url->host_port, "libwww-perl", "ok 12", "xyzzy");
$res = $ua->request($req);
print "not " unless $res->is_success;
print "ok 14\n";

# Then illegal credentials
$ua->credentials($req->url->host_port, "libwww-perl", "user", "passwd");
$res = $ua->request($req);
print "not " unless $res->code == 401;
print "ok 15\n";


#----------------------------------------------------------------
print "Check proxy...\n";
sub httpd_get_proxy
{
   my($c,$r) = @_;
   if ($r->method eq "GET" and
       $r->url->scheme eq "ftp") {
       $c->send_basic_header(200);
       $c->send_crlf;
   } else {
       $c->send_error;
   }
}

$ua->proxy(ftp => $base);
$req = new HTTP::Request GET => "ftp://ftp.perl.com/proxy";
$res = $ua->request($req);
#print $res->as_string;
print "not " unless $res->is_success;
print "ok 16\n";

#----------------------------------------------------------------
print "Check POSTing...\n";
sub httpd_post_echo
{
   my($c,$r) = @_;
   $c->send_basic_header;
   $c->print("Content-Type: text/plain");
   $c->send_crlf;
   $c->send_crlf;
   $c->print($r->as_string);
}

$req = new HTTP::Request POST => url("/echo/foo", $base);
$req->content_type("application/x-www-form-urlencoded");
$req->content("foo=bar&bar=test");
$res = $ua->request($req);
#print $res->as_string;

$_ = $res->content;
print "not " unless $res->is_success
                and /^Content-Length:\s*16$/mi
		and /^Content-Type:\s*application\/x-www-form-urlencoded$/mi
		and /^foo=bar&bar=test/m;
print "ok 17\n";		

#----------------------------------------------------------------
print "Terminating server...\n";
sub httpd_get_quit
{
    my($c) = @_;
    $c->send_error(503, "Bye, bye");
    exit;  # terminate HTTP server
}

$req = new HTTP::Request GET => url("/quit", $base);
$res = $ua->request($req);

print "not " unless $res->code == 503 and $res->content =~ /Bye, bye/;
print "ok 18\n";

