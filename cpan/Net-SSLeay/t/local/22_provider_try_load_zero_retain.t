use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay (initialise_libssl);

# Avoid default provider automatic loading. See 22_provider.t for more
# information.
#
#initialise_libssl(); # Don't do this
#
# We use a separate test file so that we get a newly loaded library
# that still has triggers for automatic loading enabled.

if (defined &Net::SSLeay::OSSL_PROVIDER_load) {
    plan(tests => 3);
} else {
    plan(skip_all => "no support for providers");
}

# Supplied OpenSSL configuration file may load unwanted providers.
local $ENV{OPENSSL_CONF} = '';

my ($null_provider, $default_avail, $null_avail);

$null_provider = Net::SSLeay::OSSL_PROVIDER_try_load(undef, 'null', 0);
ok($null_provider, 'try_load("null", retain_fallbacks = 0) returns a pointer');

$default_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'default');
is($default_avail, 0, 'default provider not automatically loaded after try_load("null", retain_fallbacks = 0)');

$null_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'null');
is($null_avail, 1, 'null provider loaded after try_load("null", retain_fallbacks = 0)');
