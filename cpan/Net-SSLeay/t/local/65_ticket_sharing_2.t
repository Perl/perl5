use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl new_ctx );

use English qw( $EVAL_ERROR -no_match_vars );

if ( !defined &Net::SSLeay::set_session_ticket_ext_cb ) {
    plan skip_all => "no support for session_ticket_ext_cb";
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
    plan tests => 4;
}

initialise_libssl();

# for debugging only
my $DEBUG = 0;
my $PCAP = 0;
require Net::PcapWriter if $PCAP;

my $SSL_ERROR; # set in _minSSL
my %TRANSFER;  # set in _handshake

my $SESSION_TICKET = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\xff";
my $SESSION_TICKET_CB_DATA = "dada";
my $set_session_ticket_ext_cb_run = 0;

my $client = _minSSL->new();
my $server = _minSSL->new( cert => [
    data_file_path('simple-cert.cert.pem'),
    data_file_path('simple-cert.key.pem'),
]);


# now attach the ticket callback to server
# ----------------------------------------------
my $ticketcb = sub {
    my ($ssl, $ticket, $data) = @_;

    is(unpack('H*', $data), unpack('H*', $SESSION_TICKET_CB_DATA), 'server set callback data with set_session_ticket_ext_cb');
    is(unpack('H*', $ticket), unpack('H*', $SESSION_TICKET), 'client set session ticket with set_session_ticket_ext');

    $set_session_ticket_ext_cb_run = 1;
    return 1;
};
my $set_ticket_cb = sub {
    Net::SSLeay::set_session_ticket_ext_cb($server->_ssl, $ticketcb, $SESSION_TICKET_CB_DATA);
    Net::SSLeay::set_session_ticket_ext($client->_ssl, $SESSION_TICKET);
};
is( _handshake($client,$server,$set_ticket_cb),'full',"full handshake with a ticket");
ok($set_session_ticket_ext_cb_run == 1, 'server run a callback set with set_session_ticket_ext_cb');

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
	my $ctx = new_ctx( undef, 'TLSv1.2' );
	Net::SSLeay::CTX_set_options($ctx,Net::SSLeay::OP_ALL());
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
