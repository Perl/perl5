use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl is_libressl new_ctx tcp_socket
);

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} else {
    plan tests => 46;
}

initialise_libssl();

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

# Values that were previously looked up for get_keyblock_size test
# Revisit: currently the only known user for get_keyblock_size is
# EAP-FAST. How it works with AEAD ciphers is for future study.
our %non_aead_cipher_to_keyblock_size =
    (
     'RC4-MD5' => 64,
     'RC4-SHA' => 72,
     'AES256-SHA256' => 160,
     'AES128-SHA256' => 128,
     'AES128-SHA' => 104,
     'AES256-SHA' => 136,
    );

our %tls_1_2_aead_cipher_to_keyblock_size = (
     'AES128-GCM-SHA256' => 56,
     'AES256-GCM-SHA384' => 88,
    );

# LibreSSL uses different names for the TLSv1.3 ciphersuites:
our %tls_1_3_aead_cipher_to_keyblock_size =
      is_libressl()
    ? (
          'AEAD-AES128-GCM-SHA256'        => 56,
          'AEAD-AES256-GCM-SHA384'        => 88,
          'AEAD-CHACHA20-POLY1305-SHA256' => 88,
      )
    : (
         'TLS_AES_128_GCM_SHA256'       => 56,
         'TLS_AES_256_GCM_SHA384'       => 88,
         'TLS_CHACHA20_POLY1305_SHA256' => 88,
      );

# Combine the AEAD hashes
our %aead_cipher_to_keyblock_size = (%tls_1_2_aead_cipher_to_keyblock_size, %tls_1_3_aead_cipher_to_keyblock_size);

# Combine the hashes
our %cipher_to_keyblock_size = (%non_aead_cipher_to_keyblock_size, %aead_cipher_to_keyblock_size);

our %version_str2int = (
    'SSLv3'   => sub { return eval { Net::SSLeay::SSL3_VERSION(); } },
    'TLSv1'   => sub { return eval { Net::SSLeay::TLS1_VERSION(); } },
    'TLSv1.1' => sub { return eval { Net::SSLeay::TLS1_1_VERSION(); } },
    'TLSv1.2' => sub { return eval { Net::SSLeay::TLS1_2_VERSION(); } },
    'TLSv1.3' => sub { return eval { Net::SSLeay::TLS1_3_VERSION(); } },
);

# Tests that don't need a connection
client_test_ciphersuites();
test_cipher_funcs();

# Tests that need a connection
my $server = tcp_socket();

{
    # SSL server - just handle single connect, send information to
    # client and exit

    my $cert_pem = data_file_path('simple-cert.cert.pem');
    my $key_pem  = data_file_path('simple-cert.key.pem');

    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");
    if ($pid == 0) {
	my $cl = $server->accept();
	my $ctx = new_ctx();
	Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
#	my $get_keyblock_size_ciphers = join(':', keys(%cipher_to_keyblock_size));
	my $get_keyblock_size_ciphers = join(':', keys(%non_aead_cipher_to_keyblock_size));
	Net::SSLeay::CTX_set_cipher_list($ctx, $get_keyblock_size_ciphers);
	my $ssl = Net::SSLeay::new($ctx);

	Net::SSLeay::set_fd($ssl, fileno($cl));
	Net::SSLeay::accept($ssl);

	# Send our idea of Finished messages to the client.
	my ($f_len, $finished_s, $finished_c);

	$f_len = Net::SSLeay::get_finished($ssl, $finished_s);
	Net::SSLeay::write($ssl, "server: $f_len ". unpack('H*', $finished_s));

	$f_len = Net::SSLeay::get_peer_finished($ssl, $finished_c);
	Net::SSLeay::write($ssl, "client: $f_len ". unpack('H*', $finished_c));

	# Echo back the termination request from client
	my $end = Net::SSLeay::read($ssl);
	Net::SSLeay::write($ssl, $end);
	Net::SSLeay::shutdown($ssl);
	Net::SSLeay::free($ssl);
	close($cl) || die("server close: $!");
	$server->close() || die("server listen socket close: $!");
	exit(0);
    }
}

sub client {
    # SSL client - connect to server and receive information that we
    # compare to our expected values

    my ($f_len, $f_len_trunc, $finished_s, $finished_c, $msg, $expected);

    my $cl = $server->connect();
    my $ctx = new_ctx();
    Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
    my $ssl = Net::SSLeay::new($ctx);

    Net::SSLeay::set_fd($ssl, $cl);

    client_test_finished($ssl);
    client_test_keyblock_size($ssl);
    client_test_version_funcs($ssl);

    # Tell the server to quit and see that our connection is still up
    my $end = "end";
    Net::SSLeay::write($ssl, $end);
    ok($end eq Net::SSLeay::read($ssl),  'Successful termination');
    Net::SSLeay::shutdown($ssl);
    Net::SSLeay::free($ssl);
    close($cl) || die("client close: $!");
    $server->close() || die("client listen socket close: $!");
    return;
}

client();
waitpid $pid, 0;
exit(0);

# Test get_finished() and get_peer_finished() with server.
sub client_test_finished
{
    my ($ssl) = @_;
    my ($f_len, $f_len_trunc, $finished_s, $finished_c, $msg, $expected);

    # Finished messages have not been sent yet
    $f_len = Net::SSLeay::get_peer_finished($ssl, $finished_s);
    ok($f_len == 0, 'Return value for get_peer_finished is empty before connect for server');
    ok(defined $finished_s && $finished_s eq '', 'Server Finished is empty');

    $f_len = Net::SSLeay::get_finished($ssl, $finished_c);
    ok($f_len == 0, 'Finished is empty before connect for client');
    ok(defined $finished_c && $finished_c eq '', 'Client Finished is empty');

    # Complete connection. After this we have Finished messages from both peers.
    Net::SSLeay::connect($ssl);

    $f_len = Net::SSLeay::get_peer_finished($ssl, $finished_s);
    ok($f_len, 'Server Finished is not empty');
    ok($f_len == length($finished_s), 'Return value for get_peer_finished equals to Finished length');
    $expected = "server: $f_len " . unpack('H*', $finished_s);
    $msg = Net::SSLeay::read($ssl);
    ok($msg eq $expected, 'Server Finished is equal');

    $f_len = Net::SSLeay::get_finished($ssl, $finished_c);
    ok($f_len, 'Client Finished is not empty');
    ok($f_len == length($finished_c), 'Return value for get_finished equals to Finished length');
    $expected = "client: $f_len " . unpack('H*', $finished_c);
    $msg = Net::SSLeay::read($ssl);
    ok($msg eq $expected, 'Client Finished is equal');

    ok($finished_s ne $finished_c, 'Server and Client Finished are not equal');

    # Finished should still be the same. See that we can fetch truncated values.
    my $trunc8_s = substr($finished_s, 0, 8);
    $f_len_trunc = Net::SSLeay::get_peer_finished($ssl, $finished_s, 8);
    ok($f_len_trunc == $f_len, 'Return value for get_peer_finished is unchanged when count is set');
    ok($trunc8_s eq $finished_s, 'Count works for get_peer_finished');

    my $trunc8_c = substr($finished_c, 0, 8);
    $f_len_trunc = Net::SSLeay::get_finished($ssl, $finished_c, 8);
    ok($f_len_trunc == $f_len, 'Return value for get_finished is unchanged when count is set');
    ok($trunc8_c eq $finished_c, 'Count works for get_finished');

}

# Test get_keyblock_size
# Notes: With TLS 1.3 the cipher is always an AEAD cipher. If AEAD
# ciphers are enabled for TLS 1.2 and earlier, with LibreSSL
# get_keyblock_size returns -1 when AEAD cipher is chosen.
sub client_test_keyblock_size
{
    my ($ssl) = @_;

    my $cipher = Net::SSLeay::get_cipher($ssl);
    ok($cipher, "get_cipher returns a value: $cipher");

    my $keyblock_size = &Net::SSLeay::get_keyblock_size($ssl);
    ok(defined $keyblock_size, 'get_keyblock_size return value is defined');
    if ($keyblock_size == -1)
    {
	# Accept -1 with AEAD ciphers with LibreSSL
	ok(is_libressl(), 'get_keyblock_size returns -1 with LibreSSL');
	ok(defined $aead_cipher_to_keyblock_size{$cipher}, 'keyblock size is -1 for an AEAD cipher');
    }
    else
    {
	ok($keyblock_size >= 0, 'get_keyblock_size return value is not negative');
	ok($cipher_to_keyblock_size{$cipher} == $keyblock_size, "keyblock size $keyblock_size is the expected value $cipher_to_keyblock_size{$cipher}");
    }
}

# Test SSL_get_version and related functions
sub client_test_version_funcs
{
    my ($ssl) = @_;

    my $version_str = Net::SSLeay::get_version($ssl);
    my $version_const = $version_str2int{$version_str};
    my $version = Net::SSLeay::version($ssl);

    ok(defined $version_const, "Net::SSLeay::get_version return value $version_str is known");
    is(&$version_const, $version, "Net:SSLeay::version return value $version matches get_version string");

    if (defined &Net::SSLeay::client_version) {
	if ($version_str eq 'TLSv1.3') {
	    # Noticed that client_version and version are equal for all SSL/TLS versions except of TLSv1.3
	    # For more, see https://github.com/openssl/openssl/issues/7079
	    is(Net::SSLeay::client_version($ssl), &{$version_str2int{'TLSv1.2'}},
	       'Net::SSLeay::client_version TLSv1.2 is expected when Net::SSLeay::version indicates TLSv1.3');
	} else {
	    is(Net::SSLeay::client_version($ssl), $version, 'Net::SSLeay::client_version equals to Net::SSLeay::version');
	}
	is(Net::SSLeay::is_dtls($ssl), 0, 'Net::SSLeay::is_dtls returns 0');
    } else
    {
      SKIP: {
	  skip('Do not have Net::SSLeay::client_version nor Net::SSLeay::is_dtls', 2);
	};
    }

    return;
}

sub client_test_ciphersuites
{
    unless (defined &Net::SSLeay::CTX_set_ciphersuites)
    {
      SKIP: {
	  skip('Do not have Net::SSLeay::CTX_set_ciphersuites', 10);
	}
	return;
    }

    my $ciphersuites = join(':', keys(%tls_1_3_aead_cipher_to_keyblock_size));

    # In OpenSSL 3.0.0 alpha 11 (commit c1e8a0c66e32b4144fdeb49bd5ff7acb76df72b9)
    # SSL_CTX_set_ciphersuites() and SSL_set_ciphersuites() were
    # changed to ignore unknown ciphers
    my $ret_partially_bad_ciphersuites = 1;
    if (Net::SSLeay::SSLeay() == 0x30000000) {
	my $ssleay_version = Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_VERSION());
	$ret_partially_bad_ciphersuites = 0 if ($ssleay_version =~ m/-alpha(\d+)/s) && $1 < 11;
    } elsif (Net::SSLeay::SSLeay() < 0x30000000) {
	$ret_partially_bad_ciphersuites = 0;
    }

    my ($ctx, $rv, $ssl);
    $ctx = new_ctx();
    $rv = Net::SSLeay::CTX_set_ciphersuites($ctx, $ciphersuites);
    is($rv, 1, 'CTX set good ciphersuites');
    $rv = Net::SSLeay::CTX_set_ciphersuites($ctx, '');
    is($rv, 1, 'CTX set empty ciphersuites');
    {
	no warnings 'uninitialized';
	$rv = Net::SSLeay::CTX_set_ciphersuites($ctx, undef);
    };
    is($rv, 1, 'CTX set undef ciphersuites');
    $rv = Net::SSLeay::CTX_set_ciphersuites($ctx, 'nosuchthing:' . $ciphersuites);
    is($rv, $ret_partially_bad_ciphersuites, 'CTX set partially bad ciphersuites');
    $rv = Net::SSLeay::CTX_set_ciphersuites($ctx, 'nosuchthing:');
    is($rv, 0, 'CTX set bad ciphersuites');

    $ssl = Net::SSLeay::new($ctx);
    $rv = Net::SSLeay::set_ciphersuites($ssl, $ciphersuites);
    is($rv, 1, 'SSL set good ciphersuites');
    $rv = Net::SSLeay::set_ciphersuites($ssl, '');
    is($rv, 1, 'SSL set empty ciphersuites');
    {
	no warnings 'uninitialized';
	$rv = Net::SSLeay::set_ciphersuites($ssl, undef);
    };
    is($rv, 1, 'SSL set undef ciphersuites');
    $rv = Net::SSLeay::set_ciphersuites($ssl, 'nosuchthing:' . $ciphersuites);
    is($rv, $ret_partially_bad_ciphersuites, 'SSL set partially bad ciphersuites');
    $rv = Net::SSLeay::set_ciphersuites($ssl, 'nosuchthing:');
    is($rv, 0, 'SSL set bad ciphersuites');

    return;
}

sub test_cipher_funcs
{

    my ($ctx, $rv, $ssl);
    $ctx = new_ctx();
    $ssl = Net::SSLeay::new($ctx);

    # OpenSSL API says these can accept NULL ssl
    {
	no warnings 'uninitialized';
	my @a = Net::SSLeay::get_ciphers(undef);
	is(@a, 0, 'SSL_get_ciphers with undefined ssl');

	is(Net::SSLeay::get_cipher_list(undef, 0), undef, 'SSL_get_cipher_list with undefined ssl');
	is(Net::SSLeay::CIPHER_get_name(undef), '(NONE)', 'SSL_CIPHER_get_name with undefined ssl');
	is(Net::SSLeay::CIPHER_get_bits(undef), 0, 'SSL_CIPHER_get_bits with undefined ssl');
	is(Net::SSLeay::CIPHER_get_version(undef), '(NONE)', 'SSL_CIPHER_get_version with undefined ssl');
    }

    # 10 is based on experimentation. Lowest count seen was 15 in
    # OpenSSL 0.9.8zh.
    my @ciphers = Net::SSLeay::get_ciphers($ssl);
    cmp_ok(@ciphers, '>=', 10, 'SSL_get_ciphers: number of ciphers: ' . @ciphers);

    my $first;
    my ($name_failed, $desc_failed, $vers_failed, $bits_failed, $alg_bits_failed) = (0, 0, 0, 0, 0);
    foreach my $c (@ciphers)
    {
	# Shortest seen: RC4-MD5
	my $name = Net::SSLeay::CIPHER_get_name($c);
	$name_failed++ if $name !~ m/^[A-Z0-9_-]{7,}\z/s;
	$first = $name unless $first;

	# Cipher description should begin with its name
	my $desc = Net::SSLeay::CIPHER_description($c);
	$desc_failed++ if $desc !~ m/^$name\s+/s;

	# For example: TLSv1/SSLv3, SSLv2
	my $vers = Net::SSLeay::CIPHER_get_version($c);
	$vers_failed++ if length($vers) < 5;

	# See that get_bits returns the same no matter how it's called
	my $alg_bits;
	my $bits = Net::SSLeay::CIPHER_get_bits($c, $alg_bits);
	$bits_failed++ if $bits ne Net::SSLeay::CIPHER_get_bits($c);

	# Once again, a value that should be reasonable
	$alg_bits_failed++ if $alg_bits < 56;
    }

    is($name_failed, 0, 'CIPHER_get_name');
    is($desc_failed, 0, 'CIPHER_description matches with CIPHER_name');
    is($vers_failed, 0, 'CIPHER_get_version');
    is($bits_failed, 0, 'CIPHER_get_bits');
    is($alg_bits_failed, 0, 'CIPHER_get_bits with alg_bits');
    is($first, Net::SSLeay::get_cipher_list($ssl, 0), 'SSL_get_cipher_list');

    Net::SSLeay::free($ssl);
    Net::SSLeay::CTX_free($ctx);

    return;
}
