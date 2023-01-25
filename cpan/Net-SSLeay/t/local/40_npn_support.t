use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(
    can_fork data_file_path initialise_libssl new_ctx tcp_socket
);

BEGIN {
    if (Net::SSLeay::SSLeay < 0x10001000) {
        plan skip_all => "OpenSSL 1.0.1 or above required";
    } elsif (Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER")) {
        plan skip_all => "LibreSSL removed support for NPN";
    } elsif (not can_fork()) {
        plan skip_all => "fork() not supported on this system";
    } elsif ( !eval { new_ctx( undef, 'TLSv1.2' ); 1 } ) {
        # NPN isn't well-defined for TLSv1.3, so these tests can't be run if
        # that's the only available protocol version
        plan skip_all => 'TLSv1.2 or below not available in this libssl';
    } else {
        plan tests => 7;
    }
}

initialise_libssl();

my $server = tcp_socket();
my $msg = 'ssleay-npn-test';

my $pid;

my $cert_pem = data_file_path('simple-cert.cert.pem');
my $key_pem  = data_file_path('simple-cert.key.pem');

my @results;

{
    # SSL server
    $pid = fork();
    BAIL_OUT("failed to fork: $!") unless defined $pid;
    if ($pid == 0) {
        my $ns = $server->accept();

        my ( $ctx, $proto ) = new_ctx( undef, 'TLSv1.2' );
        Net::SSLeay::set_cert_and_key($ctx, $cert_pem, $key_pem);

        my $rv = Net::SSLeay::CTX_set_next_protos_advertised_cb($ctx, ['spdy/2','http1.1']);
        is($rv, 1, 'CTX_set_next_protos_advertised_cb');

        my $ssl = Net::SSLeay::new($ctx);
        Net::SSLeay::set_fd($ssl, fileno($ns));
        Net::SSLeay::accept($ssl);

        is('spdy/2' , Net::SSLeay::P_next_proto_negotiated($ssl), 'P_next_proto_negotiated/server');

        my $got = Net::SSLeay::ssl_read_all($ssl);
        is($got, $msg, 'ssl_read_all compare');

        Net::SSLeay::ssl_write_all($ssl, uc($got));
        Net::SSLeay::free($ssl);
        Net::SSLeay::CTX_free($ctx);
        close($ns) || die("server close: $!");
        $server->close() || die("server listen socket close: $!");
        exit;
    }
}

{
    # SSL client
    my $s1 = $server->connect();

    my $ctx1 = new_ctx( undef, 'TLSv1.2' );

    my $rv = Net::SSLeay::CTX_set_next_proto_select_cb($ctx1, ['http1.1','spdy/2']);
    push @results, [ $rv==1, 'CTX_set_next_proto_select_cb'];

    Net::SSLeay::CTX_set_options($ctx1, &Net::SSLeay::OP_ALL);
    my $ssl1 = Net::SSLeay::new($ctx1);
    Net::SSLeay::set_fd($ssl1, $s1);
    Net::SSLeay::connect($ssl1);
    Net::SSLeay::ssl_write_all($ssl1, $msg);

    push @results, [ 'spdy/2' eq Net::SSLeay::P_next_proto_negotiated($ssl1), 'P_next_proto_negotiated/client'];
    push @results, [ 1 == Net::SSLeay::P_next_proto_last_status($ssl1), 'P_next_proto_last_status/client'];

    Net::SSLeay::free($ssl1);
    Net::SSLeay::CTX_free($ctx1);
    close($s1) || die("client close: $!");
    $server->close() || die("client listen socket close: $!");
}

waitpid $pid, 0;
push @results, [$? == 0, 'server exited with 0'];
END {
  Test::More->builder->current_test(3);
  ok( $_->[0], $_->[1] ) for (@results);
}
