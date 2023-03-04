# Test session-related functions

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl is_protocol_usable new_ctx
    tcp_socket
);

use Storable;

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} else {
    plan tests => 58;
}

initialise_libssl();

my @rounds = qw(
    TLSv1 TLSv1.1 TLSv1.2 TLSv1.3 TLSv1.3-num-tickets-ssl
    TLSv1.3-num-tickets-ctx-6 TLSv1.3-num-tickets-ctx-0
);

my %usable =
    map {
        ( my $proto = $_ ) =~ s/-.*$//;

        $_ => is_protocol_usable($proto)
    }
    @rounds;

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

my (%server_stats, %client_stats);

# Update client and server stats so that when something fails, it
# remains in failed state
sub set_client_stat
{
    my ($round, $param, $is_ok) = @_;

    if ($is_ok) {
	$client_stats{$round}->{$param} = 1 unless defined $client_stats{$round}->{$param};
	return;
    }
    $client_stats{$round}->{$param} = 0;
}

sub set_server_stat
{
    my ($round, $param, $is_ok) = @_;

    if ($is_ok) {
	$server_stats{$round}->{$param} = 1 unless defined $server_stats{$round}->{$param};
	return;
    }
    $server_stats{$round}->{$param} = 0;
}

# Separate session callbacks for client and server. The callbacks
# update stats and check that SSL_CTX, SSL and SESSION are as
# expected.
sub client_new_cb
{
    my ($ssl, $ssl_session, $expected_ctx, $round) = @_;

    $client_stats{$round}->{new_cb_called}++;

    my $ctx = Net::SSLeay::get_SSL_CTX($ssl);
    my $ssl_version = Net::SSLeay::get_version($ssl);
    my $is_ok = ($ctx eq $expected_ctx &&
		 $ssl_session eq Net::SSLeay::SSL_get0_session($ssl) &&
		 $round =~ m/^$ssl_version/);
    diag("client_new_cb params not ok: $round") unless $is_ok;
    set_client_stat($round, 'new_params_ok', $is_ok);

    if (defined &Net::SSLeay::SESSION_is_resumable) {
	my $is_resumable = Net::SSLeay::SESSION_is_resumable($ssl_session);
	BAIL_OUT("is_resumable is not 0 or 1: $round") unless defined $is_resumable && ($is_resumable == 0 || $is_resumable == 1);
	set_client_stat($round, 'new_session_is_resumable', $is_resumable);
    }

    #Net::SSLeay::SESSION_print_fp(*STDOUT, $ssl_session);
    return 0;
}

sub client_remove_cb
{
    my ($ctx, $ssl_session, $expected_ctx, $round) = @_;

    $client_stats{$round}->{remove_cb_called}++;

    my $is_ok = ($ctx eq $expected_ctx);
    diag("client_remove_cb params not ok: $round") unless $is_ok;
    set_client_stat($round, 'remove_params_ok', $is_ok);

    #Net::SSLeay::SESSION_print_fp(*STDOUT, $ssl_session);
    return;
}

sub server_new_cb
{
    my ($ssl, $ssl_session, $expected_ctx, $round) = @_;

    $server_stats{$round}->{new_cb_called}++;

    my $ctx = Net::SSLeay::get_SSL_CTX($ssl);
    my $ssl_version = Net::SSLeay::get_version($ssl);
    my $is_ok = ($ctx eq $expected_ctx &&
		 $ssl_session eq Net::SSLeay::SSL_get0_session($ssl) &&
		 $round =~ m/^$ssl_version/);
    diag("server_new_cb params not ok: $round") unless $is_ok;
    set_server_stat($round, 'new_params_ok', $is_ok);

    if (defined &Net::SSLeay::SESSION_is_resumable) {
	my $is_resumable = Net::SSLeay::SESSION_is_resumable($ssl_session);
	BAIL_OUT("is_resumable is not 0 or 1: $round") unless defined $is_resumable && ($is_resumable == 0 || $is_resumable == 1);
	set_server_stat($round, 'new_session_is_resumable', $is_resumable);
    }

    #Net::SSLeay::SESSION_print_fp(*STDOUT, $ssl_session);
    return 0;
}

sub server_remove_cb
{
    my ($ctx, $ssl_session, $expected_ctx, $round) = @_;

    $server_stats{$round}->{remove_cb_called}++;

    my $is_ok = ($ctx eq $expected_ctx);
    diag("server_remove_cb params not ok: $round") unless $is_ok;
    set_server_stat($round, 'remove_params_ok', $is_ok);

    return;
}

my ($server_ctx, $client_ctx, $server_ssl, $client_ssl);

my $server = tcp_socket();

sub server
{
    # SSL server - just handle connections, send information to
    # client and exit
    my $cert_pem = data_file_path('simple-cert.cert.pem');
    my $key_pem  = data_file_path('simple-cert.key.pem');

    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");
    if ($pid == 0) {
	my ($ctx, $ssl, $ret, $cl);

	foreach my $round (@rounds)
	{
	    ( my $proto = $round ) =~ s/-.*?$//;
	    next unless $usable{$proto};

	    $cl = $server->accept();

	    $ctx = new_ctx( $proto, $proto );

	    Net::SSLeay::CTX_set_security_level($ctx, 0)
		if Net::SSLeay::SSLeay() >= 0x30000000 && ($proto eq 'TLSv1' || $proto eq 'TLSv1.1');
	    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
	    Net::SSLeay::CTX_set_session_cache_mode($ctx, Net::SSLeay::SESS_CACHE_SERVER());
	    # Need OP_NO_TICKET to enable server side (Session ID based) resumption.
	    # See also SSL_CTX_set_options documenation about its use with TLSv1.3
	    if ( $round !~ /^TLSv1\.3/ ) {
		my $ctx_options = Net::SSLeay::OP_ALL();

		# OP_NO_TICKET requires OpenSSL 0.9.8f or above
		if ( eval { Net::SSLeay::OP_NO_TICKET(); 1; } ) {
		    $ctx_options |= Net::SSLeay::OP_NO_TICKET();
		}

		Net::SSLeay::CTX_set_options($ctx, $ctx_options);
	    }

	    Net::SSLeay::CTX_sess_set_new_cb($ctx, sub {server_new_cb(@_, $ctx, $round);});
	    Net::SSLeay::CTX_sess_set_remove_cb($ctx, sub {server_remove_cb(@_, $ctx, $round);});

	    # Test set_num_tickets separately for CTX and SSL
	    if (defined &Net::SSLeay::CTX_set_num_tickets)
	    {
		Net::SSLeay::CTX_set_num_tickets($ctx, 6) if ($round eq 'TLSv1.3-num-tickets-ctx-6');
		Net::SSLeay::CTX_set_num_tickets($ctx, 0) if ($round eq 'TLSv1.3-num-tickets-ctx-0');
		$server_stats{$round}->{get_num_tickets} = Net::SSLeay::CTX_get_num_tickets($ctx);
	    }

	    $ssl = Net::SSLeay::new($ctx);
	    if (defined &Net::SSLeay::set_num_tickets)
	    {
		Net::SSLeay::set_num_tickets($ssl, 4) if ($round eq 'TLSv1.3-num-tickets-ssl');
		$server_stats{$round}->{get_num_tickets} = Net::SSLeay::get_num_tickets($ssl);
	    }
	    Net::SSLeay::set_fd($ssl, fileno($cl));
	    Net::SSLeay::accept($ssl);

	    Net::SSLeay::write($ssl, "msg from server: $round");
	    Net::SSLeay::read($ssl);
	    Net::SSLeay::shutdown($ssl);
	    my $sess = Net::SSLeay::get1_session($ssl);
	    $ret = Net::SSLeay::CTX_remove_session($ctx, $sess);

	    if (defined &Net::SSLeay::SESSION_is_resumable) {
		my $is_resumable = Net::SSLeay::SESSION_is_resumable($sess);
		BAIL_OUT("is_resumable is not 0 or 1: $round") unless defined $is_resumable && ($is_resumable == 0 || $is_resumable == 1);
		set_server_stat($round, 'old_session_is_resumable', $is_resumable);
	    }

	    Net::SSLeay::SESSION_free($sess) unless $ret; # Not cached, undo get1
	    Net::SSLeay::free($ssl);
	    close($cl) || die("server close: $!");
	}

	$cl = $server->accept();

	print $cl "end\n";
	print $cl unpack( 'H*', Storable::freeze(\%server_stats) ), "\n";

	close($cl) || die("server close stats socket: $!");
	$server->close() || die("server listen socket close: $!");

	#use Data::Dumper; print "Server:\n" . Dumper(\%server_stats);
	exit(0);
    }
}

sub client {
    # SSL client - connect to server and receive information that we
    # compare to our expected values

    my ($ctx, $ssl, $ret, $cl);

    foreach my $round (@rounds)
    {
	( my $proto = $round ) =~ s/-.*?$//;
	next unless $usable{$proto};

	$cl = $server->connect();

	$ctx = new_ctx( $proto, $proto );

	Net::SSLeay::CTX_set_security_level($ctx, 0)
	    if Net::SSLeay::SSLeay() >= 0x30000000 && ($proto eq 'TLSv1' || $proto eq 'TLSv1.1');
	Net::SSLeay::CTX_set_session_cache_mode($ctx, Net::SSLeay::SESS_CACHE_CLIENT());
        Net::SSLeay::CTX_set_options($ctx, Net::SSLeay::OP_ALL());
	Net::SSLeay::CTX_sess_set_new_cb($ctx, sub {client_new_cb(@_, $ctx, $round);});
	Net::SSLeay::CTX_sess_set_remove_cb($ctx, sub {client_remove_cb(@_, $ctx, $round);});
	$ssl = Net::SSLeay::new($ctx);

	Net::SSLeay::set_fd($ssl, $cl);
	my $ret = Net::SSLeay::connect($ssl);
	if ($ret <= 0) {
	    diag("Protocol $proto, connect() returns $ret, Error: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
	}
	my $msg = Net::SSLeay::read($ssl);
	#print "server said: $msg\n";

	Net::SSLeay::write($ssl, "continue");
	my $sess = Net::SSLeay::get1_session($ssl);
	$ret = Net::SSLeay::CTX_remove_session($ctx, $sess);
	Net::SSLeay::SESSION_free($sess) unless $ret; # Not cached, undo get1

	if (defined &Net::SSLeay::SESSION_is_resumable) {
	    my $is_resumable = Net::SSLeay::SESSION_is_resumable($sess);
	    BAIL_OUT("is_resumable is not 0 or 1: $round") unless defined $is_resumable && ($is_resumable == 0 || $is_resumable == 1);
	    set_client_stat($round, 'old_session_is_resumable', $is_resumable);
	}

	Net::SSLeay::shutdown($ssl);
	Net::SSLeay::free($ssl);
	close($cl) || die("client close: $!");
    }

    $cl = $server->connect();
    chomp( my $server_end = <$cl> );
    is( $server_end, 'end', 'Successful termination' );

    # Stats from server
    chomp( my $server_stats = <$cl> );
    my $server_stats_ref = Storable::thaw( pack( 'H*', $server_stats ) );

    close($cl) || die("client close stats socket: $!");
    $server->close() || die("client listen socket close: $!");

    test_stats($server_stats_ref, \%client_stats);

    return;
}

sub test_stats {
    my ($srv_stats, $clt_stats) = @_;

    for my $round (@rounds) {
        # The TLSv1.3-specific results will be checked separately later
        next if $round =~ /-/;

        if (!$usable{$round}) {
            SKIP: {
                skip( "$round not available in this libssl", 12 );
            }
            next;
        }

        my $s = $srv_stats->{$round};
        my $c = $clt_stats->{$round};

        # With TLSv1.3, two session tickets are sent by default, so new_cb is
        # called twice; with all other protocol versions, new_cb is called once
        my $cbs = ( $round =~ /^TLSv1\.3/ ? 2 : 1 );

        is( $s->{new_cb_called},    $cbs, "Server $round new_cb call count" );
        is( $s->{new_params_ok},    1,    "Server $round new_cb params were correct" );
        is( $s->{remove_cb_called}, 1,    "Server $round remove_cb call count" );
        is( $s->{remove_params_ok}, 1,    "Server $round remove_cb params were correct" );

        is( $c->{new_cb_called},    $cbs, "Client $round new_cb call count" );
        is( $c->{new_params_ok},    1,    "Client $round new_cb params were correct" );
        is( $c->{remove_cb_called}, 1,    "Client $round remove_cb call count" );
        is( $c->{remove_params_ok}, 1,    "Client $round remove_cb params were correct" );

        if (
               defined &Net::SSLeay::SESSION_is_resumable
            || $round =~ /^TLSv1\.3/
        ) {
            is( $s->{new_session_is_resumable}, 1, "Server $round session is resumable" );
            is( $s->{old_session_is_resumable}, 0, "Server $round session is no longer resumable" );

            is( $c->{new_session_is_resumable}, 1, "Client $round session is resumable" );
            is( $c->{old_session_is_resumable}, 0, "Client $round session is no longer resumable" );
        } else {
            SKIP: {
                skip( 'Do not have Net::SSLeay::SESSION_is_resumable', 4 );
            }
        }
    }

    if ($usable{'TLSv1.3'}) {
        is( $srv_stats->{'TLSv1.3-num-tickets-ssl'}->{get_num_tickets}, 4, 'Server TLSv1.3 get_num_tickets 4' );
        is( $srv_stats->{'TLSv1.3-num-tickets-ssl'}->{new_cb_called},   4, 'Server TLSv1.3 new_cb call count with set_num_tickets 4' );
        is( $clt_stats->{'TLSv1.3-num-tickets-ssl'}->{new_cb_called},   4, 'Client TLSv1.3 new_cb call count with set_num_tickets 4' );

        is( $srv_stats->{'TLSv1.3-num-tickets-ctx-6'}->{get_num_tickets}, 6, 'Server TLSv1.3 CTX_get_num_tickets 6' );
        is( $srv_stats->{'TLSv1.3-num-tickets-ctx-6'}->{new_cb_called},   6, 'Server TLSv1.3 new_cb call count with CTX_set_num_tickets 6' );
        is( $clt_stats->{'TLSv1.3-num-tickets-ctx-6'}->{new_cb_called},   6, 'Client TLSv1.3 new_cb call count with CTX_set_num_tickets 6' );

        is( $srv_stats->{'TLSv1.3-num-tickets-ctx-0'}->{get_num_tickets}, 0,     'Server TLSv1.3 CTX_get_num_tickets 0' );
        is( $srv_stats->{'TLSv1.3-num-tickets-ctx-0'}->{new_cb_called},   undef, 'Server TLSv1.3 new_cb call count with CTX_set_num_tickets 0' );
        is( $clt_stats->{'TLSv1.3-num-tickets-ctx-0'}->{new_cb_called},   undef, 'Client TLSv1.3 new_cb call count with CTX_set_num_tickets 0' );
    }
    else {
        SKIP: {
            skip( 'TLSv1.3 not available in this libssl', 9 );
        }
    }

    #  use Data::Dumper; print "Server:\n" . Dumper(\%srv_stats);
    #  use Data::Dumper; print "Client:\n" . Dumper(\%clt_stats);
}

server();
client();
waitpid $pid, 0;
exit(0);
