#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/dhe.t'

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

# check if we have NPN available
# if it is available
if ( ! IO::Socket::SSL->can_npn ) {
    print "1..0 # Skipped: NPN not available in Net::SSLeay\n";
    exit
}

$|=1;
print "1..5\n";

# first create simple ssl-server
my $ID = 'server';
my $addr = '127.0.0.1';
my $server = IO::Socket::SSL->new(
    LocalAddr => $addr,
    Listen => 2,
    SSL_version => 'SSLv23:!TLSv1_3', # NPN does not exist in TLSv1.3
                                # https://github.com/openssl/openssl/issues/3665
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
    SSL_npn_protocols => [qw(one two)],
) || do {
    ok(0,$!);
    exit
};
ok(1,"Server Initialization at $addr");

# add server port to addr
$addr = "$addr:".$server->sockport;
print "# server at $addr\n";

my $pid = fork();
if ( !defined $pid ) {
    die $!; # fork failed

} elsif ( !$pid ) {    ###### Client

    $ID = 'client';
    close($server);
    my $to_server = IO::Socket::SSL->new(
	PeerAddr => $addr,
	Domain => AF_INET,
	SSL_verify_mode => 0,
	SSL_npn_protocols => [qw(two three)],
    ) or do {
	ok(0, "connect failed: ".IO::Socket::SSL->errstr() );
	exit
    };
    ok(1,"client connected" );
    my $proto = $to_server->next_proto_negotiated;
    ok($proto eq 'two',"negotiated $proto");


} else {                ###### Server

    my $to_client = $server->accept or do {
	ok(0,"accept failed: ".$server->errstr() );
	kill(9,$pid);
	exit;
    };
    ok(1,"Server accepted" );
    my $proto = $to_client->next_proto_negotiated;
    ok($proto eq 'two',"negotiated $proto");
    wait;
}

sub ok {
    my $ok = shift;
    print $ok ? '' : 'not ', "ok # [$ID] @_\n";
}
