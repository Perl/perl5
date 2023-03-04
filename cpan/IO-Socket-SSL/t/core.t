#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/core.t'

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
use Errno qw( EWOULDBLOCK EAGAIN );

do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

use Test::More;
Test::More->builder->use_numbers(0);
Test::More->builder->no_ending(1);

my $CAN_NONBLOCK = eval "use 5.006; use IO::Select; 1";
my $CAN_PEEK = &Net::SSLeay::OPENSSL_VERSION_NUMBER >= 0x0090601f;

my $numtests = 40;
$numtests+=5 if $CAN_NONBLOCK;
$numtests+=3 if $CAN_PEEK;

plan tests => $numtests;

# We need to detect the best TLS version supported by the server since we can
# not offer SSLv23 for for a reliable SSL_error_trap because of how the old
# SSLv2 compatible works. On the other side we can no longer rely on all systems
# supporting TLS 1.0 either.
my $tls_version;
for(qw(TLSv1_2 TLSv1_1 TLSv1)) {
    my $method = sprintf("Net::SSLeay::CTX_%s_new",lc($_));
    next if ! defined &$method;
    $tls_version = $_;
    last;
}
die "no TLS support" if ! $tls_version;

my $error_trapped = 0;
my $localip = '127.0.0.1';
my $server = IO::Socket::SSL->new(
    LocalAddr => $localip,
    LocalPort => 0,
    Listen => 2,
    Timeout => 30,
    ReuseAddr => 1,
    SSL_verify_mode => 0x00,
    SSL_ca_file => "t/certs/test-ca.pem",
    SSL_version => $tls_version,
    SSL_error_trap => sub {
	my $self = shift;
	print $self "This server is SSL only";
	$error_trapped = 1;
	$self->close;
    },
    SSL_cert_file => "t/certs/server-cert.pem",
    SSL_key_file => "t/certs/server-key.enc",
    SSL_passwd_cb => sub { return "bluebell" },
);

ok( $server, "Server Initialization");
$server or exit;

ok( fileno( $server), "Server Fileno Check");

my $saddr = $localip.':'.$server->sockport;


unless (fork) {
    close $server;
    my $client = IO::Socket::INET->new(
	PeerAddr => $saddr,
	LocalAddr => $localip,
    );
    print $client "Test\n";
    is( <$client>, "This server is SSL only", "Client non-SSL connection");
    close $client;

    $client = IO::Socket::SSL->new(
	PeerAddr => $saddr,
	LocalAddr => $localip,
	Domain => AF_INET,
	SSL_verify_mode => 0x01,
	SSL_ca_file => "t/certs/test-ca.pem",
	SSL_use_cert => 1,
	SSL_cert_file => "t/certs/client-cert.pem",
	SSL_key_file => "t/certs/client-key.enc",
	SSL_passwd_cb => sub { return "opossum" },
	SSL_verify_callback => \&verify_sub,
    );


    sub verify_sub {
	my ($ok, $ctx_store, $cert, $error) = @_;
	$ok && $ctx_store && $cert && !$error or do {
	    fail("client failure in verify_sub");
	    exit;
	};
	like( $cert, qr/IO::Socket::SSL Demo CA/, "Client Verify-sub Check");
	return 1;
    }


    $client || (print("not ok #client failure\n") && exit);
    ok( $client, "Client Initialization");

    $client->fileno() || print "not ";
    ok( $client->fileno(), "Client Fileno Check");

#    $client->untaint() if ($HAVE_SCALAR_UTIL);  # In the future...

    ok( $client->dump_peer_certificate(), "Client Peer Certificate Check");

    ok( $client->peer_certificate("issuer"), "Client Peer Certificate Issuer Check");

    ok( $client->get_cipher(), "Client Cipher Check");

    $client->syswrite('00waaaanf00', 7, 2);

    if ($CAN_PEEK) {
	my $buffer;
	$client->read($buffer,2);
	is( $buffer, "ok", "Client Peek Check");
    }

    $client->print("Test\n");
    $client->printf("\$%.2f\n%d\n%c\n%s",
		    1.0444442342,
		    4.0,
		    ord("y"),
		    "Test\nBeaver\nBeaver\n");

    my $buffer="\0\0aaaaaaaaaaaaaaaaaaaa";
    $client->sysread($buffer, 7, 2);
    is( $buffer, "\0\0waaaanf", "Client Sysread Check");


## The future...
#    if ($HAVE_SCALAR_UTIL) {
#       print "not " if (is_tainted($buffer));
#       &ok("client");
#    }

    my @array = $client->getline();
    is( $array[0], "Test\n", "Client Getline Check");

    is( $client->getc, "\$", "Client Getc Check");

    @array = $client->getlines;
    is( scalar @array, 6, "Client Getlines Check 1");

    is( $array[0], "1.04\n", "Client Getlines Check 2");

    is( $array[1], "4\n", "Client Getlines Check 3");

    is( $array[2], "y\n", "Client Getlines Check 4");

    is( join("", @array[3..5]),
	  "Test\nBeaver\nBeaver\n",
	  "Client Getlines Check 5");

    ok( !<$client>, "Client Finished Reading Check");

    $client->close(SSL_no_shutdown => 1);

    my $client_2 = IO::Socket::INET->new(
	PeerAddr => $saddr,
	LocalAddr => $localip
    );
    ok( $client_2, "Second Client Initialization");

    $client_2 = IO::Socket::SSL->new_from_fd($client_2->fileno, '+<>',
					     SSL_reuse_ctx => $client);
    ok( $client_2, "Client Init from Fileno Check");
    $buffer = <$client_2>;

    is( $buffer, "Boojums\n", "Client (fileno) Readline Check");
    $client_2->close(SSL_ctx_free => 1);

    if ($CAN_NONBLOCK) {
	my $client_3 = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    LocalAddr => $localip,
	    Domain => AF_INET,
	    SSL_verify_mode => 0x01,
	    SSL_ca_file => "t/certs/test-ca.pem",
	    SSL_use_cert => 1,
	    SSL_cert_file => "t/certs/client-cert.pem",
	    SSL_key_file => "t/certs/client-key.enc",
	    SSL_passwd_cb => sub { return "opossum" },
	    Blocking => 0,
	);

	ok( $client_3, "Client Nonblocking Check 1");
	close $client_3;

	my $client_4 = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    LocalAddr => $localip,
	    Domain => AF_INET,
	    SSL_reuse_ctx => $client_3,
	    Blocking => 0
	);
	ok( $client_4, "Client Nonblocking Check 2");
	$client_3->close(SSL_ctx_free => 1);
    }

    exit(0);
}

my $client = $server->accept;

ok( $error_trapped, "Server non-SSL Client Check");

if ($client && $client->opened) {
    fail("client stayed alive");
    exit;
}
ok( !$client, "Server Kill-client Check");

($client, my $peer) = $server->accept;
ok( $client, "Server Client Accept Check");
$client or exit;

ok( $peer, "Accept returning peer address check.");

ok( fileno($client), "Server Client Fileno Check");

my $buffer;

if ($CAN_PEEK) {
    $client->peek($buffer, 7, 2);
    is( $buffer, "\0\0waaaanf","Server Peek Check");

    is( $client->pending(), 7, "Server Pending Check");

    print $client "ok";
}

sysread($client, $buffer, 7, 2);
is( $buffer, "\0\0waaaanf", "Server Sysread Check");

my @array = scalar <$client>;
is( $array[0], "Test\n", "Server Getline Check");

is( getc($client), "\$", "Server Getc Check");

@array = map { scalar <$client> } (0..5);
is( scalar @array, 6, "Server Getlines Check 1");

is( $array[0], "1.04\n", "Server Getlines Check 2");

is( $array[1], "4\n", "Server Getlines Check 3");

is( $array[2], "y\n", "Server Getlines Check 4");

is( join("", @array[3..5]), "Test\nBeaver\nBeaver\n", "Server Getlines Check 5");

syswrite($client, '00waaaanf00', 7, 2);
print($client "Test\n");
printf $client "\$%.2f\n%d\n%c\n%s", (1.0444442342, 4.0, ord("y"), "Test\nBeaver\nBeaver\n");

close $client;

($client, $peer) = $server->accept or do {
    fail("client creation failed");
    exit;
};
is( inet_ntoa((unpack_sockaddr_in($peer))[1]), $localip, "Peer address check");

if ($CAN_NONBLOCK) {
    $client->blocking(0);
    $client->read($buffer, 20, 0);
    is( $SSL_ERROR, SSL_WANT_READ, "Server Nonblocking Check 1");
}

ok( $client->opened, "Server Client Opened Check 1");

print $client "Boojums\n";

close($client);

${*$client}{'_SSL_opened'} = 1;
ok( !$client->opened, "Server Client Opened Check 2");
${*$client}{'_SSL_opened'} = 0;

if ($CAN_NONBLOCK) {
    $client = $server->accept;
    ok( $client->opened, "Server Nonblocking Check 2");
    close $client;

    $server->blocking(0);
    IO::Select->new($server)->can_read(30);
    $client = $server->accept;
    while ( ! $client ) {
	#DEBUG( "$!,$SSL_ERROR" );
	if ( $! == EWOULDBLOCK || $! == EAGAIN ) {
	    if ( $SSL_ERROR == SSL_WANT_WRITE ) {
		IO::Select->new( $server->opening )->can_write(30);
	    } else {
		IO::Select->new( $server->opening )->can_read(30);
	    }
	} else {
	    last
	}
	$client = $server->accept;
    }

    ok( $client->opened, "Server Nonblocking Check 3");
    close $client;
}

$server->close(SSL_ctx_free => 1);
wait;


## The future....
#sub is_tainted {
#    my $arg = shift;
#    my $nada = substr($arg, 0, 0);
#    local $@;
#    eval {eval "# $nada"};
#    return length($@);
#}
