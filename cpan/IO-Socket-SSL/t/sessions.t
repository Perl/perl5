#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/core.t'

my $DEBUG = 0;

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

$|=1;
my $numtests = 17;
print "1..$numtests\n";

my $what = 'server';
my @servers = map {
    IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Listen => 2,
    )
} (1..3);

if ( grep { !$_ } @servers > 0 ) {
    print "not ok # Server init\n";
    exit;
}
ok("Server initialization");

my @saddr = map { $_->sockhost.':'.$_->sockport } @servers;
defined(my $pid = fork()) or die "fork failed: $!";
if ($pid == 0) {
    server();
    exit(0);
}
client();
wait;

sub client {
    $what = 'client';
    @servers = ();
    my $ctx = IO::Socket::SSL::SSL_Context->new(
	SSL_ca_file => "t/certs/test-ca.pem",
	# make cache large enough since we get multiple tickets with TLS 1.3
	SSL_session_cache_size => 100,
	# LibreSSL has currently no support for TLS 1.3 session handling
	# therefore enforce TLS 1.2
	Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") ?
	    (SSL_version => 'TLSv1_2') :
	# versions of Net::SSLeay with support for SESSION_up_ref have also the
	# other functionality needed for proper TLS 1.3 session handling
	defined(&Net::SSLeay::SESSION_up_ref) ? () :
	    (SSL_version => 'SSLv23:!TLSv1_3:!SSLv3:!SSLv2'),
    );

    my $cache = $ctx->{session_cache} or do {
	print "not ok \# Context init\n";
	exit;
    };
    ok("Context init");
    my $dump_cache = $DEBUG ? sub { diag($cache->_dump) } : sub {};

    IO::Socket::SSL::set_default_context($ctx);
    my @clients;
    push @clients, IO::Socket::SSL->new(PeerAddr => $saddr[0], Domain => AF_INET);
    push @clients, IO::Socket::SSL->new(PeerAddr => $saddr[1], Domain => AF_INET);
    my $sock3 = IO::Socket::INET->new($saddr[2]);
    push @clients, IO::Socket::SSL->start_SSL($sock3);

    if ( grep { !$_ } @clients >0 ) {
	print "not ok \# Client init $SSL_ERROR\n";
	exit;
    }
    ok("Client init, version=".$clients[0]->get_sslversion);

    for(@clients) {
	<$_>; # read ping
	print $_ "pong!\n";
    }
    &$dump_cache;

    print "not " if $cache->{room} >97;
    ok(">=3 entries in cache: ". (100- $cache->{room}));
    for(@saddr) {
	$cache->{shead}{$_} or print "not ";
	ok("$_ in cache");
    }
    $cache->{ghead}[1] eq $saddr[2] or print "not ";
    ok("latest ($saddr[2]) on top of cache");

    for (0..2) {
	# check if current session is cached
	$cache->get_session($saddr[$_],
	    Net::SSLeay::get_session($clients[$_]->_get_ssl_object))
	    or print "not ";
	ok("session in client $_");
	close $clients[$_];
    }

    # check if sessions get reused
    @clients = map { IO::Socket::SSL->new(PeerAddr => $_, Domain => AF_INET) }
	@saddr;
    for(@clients) {
	print "not " if ! $_->get_session_reused;
	ok("client $_ reused");
	<$_>; # read ping
	print $_ "pong!\n";
    }
    &$dump_cache;
}

sub server {
    my @ctx = map {
	IO::Socket::SSL::SSL_Context->new(
	    SSL_server => 1,
	    SSL_cert_file => "t/certs/server-cert.pem",
	    SSL_key_file => "t/certs/server-key.pem",
	    SSL_ca_file => "t/certs/test-ca.pem",
	);
    } @servers;
    my @clients;
    my $accept_all = sub {
	@clients = map { undef } @servers;
	for(my $i=0; $i<@servers; $i++) {
	    my $cl = $servers[$i]->accept or next;
	    IO::Socket::SSL->start_SSL($cl,
		SSL_server => 1,
		SSL_reuse_ctx => $ctx[$i]
	    ) or next;
	    $clients[$i] = $cl;
	}
    };
    &$accept_all;
    if ( grep { !$_ } @clients > 0 ) {
	print "not ok \# Client init\n";
	exit;
    }

    ok("Client init");
    for(@clients) {
	print $_ "ping!\n";
	<$_>; # read pong
    }
    ok("Server send pong, received ping");
    close($_) for @clients;

    &$accept_all;
    for(@clients) {
	print $_ "ping!\n";
	<$_>; # read pong
    }
    ok("Client again init + write + read");
}



sub ok {
    my $line = (caller)[2];
    print "ok # [$what]:$line $_[0]\n";
}
sub diag {
    my $msg = shift;
    $msg =~s{^}{ #  [$what] }mg;
    print STDERR $msg;
}
