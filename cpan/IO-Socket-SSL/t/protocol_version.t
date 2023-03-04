#!perl

use strict;
use warnings;
use Test::More;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

plan skip_all => "Test::More has no done_testing"
    if !defined &done_testing;

$|=1;

my $XDEBUG = 0;
my @versions = qw(SSLv3 TLSv1 TLSv1_1 TLSv1_2 TLSv1_3);

my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    SSL_server => 1,
    SSL_startHandshake => 0,
    SSL_version => 'SSLv23', # allow SSLv3 too
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file  => 't/certs/server-key.pem',
) or BAIL_OUT("cannot listen on localhost: $!");
print "not ok\n", exit if !$server;
my $saddr = $server->sockhost().':'.$server->sockport();
$XDEBUG && diag("server at $saddr");

defined( my $pid = fork() ) or BAIL_OUT("fork failed: $!");
if ($pid == 0) {
    close($server);
    my $check = sub {
	my ($ver,$expect) = @_;
	$XDEBUG && diag("try $ver, expect $expect");
	# Hoping that this isn't necessary, but just in case we get a TCP
	# failure rather than SSL failure, wiping the previous value here
	# seems like it might be a useful precaution:
	$SSL_ERROR = '';

	my $cl = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    Domain => AF_INET,
	    SSL_startHandshake => 0,
	    SSL_verify_mode => 0,
	    SSL_version => $ver,
	) or do {
	    # Might bail out before the starttls if we provide a known-unsupported
	    # version, for example SSLv3 on openssl 1.0.2+
	    if($SSL_ERROR =~ /$ver not supported|null ssl method passed/) {
	        $XDEBUG && diag("SSL connect failed with $ver: $SSL_ERROR");
	        return;
	    }
	    die "connection with $ver failed: $! (SSL error: $SSL_ERROR)";
	};
	$XDEBUG && diag("TCP connected");
	print $cl "starttls $ver $expect\n";
	<$cl>;
	if (!$cl->connect_SSL) {
	    $XDEBUG && diag("SSL upgrade failed with $ver: $SSL_ERROR");
	    return;
	}
	$XDEBUG && diag("SSL connect done");
	return $cl->get_sslversion();
    };
    my $stop = sub {
	my $cl = IO::Socket::INET->new($saddr) or return;
	print $cl "quit\n";
    };

    # find out the best protocol version the server can
    my %supported;
    my $ver = $check->('SSLv23','') or die "connect to server failed: $!";
    $XDEBUG && diag("best protocol version: $ver");

    for (@versions, 'foo') {
	$supported{$_} = 1;
	$ver eq $_ and last;
    }
    die "best protocol version server supports is $ver" if $supported{foo};

    # Check if the OpenSSL was compiled without support for specific protocols
    for(qw(SSLv3 TLSv1 TLSv1_1 TLSv1_2 TLSv1_3)) {
	if ( ! $check->($_,'')) {
	    diag("looks like OpenSSL was compiled without $_ support");
	    delete $supported{$_};
	}
    }

    for my $ver (@versions) {
	next if ! $supported{$ver};
	# requesting only this version should be done with this version
	$check->($ver,$ver);
	# requesting SSLv23 and disallowing anything better should give $ver too
	my $sslver = "SSLv23";
	for(reverse grep { $supported{$_} } @versions) {
	    last if $_ eq $ver;
	    $sslver .= ":!$_";
	}
	$check->($sslver,$ver);
    }

    $stop->();
    exit(0);
}

vec( my $vs = '',fileno($server),1) = 1;
while (select( my $rvs = $vs,undef,undef,15 )) {
    $XDEBUG && diag("got read event");
    my $cl = $server->accept or do {
	$XDEBUG && diag("accept failed: $!");
	next;
    };
    $XDEBUG && diag("TCP accept done");
    my $cmd = <$cl>;
    $XDEBUG && diag("got command $cmd");
    my ($ver,$expect) = $cmd =~m{^starttls (\S+) (\S*)} or do {
	$XDEBUG && diag("finish");
	done_testing() if $cmd =~m/^quit/;
	last;
    };
    print $cl "ok\n";
    $cl->accept_SSL() or do {
	$XDEBUG && diag("accept_SSL failed: $SSL_ERROR");
	if ($expect) {
	    fail("accept $ver");
	} else {
	    diag("failed to accept $ver");
	}
	next;
    };
    $XDEBUG && diag("SSL accept done");
    if ($expect) {
	is($cl->get_sslversion,$expect,"accept $ver with $expect");
    } else {
	pass("accept $ver with any, got ".$cl->get_sslversion);
    }
    close($cl);
}

wait;
