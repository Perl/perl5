use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl new_ctx );

use English qw( $EVAL_ERROR -no_match_vars );

if ( !defined &Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb ) {
    plan skip_all => "no support for tlsext_ticket_key_cb";
}
elsif ( !eval { Net::SSLeay::CTX_free( new_ctx( undef, 'TLSv1.2' ) ); 1 } ) {
    my $err = $EVAL_ERROR;
    # This test only reflects the session protocol found in TLSv1.2 and below:
    # https://wiki.openssl.org/index.php/TLS1.3#Sessions
    # TODO(GH-224): write an equivalent test for TLSv1.3
    if ( $err =~ /no usable protocol versions/ ) {
        plan skip_all => 'TLSv1.2 or below not available in this libssl';
    }
    else {
        die $err;
    }
}
else {
    plan tests => 15;
}

initialise_libssl();

# for debugging only
my $DEBUG = 0;
my $PCAP = 0;
require Net::PcapWriter if $PCAP;

my $SSL_ERROR; # set in _minSSL
my %TRANSFER;  # set in _handshake

my $client = _minSSL->new();
my $server = _minSSL->new( cert => [
    data_file_path('simple-cert.cert.pem'),
    data_file_path('simple-cert.key.pem'),
]);


# initial tests without reuse
# ----------------------------------------------
is( _handshake($client,$server), 'full', "initial handshake is full");
is( _handshake($client,$server), 'full', "another full handshake");

# explicitly reuse session in client to check that server accepts it
# ----------------------------------------------

my ($save_session,$reuse);
if (0) {
    # simple version - get via get1_session and apply via set_session
    my $saved;
    $save_session = sub { $saved = Net::SSLeay::get1_session($client->_ssl) };
    $reuse = sub { Net::SSLeay::set_session($client->_ssl, $saved) };
} else {
    # don't store the session directly but only a serialized version
    my $saved;
    $save_session = sub {
	$saved = Net::SSLeay::i2d_SSL_SESSION(
	    Net::SSLeay::get_session($client->_ssl));
    };
    $reuse = sub {
	Net::SSLeay::set_session($client->_ssl,
	    Net::SSLeay::d2i_SSL_SESSION($saved));
    };
}

&$save_session;
is( _handshake($client,$server,$reuse),'reuse',"handshake with reuse");
is( _handshake($client,$server,$reuse),'reuse',"handshake again with reuse");

# create another server and connect client with session from old server
# should not be reused
# ----------------------------------------------
my $server2 = _minSSL->new( cert => [
    data_file_path('simple-cert.cert.pem'),
    data_file_path('simple-cert.key.pem'),
]);
is( _handshake($client,$server2,$reuse),'full',"handshake with server2 is full");

# now attach the same ticket key callback to both servers
# ----------------------------------------------
Net::SSLeay::RAND_bytes(my $key,32);
my $key_name = pack("a16",'secret');
my $keycb = sub {
    my ($mykey,$name) = @_;
    return ($mykey,$key_name) if ! $name or $key_name eq $name;
    return; # unknown key
};
Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb($server->_ctx, $keycb,$key);
Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb($server2->_ctx,$keycb,$key);
is( _handshake($client,$server),'full',"initial full handshake with server1");

&$save_session;
is( _handshake($client,$server,$reuse), 'reuse',"reuse session with server1");
is( _handshake($client,$server2,$reuse),'reuse',"reuse session with server2");

# simulate rotation for $key: the callback returns now the right key, but
# has a different current_name. It is expected that the callback is called again
# for encryption with the new key and that a new session ticket gets sent to
# the client
# ----------------------------------------------
Net::SSLeay::RAND_bytes(my $newkey,32);
my $newkey_name = pack("a16",'newsecret');
my @keys = (
    [ $newkey_name, $newkey ], # current default key
    [ $key_name, $key ],       # already expired
);
my @was_called_with;
my %old_transfer = %TRANSFER;
Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb($server2->_ctx, sub {
    my (undef,$name) = @_;
    push @was_called_with,$name || '<undef>';
    return ($keys[0][1],$keys[0][0]) if ! $name;
    for(my $i = 0; $i<@keys; $i++) {
	return ($keys[$i][1],$keys[0][0]) if $name eq $keys[$i][0];
    }
    return;
});

my $expect_reuse = _handshake($client,$server2,$reuse);
if ($expect_reuse eq '> < > <') {
    # broken handshake seen with openssl 1.0.0 when a ticket was used where
    # the key is still known but expired. It will do
    # Encrypted Handshake Message, Change Cipher Spec, Encrypted Handshake Message
    # in the last packet from server to client
    is($expect_reuse,'> < > <',"(slightly broken) reuse session with old key with server2");
    ok( @was_called_with >= 2,'callback was called at least 2 times');
} else {
    is($expect_reuse,'reuse',"reuse session with old key with server2");
    is( 0+@was_called_with,2,'callback was called 2 times');
}

is( $was_called_with[0],$key_name, 'first with the old key name');
is( $was_called_with[1],"<undef>", 'then with undef to get the current key');
ok( $TRANSFER{client} == $old_transfer{client}, 'no more data from client to server');
ok( $TRANSFER{server} > $old_transfer{server}, 'but more data from server (new ticket)');

# finally try to reuse the session created with new key against server1
# this should result in a full handshake since server1 does not know newkey
# ----------------------------------------------
&$save_session;
is( _handshake($client,$server,$reuse),'full',"full handshake with new ticker on server1");



my $i;
sub _handshake {
    my ($client,$server,$after_init) = @_;
    $client->state_connect;
    $server->state_accept;
    &$after_init if $after_init;

    my $pcap = $PCAP && do {
	my $fname = 'test'.(++$i).'.pcap';
	open(my $fh,'>',$fname);
	diag("pcap in $fname");
	$fh->autoflush;
	Net::PcapWriter->new($fh)->tcp_conn('1.1.1.1',1000,'2.2.2.2',443);
    };

    my ($client_done,$server_done,@hs);
    %TRANSFER = ();
    for(my $tries = 0; $tries < 10 and !$client_done || !$server_done; $tries++ ) {
	$client_done ||= $client->handshake || 0;
	$server_done ||= $server->handshake  || 0;

	my $transfer = 0;
	if (defined(my $data = $client->bio_read())) {
	    $pcap && $pcap->write(0,$data);
	    $DEBUG && warn "client -> server: ".length($data)." bytes\n";
	    $server->bio_write($data);
	    push @hs,'>';
	    $TRANSFER{client} += length($data);
	    $transfer++;
	}
	if (defined(my $data = $server->bio_read())) {
	    $pcap && $pcap->write(1,$data);
	    $DEBUG && warn "server -> client: ".length($data)." bytes\n";
	    $client->bio_write($data);
	    # assume certificate was sent if length>700
	    push @hs, length($data) > 700 ? '<[C]':'<';
	    $TRANSFER{server} += length($data);
	    $transfer++;
	}
	if (!$transfer) {
	    # no more data to transfer - assume we are done
	    $client_done = $server_done = 1;
	}
    }

    return
	!$client_done || !$server_done ? 'failed' :
	"@hs" eq '> <[C] > <' ? 'full' :
	"@hs" eq '> < >'   ? 'reuse' :
	"@hs";
}


{
    package _minSSL;

    use Test::Net::SSLeay qw(new_ctx);

    sub new {
	my ($class,%args) = @_;
	my $ctx = new_ctx( 'TLSv1', 'TLSv1.2' );
	# Explicitly disable compression, otherwise the "no more data from client to
	# server" test may fail sometimes:
	Net::SSLeay::CTX_set_options( $ctx, Net::SSLeay::OP_ALL() | Net::SSLeay::OP_NO_COMPRESSION() );
	my $id = 'client';
	if ($args{cert}) {
	    my ($cert,$key) = @{ delete $args{cert} };
	    Net::SSLeay::set_cert_and_key($ctx, $cert, $key)
		|| die "failed to use cert file $cert,$key";
	    $id = 'server';
	}

	my $self = bless { id => $id, ctx => $ctx }, $class;
	return $self;
    }

    sub state_accept {
	my $self = shift;
	_reset($self);
	Net::SSLeay::set_accept_state($self->{ssl});
    }

    sub state_connect {
	my $self = shift;
	_reset($self);
	Net::SSLeay::set_connect_state($self->{ssl});
    }

    sub handshake {
	my $self = shift;
	my $rv = Net::SSLeay::do_handshake($self->{ssl});
	$rv = _error($self,$rv);
	return $rv;
    }

    sub ssl_read {
	my ($self) = @_;
	my ($data,$rv) = Net::SSLeay::read($self->{ssl});
	return _error($self,$rv || -1) if !$rv || $rv<0;
	return $data;
    }

    sub bio_write {
	my ($self,$data) = @_;
	defined $data and $data ne '' or return;
	Net::SSLeay::BIO_write($self->{rbio},$data);
    }

    sub ssl_write {
	my ($self,$data) = @_;
	my $rv = Net::SSLeay::write($self->{ssl},$data);
	return _error($self,$rv || -1) if !$rv || $rv<0;
	return $rv;
    }

    sub bio_read {
	my ($self) = @_;
	return Net::SSLeay::BIO_read($self->{wbio});
    }

    sub _ssl { shift->{ssl} }
    sub _ctx { shift->{ctx} }

    sub _reset {
	my $self = shift;
	my $ssl = Net::SSLeay::new($self->{ctx});
	my @bio = (
	    Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem()),
	    Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem()),
	);
	Net::SSLeay::set_bio($ssl,$bio[0],$bio[1]);
	$self->{ssl} = $ssl;
	$self->{rbio} = $bio[0];
	$self->{wbio} = $bio[1];
    }

    sub _error {
	my ($self,$rv) = @_;
	if ($rv>0) {
	    $SSL_ERROR = undef;
	    return $rv;
	}
	my $err = Net::SSLeay::get_error($self->{ssl},$rv);
	if ($err == Net::SSLeay::ERROR_WANT_READ()
	    || $err == Net::SSLeay::ERROR_WANT_WRITE()) {
	    $SSL_ERROR = $err;
	    $DEBUG && warn "[$self->{id}] rw:$err\n";
	    return;
	}
	$DEBUG && warn "[$self->{id}] ".Net::SSLeay::ERR_error_string($err)."\n";
	return;
    }

}
