print "1..9\n";

use strict;
use URI;
my $uri = URI->new("http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html");

print "not " unless $uri->as_string eq "http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html";
print "ok 1\n";

print "not " unless $uri->host eq "[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]";
print "ok 2\n";

print "not " unless $uri->host_port eq "[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80";
print "ok 3\n";

print "not " unless $uri->port eq "80";
print "ok 4\n";

$uri->host("host");
print "not " unless $uri->as_string eq "http://host:80/index.html";
print "ok 5\n";

$uri = URI->new("ftp://ftp:@[3ffe:2a00:100:7031::1]");
print "not " unless $uri->as_string eq "ftp://ftp:@[3ffe:2a00:100:7031::1]";
print "ok 6\n";

print "not " unless $uri->port eq "21" && !$uri->_port;
print "ok 7\n";

print "not " unless $uri->host("ftp") eq "[3ffe:2a00:100:7031::1]";
print "ok 8\n";

print "not " unless $uri eq "ftp://ftp:\@ftp";
print "ok 9\n";

__END__

      http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html
      http://[1080:0:0:0:8:800:200C:417A]/index.html
      http://[3ffe:2a00:100:7031::1]
      http://[1080::8:800:200C:417A]/foo
      http://[::192.9.5.5]/ipng
      http://[::FFFF:129.144.52.38]:80/index.html
      http://[2010:836B:4179::836B:4179]
