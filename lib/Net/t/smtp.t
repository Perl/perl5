#!./perl -w

use Net::Config;
use Net::SMTP;

unless(@{$NetConfig{smtp_hosts}} && $NetConfig{test_hosts}) {
    print "1..0\n";
    exit 0;
}

print "1..3\n";

my $i = 1;

$smtp = Net::SMTP->new(Debug => 0)
	or (print("not ok 1\n"), exit);

print "ok 1\n";

$smtp->domain or print "not ";
print "ok 2\n";

$smtp->quit or print "not ";
print "ok 3\n";

