# RAND-related tests

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl is_libressl );

plan tests => 53;

initialise_libssl();

is(Net::SSLeay::RAND_status(), 1, 'RAND_status');
is(Net::SSLeay::RAND_poll(), 1, 'RAND_poll');

# RAND_file_name has significant differences between the two libraries
is_libressl() ?
    test_rand_file_name_libressl() :
    test_rand_file_name_openssl();

# RAND_load_file
my $binary_file      = data_file_path('binary-test.file');
my $binary_file_size = -s $binary_file;

cmp_ok($binary_file_size, '>=', 1000, "Have binary file with good size: $binary_file $binary_file_size");
is(Net::SSLeay::RAND_load_file($binary_file, $binary_file_size), $binary_file_size, 'RAND_load with specific size');
if (Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER"))
{
    # RAND_load_file does nothing on LibreSSL but should return something sane
    cmp_ok(Net::SSLeay::RAND_load_file($binary_file, -1), '>', 0, 'RAND_load with -1 is positive with LibreSSL');
} else {
    is(Net::SSLeay::RAND_load_file($binary_file, -1), $binary_file_size, 'RAND_load with -1 returns file size');
}

test_rand_bytes();

exit(0);

# With LibreSSL RAND_file_name is expected to always succeed as long
# as the buffer size is large enough. Their manual states that it's
# implemented for API compatibility only and its use is discouraged.
sub test_rand_file_name_libressl
{
    my $file_name = Net::SSLeay::RAND_file_name(300);
    isnt($file_name, undef, 'RAND_file_name returns defined value');
    isnt($file_name, q{}, "RAND_file_name returns non-empty string: $file_name");

    $file_name = Net::SSLeay::RAND_file_name(2);
    is($file_name, undef, "RAND_file_name return value is undef with too short buffer");

    return;
}

# With OpenSSL there are a number of options that affect
# RAND_file_name return value. Note: we override environment variables
# temporarily because some environments do not have HOME set or may
# already have RANDFILE set. We do not try to trigger a failure which
# happens if there's no HOME nor RANDFILE in order to keep the test
# from becoming overly complicated.
sub test_rand_file_name_openssl
{
    my $file_name;
    local %ENV = %ENV;
    delete $ENV{RANDFILE};

    # NOTE: If there are test failures, are you using some type of
    # setuid environment? If so, this may affect usability of
    # environment variables.

    $ENV{HOME} = '/nosuchdir-1/home';
    $file_name = Net::SSLeay::RAND_file_name(300);
    if (Net::SSLeay::SSLeay() >= 0x10100006 && Net::SSLeay::SSLeay() <= 0x1010000f)
    {
	# This was broken starting with 1.0.0-pre6 and fixed after 1.0.0
	is($file_name, q{}, "RAND_file_name return value is empty and doesn't include '.rnd'");
    } else {
	like($file_name, qr/\.rnd/s, "RAND_file_name return value '$file_name' includes '.rnd'");
    }

    my $randfile = '/nosuchdir-2/randfile';
    $ENV{RANDFILE} = $randfile;
    $file_name = Net::SSLeay::RAND_file_name(300);
    if (Net::SSLeay::SSLeay() < 0x1010001f) {
	# On Windows, and possibly other non-Unix systems, 1.0.2
	# series and earlier did not honour RANDFILE. 1.1.0a is an
	# educated guess when it starts working with all platforms.
	isnt($file_name, q{}, "RAND_file_name returns non-empty string when RANDFILE is set: $file_name");
    } else {
	is($file_name, $randfile, "RAND_file_name return value '$file_name' is RANDFILE environment value");
    }

    # RANDFILE is longer than 2 octets. OpenSSL 1.1.0a and later
    # return undef with short buffer
    $file_name = Net::SSLeay::RAND_file_name(2);
    if (Net::SSLeay::SSLeay() < 0x1010001f) {
	is($file_name, q{}, "RAND_file_name return value is empty string with too short buffer");
    } else {
	is($file_name, undef, "RAND_file_name return value is undef with too short buffer");
    }

    return;
}

sub test_rand_bytes
{
    my ($ret, $rand_bytes, $rand_length, $rand_expected_length);

    my @rand_lengths = (0, 1, 1024, 65536, 1024**2);

    foreach $rand_expected_length (@rand_lengths)
    {
	$rand_length = $rand_expected_length;
	$ret = Net::SSLeay::RAND_bytes($rand_bytes, $rand_length);
	test_rand_bytes_results('RAND_bytes', $ret, $rand_bytes, $rand_length, $rand_expected_length);
    }

    foreach $rand_expected_length (@rand_lengths)
    {
	$rand_length = $rand_expected_length;
	$ret = Net::SSLeay::RAND_pseudo_bytes($rand_bytes, $rand_length);
	test_rand_bytes_results('RAND_pseudo_bytes', $ret, $rand_bytes, $rand_length, $rand_expected_length);
    }

    if (defined &Net::SSLeay::RAND_priv_bytes)
    {
	foreach $rand_expected_length (@rand_lengths)
	{
	    $rand_length = $rand_expected_length;
	    $ret = Net::SSLeay::RAND_priv_bytes($rand_bytes, $rand_length);
	    test_rand_bytes_results('RAND_priv_bytes', $ret, $rand_bytes, $rand_length, $rand_expected_length);
	}
    } else {
	SKIP : {
	    # Multiplier is the test count in test_rand_bytes_results
	    skip("Do not have Net::SSLeay::RAND_priv_bytes", ((scalar @rand_lengths) * 3));
	};
    }
}

sub test_rand_bytes_results
{
    my ($func, $ret, $rand_bytes, $rand_length, $rand_expected_length) = @_;

    # RAND_bytes functions do not update their rand_length argument, but check for this
    is($ret, 1, "$func: $rand_expected_length return value ok");
    is(length($rand_bytes), $rand_length, "$func: length of rand_bytes and rand_length match");
    is(length($rand_bytes), $rand_expected_length, "$func: length of rand_bytes is expected length $rand_length");
}
