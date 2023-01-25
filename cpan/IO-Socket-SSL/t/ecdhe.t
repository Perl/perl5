#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/ecdhe.t'

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

my $can_ecdh = IO::Socket::SSL->can_ecdh;
if (! $can_ecdh) {
    print "1..0 # Skipped: no support for ecdh with this openssl/Net::SSLeay\n";
    exit
}

$|=1;
print "1..4\n";

# first create simple ssl-server
my $ID = 'server';
my $addr = '127.0.0.1';
my $server = IO::Socket::SSL->new(
    LocalAddr => $addr,
    Listen => 2,
    ReuseAddr => 1,
    SSL_cert_file => "t/certs/server-cert.pem",
    SSL_key_file  => "t/certs/server-key.pem",
    (defined &Net::SSLeay::CTX_set1_groups_list || defined &Net::SSLeay::CTX_set1_curves_list)
	? (SSL_ecdh_curve => 'prime256v1' ) : (),
) || do {
    notok($!);
    exit
};
ok("Server Initialization");

# add server port to addr
$addr.= ':'.(sockaddr_in( getsockname( $server )))[0];

my $pid = fork();
if ( !defined $pid ) {
    die $!; # fork failed

} elsif ( !$pid ) {    ###### Client

    $ID = 'client';
    close($server);
    my $to_server = IO::Socket::SSL->new(
	PeerAddr => $addr,
	Domain => AF_INET,
	(defined &Net::SSLeay::CTX_set1_groups_list || defined &Net::SSLeay::CTX_set1_curves_list)
	    ? (SSL_ecdh_curve => 'prime256v1' ) : (),
	SSL_verify_mode => 0 ) || do {
	notok( "connect failed: $SSL_ERROR" );
	exit
    };
    ok( "client connected" );

    my $protocol = $to_server->get_sslversion;
    if ($protocol eq 'TLSv1_3') {
        # <https://www.openssl.org/blog/blog/2017/05/04/tlsv1.3/>
        ok("# SKIP TLSv1.3 doesn't advertize key exchange in a chipher name");
    } else {
        my $cipher = $to_server->get_cipher();
        if ( $cipher !~m/^ECDHE-/ ) {
            notok("bad key exchange: $cipher");
            exit;
        }
        ok("ecdh key exchange: $cipher");
    }

} else {                ###### Server

    my $to_client = $server->accept || do {
	notok( "accept failed: $SSL_ERROR" );
	kill(9,$pid);
	exit;
    };
    ok( "Server accepted" );
    wait;
}

sub ok { print "ok # [$ID] @_\n"; }
sub notok { print "not ok # [$ID] @_\n"; }
