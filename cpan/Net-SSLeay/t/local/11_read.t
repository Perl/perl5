# Various SSL read and write related tests: SSL_read, SSL_peek, SSL_read_ex,
# SSL_peek_ex, SSL_write_ex, SSL_pending and SSL_has_pending

use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl tcp_socket
);

use Storable;

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} else {
    plan tests => 53;
}

initialise_libssl();

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

my $server = tcp_socket();

# See that lengths differ for all msgs
my $msg1 = "1 first message from server";
my $msg2 = "2 second message from server";
my $msg3 = "3 third message from server: pad";

my @rounds = qw(openssl openssl-1.1.0 openssl-1.1.1);

sub server
{
    # SSL server - just handle connections, send to client and exit
    my $cert_pem = data_file_path('simple-cert.cert.pem');
    my $key_pem  = data_file_path('simple-cert.key.pem');

    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");
    if ($pid == 0) {
	foreach my $round (@rounds)
	{
	    my ($ctx, $ssl, $cl);

	    next if skip_round($round);

	    $cl = $server->accept();

	    $ctx = Net::SSLeay::CTX_new();
	    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);

	    $ssl = Net::SSLeay::new($ctx);
	    Net::SSLeay::set_fd($ssl, fileno($cl));
	    Net::SSLeay::accept($ssl);

	    Net::SSLeay::write($ssl, $msg1);
	    Net::SSLeay::write($ssl, $msg2);

	    my $msg = Net::SSLeay::read($ssl);
	    Net::SSLeay::write($ssl, $msg);
	    Net::SSLeay::shutdown($ssl);
	    Net::SSLeay::free($ssl);
	    close($cl) || die("client close: $!");
	}
	$server->close() || die("server listen socket close: $!");
	exit(0);
    }
}

sub client
{
    foreach my $round (@rounds)
    {
	my ($ctx, $ssl, $cl);

	$cl = $server->connect();

	$ctx = Net::SSLeay::CTX_new();
	$ssl = Net::SSLeay::new($ctx);

	my ($reason, $num_tests) = skip_round($round);
	if ($reason) {
	  SKIP: {
	      skip($reason, $num_tests);
	    }
	    next;
	}

	round_openssl($ctx, $ssl, $cl) if $round eq 'openssl';
	round_openssl_1_1_0($ctx, $ssl, $cl) if $round eq 'openssl-1.1.0';
	round_openssl_1_1_1($ctx, $ssl, $cl) if $round eq 'openssl-1.1.1';

	Net::SSLeay::shutdown($ssl);
	Net::SSLeay::free($ssl);
	close($cl) || die("client close: $!");
    }
    $server->close() || die("client listen socket close: $!");
    return;
}

# Returns list for skip() if we should skip this round, false if we
# shouldn't
sub skip_round
{
    my ($round) = @_;

    return if $round eq 'openssl';

    if ($round eq 'openssl-1.1.0') {
	if (Net::SSLeay::constant("OPENSSL_VERSION_NUMBER") < 0x1010000f ||
	    Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER"))
	{
	    return ("Need OpenSSL 1.1.0 or later", 6);
	} else {
	    return;
	}
    }

    if ($round eq 'openssl-1.1.1') {
	if (Net::SSLeay::constant("OPENSSL_VERSION_NUMBER") < 0x1010100f ||
	    Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER"))
	{
	    return ("Need OpenSSL 1.1.1 or later", 26);
	} else {
	    return;
	}
    }

    diag("Unknown round: $round");
    return;
}

sub round_openssl
{
    my ($ctx, $ssl, $cl) = @_;

    my ($peek_msg, $read_msg, $len, $err, $ret);

    # ssl is not connected yet
    $peek_msg = Net::SSLeay::peek($ssl);
    is($peek_msg, undef, "scalar: peek returns undef for closed ssl");

    ($peek_msg, $len) = Net::SSLeay::peek($ssl);
    is($peek_msg, undef, "list: peek returns undef for closed ssl");
    cmp_ok($len, '<=', 0, 'list: peek returns length <=0 for closed ssl');
    $err = Net::SSLeay::get_error($ssl, $len);
    isnt($err, Net::SSLeay::ERROR_WANT_READ(), "peek err $err is not retryable WANT_READ");
    isnt($err, Net::SSLeay::ERROR_WANT_WRITE(), "peek err $err is not retryable WANT_WRITE");

    $read_msg = Net::SSLeay::read($ssl);
    is($read_msg, undef, "scalar: read returns undef for closed ssl");

    ($read_msg, $len) = Net::SSLeay::read($ssl);
    is($read_msg, undef, "list: read returns undef for closed ssl");
    cmp_ok($len, '<=', 0, 'list: read returns length <=0 for closed ssl');
    $err = Net::SSLeay::get_error($ssl, $len);
    isnt($err, Net::SSLeay::ERROR_WANT_READ(), "read err $err is not retryable WANT_READ");
    isnt($err, Net::SSLeay::ERROR_WANT_WRITE(), "read err $err is not retryable WANT_WRITE");

    $ret = Net::SSLeay::pending($ssl);
    is($ret, 0, "pending returns 0 for closed ssl");

    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::connect($ssl);

    # msg1
    $ret = Net::SSLeay::pending($ssl);
    is($ret, 0, "pending returns 0");

    $peek_msg = Net::SSLeay::peek($ssl);
    is($peek_msg, $msg1, "scalar: peek returns msg1");

    # processing was triggered by peek
    $ret = Net::SSLeay::pending($ssl);
    is($ret, length($msg1), "pending returns msg1 length");

    ($peek_msg, $len) = Net::SSLeay::peek($ssl);
    is($peek_msg, $msg1, "list: peek returns msg1");
    is($len, length($msg1), "list: peek returns msg1 length");

    $read_msg = Net::SSLeay::read($ssl);
    is($peek_msg, $read_msg, "scalar: read and peek agree about msg1");

    # msg2
    $peek_msg = Net::SSLeay::peek($ssl);
    is($peek_msg, $msg2, "scalar: peek returns msg2");

    ($read_msg, $len) = Net::SSLeay::read($ssl);
    is($peek_msg, $read_msg, "list: read and peek agree about msg2");
    is($len, length($msg2), "list: read returns msg2 length");

    # msg3
    Net::SSLeay::write($ssl, $msg3);
    is(Net::SSLeay::read($ssl), $msg3, "ping with msg3");

    return;
}

# Test has_pending and other functionality added in 1.1.0.
# Revisit: Better tests for has_pending
sub round_openssl_1_1_0
{
    my ($ctx, $ssl, $cl) = @_;

    my ($peek_msg, $read_msg, $len, $err, $ret);

    # ssl is not connected yet
    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 0, "1.1.0: has_pending returns 0 for closed ssl");

    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::connect($ssl);

    # msg1
    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 0, "1.1.0: has_pending returns 0");

    # This triggers processing after which we have pending data
    $peek_msg = Net::SSLeay::peek($ssl);
    is($peek_msg, $msg1, "1.1.0: peek returns msg1");

    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 1, "1.1.0: has_pending returns 1");

    Net::SSLeay::read($ssl); # Read and discard

    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 0, "1.1.0: has_pending returns 0 after read");

    # msg2
    Net::SSLeay::read($ssl); # Read and discard

    # msg3
    Net::SSLeay::write($ssl, $msg3);
    is(Net::SSLeay::read($ssl), $msg3, "1.1.0: ping with msg3");

    return;
}

sub round_openssl_1_1_1
{
    my ($ctx, $ssl, $cl) = @_;

    my ($peek_msg, $read_msg, $len, $err, $err_ex, $ret);

    # ssl is not connected yet
    ($peek_msg, $ret) = Net::SSLeay::peek_ex($ssl);
    is($peek_msg, undef, "1.1.1: list: peek_ex returns undef message for closed ssl");
    is($ret, 0, '1.1.1: list: peek_ex returns 0 for closed ssl');
    $err = Net::SSLeay::get_error($ssl, $ret);
    isnt($err, Net::SSLeay::ERROR_WANT_READ(), "1.1.1: peek_ex err $err is not retryable WANT_READ");
    isnt($err, Net::SSLeay::ERROR_WANT_WRITE(), "1.1.1: peek_ex err $err is not retryable WANT_WRITE");

    ($read_msg, $len) = Net::SSLeay::read($ssl);
    is($read_msg, undef, "1.1.1: list: read returns undef message for closed ssl");
    cmp_ok($len, '<=', 0, '1.1.1: list: read returns length <=0 for closed ssl');
    $err = Net::SSLeay::get_error($ssl, $len);
    isnt($err, Net::SSLeay::ERROR_WANT_READ(), "1.1.1: read err $err is not retryable WANT_READ");
    isnt($err, Net::SSLeay::ERROR_WANT_WRITE(), "1.1.1: read err $err is not retryable WANT_WRITE");

    ($read_msg, $ret) = Net::SSLeay::read_ex($ssl);
    is($read_msg, undef, "1.1.1: list: read_ex returns undef message for closed sssl");
    is($ret, 0, "1.1.1: list: read_ex returns 0 for closed sssl");
    $err_ex = Net::SSLeay::get_error($ssl, $ret);
    is ($err_ex, $err, '1.1.1: read_ex and read err are equal');

    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::connect($ssl);

    # msg1
    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 0, "1.1.1: has_pending returns 0");

    # This triggers processing after which we have pending data
    ($peek_msg, $ret) = Net::SSLeay::peek_ex($ssl);
    is($peek_msg, $msg1, "1.1.1: list: peek_ex returns msg1");
    is($ret, 1, "1.1.1: list: peek_ex returns 1");

    $len = Net::SSLeay::pending($ssl);
    is($len, length($msg1), "1.1.1: pending returns msg1 length");

    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 1, "1.1.1: has_pending returns 1");

    ($read_msg, $ret) = Net::SSLeay::read_ex($ssl);
    is($read_msg, $msg1, "1.1.1: list: read_ex returns msg1");
    is($ret, 1, "1.1.1: list: read_ex returns 1");

    $len = Net::SSLeay::pending($ssl);
    is($len, 0, "1.1.1: pending returns 0 after read_ex");

    $ret = Net::SSLeay::has_pending($ssl);
    is($ret, 0, "1.1.1: has_pending returns 0 after read_ex");

    # msg2
    Net::SSLeay::read($ssl); # Read and discard

    # msg3
    ($len, $ret) = Net::SSLeay::write_ex($ssl, $msg3);
    is($len, length($msg3), "1.1.1: write_ex wrote all");
    is($ret, 1, "1.1.1: write_ex returns 1");

    my ($read_msg1, $ret1) = Net::SSLeay::read_ex($ssl, 5);
    my ($read_msg2, $ret2) = Net::SSLeay::read_ex($ssl, (length($msg3) - 5));

    is($ret1, 1, '1.1.1: ping with msg3 part1 ok');
    is($ret2, 1, '1.1.1: ping with msg3 part2 ok');
    is(length($read_msg1), 5, '1.1.1: ping with msg3, part1 length was 5');
    is($read_msg1 . $read_msg2, $msg3, "1.1.1: ping with msg3 in two parts");

    return;
}

server();
client();
waitpid $pid, 0;
exit(0);
