use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(initialise_libssl);

if (Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") || Net::SSLeay::constant("OPENSSL_VERSION_NUMBER") >= 0x10100000) {
    plan skip_all => "LibreSSL and OpenSSL 1.1.0 removed support for ephemeral/temporary RSA private keys";
} else {
    plan tests => 3;
}

initialise_libssl();

ok( my $ctx = Net::SSLeay::CTX_new(), 'CTX_new' );
ok( my $rsa = Net::SSLeay::RSA_generate_key(2048, Net::SSLeay::RSA_F4()), 'RSA_generate_key' );
ok( Net::SSLeay::CTX_set_tmp_rsa($ctx, $rsa), 'CTX_set_tmp_rsa' );
