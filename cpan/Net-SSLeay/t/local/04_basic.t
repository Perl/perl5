# Test version and initialisation functions

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(lives_ok);

plan tests => 29;

lives_ok( sub { Net::SSLeay::randomize() }, 'seed pseudorandom number generator' );
lives_ok( sub { Net::SSLeay::ERR_load_crypto_strings() }, 'load libcrypto error strings' );
lives_ok( sub { Net::SSLeay::load_error_strings() }, 'load libssl error strings' );
lives_ok( sub { Net::SSLeay::library_init() }, 'register default TLS ciphers and digest functions' );
lives_ok( sub { Net::SSLeay::OpenSSL_add_all_digests() }, 'register all digest functions' );
#version numbers: 0x00903100 ~ 0.9.3, 0x0090600f ~ 0.6.9
ok( Net::SSLeay::SSLeay() >= 0x00903100, 'SSLeay (version min 0.9.3)' );
isnt( Net::SSLeay::SSLeay_version(), '', 'SSLeay (version string)' );
is( Net::SSLeay::SSLeay_version(),  Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_VERSION()), 'SSLeay_version optional argument' );
is(Net::SSLeay::hello(), 1, 'hello world');

if (exists &Net::SSLeay::OpenSSL_version)
{
    is(Net::SSLeay::SSLeay(), Net::SSLeay::OpenSSL_version_num(), 'OpenSSL_version_num');

    is(Net::SSLeay::OpenSSL_version(), Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_VERSION()), 'OpenSSL_version optional argument');

    is(Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_VERSION()),  Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_VERSION()),  'OpenSSL_version(OPENSSL_VERSION)');
    is(Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_CFLAGS()),   Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_CFLAGS()),   'OpenSSL_version(OPENSSL_CFLAGS)');
    is(Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_BUILT_ON()), Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_BUILT_ON()), 'OpenSSL_version(OPENSSL_BUILT_ON)');
    is(Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_PLATFORM()), Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_PLATFORM()), 'OpenSSL_version(OPENSSL_PLATFORM)');
    is(Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_DIR()),      Net::SSLeay::OpenSSL_version(Net::SSLeay::OPENSSL_DIR()),      'OpenSSL_version(OPENSSL_DIR)');
}
else
{
  SKIP: {
      skip('Only on OpenSSL 1.1.0 or later', 7);
    }
}

if (defined &Net::SSLeay::OPENSSL_version_major)
{

    my $major = Net::SSLeay::OPENSSL_version_major();
    my $minor = Net::SSLeay::OPENSSL_version_minor();
    my $patch = Net::SSLeay::OPENSSL_version_patch();

    # Separate test for being defined because cmp_ok won't fail this:
    # cmp_ok(undef, '>=', 0)
    isnt($major, undef, 'major is defined');
    isnt($minor, undef, 'minor is defined');
    isnt($patch, undef, 'patch is defined');

    cmp_ok($major, '>=', 3, 'OPENSSL_version_major');
    cmp_ok($minor, '>=', 0, 'OPENSSL_version_minor');
    cmp_ok($patch, '>=', 0, 'OPENSSL_version_patch');

    is(Net::SSLeay::OPENSSL_VERSION_MAJOR(), $major, 'OPENSSL_VERSION_MAJOR and OPENSSL_version_major are equal');
    is(Net::SSLeay::OPENSSL_VERSION_MINOR(), $minor, 'OPENSSL_VERSION_MINOR and OPENSSL_version_minor are equal');
    is(Net::SSLeay::OPENSSL_VERSION_PATCH(), $patch, 'OPENSSL_VERSION_PATCH and OPENSSL_version_patch are equal');

    isnt(defined Net::SSLeay::OPENSSL_version_pre_release(), undef, 'OPENSSL_version_pre_release returns a defined value');
    isnt(defined Net::SSLeay::OPENSSL_version_build_metadata(), undef, 'OPENSSL_version_build_metadata returns a defined value');

    isnt(Net::SSLeay::OPENSSL_info(Net::SSLeay::OPENSSL_INFO_CONFIG_DIR()), undef, 'OPENSSL_INFO(OPENSSL_INFO_CONFIG_DIR) returns a defined value');
    is(Net::SSLeay::OPENSSL_info(-1), undef, 'OPENSSL_INFO(-1) returns an undefined value');
}
else
{
  SKIP: {
      skip('Only on OpenSSL 3.0.0 or later', 13);
    }
}
