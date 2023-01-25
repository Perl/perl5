# Various TLS exporter-related tests

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl is_protocol_usable new_ctx
    tcp_socket
);

use Storable;

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} elsif (!defined &Net::SSLeay::export_keying_material) {
    plan skip_all => "No export_keying_material()";
} else {
    plan tests => 36;
}

initialise_libssl();

my @rounds = qw( TLSv1 TLSv1.1 TLSv1.2 TLSv1.3 );

my %usable =
    map {
        $_ => is_protocol_usable($_)
    }
    @rounds;

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

my (%server_stats, %client_stats);

my ($server_ctx, $client_ctx, $server_ssl, $client_ssl);

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

	    Net::SSLeay::CTX_set_security_level($ctx, 0)
		if Net::SSLeay::SSLeay() >= 0x30000000 && ($round eq 'TLSv1' || $round eq 'TLSv1.1');
	    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
	    $ssl = Net::SSLeay::new($ctx);
	    Net::SSLeay::set_fd($ssl, fileno($cl));
	    Net::SSLeay::accept($ssl);

	    Net::SSLeay::write($ssl, $round);
	    my $msg = Net::SSLeay::read($ssl);

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
    for my $round (@rounds) {
        if ($usable{$round}) {
            my $cl = $server->connect();

            my $ctx = new_ctx( $round, $round );
	    Net::SSLeay::CTX_set_security_level($ctx, 0)
		if Net::SSLeay::SSLeay() >= 0x30000000 && ($round eq 'TLSv1' || $round eq 'TLSv1.1');
            my $ssl = Net::SSLeay::new($ctx);
            Net::SSLeay::set_fd( $ssl, $cl );
            my $ret = Net::SSLeay::connect($ssl);
            if ($ret <= 0) {
                diag("Protocol $round, connect() returns $ret, Error: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
            }

            my $msg = Net::SSLeay::read($ssl);

            test_export($ssl);

            Net::SSLeay::write( $ssl, $msg );

            Net::SSLeay::shutdown($ssl);
            Net::SSLeay::free($ssl);
            close($cl) || die("client close: $!");
        }
        else {
            SKIP: {
                skip( "$round not available in this libssl", 9 );
            }
        }
    }
    $server->close() || die("client listen socket close: $!");

    return 1;
}

sub test_export
{
    my ($ssl) = @_;

    my ($bytes1_0, $bytes1_1, $bytes1_2, $bytes1_3, $bytes2_0, $bytes2_2_64);

    my $tls_version = Net::SSLeay::get_version($ssl);

    $bytes1_0 = Net::SSLeay::export_keying_material($ssl, 64, 'label 1');
    $bytes1_1 = Net::SSLeay::export_keying_material($ssl, 64, 'label 1', undef);
    $bytes1_2 = Net::SSLeay::export_keying_material($ssl, 64, 'label 1', '');
    $bytes1_3 = Net::SSLeay::export_keying_material($ssl, 64, 'label 1', 'context');
    $bytes2_0 = Net::SSLeay::export_keying_material($ssl, 128, 'label 1', '');
    $bytes2_2_64 = substr($bytes2_0, 0, 64);

    is(length($bytes1_0), 64, "$tls_version: Got enough for bytes1_0");
    is(length($bytes1_1), 64, "$tls_version: Got enough for bytes1_1");
    is(length($bytes1_2), 64, "$tls_version: Got enough for bytes1_2");
    is(length($bytes1_3), 64, "$tls_version: Got enough for bytes1_3");
    is(length($bytes2_0), 128, "$tls_version: Got enough for bytes2_0");

    $bytes1_0 = unpack('H*', $bytes1_0);
    $bytes1_1 = unpack('H*', $bytes1_1);
    $bytes1_2 = unpack('H*', $bytes1_2);
    $bytes1_3 = unpack('H*', $bytes1_3);
    $bytes2_0 = unpack('H*', $bytes2_0);
    $bytes2_2_64 = unpack('H*', $bytes2_2_64);

    # Last argument should default to undef
    is($bytes1_0, $bytes1_1, "$tls_version: context default param is undef");

    # Empty and undefined context are the same for TLSv1.3.
    # Different length export changes the whole values for TLSv1.3.
    if ($tls_version eq 'TLSv1.3') {
	is($bytes1_0, $bytes1_2, "$tls_version: empty and undefined context yields equal values");
	isnt($bytes2_2_64, $bytes1_2, "$tls_version: export length does matter");
    } else {
	isnt($bytes1_0, $bytes1_2, "$tls_version: empty and undefined context yields different values");
	is($bytes2_2_64, $bytes1_2, "$tls_version: export length does not matter");
    }

    isnt($bytes1_3, $bytes1_0, "$tls_version: different context");

    return;
}

# For SSL_export_keying_material_early available with TLSv1.3
sub test_export_early
{

    return;
}

server();
client();
waitpid $pid, 0;
exit(0);
