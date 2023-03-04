use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl new_ctx tcp_socket
);

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} else {
    plan tests => 10;
}

initialise_libssl();

my $pid;
alarm(30);
END { kill 9,$pid if $pid }

my $server = tcp_socket();

{
    # SSL server - just handle single connect and  shutdown connection
    my $cert_pem = data_file_path('simple-cert.cert.pem');
    my $key_pem  = data_file_path('simple-cert.key.pem');

    defined($pid = fork()) or BAIL_OUT("failed to fork: $!");
    if ($pid == 0) {
	for(qw(ctx ssl)) {
	    my $cl = $server->accept();
	    my $ctx = new_ctx();
	    Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);
	    my $ssl = Net::SSLeay::new($ctx);
	    Net::SSLeay::set_fd($ssl, fileno($cl));
	    Net::SSLeay::accept($ssl);
	    for(1,2) {
		last if Net::SSLeay::shutdown($ssl)>0;
	    }
	    close($cl) || die("server close: $!");
	}
	$server->close() || die("server listen socket close: $!");
        exit;
    }
}

sub client {
    my ($where) = @_;
    # SSL client - connect and shutdown, all the while getting state updates
    #  with info callback

    my @cb_data;
    my @states;
    my $msgcb = sub {
        my ($write_p,$version,$content_type,$buf,$len,$ssl,$cb_data) = @_;
        # buffer is of course randomized/timestamped, this is hard to test, so
        # skip this
        my $hex_buf = unpack("H*", $buf||'');

        # version appears to be different running in different test envs that
        # have a different openssl version, so we skip that too. This isn't a
        # good test for that, and it's not up to Net::SSLeay to make all
        # openssl implementations look the same

        # the 3 things this sub needs to do:
        #  1. not die
        #  2. no memory leak
        #  3. provide information
        #
        # The validness of the buffer can be checked, so we use this as a
        # validation instead. This selftest is not here to validate the
        # protocol and the intricacies of the possible implementation or 
        # version (ssl3 vs tls1 etc)

        push @states,(defined $buf and length($buf) == $len)||0;

        # cb_data can act as a check
        push @cb_data, $cb_data;
    };

    my $cl = $server->connect();
    my $ctx = new_ctx();
    Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
    Net::SSLeay::CTX_set_msg_callback($ctx, $msgcb, "CB_DATA") if $where eq 'ctx';
    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::set_msg_callback($ssl, $msgcb, "CB_DATA") if $where eq 'ssl';
    Net::SSLeay::connect($ssl);
    for(1,2) {
	last if Net::SSLeay::shutdown($ssl)>0;
    }
    close($cl) || die("client close: $!");

    ok(scalar(@states) > 1, "at least 2 messages logged: $where");
    my $all_ok = 1;
    $all_ok &= $_ for @states;
    is($all_ok, 1, "all states are OK: length(buf) = len for $where");

    ok(scalar(@cb_data) > 1, "all cb data SV's are OK for $where (at least 2)");
    my $all_cb_data_ok = 0;
    $all_cb_data_ok++ for grep {$_ eq "CB_DATA"} grep {defined} @cb_data;
    is(scalar(@cb_data), $all_cb_data_ok, "all cb data SV's are OK for $where");

    eval {
        Net::SSLeay::CTX_set_msg_callback($ctx, undef) if $where eq 'ctx';
        Net::SSLeay::set_msg_callback($ssl, undef) if $where eq 'ssl';
    };
    is($@, '', "no error during set_msg_callback() for $where");
}

client('ctx');
client('ssl');
$server->close() || die("client listen socket close: $!");
waitpid $pid, 0;

