#!perl

# make sure IO::Socket::IP will not be used
BEGIN { 
    if ( eval { require Acme::Override::INET }) {
	print "1..0 # Skipped: will not work with Acme::Override::INET installed\n";
	exit
    }
    $INC{'IO/Socket/IP.pm'} = undef 
}

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

# check first if we have loaded IO::Socket::IP, as if so we won't need or use
# IO::Socket::INET6
if( IO::Socket::SSL->CAN_IPV6 eq "IO::Socket::IP" ) {
    print "1..0 # Skipped: using IO::Socket::IP instead\n";
    exit;
}

# check if we have loaded INET6, IO::Socket::SSL should do it by itself
# if it is available
unless( IO::Socket::SSL->CAN_IPV6 eq "IO::Socket::INET6" ) {
    # not available or IO::Socket::SSL forgot to load it
    if ( ! eval { require IO::Socket::INET6 } ) {
	print "1..0 # Skipped: no IO::Socket::INET6 available\n";
    } elsif ( ! eval { IO::Socket::INET6->VERSION(2.62) } ) {
	print "1..0 # Skipped: no IO::Socket::INET6 available\n";
    } else {
	print "1..1\nnot ok # automatic use of INET6\n";
    }
    exit
}

my $addr = '::1';
# check if we can use ::1, e.g. if the computer has IPv6 enabled
if ( ! IO::Socket::INET6->new(
    Listen => 10,
    LocalAddr => $addr,
)) {
    print "1..0 # no IPv6 enabled on this computer\n";
    exit
}

$|=1;
print "1..3\n";
print "# IO::Socket::INET6 version=$IO::Socket::INET6::VERSION\n";

# first create simple ssl-server
my $ID = 'server';
my $server = IO::Socket::SSL->new(
    LocalAddr => $addr,
    Listen => 2,
    SSL_cert_file => "t/certs/server-cert.pem",
    SSL_key_file  => "t/certs/server-key.pem",
) || do {
    notok($!);
    exit
};
ok("Server Initialization at $addr");

# add server port to addr
$addr = "[$addr]:".$server->sockport;
print "# server at $addr\n";

my $pid = fork();
if ( !defined $pid ) {
    die $!; # fork failed

} elsif ( !$pid ) {    ###### Client

    $ID = 'client';
    close($server);
    my $to_server = IO::Socket::SSL->new(
	PeerAddr => $addr,
	SSL_verify_mode => 0,
    ) || do {
	notok( "connect failed: ".IO::Socket::SSL->errstr() );
	exit
    };
    ok( "client connected" );

} else {                ###### Server

    my $to_client = $server->accept || do {
	notok( "accept failed: ".$server->errstr() );
	kill(9,$pid);
	exit;
    };
    ok( "Server accepted" );
    wait;
}

sub ok { print "ok # [$ID] @_\n"; }
sub notok { print "not ok # [$ID] @_\n"; }
