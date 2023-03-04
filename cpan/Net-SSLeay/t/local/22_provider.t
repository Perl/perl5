use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay (initialise_libssl);

# We don't do intialise_libssl() now because we want to want to
# trigger automatic loading of the default provider.
#
# Quote from
# https://www.openssl.org/docs/manmaster/man7/OSSL_PROVIDER-default.html
# about default provider:
#
#   It is loaded automatically the first time that an algorithm is
#   fetched from a provider or a function acting on providers is
#   called and no other provider has been loaded yet.
#
#initialise_libssl(); # Don't do this

if (defined &Net::SSLeay::OSSL_PROVIDER_load) {
    plan(tests => 16);
} else {
    plan(skip_all => "no support for providers");
}

# Supplied OpenSSL configuration file may load unwanted providers.
local $ENV{OPENSSL_CONF} = '';

# provider loading, availability and unloading
{
    # See top of file why things are done in this order. We don't want
    # to load the default provider automatically.

    my $null_provider = Net::SSLeay::OSSL_PROVIDER_load(undef, 'null');
    ok($null_provider, 'null provider load returns a pointer');
    my $null_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'null');
    is($null_avail, 1, 'null provider loaded and available');

    my $default_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'default');
    is($default_avail, 0, 'default provider not loaded, not available');
    if ($default_avail)
    {
	diag('Default provider was already available. More provider tests in this and other provider test files may fail');
	diag('If your configuration loads the default provider, consider ignoring the errors or using OPENSSL_CONF environment variable');
	diag('For example: OPENSSL_CONF=/path/to/openssl/ssl/openssl.cnf.dist make test');
    }

    my $null_unload = Net::SSLeay::OSSL_PROVIDER_unload($null_provider);
    is($null_unload, 1, 'null provider successfully unloaded');
    $null_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'null');
    is($null_avail, 0, 'null provider is no longer available');

    $default_avail = Net::SSLeay::OSSL_PROVIDER_available(undef, 'default');
    is($default_avail, 0, 'default provider still not loaded, not available');

    my $default_provider_undef_libctx = Net::SSLeay::OSSL_PROVIDER_load(undef, 'default');
    ok($default_provider_undef_libctx, 'default provider with NULL libctx loaded successfully');

    my $libctx = Net::SSLeay::OSSL_LIB_CTX_get0_global_default();
    ok($libctx, 'OSSL_LIB_CTX_get0_global_default() returns a pointer');

    my $default_provider_default_libctx = Net::SSLeay::OSSL_PROVIDER_load($libctx, 'default');
    ok($default_provider_default_libctx, 'default provider with default libctx loaded successfully');
    is($default_provider_default_libctx, $default_provider_undef_libctx, 'OSSL_PROVIDER_load with undef and defined libctx return the same pointer');
}


# get0_name, selftest
{
    my $null_provider = Net::SSLeay::OSSL_PROVIDER_load(undef, 'null');
    my $default_provider = Net::SSLeay::OSSL_PROVIDER_load(undef, 'default');

    is(Net::SSLeay::OSSL_PROVIDER_get0_name($null_provider), 'null', 'get0_name for null provider');
    is(Net::SSLeay::OSSL_PROVIDER_get0_name($default_provider), 'default', 'get0_name for default provider');

    is(Net::SSLeay::OSSL_PROVIDER_self_test($null_provider), 1, 'self_test for null provider');
    is(Net::SSLeay::OSSL_PROVIDER_self_test($default_provider), 1, 'self_test for default provider');
}


# do_all
{
    my %seen_providers;
    sub all_cb {
	my ($provider_cb, $cbdata_cb) = @_;

	fail('provider already seen') if exists $seen_providers{$provider_cb};
	$seen_providers{$provider_cb} = $cbdata_cb;
	return 1;
    };

    my $null_provider = Net::SSLeay::OSSL_PROVIDER_load(undef, 'null');
    my $default_provider = Net::SSLeay::OSSL_PROVIDER_load(undef, 'default');
    my $cbdata = 'data for cb';

    Net::SSLeay::OSSL_PROVIDER_do_all(undef, \&all_cb, $cbdata);
    foreach my $provider ($null_provider, $default_provider)
    {
	my $name = Net::SSLeay::OSSL_PROVIDER_get0_name($provider);
	is(delete $seen_providers{$provider}, $cbdata, "provider '$name' was seen");
    }
    foreach my $provider (keys(%seen_providers))
    {
	my $name = Net::SSLeay::OSSL_PROVIDER_get0_name($provider);
	diag("Provider '$name' was also seen by the callback");
    }
}
