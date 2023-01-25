#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use IO::Socket::SSL;
#$Net::SSLeay::trace=3;

plan skip_all => "no OCSP support" if ! IO::Socket::SSL->can_ocsp;

my $fingerprints = do './fingerprint.pl' 
    || do './t/external/fingerprint.pl' 
    || die "no fingerprints for sites";
my @tests = grep { $_->{ocsp} } @$fingerprints;

plan tests => 0+@tests;

my $timeout = 10;
my $proxy = ( $ENV{http_proxy} || '' )
    =~m{^(?:\w+://)?([\w\-.:\[\]]+:\d+)/?$} && $1;
my $have_httptiny = eval { require HTTP::Tiny };
my $ipclass = 'IO::Socket::INET';
for( qw( IO::Socket::IP IO::Socket::INET6  )) {
    eval { require $_ } or next;
    $ipclass = $_;
    last;
}


TEST:
for my $test (@tests) {
    my $tcp_connect = sub {
	if ( ! $proxy ) {
	    # direct connection
	    return $ipclass->new(
		PeerAddr => $test->{host},
		PeerPort => $test->{port},
		Timeout => $timeout,
	    ) || die "tcp connect to $test->{host}:$test->{port} failed: $!";
	}
	my $cl = $ipclass->new(
	    PeerAddr => $proxy,
	    Timeout => $timeout,
	) || die "tcp connect to proxy $proxy failed: $!";

	# try to establish tunnel via proxy with CONNECT
	{
	    local $SIG{ALRM} = sub {
		die "proxy HTTP tunnel creation timed out" };
	    alarm($timeout);
	    print $cl "CONNECT $test->{host}:$test->{port} HTTP/1.0\r\n\r\n";
	    my $reply = '';
	    while (<$cl>) {
		$reply .= $_;
		last if m{\A\r?\n\Z};
	    }
	    alarm(0);
	    $reply =~m{\AHTTP/1\.[01] 200\b} or
		die "unexpected response from proxy: $reply";
	}
	return $cl;
    };

    SKIP: {
	# first check fingerprint in case of SSL interception
	my $cl = eval { &$tcp_connect } or skip "TCP connect#1 failed: $@",1;
	diag("tcp connect to $test->{host}:$test->{port} ok");
	skip "SSL upgrade w/o validation failed: $SSL_ERROR",1
	    if ! IO::Socket::SSL->start_SSL($cl, 
		SSL_hostname => $test->{host}, 
		SSL_verify_mode => 0
	    );
	my $pubkey_fp = $test->{fingerprint} =~m{\$pub\$};
	skip "fingerprints do not match",1
	    if $cl->get_fingerprint('sha1',undef,$pubkey_fp) ne $test->{fingerprint};
	diag("fingerprint matches");

	# then check if we can use the default CA path for successful
	# validation without OCSP yet
	$cl = eval { &$tcp_connect } or skip "TCP connect#2 failed: $@",1;
	skip "SSL upgrade w/o OCSP failed: $SSL_ERROR",1
	    if ! IO::Socket::SSL->start_SSL($cl, 
		SSL_hostname => $test->{host}, 
		SSL_ocsp_mode => SSL_OCSP_NO_STAPLE 
	    );
	diag("validation with default CA w/o OCSP ok");

	# check with default settings
	$cl = eval { &$tcp_connect } or skip "TCP connect#3 failed: $@",1;
	my $ok = IO::Socket::SSL->start_SSL($cl, SSL_hostname => $test->{host});
	my $err = !$ok && $SSL_ERROR;
	if (!$ok && !$test->{ocsp}{revoked}) {
	    fail("SSL upgrade with OCSP stapling failed: $err");
	    next TEST;
	}

	# we got usable stapling if _SSL_ocsp_verify is defined
	if ($test->{ocsp}{staple}) {
	    if ( ! ${*$cl}{_SSL_ocsp_verify}) {
		fail("did not get expected OCSP response with stapling");
		next TEST;
	    } else {
		diag("got stapled response as expected");
	    }
	}

	if (!$err && !$${*$cl}{_SSL_ocsp_verify} && $have_httptiny) {
	    # use OCSP resolver to resolve remaining certs, should be at most one
	    my $ocsp_resolver = $cl->ocsp_resolver;
	    my %rq = $ocsp_resolver->requests;
	    if (keys(%rq)>1) {
		fail("got more open OCSP requests (".keys(%rq).
		    ") than expected(1) in default mode");
		next TEST;
	    }
	    $err = $ocsp_resolver->resolve_blocking(timeout => $timeout);
	}

	if ($test->{ocsp}{revoked}) {
	    if ($err =~m/revoked/) {
		my $where = ${*$cl}{_SSL_ocsp_verify} ? 'stapled':'asked OCSP server';
		pass("revoked as expected ($where)");
	    } elsif ($err =~m/OCSP_basic_verify:certificate verify error/) {
		# badly signed OCSP record
		pass("maybe revoked, but got OCSP verification error: $SSL_ERROR");
	    } elsif ($err =~m/response not yet valid or expired/) {
		pass("maybe revoked, but got not yet valid/expired response from OCSP server");
	    } elsif ($err) {
		# some other error
		pass("maybe revoked, but got error: $err");
	    } elsif (!$have_httptiny && !$test->{ocsp}{staple}) {
		# could not check because HTTP::Tiny is missing
		pass("maybe revoked, but could not check because HTTP::Tiny is missing");
	    } else {
		fail("expected revoked but connection ok");
	    }
	    next TEST;

	} elsif ($err) {
	    if ($err =~m/revoked/) {
		fail("expected ok but revoked");
	    } else {
		pass("probably ok, but got $err");
	    }
	    next TEST;
	}

	diag("validation with default CA with OCSP defaults ok");

	# now check with full chain
	$cl = eval { &$tcp_connect } or skip "TCP connect#4 failed: $@",1;
	my $cache = IO::Socket::SSL::OCSP_Cache->new;
	if (! IO::Socket::SSL->start_SSL($cl,
	    SSL_hostname => $test->{host},
	    SSL_ocsp_mode => SSL_OCSP_FULL_CHAIN,
	    SSL_ocsp_cache => $cache
	)) {
	    skip "unexpected fail of SSL connect: $SSL_ERROR",1
	}
	my $chain_size = $cl->peer_certificates;
	if ( my $ocsp_resolver = $have_httptiny && $cl->ocsp_resolver ) {
	    # there should be no hard error after resolving - unless an
	    # intermediate certificate got revoked which I don't hope
	    $err = $ocsp_resolver->resolve_blocking(timeout => $timeout);
	    if ($err) {
		fail("fatal error in OCSP resolver: $err");
		next TEST;
	    }
	    # we should now either have soft errors or the OCSP cache should
	    # have chain_size entries
	    if ( ! $ocsp_resolver->soft_error ) {
		my $cache_size = keys(%$cache)-1;
		if ($cache_size!=$chain_size) {
		    fail("cache_size($cache_size) != chain_size($chain_size)");
		    next TEST;
		}
	    }
	    diag("validation with default CA with OCSP full chain ok");
	}

	done:
	pass("OCSP tests $test->{host}:$test->{port} ok");
    }
}
