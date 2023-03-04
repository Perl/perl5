# Tests for logging TLS key material

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl is_protocol_usable new_ctx
    tcp_socket
);

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} elsif (!defined &Net::SSLeay::CTX_set_keylog_callback) {
    plan skip_all => "No CTX_set_keylog_callback()";
} else {
    plan tests => 11;
}

initialise_libssl();

# TLSv1.3 keylog is different from previous TLS versions. We expect
# that both types can be tested
my @rounds = qw( TLSv1.2 TLSv1.3 );
my %keylog = (
    'TLSv1.2' => {},
    'TLSv1.3' => {},
    );

# %keylog ends up looking like this if everything goes as planned
# See below for more information about the keys and the values.
# $VAR1 = {
#   'TLSv1.2' => {
#                  'CLIENT_RANDOM' => '54f8fdb2... 2232f0ab...'
#                 },
#   'TLSv1.3' => {
#                  'CLIENT_HANDSHAKE_TRAFFIC_SECRET' => '0d862c40... d85e3d34...',
#                  'CLIENT_TRAFFIC_SECRET_0'         => '0d862c40... 5c211de7...',
#                  'EXPORTER_SECRET'                 => '0d862c40... 332b80bb...',
#                  'SERVER_HANDSHAKE_TRAFFIC_SECRET' => '0d862c40... 93a9c58e...',
#                  'SERVER_TRAFFIC_SECRET_0'         => '0d862c40... 34b7afff...'
#                 }
#         };

# This will trigger diagnostics if the desired TLS versions are not
# available.
my %usable =
    map {
        $_ => is_protocol_usable($_)
    }
    @rounds;

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

my $server = tcp_socket();

sub server
{
    # SSL server - just handle connections, write, wait for read and repeat
    my $cert_pem = data_file_path('simple-cert.cert.pem');
    my $key_pem  = data_file_path('simple-cert.key.pem');

    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");
    if ($pid == 0) {
	my ($ctx, $ssl, $ret, $cl);

	foreach my $round (@rounds)
	{
	    next unless $usable{$round};

	    $cl = $server->accept();

	    $ctx = new_ctx( $round, $round );
	    Net::SSLeay::CTX_set_keylog_callback($ctx, \&keylog_cb);
	    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
	    $ssl = Net::SSLeay::new($ctx);
	    Net::SSLeay::set_fd($ssl, fileno($cl));
	    Net::SSLeay::accept($ssl);

	    # Keylog data has been collected at this point. Doing some
	    # reads and writes allows us to see our connection works.
	    my $ssl_version = Net::SSLeay::read($ssl);
	    Net::SSLeay::write($ssl, $ssl_version);
	    my $keys = $keylog{$ssl_version};
	    foreach my $label (keys %{$keylog{$round}})
	    {
		Net::SSLeay::write($ssl, $label);
		Net::SSLeay::write($ssl, $keylog{$ssl_version}->{$label});
	    }
	    Net::SSLeay::shutdown($ssl);
	    Net::SSLeay::free($ssl);
	    close($cl) || die("server close: $!");
	}
	$server->close() || die("server listen socket close: $!");

	exit(0);
    }
}

# SSL client - connect to server, read, test and repeat
sub client {

    # For storing keylog information the server sends
    my %server_keylog;

    for my $round (@rounds) {
        if ($usable{$round}) {
            my $cl = $server->connect();

            my $ctx = new_ctx( $round, $round );
	    Net::SSLeay::CTX_set_keylog_callback($ctx, \&keylog_cb);
            my $ssl = Net::SSLeay::new($ctx);
            Net::SSLeay::set_fd( $ssl, $cl );
            my $ret = Net::SSLeay::connect($ssl);
            if ($ret <= 0) {
                diag("Protocol $round, connect() returns $ret, Error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
            }

	    # Pull server's keylog for this TLS version.
            Net::SSLeay::write($ssl, $round);
            my $ssl_version = Net::SSLeay::read($ssl);
	    my %keys;
	    while (my $label = Net::SSLeay::read($ssl))
	    {
		$keys{$label} = Net::SSLeay::read($ssl);
	    }
	    $server_keylog{$round} = \%keys;

            Net::SSLeay::shutdown($ssl);
            Net::SSLeay::free($ssl);
            close($cl) || die("client close: $!");
        }
        else {
	    diag("$round not available in this libssl but required by test");
        }
    }
    $server->close() || die("client listen socket close: $!");

    # Server and connections are gone but the client has all the data
    # it needs for the tests

    # Start with set/get test
    {
	my $ctx = new_ctx();
	my $cb = Net::SSLeay::CTX_get_keylog_callback($ctx);
	is($cb, undef, 'Keylog callback is initially undefined');

	Net::SSLeay::CTX_set_keylog_callback($ctx, \&keylog_cb);
	$cb = Net::SSLeay::CTX_get_keylog_callback($ctx);
	is($cb, \&keylog_cb, 'CTX_get_keylog_callback');

	Net::SSLeay::CTX_set_keylog_callback($ctx, undef);
	$cb = Net::SSLeay::CTX_get_keylog_callback($ctx);
	is($cb, undef, 'Keylog callback successfully unset');
    }

    # Make it clear we have separate keylog hashes. The also align
    # nicely below.  The compare server and client keylogs.
    my %client_keylog = %keylog;
    foreach my $round (@rounds)
    {
	ok(exists $server_keylog{$round}, "Server keylog for $round exists");
	ok(exists $client_keylog{$round}, "Client keylog for $round exists");

	my $s_kl = delete $server_keylog{$round};
	my $c_kl = delete $client_keylog{$round};
	is_deeply($s_kl, $c_kl, "Client and Server have equal keylog for $round");
    }
    is_deeply(\%server_keylog, {}, 'Server keylog has no unexpected entries');
    is_deeply(\%client_keylog, {}, 'Client keylog has no unexpected entries');

    return 1;
}


# The keylog file format is specified by Mozilla:
# https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format
# Quote:
#    This key log file is a series of lines. Comment lines begin with
#    a sharp character ('#') and are ignored. Secrets follow the
#    format <Label> <space> <ClientRandom> <space> <Secret>
#
# OpenSSL keylog callback is called separately for each secret. That
# is, $line starts with <Label> and ends with <Secret> without
# trailing newline.
sub keylog_cb
{
    my ($ssl, $line) = @_;

    my $tls_version = Net::SSLeay::get_version($ssl);
    my ($label, $rand_secret) = split(m/ /s, $line, 2);

    BAIL_OUT("Could not parse line '$line' in keylog callback")
	unless (length($label) && length($rand_secret));
    BAIL_OUT('Could not get expected version from ssl in keylog callback')
	unless exists $keylog{$tls_version};

    $keylog{$tls_version}->{$label} = $rand_secret;

    return;
}

server();
client();
waitpid $pid, 0;

exit(0);
