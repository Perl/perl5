use strict;
use warnings;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
print "1..15\n";

# first use SSL client
{
    my ($server,$saddr) = create_listen_socket();
    ok(1, "listening \@$saddr" );
    my $srv = fork_sub( 'server',$server );
    close($server);
    fd_grep_ok( 'Waiting', $srv );
    my $cl = fork_sub( 'client_ssl',$saddr );
    fd_grep_ok( 'Connect from',$srv );
    fd_grep_ok( 'Connected', $cl );
    fd_grep_ok( 'SSL Handshake OK', $srv );
    fd_grep_ok( 'Hi!', $cl );
}

# then try bad non-SSL client
{
    my ($server,$saddr) = create_listen_socket();
    ok(1, "listening \@$saddr" );
    my $srv = fork_sub( 'server',$server );
    close($server);
    fd_grep_ok( 'Waiting', $srv );
    my $cl = fork_sub( 'client_no_ssl',$saddr );
    fd_grep_ok( 'Connect from',$srv );
    fd_grep_ok( 'Connected', $cl );
    fd_grep_ok( 'SSL Handshake FAILED', $srv );
}


sub server {
    my $server = shift;
    print "Waiting\n";
    my $client = $server->accept || die "accept failed: $!";
    print "Connect from ".$client->peerhost.':'.$client->peerport."\n";
    if ( IO::Socket::SSL->start_SSL( $client,
	SSL_server => 1,
	Timeout => 5,
	SSL_cert_file => 't/certs/server-cert.pem',
	SSL_key_file => 't/certs/server-key.pem',
    )) {
	print "SSL Handshake OK\n";
	print $client "Hi!\n";
    } else {
	print "SSL Handshake FAILED - $!\n"
    }
}

sub client_no_ssl {
    my $saddr = shift;
    my $c = IO::Socket::INET->new( $saddr ) || die "connect failed: $!";
    print "Connected\n";
    while ( sysread( $c,my $buf,8000 )) {}
}

sub client_ssl {
    my $saddr = shift;
    my $c = IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_verify_mode => 0
    ) || die "connect failed: $!|$SSL_ERROR";
    print "Connected\n";
    while ( sysread( $c,my $buf,8000 )) { print $buf }
}
