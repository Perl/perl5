#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;

if (!IO::Socket::SSL->can_partial_chain) {
    print "1..0 # no support for X509_V_FLAG_PARTIAL_CHAIN\n";
    exit(0);
}

do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
print "1..3\n";

my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    ReuseAddr => 1,
    SSL_cert_file => "t/certs/sub-server.pem",
    SSL_key_file => "t/certs/sub-server.pem",
);
warn "\$!=$!, \$\@=$@, S\$SSL_ERROR=$SSL_ERROR" if ! $server;
print "not ok\n", exit if !$server;
ok("Server Initialization");
my $saddr = $server->sockhost.':'.$server->sockport;

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {
    close($server);
    my $client = IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_ca_file => "t/certs/test-subca.pem",
    ) or print "not ";
    ok( "client ssl connect" );
    if ($client) {
	my $issuer = $client->peer_certificate( 'issuer' );
	print "not " if $issuer !~m{IO::Socket::SSL Demo Sub CA};
	ok("issuer");
    } else {
	ok("skip issuer check since no client");
    }
    exit;
}

my $csock = $server->accept;
wait;

sub ok { print "ok #$_[0]\n"; }
