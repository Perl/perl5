#!./perl -w

use Net::Config;
use Net::PH;

unless(@{$NetConfig{ph_hosts}} && $NetConfig{test_hosts}) {
    print "1..0\n";
    exit 0;
}

print "1..5\n";

my $i = 1;

$ph = Net::PH->new(Debug => 0)
	or (print("not ok 1\n"), exit);

print "ok 1\n";

$ph->fields or print "not ";
print "ok 2\n";

$ph->siteinfo or print "not ";
print "ok 3\n";

$ph->id or print "not ";
print "ok 4\n";

$ph->quit or print "not ";
print "ok 5\n";

