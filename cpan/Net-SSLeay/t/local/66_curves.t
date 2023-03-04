use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

initialise_libssl();

my @set_list = (
    defined &Net::SSLeay::CTX_set1_groups_list ? (\&Net::SSLeay::CTX_set1_groups_list) : (),
    defined &Net::SSLeay::CTX_set1_curves_list ? (\&Net::SSLeay::CTX_set1_curves_list) : (),
);

if (!@set_list) {
    plan skip_all => "no support for CTX_set_curves_list";
} else {
    plan tests => 4 * @set_list;
}

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


my $set_curves;
while ($set_curves = shift @set_list) {
    ok(_handshake($client,$server,'P-521:P-384','P-521',1), 'first curve');
    ok(_handshake($client,$server,'P-521:P-384','P-384',1), 'second curve');
    ok(_handshake($client,$server,'P-521:P-384','P-256',0), 'wrong curve failed');
    ok(_handshake($client,$server,'P-521:P-384','P-384:P-521',1), 'both curve');
}


my $i;
sub _handshake {
    my ($client,$server,$server_curve,$client_curve,$expect_ok) = @_;
    $client->state_connect($client_curve);
    $server->state_accept($server_curve);

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

    my $result = "$client_done - $server_done - @hs";
    return $result eq '1 - 1 - > <[C] > <' if $expect_ok;
    return 1 if $result eq '1 - 1 - > <'; # failed connect with OpenSSL >= 1.1.0
    return 1 if $result =~ qr{^\Q0 - 0 - > < < <}; # OpenSSL 1.0.2, LibreSSL
    return 0; # unexpected result
}


{
    package _minSSL;

    use Test::Net::SSLeay qw(new_ctx);

    sub new {
	my ($class,%args) = @_;
	my $ctx = new_ctx();
	Net::SSLeay::CTX_set_options($ctx,Net::SSLeay::OP_ALL());
	Net::SSLeay::CTX_set_cipher_list($ctx,'ECDHE');
	Net::SSLeay::CTX_set_ecdh_auto($ctx,1)
	    if defined &Net::SSLeay::CTX_set_ecdh_auto;
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
	my ($self,$curve) = @_;
	_reset($self,$curve);
	Net::SSLeay::set_accept_state($self->{ssl});
    }

    sub state_connect {
	my ($self,$curve) = @_;
	_reset($self,$curve);
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
	my ($self,$curve) = @_;
	$set_curves->($self->{ctx},$curve) if $curve;
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
