print "1..19\n";

use HTTP::Request::Common;

$r = GET 'http://www.sn.no/';
print $r->as_string;

print "not " unless $r->method eq "GET" and $r->url eq "http://www.sn.no/";
print "ok 1\n";

$r = HEAD "http://www.sn.no/",
     If_Match => 'abc',
     From => 'aas@sn.no';
print $r->as_string;

print "not " unless $r->method eq "HEAD" and $r->url->eq("http://www.sn.no");
print "ok 2\n";

print "not " unless $r->header('If-Match') eq "abc" and $r->header("from") eq "aas\@sn.no";
print "ok 3\n";

$r = PUT "http://www.sn.no",
     Content => 'foo';
print $r->as_string;

print "not " unless $r->method eq "PUT" and $r->uri->host eq "www.sn.no";
print "ok 4\n";

print "not " if defined($r->header("Content"));
print "ok 5\n";

print "not " unless ${$r->content_ref} eq "foo" and
                    $r->content eq "foo";
print "ok 6\n";

#--- Test POST requests ---

$r = POST "http://www.sn.no", [foo => 'bar;baz',
                               baz => [qw(a b c)],
                               foo => 'zoo=&',
                               "space " => " + ",
                              ],
                              bar => 'foo';
print $r->as_string;

print "not " unless $r->method eq "POST" and
                    $r->content_type eq "application/x-www-form-urlencoded" and
                    $r->content_length == 58 and
                    $r->header("bar") eq "foo";
print "ok 7\n";

print "not " unless $r->content eq "foo=bar%3Bbaz&baz=a&baz=b&baz=c&foo=zoo%3D%26&space+=+%2B+";
print "ok 8\n";

$r = POST "mailto:gisle\@aas.no",
     Subject => "Heisan",
     Content_Type => "text/plain",
     Content => "Howdy\n";
print $r->as_string;

print "not " unless $r->method eq "POST" and
                    $r->header("Subject") eq "Heisan" and
                    $r->content eq "Howdy\n" and
	            $r->content_type eq "text/plain";
print "ok 9\n";

#
# POST for File upload
#
$file = "test-$$";
open(FILE, ">$file") or die "Can't create $file: $!";
print FILE "foo\nbar\nbaz\n";
close(FILE);

$r = POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'm',
                         born   => '1964',
                         file   => [$file],
                       ];
print $r->as_string;

unlink($file) or warn "Can't unlink $file: $!";

print "not " unless $r->method eq "POST" and
	            $r->url->path eq "/survey.cgi" and
                    $r->content_type eq "multipart/form-data" and
	            $r->header(Content_type) =~ /boundary="?([^"]+)"?/;
print "ok 10\n";
$boundary = $1;

$c = $r->content;
$c =~ s/\r//g;
@c = split(/--\Q$boundary/, $c);
print "$c[5]\n";

print "not " unless @c == 7 and $c[6] =~ /^--\n/;  # 5 parts + header & trailer
print "ok 11\n";

print "not " unless $c[2] =~ /^Content-Disposition:\s*form-data;\s*name="email"/m and
                    $c[2] =~ /^gisle\@aas.no$/m;
print "ok 12\n";

print "not " unless $c[5] =~ /^Content-Disposition:\s*form-data;\s*name="file";\s*filename="$file"/m and
	            $c[5] =~ /^Content-Type:\s*text\/plain$/m and
	            $c[5] =~ /^foo\nbar\nbaz/m;
print "ok 13\n";

$r = POST 'http://www.perl.org/survey.cgi',
      [ file => [ undef, "xxx", Content_type => "text/html", Content => "<h1>Hello, world!</h1>" ]],
      Content_type => 'multipart/form-data';
print $r->as_string;

if($^O eq "MacOS") {
    print "not " unless $r->content =~ /^--\S+\015\012Content-Disposition:\s*form-data;\s*name="file";\s*filename="xxx"/m and
		        $r->content =~ /^\012Content-Type: text\/html/m and
	        	$r->content =~ /^\012<h1>Hello, world/m;
} else {
    print "not " unless $r->content =~ /^--\S+\015\012Content-Disposition:\s*form-data;\s*name="file";\s*filename="xxx"/m and
	                $r->content =~ /^Content-Type: text\/html/m and
	                $r->content =~ /^<h1>Hello, world/m;
}
print "ok 14\n";


$r = POST 'http://www.perl.org/survey.cgi',
      Content_type => 'multipart/form-data',
      Content => [ file => [ undef, undef, Content => "foo"]];
print $r->as_string;

print "not " if $r->content =~ /filename=/;
print "ok 15\n";


# The POST routine can now also take a hash reference.
my %hash = (foo => 42, bar => 24);
$r = POST 'http://www.perl.org/survey.cgi', \%hash;
print $r->as_string;
print "not " unless $r->content =~ /foo=42/ &&
                    $r->content =~ /bar=24/ &&
                    $r->content_type eq "application/x-www-form-urlencoded" &&
                    $r->content_length == 13;
print "ok 16\n";

 
#
# POST for File upload
#
use HTTP::Request::Common qw($DYNAMIC_FILE_UPLOAD);

$file = "test-$$";
open(FILE, ">$file") or die "Can't create $file: $!";
for (1..1000) {
   print FILE "a" .. "z";
}
close(FILE);

$DYNAMIC_FILE_UPLOAD++;
$r = POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'm',
                         born   => '1964',
                         file   => [$file],
                       ];
print $r->as_string;

print "not " unless $r->method eq "POST" and
	            $r->url->path eq "/survey.cgi" and
                    $r->content_type eq "multipart/form-data" and
	            $r->header(Content_type) =~ /boundary="?([^"]+)"?/ and
		    ref($r->content) eq "CODE";
print "ok 17\n";
$boundary = $1;

print "not " unless length($boundary) > 10;
print "ok 18\n";

$code = $r->content;
my $chunk;
my @chunks;
while (defined($chunk = &$code) && length $chunk) {
   push(@chunks, $chunk);
}

unlink($file) or warn "Can't unlink $file: $!";

$_ = join("", @chunks);

print int(@chunks), " chunks, total size is ", length($_), " bytes\n";

# should be close to expected size and number of chunks
print "not " unless abs(@chunks - 15 < 3) and
                    abs(length($_) - 26589) < 20;
print "ok 19\n";

