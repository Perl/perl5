# Checks whether (a subset of) the functions that should be exported by
# Net::SSLeay can be autoloaded. This script does not check whether constants
# can be autoloaded - see t/local/21_constants.t for that.

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(dies_like);

my @functions = qw(
    die_if_ssl_error
    die_now
    do_https
    dump_peer_certificate
    get_http
    get_http4
    get_https
    get_https3
    get_https4
    get_httpx
    get_httpx4
    make_form
    make_headers
    post_http
    post_http4
    post_https
    post_https3
    post_https4
    post_httpx
    post_httpx4
    print_errs
    set_cert_and_key
    set_server_cert_and_key
    sslcat
    tcpcat
    tcpxcat
);

plan tests => @functions + 1;

for (@functions) {
    dies_like(
        sub { "Net::SSLeay::$_"->(); die "ok\n" },
        qr/^(?!Can't locate .*\.al in \@INC)/,
        "function is autoloadable: $_"
    );
}

dies_like(
    sub { Net::SSLeay::doesnt_exist() },
    qr/^Can't locate .*\.al in \@INC/,
    'nonexistent function is not autoloadable'
);
