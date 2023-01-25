#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/nonblock.t'


use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
use IO::Select;
use Errno qw( EWOULDBLOCK EAGAIN EINPROGRESS);
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

if ( ! eval "use 5.006; use IO::Select; return 1" ) {
    print "1..0 # Skipped: no support for nonblocking sockets\n";
    exit;
}

$|=1;
print "1..27\n";

my $START = time();

# first create simple non-blocking tcp-server
my $ID = 'server';
my $server = IO::Socket::INET->new(
    Blocking => 0,
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
);

print "not ok: $!\n", exit if !$server; # Address in use?
ok("Server Initialization");

my $saddr = $server->sockhost.':'.$server->sockport;
my $ssock = $server->sockname;

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {

    ############################################################
    # CLIENT == child process
    ############################################################

    close($server);
    $ID = 'client';

    # fast: try connect_SSL immediately after sending plain text
    #	connect_SSL should fail on the first attempt because server
    #	is not ready yet
    # slow: wait before calling connect_SSL
    #	connect_SSL should succeed, because server was already waiting

    for my $test ( 'fast','slow' ) {

	# initial socket is unconnected, tcp, nonblocking
	my $to_server = IO::Socket::INET->new( Proto => 'tcp', Blocking => 0 );

	# nonblocking connect of tcp socket
	while (1) {
	    connect($to_server,$ssock ) && last;
	    if ( $!{EINPROGRESS} ) {
		diag( 'connect in progress' );
		IO::Select->new( $to_server )->can_write(30) && next;
		print "not ";
		last;
	    } elsif ( $!{EWOULDBLOCK} || $!{EAGAIN} ) {
		diag( 'connect not yet completed');
		# just wait
		select(undef,undef,undef,0.1);
		next;
	    } elsif ( $!{EISCONN} ) {
		diag('claims that socket is already connected');
		# found on Mac OS X, dunno why it does not tell me that
		# the connect succeeded before
		last;
	    }
	    diag( 'connect failed: '.$! );
	    print "not ";
	    last;
	}
	ok( "client tcp connect" );

	# work around (older?) systems where IO::Socket::INET
	# cannot do non-blocking connect by forcing non-blocking
	# again (we want to test non-blocking behavior of IO::Socket::SSL,
	# not IO::Socket::INET)
	$to_server->blocking(0);

	# send some plain text on non-ssl socket
	my $pmsg = 'plaintext';
	while ( $pmsg ne '' ) {
	    my $w = syswrite( $to_server,$pmsg );
	    if ( ! defined $w ) {
		if ( ! $!{EWOULDBLOCK} && ! $!{EAGAIN} ) {
		    diag("syswrite failed with $!");
		    print "not ";
		    last;
		}
		IO::Select->new($to_server)->can_write(30) or do {
		    diag("failed to get write ready");
		    print "not ";
		    last;
		};
	    } elsif ( $w>0 ) {
		diag("wrote $w bytes");
		substr($pmsg,0,$w,'');
	    } else {
		die "syswrite returned 0";
	    }
	}
	ok( "write plain text" );

	# let server catch up, so that it awaits my connection
	# so that connect_SSL does not have to wait
	sleep(5) if ( $test eq 'slow' );

	# upgrade to SSL socket w/o connection yet
	if ( ! IO::Socket::SSL->start_SSL( $to_server,
	    SSL_startHandshake => 0,
	    SSL_verify_mode => 0,
	    SSL_key_file => "t/certs/server-key.enc",
	    SSL_passwd_cb => sub { return "bluebell" },
	)) {
	    diag( 'start_SSL return undef' );
	    print "not ";
	} elsif ( !UNIVERSAL::isa( $to_server,'IO::Socket::SSL' ) ) {
	    diag( 'failed to upgrade socket' );
	    print "not ";
	}
	ok( "upgrade client to IO::Socket::SSL" );

	# SSL handshake thru connect_SSL
	# if $test eq 'fast' we expect one failed attempt because server
	# did not call accept_SSL yet
	my $attempts = 0;
	while ( 1 ) {
	    $to_server->connect_SSL && last;
	    diag( $SSL_ERROR );
	    if ( $SSL_ERROR == SSL_WANT_READ ) {
		$attempts++;
		IO::Select->new($to_server)->can_read(30) && next; # retry if can read
	    } elsif ( $SSL_ERROR == SSL_WANT_WRITE ) {
		IO::Select->new($to_server)->can_write(30) && next; # retry if can write
	    }
	    diag( "failed to connect: $@" );
	    print "not ";
	    last;
	}
	ok( "connected" );

	if ( $test ne 'slow' ) {
	    print "not " if !$attempts;
	    ok( "nonblocking connect with $attempts attempts" );
	}

	# send some data
	# we send up to 500000 bytes, server reads first 10 bytes and then sleeps
	# before reading more. In total server only reads 30000 bytes
	# the sleep will cause the internal buffers to fill up so that the syswrite
	# should return with EWOULDBLOCK+SSL_WANT_WRITE.
	# the socket close should cause EPIPE or ECONNRESET

	my $msg = "1234567890";
	$attempts = 0;
	my $bytes_send = 0;

	# set send buffer to 8192 so it will definitely fail writing all 500000 bytes in it
	# beware that linux allocates twice as much (see tcp(7))
	# AIX seems to get very slow if you set the sndbuf on localhost, so don't to it
	# https://rt.cpan.org/Public/Bug/Display.html?id=72305
	if ( $^O !~m/aix/i ) {
	    eval q{
		setsockopt( $to_server, SOL_SOCKET, SO_SNDBUF, pack( "I",8192 ));
		diag( "sndbuf=".unpack( "I",getsockopt( $to_server, SOL_SOCKET, SO_SNDBUF )));
	    };
	}

	# This test is too much dependant on OS
	my $test_might_fail = 1;

	my $can;
	WRITE:
	for( my $i=0;$i<50000;$i++ ) {
	    my $offset = 0;
	    my $sel_server = IO::Select->new($to_server);
	    while (1) {
		if ($can && !$sel_server->$can(15)) {
		    if ( $bytes_send > 30000 ) {
			diag("fail $can, but limit reached. Assume connection closed");
		    } else {
			diag("fail $can");
			print "not ";
		    }
		    last WRITE;
		}

		my $n = syswrite( $to_server,$msg,length($msg)-$offset,$offset );
		if ( !defined($n) ) {
		    diag( "\$!=$! \$SSL_ERROR=$SSL_ERROR send=$bytes_send" );
		    if ( $! == EWOULDBLOCK || $! == EAGAIN ) {
			if ( $SSL_ERROR == SSL_WANT_WRITE ) {
			    diag( 'wait for write' );
			    $can = 'can_write';
			    $attempts++;
			} elsif ( $SSL_ERROR == SSL_WANT_READ ) {
			    diag( 'wait for read' );
			    $can = 'can_read';
			} else {
			    $can = 'can_write';
			}
		    } elsif ( $bytes_send > 30000 ) {
			diag( "connection closed" );
			last WRITE;
		    }
		    next;
		} elsif ( $n == 0 ) {
		    diag( "connection closed" );
		    last WRITE;
		} elsif ( $n<0 ) {
		    diag( "syswrite returned $n!" );
		    print "not ";
		    last WRITE;
		}

		$bytes_send += $n;
		if ( $n + $offset == 10 ) {
		    last
		} else {
		    $offset += $n;
		    diag( "partial write of $n new offset=$offset" );
		}
	    }
	}
	ok( "syswrite" );

	if ( ! $attempts && $test_might_fail ) {
	    ok( "write attempts failed, but OK nevertheless because we know it can fail" );
	} else {
	    print "not " if !$attempts;
	    ok( "multiple write attempts" );
	}

	print "not " if $bytes_send < 30000;
	ok( "30000 bytes send" );
    }

} else {

    ############################################################
    # SERVER == parent process
    ############################################################

    # pendant to tests in client. Where client is slow (sleep
    # between plain text sending and connect_SSL) I need to
    # be fast and where client is fast I need to be slow (sleep
    # between receiving plain text and accept_SSL)

    foreach my $test ( 'slow','fast' ) {

	# accept a connection
	my $can_read = IO::Select->new( $server )->can_read(30);
	diag("tcp server socket is ".($can_read? "ready" : "NOT ready"));
	my $from_client = $server->accept or print "not ";
	ok( "tcp accept" );
	$from_client || do {
	    diag( "failed to tcp accept: $!" );
	    next;
	};

	# make client non-blocking!
	$from_client->blocking(0);

	# read plain text data
	my $buf = '';
	while ( length($buf) <9 ) {
	    sysread( $from_client, $buf,9-length($buf),length($buf) ) && next;
	    die "sysread failed: $!" if $! != EWOULDBLOCK && $! != EAGAIN;
	    IO::Select->new( $from_client )->can_read(30);
	}
	$buf eq 'plaintext' || print "not ";
	ok( "received plain text" );

	# upgrade socket to IO::Socket::SSL
	# no handshake yet
	if ( ! IO::Socket::SSL->start_SSL( $from_client,
	    SSL_startHandshake => 0,
	    SSL_server => 1,
	    SSL_verify_mode => 0x00,
	    SSL_ca_file => "t/certs/test-ca.pem",
	    SSL_use_cert => 1,
	    SSL_cert_file => "t/certs/client-cert.pem",
	    SSL_key_file => "t/certs/client-key.enc",
	    SSL_passwd_cb => sub { return "opossum" },
	)) {
	    diag( 'start_SSL return undef' );
	    print "not ";
	} elsif ( !UNIVERSAL::isa( $from_client,'IO::Socket::SSL' ) ) {
	    diag( 'failed to upgrade socket' );
	    print "not ";
	}
	ok( "upgrade to_client to IO::Socket::SSL" );

	sleep(5) if $test eq 'slow'; # wait until client calls connect_SSL

	# SSL handshake  thru accept_SSL
	# if test is 'fast' (e.g. client is 'slow') we expect the first
	# accept_SSL attempt to fail because client did not call connect_SSL yet
	my $attempts = 0;
	while ( 1 ) {
	    $from_client->accept_SSL && last;
	    if ( $SSL_ERROR == SSL_WANT_READ ) {
		$attempts++;
		IO::Select->new($from_client)->can_read(30) && next; # retry if can read
	    } elsif ( $SSL_ERROR == SSL_WANT_WRITE ) {
		$attempts++;
		IO::Select->new($from_client)->can_write(30) && next; # retry if can write
	    } else {
		diag( "failed to ssl accept ($test): $@" );
		print "not ";
		last;
	    }
	}
	ok( "ssl accept handshake done" );

	if ( $test eq 'fast' ) {
	    print "not " if !$attempts;
	    ok( "nonblocking accept_SSL with $attempts attempts" );
	}

	# reading 10 bytes
	# then sleeping so that buffers from client to server gets
	# filled up and clients receives EWOULDBLOCK+SSL_WANT_WRITE

	IO::Select->new( $from_client )->can_read(30);
	( sysread( $from_client, $buf,10 ) == 10 ) || print "not ";
	#diag($buf);
	ok( "received client message" );

	sleep(5);
	my $bytes_received = 10;

	# read up to 30000 bytes from client, then close the socket
	my $can;
	READ:
	while ( ( my $diff = 30000 - $bytes_received ) > 0 ) {
	    if ( $can && ! IO::Select->new($from_client)->$can(30)) {
		diag("failed $can");
		print "not ";
		last READ;
	    }
	    my $n = sysread( $from_client,my $buf,$diff );
	    if ( !defined($n) ) {
		diag( "\$!=$! \$SSL_ERROR=$SSL_ERROR" );
		if ( $! == EWOULDBLOCK || $! == EAGAIN ) {
		    if ( $SSL_ERROR == SSL_WANT_READ ) {
			$attempts++;
			$can = 'can_read';
		    } elsif ( $SSL_ERROR == SSL_WANT_WRITE ) {
			$attempts++;
			$can = 'can_write';
		    } else {
			$can = 'can_read';
		    }
		} else {
		    print "not ";
		    last READ;
		}
		next;
	    } elsif ( $n == 0 ) {
		diag( "connection closed" );
		last READ;
	    } elsif ( $n<0 ) {
		diag( "sysread returned $n!" );
		print "not ";
		last READ;
	    }

	    $bytes_received += $n;
	    #diag( "read of $n bytes total $bytes_received" );
	}

	diag( "read $bytes_received ($attempts r/w attempts)" );
	close($from_client);
    }

    # wait until client exits
    wait;
}

exit;



sub ok   { unshift @_, "ok # "; goto &_out }
sub diag { unshift @_, "#    "; goto &_out }
sub _out {
    my $prefix = shift;
    printf "%s [%04d.%s:%03d] %s\n",
	$prefix,
	time() - $START,
	$ID,
	(caller())[2],
	"@_";
}
