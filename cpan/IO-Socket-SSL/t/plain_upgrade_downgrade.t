use strict;
use warnings;
use Socket;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
use Test::More;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

# create listener
IO::Socket::SSL::default_ca('t/certs/test-ca.pem');
my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
    # start as plain and upgrade later
    SSL_startHandshake => 0,
) || die "not ok #tcp listen failed: $!\n";
my $saddr = $server->sockhost.':'.$server->sockport;
#diag("listen at $saddr");

# fork child for server
defined( my $pid = fork() ) || die $!;
if ( ! $pid ) {
    $SIG{ALRM} = sub { die "server timed out" };
    while (1) {
	alarm(30);
	my $cl = $server->accept;
	diag("server accepted new client");
	#${*$cl}{_SSL_ctx} or die "accepted socket has no SSL context";
	${*$cl}{_SSL_object} and die "accepted socket is already SSL";

	# try to find out if we start with TLS immediately (peek gets data from
	# client hello) or have some plain data initially (peek gets these
	# plain data)
	diag("wait for initial data from client");
	my $buf = '';
	while (length($buf)<3) {
	    vec(my $rin='',fileno($cl),1) = 1;
	    my $rv = select($rin,undef,undef,10);
	    die "timeout waiting for data from client" if ! $rv;
	    die "something wrong: $!" if $rv<0;
	    $cl->peek($buf,3);
	    $buf eq '' and die "eof from client";
	    diag("got 0x".unpack("H*",$buf)." from client");
	}

	if ($buf eq "end") {
	    # done
	    diag("client requested end of tests");
	    exit(0);
	}

	if ($buf eq 'foo') {
	    # initial plain dialog
	    diag("server: got plain data at start of connection");
	    read($cl,$buf,3) or die "failed to read";
	    $buf eq 'foo' or die "read($buf) different from peek";
	    print $cl "bar"; # reply
	}

	# now we upgrade to TLS
	diag("server: TLS upgrade");
	$cl->accept_SSL or die "failed to SSL upgrade server side: $SSL_ERROR";
	${*$cl}{_SSL_object} or die "no SSL object after accept_SSL";
	read($cl,$buf,6) or die "failed to ssl read";
	$buf eq 'sslfoo' or die "wrong data received from client '$buf'";
	print $cl "sslbar";

	# now we downgrade from TLS to plain and try to exchange some data
	diag("server: TLS downgrade");
	$cl->stop_SSL or die "failed to stop SSL";
	${*$cl}{_SSL_object} and die "still SSL object after stop_SSL";
	read($cl,$buf,3);
	$buf eq 'foo' or die "wrong data received from client '$buf'";
	print $cl "bar";

	# now we upgrade again to TLS
	diag("server: TLS upgrade#2");
	$cl->accept_SSL or die "failed to SSL upgrade server side";
	${*$cl}{_SSL_object} or die "no SSL object after accept_SSL";
	read($cl,$buf,6) or die "failed to ssl read";
	$buf eq 'sslfoo' or die "wrong data received from client '$buf'";
	print $cl "sslbar";
    }
}

# client
close($server); # close server in client
$SIG{ALRM} = sub { die "client timed out" };

plan tests => 15;

for my $test (
    [qw(newINET start_SSL stop_SSL start_SSL)],
    [qw(newSSL stop_SSL connect_SSL)],
    [qw(newSSL:0 connect_SSL stop_SSL connect_SSL)],
    [qw(newSSL:0 start_SSL stop_SSL connect_SSL)],
) {
    my $cl;
    diag("-- test: @$test");
    for my $act (@$test) {
	if (eval {
	    if ($act =~m{newSSL(?::(.*))?$} ) {
		$cl = IO::Socket::SSL->new(
		    PeerAddr => $saddr,
		    Domain => AF_INET,
		    defined($1) ? (SSL_startHandshake => $1):(),
		) or die "failed to connect: $!|$SSL_ERROR";
		if ( ! defined($1) || $1 ) {
		    ${*$cl}{_SSL_object} or die "no SSL object";
		} else {
		    ${*$cl}{_SSL_object} and die "have SSL object";
		}
	    } elsif ($act eq 'newINET') {
		$cl = IO::Socket::INET->new($saddr)
		    or die "failed to connect: $!";
	    } elsif ($act eq 'stop_SSL') {
		$cl->stop_SSL or die "stop_SSL failed: $SSL_ERROR";
		${*$cl}{_SSL_object} and
		    die "still having SSL object after stop_SSL";
	    } elsif ($act eq 'connect_SSL') {
		$cl->connect_SSL or die "connect_SSL failed: $SSL_ERROR";
		${*$cl}{_SSL_object} or die "no SSL object after connect_SSL";
	    } elsif ($act eq 'start_SSL') {
		IO::Socket::SSL->start_SSL($cl) or
		    die "start_SSL failed: $SSL_ERROR";
		${*$cl}{_SSL_object} or die "no SSL object after start_SSL";
	    } else {
		die "unknown action $act"
	    }
	    if (${*$cl}{_SSL_object}) {
		print $cl "sslfoo";
		read($cl, my $buf,6);
		$buf eq 'sslbar' or die "wrong response with ssl: $buf";
	    } else {
		print $cl "foo";
		read($cl, my $buf,3);
		$buf eq 'bar' or die "wrong response without ssl: $buf";
	    }
	}) {
	    pass($act);
	} else {
	    fail("$act: $@");
	    last; # slip rest
	}
    }
}

# make server exit
alarm(10);
my $cl = IO::Socket::INET->new($saddr);
print $cl "end" if $cl;
wait;
