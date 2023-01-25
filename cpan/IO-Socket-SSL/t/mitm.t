#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
use IO::Socket::SSL::Intercept;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

print "1..8\n";

my @pid;
END { kill 9,@pid }

my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
    Listen => 10,
);
ok($server,"server ssl socket");
my $saddr = $server->sockhost.':'.$server->sockport;
defined( my $pid = fork ) or die $!;
exit( server()) if ! $pid; # child -> server()
push @pid,$pid;
close($server);

my $proxy = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 10,
    Reuse => 1,
);
sys_ok($proxy,"proxy tcp socket");
my $paddr = $proxy->sockhost.':'.$proxy->sockport;
defined( $pid = fork ) or die $!;
exit( proxy()) if ! $pid; # child -> proxy()
push @pid,$pid;
close($proxy);

# connect to server, check certificate
my $cl = IO::Socket::SSL->new(
    PeerAddr => $saddr,
    Domain => AF_INET,
    SSL_verify_mode => 1,
    SSL_ca_file => 't/certs/test-ca.pem',
);
ssl_ok($cl,"ssl connected to server");
ok( $cl->peer_certificate('subject') =~ m{server\.local}, "subject w/o mitm");
ok( $cl->peer_certificate('issuer') =~ m{IO::Socket::SSL Demo CA},
    "issuer w/o mitm");

# connect to proxy, check certificate
$cl = IO::Socket::SSL->new(
    PeerAddr => $paddr,
    Domain => AF_INET,
    SSL_verify_mode => 1,
    SSL_ca_file => 't/certs/proxyca.pem',
);
ssl_ok($cl,"ssl connected to proxy");
ok( $cl->peer_certificate('subject') =~ m{server\.local}, "subject w/ mitm");
ok( $cl->peer_certificate('issuer') =~ m{IO::Socket::SSL::Intercept},
    "issuer w/ mitm");


sub server {
    while (1) {
	my $cl = $server->accept or next;
	sleep(1);
    }
}

sub proxy {
    my $mitm = IO::Socket::SSL::Intercept->new(
	proxy_cert_file => 't/certs/proxyca.pem',
	proxy_key_file => 't/certs/proxyca.pem',
    );
    while (1) {
	my $toc = $proxy->accept or next;
	my $tos = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    Domain => AF_INET,
	    SSL_verify_mode => 1,
	    SSL_ca_file => 't/certs/test-ca.pem',
	) or die "failed connect to server: $!, $SSL_ERROR";
	my ($cert,$key) = $mitm->clone_cert($tos->peer_certificate);
	$toc = IO::Socket::SSL->start_SSL( $toc,
	    SSL_server => 1,
	    SSL_cert => $cert,
	    SSL_key => $key,
	) or die "ssl upgrade client failed: $SSL_ERROR";
	sleep(1);
    }
}

sub ok {
    my ($what,$msg) = @_;
    print "not " if ! $what;
    print "ok # $msg\n";
}
sub sys_ok {
    my ($what,$msg) = @_;
    if ( $what ) {
	print "ok # $msg\n";
    } else {
	print "not ok # $msg - $!\n";
	exit
    }
}

sub ssl_ok {
    my ($what,$msg) = @_;
    if ( $what ) {
	print "ok # $msg\n";
    } else {
	print "not ok # $msg - $SSL_ERROR\n";
	exit
    }
}
