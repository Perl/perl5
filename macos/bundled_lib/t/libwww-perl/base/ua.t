print "1..5\n";

use LWP::UserAgent;

$ua = LWP::UserAgent->new;

print "not " unless $ua->agent =~ /^libwww-perl/;
print "ok 1\n";


print "not " if defined $ua->proxy(ftp => "http://www.sol.no");
print "ok 2\n";

print "not " unless $ua->proxy("ftp") eq "http://www.sol.no";
print "ok 3\n";

@a = $ua->proxy([qw(ftp http wais)], "http://proxy.foo.com");

for (@a) { $_ = "undef" unless defined; }

print "not " unless "@a" eq "http://www.sol.no undef undef";
print "ok 4\n";

print "not " unless $ua->proxy("http") eq "http://proxy.foo.com";
print "ok 5\n";


