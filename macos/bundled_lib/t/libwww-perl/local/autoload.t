#
# See if autoloading of protocol schemes work
#

print "1..1\n";

require LWP::UserAgent;
# note no LWP::Protocol::file;

$url = "file:.";

require URI;
print "Trying to fetch '" . URI->new($url)->file . "'\n";

my $ua = new LWP::UserAgent;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds

my $request = HTTP::Request->new(GET => $url);

my $response = $ua->request($request);
if ($response->is_success) {
    print "ok 1\n";
    print $response->as_string;
} else {
    print "not ok 1\n";
    print $response->error_as_HTML;
}
