#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/sysread_write.t'

# This tests that sysread/syswrite behave different to read/write, e.g.
# that the latter ones are blocking until they read/write everything while
# the sys* function also can read/write partial data.

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
print "1..9\n";

#################################################################
# create Server socket before forking client, so that it is
# guaranteed to be listening
#################################################################

# first create simple ssl-server
my $ID = 'server';
my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    SSL_cert_file => "t/certs/server-cert.pem",
    SSL_key_file => "t/certs/server-key.pem",
);
print "not ok: $!\n", exit if !$server;
ok("Server Initialization");

my $saddr = $server->sockhost.':'.$server->sockport;

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {

    ############################################################
    # CLIENT == child process
    ############################################################

    close($server);
    $ID = 'client';

    my $to_server = IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_ca_file => "t/certs/test-ca.pem",
    ) || do {
	print "not ok: connect failed: $!\n";
	exit
    };

    ok( "client connected" );

    # write 512 byte, server reads it in 66 byte chunks which
    # should cause at least the last read to be less then 66 bytes
    # (and not block).
    alarm(10);
    $SIG{ALRM} = sub {
	print "not ok: timed out\n";
	exit;
    };
    #DEBUG( "send 2x512 byte" );
    unless ( syswrite( $to_server, 'x' x 512 ) == 512
	and syswrite( $to_server, 'x' x 512 ) == 512 ) {
	print "not ok: write to small: $!\n";
	exit;
    }

    sysread( $to_server,my $ack,1 ) || print "not ";
    ok( "received ack" );

    alarm(0);
    ok( "send in time" );

    # make a syswrite with a buffer length greater than the
    # ssl message block size (16k for sslv3). It should send
    # only a partial packet of 16k
    my $n = syswrite( $to_server, 'x' x 18000 );
    #DEBUG( "send $n bytes" );
    print "not " if $n != 16384;
    ok( "partial write in syswrite" );

    # but write should send everything because it does ssl_write_all
    $n = $to_server->write( 'x' x 18000 );
    #DEBUG( "send $n bytes" );
    print "not " if $n != 18000;
    ok( "full write in write ($n)" );

    exit;

} else {

    ############################################################
    # SERVER == parent process
    ############################################################

    my $to_client = $server->accept || do {
	print "not ok: accept failed: $!\n";
	kill(9,$pid);
	exit;
    };
    ok( "Server accepted" );

    my $total = 1024;
    my $partial;
    while ( $total > 0 ) {
	#DEBUG( "reading 66 of $total bytes pending=".$to_client->pending() );
	my $n = sysread( $to_client, my $buf,66 );
	#DEBUG( "read $n bytes" );
	if ( !$n ) {
	    print "not ok: read failed: $!\n";
	    kill(9,$pid);
	    exit;
	} elsif ( $n != 66 ) {
	    $partial++;
	}
	$total -= $n;
    }
    print "not " if !$partial;
    ok( "partial read in sysread" );

    # send ack back
    print "not " if !syswrite( $to_client, 'x' );
    ok( "send ack back" );

    # just read so that the writes will not block
    $to_client->read( my $buf,18000 );
    $to_client->read( $buf,18000 );


    # wait until client exits
    wait;
}

exit;


sub ok { print "ok # [$ID] @_\n"; }
