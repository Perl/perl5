# Test various verify and ASN functions

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl is_libressl is_openssl new_ctx
    tcp_socket
);

plan tests => 105;

initialise_libssl();

my $root_ca_pem   = data_file_path('root-ca.cert.pem');
my $ca_pem        = data_file_path('verify-ca.certchain.pem');
my $ca_dir        = '';
my $cert_pem      = data_file_path('verify-cert.cert.pem');
my $certchain_pem = data_file_path('verify-cert.certchain.pem');
my $key_pem       = data_file_path('verify-cert.key.pem');

# The above certificate must specify the following policy OID:
my $required_oid = '1.2.3.4.5';

my $pm;
my $pm2;
my $verify_result = -1;

SKIP: {
  skip 'openssl-0.9.8 required', 7 unless Net::SSLeay::SSLeay >= 0x0090800f;
  $pm = Net::SSLeay::X509_VERIFY_PARAM_new();
  ok($pm, 'X509_VERIFY_PARAM_new');
  $pm2 = Net::SSLeay::X509_VERIFY_PARAM_new();
  ok($pm2, 'X509_VERIFY_PARAM_new 2');
  ok(Net::SSLeay::X509_VERIFY_PARAM_inherit($pm2, $pm), 'X509_VERIFY_PARAM_inherit');
  ok(Net::SSLeay::X509_VERIFY_PARAM_set1($pm2, $pm), 'X509_VERIFY_PARAM_inherit');
  ok(Net::SSLeay::X509_VERIFY_PARAM_set1_name($pm, 'fred'), 'X509_VERIFY_PARAM_set1_name');
  ok(Net::SSLeay::X509_V_FLAG_ALLOW_PROXY_CERTS() == 0x40, 'X509_V_FLAG_ALLOW_PROXY_CERTS');
  ok(Net::SSLeay::X509_VERIFY_PARAM_set_flags($pm, Net::SSLeay::X509_V_FLAG_ALLOW_PROXY_CERTS()), 'X509_VERIFY_PARAM_set_flags');
}

SKIP: {
  skip 'openssl-0.9.8a required', 3 unless Net::SSLeay::SSLeay >= 0x0090801f;

  # Between versions 3.2.4 and 3.4.0, LibreSSL signals the use of its legacy
  # X.509 verifier via the X509_V_FLAG_LEGACY_VERIFY flag; this flag persists
  # even after X509_VERIFY_PARAM_clear_flags() is called
  my $base_flags =
      is_libressl()
          && Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") >= 0x3020400f
          && Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") <= 0x3040000f
    ? Net::SSLeay::X509_V_FLAG_LEGACY_VERIFY()
    : 0;

  ok(Net::SSLeay::X509_VERIFY_PARAM_get_flags($pm) == ($base_flags | Net::SSLeay::X509_V_FLAG_ALLOW_PROXY_CERTS()), 'X509_VERIFY_PARAM_get_flags');
  ok(Net::SSLeay::X509_VERIFY_PARAM_clear_flags($pm, Net::SSLeay::X509_V_FLAG_ALLOW_PROXY_CERTS()), 'X509_VERIFY_PARAM_clear_flags');
  ok(Net::SSLeay::X509_VERIFY_PARAM_get_flags($pm) == ($base_flags | 0), 'X509_VERIFY_PARAM_get_flags');
};

SKIP: {
  skip 'openssl-0.9.8 required', 4 unless Net::SSLeay::SSLeay >= 0x0090800f;
  ok(Net::SSLeay::X509_PURPOSE_SSL_CLIENT() == 1, 'X509_PURPOSE_SSL_CLIENT');
  ok(Net::SSLeay::X509_VERIFY_PARAM_set_purpose($pm, Net::SSLeay::X509_PURPOSE_SSL_CLIENT()), 'X509_VERIFY_PARAM_set_purpose');
  ok(Net::SSLeay::X509_TRUST_EMAIL() == 4, 'X509_TRUST_EMAIL');
  ok(Net::SSLeay::X509_VERIFY_PARAM_set_trust($pm, Net::SSLeay::X509_TRUST_EMAIL()), 'X509_VERIFY_PARAM_set_trust');
  Net::SSLeay::X509_VERIFY_PARAM_set_depth($pm, 5);
  Net::SSLeay::X509_VERIFY_PARAM_set_time($pm, time);
  Net::SSLeay::X509_VERIFY_PARAM_free($pm);
  Net::SSLeay::X509_VERIFY_PARAM_free($pm2);
}

# Test ASN1 objects
my $asn_object = Net::SSLeay::OBJ_txt2obj('1.2.3.4', 0);
ok($asn_object, 'OBJ_txt2obj');
ok(Net::SSLeay::OBJ_obj2txt($asn_object, 0) eq '1.2.3.4', 'OBJ_obj2txt');

ok(Net::SSLeay::OBJ_txt2nid('1.2.840.113549.1') == 2, 'OBJ_txt2nid');   # NID_pkcs
ok(Net::SSLeay::OBJ_txt2nid('1.2.840.113549.2.5') == 4, 'OBJ_txt2nid'); # NID_md5

ok(Net::SSLeay::OBJ_ln2nid('RSA Data Security, Inc. PKCS') == 2, 'OBJ_ln2nid'); # NID_pkcs
ok(Net::SSLeay::OBJ_ln2nid('md5') == 4, 'OBJ_ln2nid'); # NID_md5

ok(Net::SSLeay::OBJ_sn2nid('pkcs') == 2, 'OBJ_sn2nid'); # NID_pkcs
ok(Net::SSLeay::OBJ_sn2nid('MD5') == 4, 'OBJ_sn2nid'); # NID_md5

my $asn_object2 = Net::SSLeay::OBJ_txt2obj('1.2.3.4', 0);
ok(Net::SSLeay::OBJ_cmp($asn_object2, $asn_object) == 0, 'OBJ_cmp');
$asn_object2 = Net::SSLeay::OBJ_txt2obj('1.2.3.5', 0);
ok(Net::SSLeay::OBJ_cmp($asn_object2, $asn_object) != 0, 'OBJ_cmp');

ok(1, "Finished with tests that don't need fork");

my $server;
SKIP: {
    if (not can_fork()) {
        skip "fork() not supported on this system", 54;
    }

    $server = tcp_socket();

    run_server(); # Forks: child does not return
    $server->close() || die("client listen socket close: $!");
    client();
}

verify_local_trust();

sub test_policy_checks
{
    my ($ctx, $cl, $ok) = @_;

    $pm = Net::SSLeay::X509_VERIFY_PARAM_new();

    # Certificate must have this policy
    Net::SSLeay::X509_VERIFY_PARAM_set_flags($pm, Net::SSLeay::X509_V_FLAG_POLICY_CHECK() | Net::SSLeay::X509_V_FLAG_EXPLICIT_POLICY());

    my $oid = $ok ? $required_oid : ( $required_oid . '.1' );
    my $pobject = Net::SSLeay::OBJ_txt2obj($oid, 1);
    ok($pobject, "OBJ_txt2obj($oid)");
    is(Net::SSLeay::X509_VERIFY_PARAM_add0_policy($pm, $pobject), 1, "X509_VERIFY_PARAM_add0_policy($oid)");

    my $ssl = client_get_ssl($ctx, $cl, $pm);
    my $ret = Net::SSLeay::connect($ssl);
    is($verify_result, Net::SSLeay::get_verify_result($ssl), 'Verify callback result and get_verify_result are equal');
    if ($ok) {
	is($ret, 1, 'connect ok: policy checks succeeded');
	is($verify_result, Net::SSLeay::X509_V_OK(), 'Verify result is X509_V_OK');
	print "connect failed: $ret: " . Net::SSLeay::print_errs() . "\n" unless $ret == 1;
    } else {
	isnt($ret, 1, 'connect not ok: policy checks must fail') if !$ok;
	is($verify_result, Net::SSLeay::X509_V_ERR_NO_EXPLICIT_POLICY(), 'Verify result is X509_V_ERR_NO_EXPLICIT_POLICY');
    }

    Net::SSLeay::X509_VERIFY_PARAM_free($pm);
}

# These need at least OpenSSL 1.0.2 or LibreSSL 2.7.0
sub test_hostname_checks
{
    my ($ctx, $cl, $ok) = @_;
  SKIP: {
      skip 'No Net::SSLeay::X509_VERIFY_PARAM_set1_host, skipping hostname_checks', 13 unless (exists &Net::SSLeay::X509_VERIFY_PARAM_set1_host);

      $pm = Net::SSLeay::X509_VERIFY_PARAM_new();

      # Note: wildcards are supported by default
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_host($pm, 'test.johndoe.net-ssleay.example'), 1, 'X509_VERIFY_PARAM_set1_host(test.johndoe.net-ssleay.example)') if $ok;
      is(Net::SSLeay::X509_VERIFY_PARAM_add1_host($pm, 'invalid.net-ssleay.example'), 1, 'X509_VERIFY_PARAM_add1_host(invalid.net-ssleay.example)') if !$ok;

      is(Net::SSLeay::X509_VERIFY_PARAM_set1_email($pm, 'john.doe@net-ssleay.example'), 1, 'X509_VERIFY_PARAM_set1_email(john.doe@net-ssleay.example)');

      # Note: 'set' means that only one successfully set can be active
      # set1_ip:      IPv4 or IPv6 address as 4 or 16 octet binary.
      # setip_ip_asc: IPv4 or IPv6 address as ASCII string
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip($pm, pack('CCCC', 192, 168, 0, 3)), 1, 'X509_VERIFY_PARAM_set1_ip(192.168.0.3)');
#      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip($pm, pack('NNNN', hex('20010db8'), hex('01480100'), 0, hex('31'))), 1, 'X509_VERIFY_PARAM_set1_ip(2001:db8:148:100::31)');
#      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip_asc($pm, '10.20.30.40'), 1, 'X509_VERIFY_PARAM_set1_ip_asc(10.20.30.40)');
#      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip_asc($pm, '2001:db8:148:100::31'), 1, 'X509_VERIFY_PARAM_set1_ip_asc(2001:db8:148:100::31))');

      # Also see that incorrect values do not change anything.
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip($pm, '123'),              0, 'X509_VERIFY_PARAM_set1_ip(123)');
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip($pm, '123456789012345'),  0, 'X509_VERIFY_PARAM_set1_ip(123456789012345)');
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip_asc($pm, '10.20.30.256'), 0, 'X509_VERIFY_PARAM_set1_ip_asc(10.20.30.256)');
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_ip_asc($pm, '12345::'),      0, 'X509_VERIFY_PARAM_set1_ip_asc(12345::)');

      my $ssl = client_get_ssl($ctx, $cl, $pm);
      my $ret = Net::SSLeay::connect($ssl);
      is($verify_result, Net::SSLeay::get_verify_result($ssl), 'Verify callback result and get_verify_result are equal');
      if ($ok) {
	  is($ret, 1, 'connect ok: hostname checks succeeded');
	  is($verify_result, Net::SSLeay::X509_V_OK(), 'Verify result is X509_V_OK');
	  print "connect failed: $ret: " . Net::SSLeay::print_errs() . "\n" unless $ret == 1;
      } else {
	  isnt($ret, 1, 'connect not ok: hostname checks must fail') if !$ok;
	  is($verify_result, Net::SSLeay::X509_V_ERR_HOSTNAME_MISMATCH(), 'Verify result is X509_V_ERR_HOSTNAME_MISMATCH');
      }

      # For some reason OpenSSL 1.0.2 and LibreSSL return undef for get0_peername. Are we doing this wrong?
      $pm2 = Net::SSLeay::get0_param($ssl);
      my $peername = Net::SSLeay::X509_VERIFY_PARAM_get0_peername($pm2);
      if ($ok) {
	  is($peername, '*.johndoe.net-ssleay.example', 'X509_VERIFY_PARAM_get0_peername returns *.johndoe.net-ssleay.example')
	      if (Net::SSLeay::SSLeay >= 0x10100000 && is_openssl());
	  is($peername, undef, 'X509_VERIFY_PARAM_get0_peername returns undefined for OpenSSL 1.0.2 and LibreSSL')
	      if (Net::SSLeay::SSLeay <  0x10100000 || is_libressl());
      } else {
	  is($peername, undef, 'X509_VERIFY_PARAM_get0_peername returns undefined');
      }

      Net::SSLeay::X509_VERIFY_PARAM_free($pm);
      Net::SSLeay::X509_VERIFY_PARAM_free($pm2);
    }
}

sub test_wildcard_checks
{
    my ($ctx, $cl) = @_;
  SKIP: {
      skip 'No Net::SSLeay::X509_VERIFY_PARAM_set1_host, skipping wildcard_checks', 7 unless (exists &Net::SSLeay::X509_VERIFY_PARAM_set1_host);

      $pm = Net::SSLeay::X509_VERIFY_PARAM_new();

      # Wildcards are allowed by default: disallow
      is(Net::SSLeay::X509_VERIFY_PARAM_set1_host($pm, 'test.johndoe.net-ssleay.example'), 1, 'X509_VERIFY_PARAM_set1_host');
      is(Net::SSLeay::X509_VERIFY_PARAM_set_hostflags($pm, Net::SSLeay::X509_CHECK_FLAG_NO_WILDCARDS()), undef, 'X509_VERIFY_PARAM_set_hostflags(X509_CHECK_FLAG_NO_WILDCARDS)');

      my $ssl = client_get_ssl($ctx, $cl, $pm);
      my $ret = Net::SSLeay::connect($ssl);
      isnt($ret, 1, 'Connect must fail in wildcard test');
      is($verify_result, Net::SSLeay::get_verify_result($ssl), 'Verify callback result and get_verify_result are equal');
      is($verify_result, Net::SSLeay::X509_V_ERR_HOSTNAME_MISMATCH(), 'Verify result is X509_V_ERR_HOSTNAME_MISMATCH');

      Net::SSLeay::X509_VERIFY_PARAM_free($pm);
    }
}

sub verify_local_trust {
    # Read entire certificate chain
    my $bio = Net::SSLeay::BIO_new_file($certchain_pem, 'r');
    ok(my $x509_info_sk = Net::SSLeay::PEM_X509_INFO_read_bio($bio), "PEM_X509_INFO_read_bio able to read in entire chain");
    Net::SSLeay::BIO_free($bio);
    # Read just the leaf certificate from the chain
    $bio = Net::SSLeay::BIO_new_file($certchain_pem, 'r');
    ok(my $cert = Net::SSLeay::PEM_read_bio_X509($bio), "PEM_read_bio_X509 able to read in single cert from chain");
    Net::SSLeay::BIO_free($bio);
    # Read root CA certificate
    $bio = Net::SSLeay::BIO_new_file($root_ca_pem, 'r');
    ok(my $ca = Net::SSLeay::PEM_read_bio_X509($bio), "PEM_read_bio_X509 able to read in root CA");
    Net::SSLeay::BIO_free($bio);

    ok(my $x509_sk = Net::SSLeay::sk_X509_new_null(), "sk_X509_new_null creates STACK_OF(X509) successfully");
    ok(my $num = Net::SSLeay::sk_X509_INFO_num($x509_info_sk), "sk_X509_INFO_num is nonzero");

    # Set up STORE_CTX and verify leaf certificate using only root CA (should fail due to incomplete chain)
    ok(my $store = Net::SSLeay::X509_STORE_new(), "X509_STORE_new creates new store");
    ok(Net::SSLeay::X509_STORE_add_cert($store, $ca), "X509_STORE_add_cert CA cert");
    ok(my $ctx = Net::SSLeay::X509_STORE_CTX_new(), "X509_STORE_CTX_new creates new store context");
    is(Net::SSLeay::X509_STORE_CTX_init($ctx, $store, $cert), 1, 'X509_STORE_CTX_init succeeds');
    ok(!Net::SSLeay::X509_verify_cert($ctx), 'X509_verify_cert correctly fails');
    is(Net::SSLeay::X509_STORE_CTX_get_error($ctx),
        Net::SSLeay::X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY(), "X509_STORE_CTX_get_error returns unable to get local issuer certificate");
    Net::SSLeay::X509_STORE_free($store);
    Net::SSLeay::X509_STORE_CTX_free($ctx);

    # Add all certificates from entire certificate chain to X509 stack
    for (my $i = 0; $i < $num; $i++) {
        ok(my $x509_info = Net::SSLeay::sk_X509_INFO_value($x509_info_sk, $i), "sk_X509_INFO_value");
        ok(my $x509 = Net::SSLeay::P_X509_INFO_get_x509($x509_info), "P_X509_INFO_get_x509");
        ok(Net::SSLeay::sk_X509_push($x509_sk, $x509), "sk_X509_push");
    }

    # set up STORE_CTX and verify leaf certificate using root CA and chain (should succeed)
    ok($store = Net::SSLeay::X509_STORE_new(), "X509_STORE_new creates new store");
    ok(Net::SSLeay::X509_STORE_add_cert($store, $ca), "X509_STORE_add_cert CA cert");
    ok($ctx = Net::SSLeay::X509_STORE_CTX_new(), "X509_STORE_CTX_new creates new store context");
    is(Net::SSLeay::X509_STORE_CTX_init($ctx, $store, $cert, $x509_sk), 1, 'X509_STORE_CTX_init succeeds');
    ok(Net::SSLeay::X509_verify_cert($ctx), 'X509_verify_cert correctly succeeds');
    is(Net::SSLeay::X509_STORE_CTX_get_error($ctx), Net::SSLeay::X509_V_OK(), "X509_STORE_CTX_get_error returns ok");
    Net::SSLeay::X509_STORE_free($store);
    Net::SSLeay::X509_STORE_CTX_free($ctx);

    Net::SSLeay::sk_X509_free($x509_sk);
}

# Prepare and return a new $ssl based on callers verification needs
# Note that this adds tests to caller's test count.
sub client_get_ssl
{
    my ($ctx, $cl, $pm) = @_;

    my $store = Net::SSLeay::CTX_get_cert_store($ctx);
    ok($store, 'CTX_get_cert_store');
    is(Net::SSLeay::X509_STORE_set1_param($store, $pm), 1, 'X509_STORE_set1_param');

    # Needs OpenSSL 1.0.0 or later
    #Net::SSLeay::CTX_set1_param($ctx, $pm);

    $verify_result = -1; # Last verification result, set by callback below
    my $verify_cb = sub { $verify_result = Net::SSLeay::X509_STORE_CTX_get_error($_[1]); return $_[0];};

    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_verify($ssl, Net::SSLeay::VERIFY_PEER(), $verify_cb);
    Net::SSLeay::set_fd($ssl, $cl);

    return $ssl;
}

# SSL client - connect to server and test different verification
# settings
sub client {
    my ($ctx, $cl);
    foreach my $task (qw(
		      policy_checks_ok policy_checks_fail
		      hostname_checks_ok hostname_checks_fail
		      wildcard_checks
		      finish))
    {
	$ctx = new_ctx();
	is(Net::SSLeay::CTX_load_verify_locations($ctx, $ca_pem, $ca_dir), 1, "load_verify_locations($ca_pem $ca_dir)");

	$cl = $server->connect();

	test_policy_checks($ctx, $cl, 1)   if $task eq 'policy_checks_ok';
	test_policy_checks($ctx, $cl, 0)   if $task eq 'policy_checks_fail';
	test_hostname_checks($ctx, $cl, 1) if $task eq 'hostname_checks_ok';
	test_hostname_checks($ctx, $cl, 0) if $task eq 'hostname_checks_fail';
	test_wildcard_checks($ctx, $cl) if $task eq 'wildcard_checks';
	last if $task eq 'finish'; # Leaves $cl alive

	close($cl) || die("client close: $!");
    }

    # Tell the server to quit and see that our connection is still up
    $ctx = new_ctx();
    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::connect($ssl);
    my $end = "end";
    Net::SSLeay::ssl_write_all($ssl, $end);
    Net::SSLeay::shutdown($ssl);
    ok($end eq Net::SSLeay::ssl_read_all($ssl), 'Successful termination');
    Net::SSLeay::free($ssl);
    close($cl) || die("client final close: $!");
    return;
}

# SSL server - just accept connnections and exit when told to by
# the client
sub run_server
{
    my $pid;
    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");

    return if $pid != 0;

    $SIG{'PIPE'} = 'IGNORE';
    my $ctx = new_ctx();
    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
    my $ret = Net::SSLeay::CTX_check_private_key($ctx);
    BAIL_OUT("Server: CTX_check_private_key failed: $cert_pem, $key_pem") unless $ret == 1;
    if (defined &Net::SSLeay::CTX_set_num_tickets) {
        # TLS 1.3 server sends session tickets after a handhake as part of
        # the SSL_accept(). If a client finishes all its job including closing
        # TCP connectino before a server sends the tickets, SSL_accept() fails
        # with SSL_ERROR_SYSCALL and EPIPE errno and the server receives
        # SIGPIPE signal. <https://github.com/openssl/openssl/issues/6904>
        my $ret = Net::SSLeay::CTX_set_num_tickets($ctx, 0);
        BAIL_OUT("Session tickets disabled") unless $ret;
    }

    while (1)
    {
	my $cl = $server->accept() or BAIL_OUT("accept failed: $!");
	my $ssl = Net::SSLeay::new($ctx);

	Net::SSLeay::set_fd($ssl, fileno($cl));
	my $ret = Net::SSLeay::accept($ssl);
	next unless $ret == 1;

	# Termination request or other message from client
	my $msg = Net::SSLeay::ssl_read_all($ssl);
	if (defined $msg and $msg eq 'end')
	{
	    Net::SSLeay::ssl_write_all($ssl, 'end');
	    Net::SSLeay::shutdown($ssl);
	    Net::SSLeay::free($ssl);
	    close($cl) || die("server close: $!");
	    $server->close() || die("server listen socket close: $!");
	    exit (0);
	}
    }
}
