use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    dies_like doesnt_warn initialise_libssl lives_ok warns_like
);

plan tests => 11;

doesnt_warn('tests run without outputting unexpected warnings');

initialise_libssl();

# See below near 'sub put_err' for more about how error string and
# erro code contents have changed between library versions.
my $err_string = "foo $$: 1 - error:10000080:BIO routines:";
$err_string    = "foo $$: 1 - error:20000080:BIO routines:"
    if  Net::SSLeay::SSLeay_version(Net::SSLeay::SSLEAY_VERSION()) =~ m/^OpenSSL 3.0.0-alpha[1-4] /s;
$err_string    = "foo $$: 1 - error:2006D080:BIO routines:"
    if (Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") || Net::SSLeay::constant("OPENSSL_VERSION_NUMBER") < 0x30000000);

# Note, die_now usually just prints the process id and the argument string eg:
# 57611: test
# but on some systems, perhaps if diagnostics are enabled, it might [roduce something like:
# found: Uncaught exception from user code:
# 	57611: test
# therefore the qr match strings below have been chnaged so they dont have tooccur at the 
# beginning of the line.
{
    dies_like(sub {
            Net::SSLeay::die_now('test')
    }, qr/$$: test\n$/, 'die_now dies without errors');

    lives_ok(sub {
            Net::SSLeay::die_if_ssl_error('test');
    }, 'die_if_ssl_error lives without errors');

    put_err();
    dies_like(sub {
            Net::SSLeay::die_now('test');
    }, qr/$$: test\n$/, 'die_now dies with errors');

    put_err();
    dies_like(sub {
            Net::SSLeay::die_if_ssl_error('test');
    }, qr/$$: test\n$/, 'die_if_ssl_error dies with errors');
}

{
    local $Net::SSLeay::trace = 1;

    dies_like(sub {
            Net::SSLeay::die_now('foo');
    }, qr/$$: foo\n$/, 'die_now dies without arrors and with trace');

    lives_ok(sub {
            Net::SSLeay::die_if_ssl_error('foo');
    }, 'die_if_ssl_error lives without errors and with trace');

    put_err();
    warns_like(sub {
            dies_like(sub {
                    Net::SSLeay::die_now('foo');
            }, qr/^$$: foo\n$/, 'die_now dies with errors and trace');
    }, qr/$err_string/i, 'die_now raises warnings about the occurred error when tracing');

    put_err();
    warns_like(sub {
            dies_like(sub {
                Net::SSLeay::die_if_ssl_error('foo');
            }, qr/^$$: foo\n$/, 'die_if_ssl_error dies with errors and trace');
    }, qr/$err_string/i, 'die_if_ssl_error raises warnings about the occurred error when tracing');
}

# The resulting error strings looks something like below. The number
# after 'foo' is the process id. OpenSSL 3.0.0 drops function name and
# changes how error code is packed.
# - OpenSSL 3.0.0:        foo 61488: 1 - error:10000080:BIO routines::no such file
# - OpenSSL 3.0.0-alpha5: foo 16380: 1 - error:10000080:BIO routines::no such file
# - OpenSSL 3.0.0-alpha1: foo 16293: 1 - error:20000080:BIO routines::no such file
# - OpenSSL 1.1.1l:       foo 61202: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 1.1.0l:       foo 61295: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 1.0.2u:       foo 61400: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 1.0.1u:       foo 13621: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 1.0.0t:       foo 14349: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 0.9.8zh:      foo 14605: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
# - OpenSSL 0.9.8f:       foo 14692: 1 - error:2006D080:BIO routines:BIO_new_file:no such file
#
# 1.1.1 series and earlier create error by ORing together lib, func
# and reason with 24 bit left shift, 12 bit left shift and without bit
# shift, respectively.
# 3.0.0 alpha1 drops function name from error string and alpha5
# changes bit shift of lib to 23.
# LibreSSL 2.5.1 drops function name from error string.
sub put_err {
    Net::SSLeay::ERR_put_error(
        32, #lib    - 0x20 ERR_LIB_BIO 'BIO routines'
       109, #func   - 0x6D BIO_F_BIO_NEW_FILE 'BIO_new_file'
       128, #reason - 0x80 BIO_R_NO_SUCH_FILE 'no such file'
         1, #file   - file name (not packed into error code)
         1, #line   - line number (not packed into error code)
    );
}
