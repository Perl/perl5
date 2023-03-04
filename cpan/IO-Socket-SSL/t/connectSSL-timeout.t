use strict;
use warnings;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
print "1..16\n";


{
    # first use SSL client
    my ($server,$saddr) = create_listen_socket();
    ok( 1, "listening \@$saddr" );
    my $srv = fork_sub( 'server','ssl',$server );
    close($server);
    fd_grep_ok( 'Waiting', $srv );
    my $cl = fork_sub( 'client',$saddr );
    fd_grep_ok( 'Connect from',$srv );
    fd_grep_ok( 'Connected', $cl );
    fd_grep_ok( 'Server SSL Handshake OK', $srv );
    fd_grep_ok( 'Client SSL Handshake OK', $cl );
    fd_grep_ok( 'Hi!', $cl );
}

{
    # then try bad non-SSL client
    my ($server,$saddr) = create_listen_socket();
    ok( 1, "listening \@$saddr" );
    my $srv = fork_sub( 'server','nossl',$server );
    close($server);
    fd_grep_ok( 'Waiting', $srv );
    my $cl = fork_sub( 'client',$saddr );
    fd_grep_ok( 'Connect from',$srv );
    fd_grep_ok( 'Connected', $cl );
    fd_grep_ok( 'Client SSL Handshake FAILED', $cl );
}


sub server {
    my ($behavior,$server) = @_;
    print "Waiting\n";
    my $client = $server->accept || die "accept failed: $!";
    print "Connect from ".$client->peerhost.':'.$client->peerport."\n";
    if ( $behavior eq 'ssl' ) {
	if ( IO::Socket::SSL->start_SSL( $client,
	    SSL_server => 1,
	    Timeout => 30,
	    SSL_cert_file => 't/certs/server-cert.pem',
	    SSL_key_file => 't/certs/server-key.pem',
	)) {
	    print "Server SSL Handshake OK\n";
	    print $client "Hi!\n";
	}
    } else {
	while ( sysread( $client, my $buf,8000 )) {}
    }
}

sub client {
    my $saddr = shift;
    my $c = IO::Socket::INET->new( $saddr ) || die "connect failed: $!";
    print "Connected\n";
    if ( IO::Socket::SSL->start_SSL( $c,
	Timeout => 5,
	SSL_ca_file => 't/certs/test-ca.pem',
    )) {
	print "Client SSL Handshake OK\n";
	print <$c>
    } else {
	print "Client SSL Handshake FAILED - $SSL_ERROR\n";
    }
}
