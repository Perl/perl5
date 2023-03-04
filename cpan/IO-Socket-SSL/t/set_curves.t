#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;

do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

my $set_groups_list =
    defined &Net::SSLeay::CTX_set1_groups_list ? \&Net::SSLeay::CTX_set1_groups_list :
    defined &Net::SSLeay::CTX_set1_curves_list ? \&Net::SSLeay::CTX_set1_curves_list :
    do {
	print "1..0 # no support for CTX_set1_curves_list or CTX_set1_groups_list\n";
	exit;
    };

print "1..6\n";
my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    Listen => 2,
    ReuseAddr => 1,
    SSL_server => 1,
    SSL_ca_file => "t/certs/test-ca.pem",
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
    SSL_cipher_list => 'ECDHE',
    SSL_ecdh_curve => 'P-521:P-384',
);

warn "\$!=$!, \$\@=$@, S\$SSL_ERROR=$SSL_ERROR" if ! $server;
print "not ok\n", exit if !$server;
print "ok # Server Initialization\n";
my $saddr = $server->sockhost.':'.$server->sockport;

my @tests = (
    [ 1,'P-521' ],
    [ 1,'P-384' ],
    [ 0,'P-256' ],
    [ 1,'P-384:P-521' ],
    [ 1,'P-256:P-384:P-521' ],
);

defined( my $pid = fork() ) || die $!;
if (!$pid) {
    close($server);
    for my $t (@tests) {
	my (undef,$curves) = @$t;
	my $cl = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    SSL_verify_mode => 1,
	    SSL_ca_file => 't/certs/test-ca.pem',
	    SSL_ecdh_curve => $curves,
	) or next;
	<$cl>;
    }
    exit;
}

for my $t (@tests) {
    my ($expect_ok,$curves) = @$t;
    my $csock = $server->accept;
    if ($csock && $expect_ok) {
	print "ok # expect success $curves\n";
    } elsif (!$csock && !$expect_ok) {
	print "ok # expect fail $curves: $SSL_ERROR\n";
    } elsif ($csock) {
	print "not ok # expect fail $curves\n";
    } else {
	print "not ok # expect success $curves: $SSL_ERROR\n";
    }
    close($csock) if $csock;
}
wait;
