
use Net::Domain qw(hostname domainname hostdomain);
use Net::Config;

unless($NetConfig{test_hosts}) {
    print "1..0\n";
    exit 0;
}

print "1..1\n";

$domain = domainname();

if(defined $domain && $domain ne "") {
 print "ok 1\n";
}
else {
 print "not ok 1\n";
}
