# Test SSL_CTX_new and related functions, and handshake state machine retrieval

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(initialise_libssl);

plan tests => 44;

initialise_libssl();

sub is_known_proto_version {
    return 1 if $_[0] == 0x0000;                            # Automatic version selection
    return 1 if $_[0] == Net::SSLeay::SSL3_VERSION();       # OpenSSL 0.9.8+
    return 1 if $_[0] == Net::SSLeay::TLS1_VERSION();       # OpenSSL 0.9.8+
    return 1 if $_[0] == Net::SSLeay::TLS1_1_VERSION();     # OpenSSL 0.9.8+
    return 1 if $_[0] == Net::SSLeay::TLS1_2_VERSION();     # OpenSSL 0.9.8+
    if (eval { Net::SSLeay::TLS1_3_VERSION() }) {
        return 1 if $_[0] == Net::SSLeay::TLS1_3_VERSION(); # OpenSSL 1.1.1+
    }

    return;
}

# Shortcuts from SSLeay.xs
my $ctx = Net::SSLeay::CTX_new();
ok($ctx, 'CTX_new');
$ctx =  Net::SSLeay::CTX_v23_new();
ok($ctx, 'CTX_v23_new');
$ctx =  Net::SSLeay::CTX_tlsv1_new();
ok($ctx, 'CTX_tlsv1_new');

my $ctx_23 = Net::SSLeay::CTX_new_with_method(Net::SSLeay::SSLv23_method());
ok($ctx_23, 'CTX_new with SSLv23_method');

my $ctx_23_client = Net::SSLeay::CTX_new_with_method(Net::SSLeay::SSLv23_client_method());
ok($ctx_23_client, 'CTX_new with SSLv23_client_method');

my $ctx_23_server = Net::SSLeay::CTX_new_with_method(Net::SSLeay::SSLv23_server_method());
ok($ctx_23_server, 'CTX_new with SSLv23_server_method');

my $ctx_tls1 = Net::SSLeay::CTX_new_with_method(Net::SSLeay::TLSv1_method());
ok($ctx_tls1, 'CTX_new with TLSv1_method');

# Retrieve information about the handshake state machine
is(Net::SSLeay::in_connect_init(Net::SSLeay::new($ctx_23_client)), 1, 'in_connect_init() is 1 for client');
is(Net::SSLeay::in_accept_init(Net::SSLeay::new($ctx_23_client)),  0, 'in_accept_init() is 0 for client');
is(Net::SSLeay::in_connect_init(Net::SSLeay::new($ctx_23_server)), 0, 'in_connect_init() is 0 for server');
is(Net::SSLeay::in_accept_init(Net::SSLeay::new($ctx_23_server)),  1, 'in_accept_init() is 1 for server');

# Need recent enough OpenSSL or LibreSSL for TLS_method functions
my ($ctx_tls, $ssl_tls, $ctx_tls_client, $ssl_tls_client, $ctx_tls_server, $ssl_tls_server);
if (exists &Net::SSLeay::TLS_method)
{
    $ctx_tls = Net::SSLeay::CTX_new_with_method(Net::SSLeay::TLS_method());
    ok($ctx_tls, 'CTX_new with TLS_method');

    $ssl_tls = Net::SSLeay::new($ctx_tls);
    ok($ssl_tls, 'New SSL created with ctx_tls');

    $ctx_tls_client = Net::SSLeay::CTX_new_with_method(Net::SSLeay::TLS_client_method());
    ok($ctx_tls_client, 'CTX_new with TLS_client_method');

    $ctx_tls_server = Net::SSLeay::CTX_new_with_method(Net::SSLeay::TLS_server_method());
    ok($ctx_tls_server, 'CTX_new with TLS_server_method');
}
else
{
  SKIP: {
      skip('Do not have Net::SSLeay::TLS_method', 4);
    };
}

# Having TLS_method() does not necessarily that proto setters are available
if ($ctx_tls && exists &Net::SSLeay::CTX_set_min_proto_version)
{
    my $ver_1_0 = Net::SSLeay::TLS1_VERSION();
    ok($ver_1_0, "Net::SSLeay::TLS1_VERSION() returns non-false: $ver_1_0, hex " . sprintf('0x%04x', $ver_1_0));
    my $ver_min = Net::SSLeay::TLS1_1_VERSION();
    ok($ver_min, "Net::SSLeay::TLS1_1_VERSION() returns non-false: $ver_min, hex " . sprintf('0x%04x', $ver_min));
    my $ver_max = Net::SSLeay::TLS1_2_VERSION();
    ok($ver_max, "Net::SSLeay::TLS1_2_VERSION() returns $ver_max, hex " . sprintf('0x%04x', $ver_max));
    isnt($ver_1_0, $ver_min, 'Version 1_0 and 1_1 values are different');
    isnt($ver_min, $ver_max, 'Version 1_1 and 1_2 values are different');

    my $rv;

    $rv = Net::SSLeay::CTX_set_min_proto_version($ctx_tls_client, $ver_min);
    is($rv, 1, 'Setting client CTX minimum version');

    $rv = Net::SSLeay::CTX_set_min_proto_version($ctx_tls_client, 0);
    is($rv, 1, 'Setting client CTX minimum version to automatic');

    $rv = Net::SSLeay::CTX_set_min_proto_version($ctx_tls_client, -1);
    is($rv, 0, 'Setting client CTX minimum version to bad value');

    $rv = Net::SSLeay::CTX_set_min_proto_version($ctx_tls_client, $ver_min);
    is($rv, 1, 'Setting client CTX minimum version back to good value');

    $rv = Net::SSLeay::CTX_set_max_proto_version($ctx_tls_client, $ver_max);
    is($rv, 1, 'Setting client CTX maximum version');

    # This SSL should have min and max versions set based on its
    # CTX. We test the getters later, if they exist.
    $ssl_tls_client =  Net::SSLeay::new($ctx_tls_client);
    ok($ssl_tls_client, 'New SSL created from client CTX');

    # This SSL should have min and max versions set to automatic based
    # on its CTX. We change them now and test the getters later, if
    # they exist.
    $ssl_tls_server =  Net::SSLeay::new($ctx_tls_server);
    ok($ssl_tls_server, 'New SSL created from server CTX');
    $rv = Net::SSLeay::set_min_proto_version($ssl_tls_server,  Net::SSLeay::TLS1_VERSION());
    is($rv, 1, 'Setting SSL minimum version for ssl_tls_server');
    $rv = Net::SSLeay::set_max_proto_version($ssl_tls_server,  Net::SSLeay::TLS1_2_VERSION());
    is($rv, 1, 'Setting SSL maximum version for ssl_tls_server');
}
else
{
  SKIP: {
      skip('Do not have Net::SSLeay::CTX_get_min_proto_version', 14);
    };
}

# Having TLS_method() does not necessarily that proto getters are available
if ($ctx_tls && exists &Net::SSLeay::CTX_get_min_proto_version)
{
    my $ver;
    $ver = Net::SSLeay::CTX_get_min_proto_version($ctx_tls);
    ok(is_known_proto_version($ver), 'TLS_method CTX has known minimum version');
    $ver = Net::SSLeay::CTX_get_max_proto_version($ctx_tls);
    ok(is_known_proto_version($ver), 'TLS_method CTX has known maximum version');

    $ver = Net::SSLeay::get_min_proto_version($ssl_tls);
    ok(is_known_proto_version($ver), 'SSL from TLS_method CTX has known minimum version');
    $ver = Net::SSLeay::get_max_proto_version($ssl_tls);
    ok(is_known_proto_version($ver), 'SSL from TLS_method CTX has known maximum version');

    # First see if our CTX has min and max settings enabled
    $ver = Net::SSLeay::CTX_get_min_proto_version($ctx_tls_client);
    is($ver, Net::SSLeay::TLS1_1_VERSION(), 'TLS_client CTX has minimum version correctly set');
    $ver = Net::SSLeay::CTX_get_max_proto_version($ctx_tls_client);
    is($ver, Net::SSLeay::TLS1_2_VERSION(), 'TLS_client CTX has maximum version correctly set');

    # Then see if our client SSL has min and max settings enabled
    $ver = Net::SSLeay::get_min_proto_version($ssl_tls_client);
    is($ver, Net::SSLeay::TLS1_1_VERSION(), 'SSL from TLS_client CTX has minimum version correctly set');
    $ver = Net::SSLeay::get_max_proto_version($ssl_tls_client);
    is($ver, Net::SSLeay::TLS1_2_VERSION(), 'SSL from TLS_client CTX has maximum version correctly set');

    # Then see if our server SSL has min and max settings enabled
    $ver = Net::SSLeay::get_min_proto_version($ssl_tls_server);
    is($ver, Net::SSLeay::TLS1_VERSION(), 'SSL from TLS_server CTX has minimum version correctly set');
    $ver = Net::SSLeay::get_max_proto_version($ssl_tls_server);
    is($ver, Net::SSLeay::TLS1_2_VERSION(), 'SSL from TLS_server CTX has maximum version correctly set');
}
else
{
  SKIP: {
      skip('Do not have Net::SSLeay::CTX_get_min_proto_version', 10);
    };
}

if (eval {Net::SSLeay::TLS1_3_VERSION()})
{
    my $ver_1_2 = Net::SSLeay::TLS1_2_VERSION();
    ok($ver_1_2, "Net::SSLeay::TLS1_2_VERSION() returns non-false: $ver_1_2, hex " . sprintf('0x%04x', $ver_1_2));
    my $ver_1_3 = Net::SSLeay::TLS1_3_VERSION();
    ok($ver_1_3, "Net::SSLeay::TLS1_3_VERSION() returns non-false: $ver_1_3, hex " . sprintf('0x%04x', $ver_1_3));
    isnt($ver_1_2, $ver_1_3, 'Version 1_2 and 1_3 values are different');

    my $rv = 0;
    ok(eval {$rv = Net::SSLeay::OP_NO_TLSv1_3()}, 'Have OP_NO_TLSv1_3');
    isnt($rv, 0, 'OP_NO_TLSv1_3 returns non-zero value');
}
else
{
  SKIP: {
      skip('Do not have Net::SSLeay::TLS1_3_VERSION', 5);
    };
}

exit(0);
