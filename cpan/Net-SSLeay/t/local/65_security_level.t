use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(initialise_libssl);

if (Net::SSLeay::SSLeay < 0x10100001) {
    plan skip_all => 'OpenSSL 1.1.0 required';
} elsif (Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER")) {
    plan skip_all => 'get/set_security_level not available with LibreSSL';
} else {
    plan tests => 20;
}

initialise_libssl();

my $ctx = Net::SSLeay::CTX_new();
ok( defined Net::SSLeay::CTX_get_security_level($ctx),
    "CTX_get_security_level() returns a value"
);

ok( Net::SSLeay::CTX_get_security_level($ctx) >= 0,
    "CTX_get_security_level() is non-negative"
);

for (0..7) {
    Net::SSLeay::CTX_set_security_level($ctx, $_);
    is( Net::SSLeay::CTX_get_security_level($ctx),
        $_, "CTX_get_security_level() matches CTX_set_security_level($_)" );
}

my $ssl = Net::SSLeay::new($ctx);
ok( defined Net::SSLeay::get_security_level($ssl),
    "get_security_level() returns a value"
);

ok( Net::SSLeay::get_security_level($ssl) >= 0,
    "get_security_level() is non-negative"
);

for (0..7) {
    Net::SSLeay::set_security_level($ssl, $_);
    is( Net::SSLeay::get_security_level($ssl),
        $_, "get_security_level() matches set_security_level($_)" );
}
