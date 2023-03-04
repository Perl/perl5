# Test password entry callback functionality

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

plan tests => 36;

initialise_libssl();

my $key_pem      = data_file_path('simple-cert.key.enc.pem');
my $key_password = 'test';

my $cb_1_calls = 0;
my $cb_2_calls = 0;
my $cb_3_calls = 0;
my $cb_4_calls = 0;
my $cb_bad_calls = 0;

sub callback1 {
    my ($rwflag, $userdata) = @_;

    $cb_1_calls++;

    is ($rwflag, 0, 'rwflag is set correctly');
    is( $$userdata, $key_password, 'received userdata properly' );
    return $$userdata;
}

sub callback2 {
    my ($rwflag, $userdata) = @_;

    $cb_2_calls++;

    is( $$userdata, $key_password, 'received userdata properly' );
    return $$userdata;
}

sub callback3 {
    my ($rwflag, $userdata) = @_;

    $cb_3_calls++;

    is( $userdata, undef, 'received no userdata' );
    return $key_password;
}

sub callback_bad {
    my ($rwflag, $userdata) = @_;

    $cb_bad_calls++;

    is( $userdata, $key_password, 'received userdata properly' );
    return $key_password . 'incorrect'; # Return incorrect password
}

my $ctx_1 = Net::SSLeay::CTX_new();
ok($ctx_1, 'CTX_new 1');

my $ctx_2 = Net::SSLeay::CTX_new();
ok($ctx_2, 'CTX_new 2');

my $ctx_3 = Net::SSLeay::CTX_new();
ok($ctx_3, 'CTX_new 3');

my $ctx_4 = Net::SSLeay::CTX_new();
ok($ctx_4, 'CTX_new 4');

Net::SSLeay::CTX_set_default_passwd_cb($ctx_1, \&callback1);
Net::SSLeay::CTX_set_default_passwd_cb_userdata($ctx_1, \$key_password);

Net::SSLeay::CTX_set_default_passwd_cb($ctx_2, \&callback2);
Net::SSLeay::CTX_set_default_passwd_cb_userdata($ctx_2, \$key_password);

Net::SSLeay::CTX_set_default_passwd_cb($ctx_3, \&callback3);

ok( Net::SSLeay::CTX_use_PrivateKey_file($ctx_1, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'CTX_use_PrivateKey_file works with right passphrase and userdata' );

ok( Net::SSLeay::CTX_use_PrivateKey_file($ctx_2, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'CTX_use_PrivateKey_file works with right passphrase and userdata' );

ok( Net::SSLeay::CTX_use_PrivateKey_file($ctx_3, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'CTX_use_PrivateKey_file works with right passphrase and without userdata' );

Net::SSLeay::CTX_set_default_passwd_cb($ctx_4, sub { $cb_4_calls++; return $key_password; });
ok( Net::SSLeay::CTX_use_PrivateKey_file($ctx_4, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'CTX_use_PrivateKey_file works when callback data is unset' );

ok( $cb_1_calls == 1
    && $cb_2_calls == 1
    && $cb_3_calls == 1
    && $cb_4_calls == 1,
    'different cbs per ctx work' );

$key_password = 'incorrect';

ok( !Net::SSLeay::CTX_use_PrivateKey_file($ctx_1, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'CTX_use_PrivateKey_file doesn\'t work with wrong passphrase' );

is($cb_1_calls, 2, 'callback1 called 2 times');


# OpenSSL 1.1.0 has SSL_set_default_passwd_cb, but the callback is not
# called for SSL before OpenSSL 1.1.0f
if (exists &Net::SSLeay::set_default_passwd_cb)
{
    test_ssl_funcs();
}
else
{
  SKIP: {
      skip('Do not have Net::SSLeay::set_default_passwd_cb', 19);
    };
}

exit(0);

sub test_ssl_funcs
{
    my $ctx_1 = Net::SSLeay::CTX_new();
    my $ssl_1 = Net::SSLeay::new($ctx_1);
    ok($ssl_1, 'SSL_new 1');

    my $ctx_2 = Net::SSLeay::CTX_new();
    my $ssl_2 = Net::SSLeay::new($ctx_2);
    ok($ssl_2, 'SSL_new 2');

    my $ctx_3 = Net::SSLeay::CTX_new();
    my $ssl_3 = Net::SSLeay::new($ctx_3);
    ok($ssl_3, 'SSL_new 3');

    my $ctx_4 = Net::SSLeay::CTX_new();
    my $ssl_4 = Net::SSLeay::new($ctx_4);
    ok($ssl_4, 'SSL_new 4');

    $cb_1_calls = $cb_2_calls = $cb_3_calls = $cb_4_calls = $cb_bad_calls = 0;
    $key_password = 'test';

    Net::SSLeay::set_default_passwd_cb($ssl_1, \&callback1);
    Net::SSLeay::set_default_passwd_cb_userdata($ssl_1, \$key_password);

    Net::SSLeay::set_default_passwd_cb($ssl_2, \&callback2);
    Net::SSLeay::set_default_passwd_cb_userdata($ssl_2, \$key_password);

    Net::SSLeay::set_default_passwd_cb($ssl_3, \&callback3);

    ok( Net::SSLeay::use_PrivateKey_file($ssl_1, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file works with right passphrase and userdata' );

    ok( Net::SSLeay::use_PrivateKey_file($ssl_2, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file works with right passphrase and userdata' );

    # Setting the callback for CTX should not change anything
    Net::SSLeay::CTX_set_default_passwd_cb($ctx_2, \&callback_bad);
    Net::SSLeay::CTX_set_default_passwd_cb_userdata($ctx_2, \$key_password);
    ok( Net::SSLeay::use_PrivateKey_file($ssl_2, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file works with right passphrase and userdata after bad passphrase set for CTX' );

    ok( Net::SSLeay::use_PrivateKey_file($ssl_3, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file works with right passphrase and without userdata' );

    Net::SSLeay::set_default_passwd_cb($ssl_4, sub { $cb_4_calls++; return $key_password; });
    ok( Net::SSLeay::use_PrivateKey_file($ssl_4, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file works when callback data is unset' );

    ok( $cb_1_calls == 1
	&& $cb_2_calls == 2
	&& $cb_3_calls == 1
	&& $cb_4_calls == 1
	&& $cb_bad_calls == 0,
	'different cbs per ssl work' );

    $key_password = 'incorrect';

    ok( !Net::SSLeay::use_PrivateKey_file($ssl_1, $key_pem, &Net::SSLeay::FILETYPE_PEM),
        'use_PrivateKey_file doesn\'t work with wrong passphrase' );

    is($cb_1_calls, 2, 'callback1 called 2 times');
}
