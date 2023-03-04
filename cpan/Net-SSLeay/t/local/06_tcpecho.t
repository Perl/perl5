use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( can_fork initialise_libssl tcp_socket );

BEGIN {
    if (not can_fork()) {
        plan skip_all => "fork() not supported on this system";
    } else {
        plan tests => 4;
    }
}

initialise_libssl();

my $server = tcp_socket();
my $msg = 'ssleay-tcp-test';

my $pid;

{
    $pid = fork();
    die  "fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        $server->accept(\*Net::SSLeay::SSLCAT_S);

        my $got = Net::SSLeay::tcp_read_all();
        is($got, $msg, 'tcp_read_all');

        ok(Net::SSLeay::tcp_write_all(uc($got)), 'tcp_write_all');

        close Net::SSLeay::SSLCAT_S;
        $server->close() || die("server listen socket close: $!");

        exit;
    }
}

my @results;
{
    my ($got) = Net::SSLeay::tcpcat($server->get_addr(), $server->get_port(), $msg);
    push @results, [ $got eq uc($msg), 'sent and received correctly' ];
}

$server->close() || die("client listen socket close: $!");

waitpid $pid, 0;
push @results, [ $? == 0, 'server exited with 0' ];

END {
    Test::More->builder->current_test(2);
    for my $t (@results) {
        ok( $t->[0], $t->[1] );
    }
}
