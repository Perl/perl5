use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl new_ctx tcp_socket
);

if (not can_fork()) {
    plan skip_all => "fork() not supported on this system";
} else {
    plan tests => 2;
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
    my ($where,$expect) = @_;
    # SSL client - connect and shutdown, all the while getting state updates
    #  with info callback

    my @states;
    my $infocb = sub {
	my ($ssl,$where,$ret) = @_;
	push @states,[$where,$ret];
    };

    my $cl = $server->connect();
    my $ctx = new_ctx();
    Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
    Net::SSLeay::CTX_set_info_callback($ctx, $infocb) if $where eq 'ctx';
    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, $cl);
    Net::SSLeay::set_info_callback($ssl, $infocb) if $where eq 'ssl';
    Net::SSLeay::connect($ssl);
    for(1,2) {
	last if Net::SSLeay::shutdown($ssl)>0;
    }

    for my $st (@states) {
	my @txt;
	for(qw(
	    CB_READ_ALERT CB_WRITE_ALERT
	    CB_ACCEPT_EXIT CB_ACCEPT_LOOP
	    CB_CONNECT_EXIT CB_CONNECT_LOOP
	    CB_HANDSHAKE_START CB_HANDSHAKE_DONE
	    CB_READ CB_WRITE CB_ALERT
	    CB_LOOP CB_EXIT
	)) {
	    my $i = eval "Net::SSLeay::$_()" 
		or BAIL_OUT("no state $_ known");
	    if (($st->[0] & $i) == $i) {
		$st->[0] &= ~$i;
		push @txt,$_;
	    }
	}
	die "incomplete: @txt | $st->[0]" if $st->[0];
	$st = join("|",@txt);
    }

    if ("@states" =~ $expect) {
	pass("$where: @states");
    } else {
	fail("$where: @states");
    }
    close($cl) || die("client close: $!");

}

my $expect = qr{^
    CB_HANDSHAKE_START\s
    (CB_CONNECT_LOOP\s)+ 
    CB_HANDSHAKE_DONE\s
    CB_CONNECT_EXIT\b
}x;

client('ctx',$expect);
client('ssl',$expect);
$server->close() || die("client listen socket close: $!");
waitpid $pid, 0;

