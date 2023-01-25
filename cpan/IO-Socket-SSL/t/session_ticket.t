use strict;
use warnings;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
use Test::More;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";


$|=1;
plan skip_all => 'no support for session ticket key callback'
    if ! IO::Socket::SSL->can_ticket_keycb;

plan tests => 6;

# create two servers with the same session ticket callback
my (@server,@saddr);
for (1,2) {
    my $server = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Listen => 2,
    ) or die "failed to create listener: $!";
    push @server,{ fd => $server };
    push @saddr, $server->sockhost.':'.$server->sockport;
    diag("listen at $saddr[-1]");
}

# create some self signed certificate
my ($cert,$key) = CERT_create(CA => 1,
    subject => { CN => 'ca' },
);
my ($client_cert,$client_key) = CERT_create(
    issuer => [ $cert,$key],
    subject => { CN => 'client' },
    purpose => { client => 1 }
);
my ($server_cert,$server_key) = CERT_create(
    issuer => [ $cert,$key],
    subject => { CN => 'server' },
    subjectAltNames => [
	[ DNS => 'server' ],
	[ IP => $saddr[0]=~m{^(.*):} && $1 ],
	[ IP => $saddr[1]=~m{^(.*):} && $1 ],
    ],
    purpose => { server => 1 }
);


defined( my $pid = fork() ) || die $!;
exit(_server()) if ! $pid;
@server = ();



# if anything blocks - this will at least finish the test
alarm(60);
$SIG{ALRM} = sub { die "test takes too long" };
END{ kill 9,$pid if $pid };

my $clctx = IO::Socket::SSL::SSL_Context->new(
    SSL_session_cache_size => 10,
    SSL_cert => $client_cert,
    SSL_key => $client_key,
    SSL_ca => [ $cert ],

    # LibreSSL has currently no support for TLS 1.3 session handling
    # therefore enforce TLS 1.2
    Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER") ?
	(SSL_version => 'TLSv1_2') :
    # versions of Net::SSLeay with support for SESSION_up_ref have also the
    # other functionality needed for proper TLS 1.3 session handling
    defined(&Net::SSLeay::SESSION_up_ref) ? ()
	: (SSL_version => 'SSLv23:!TLSv1_3:!SSLv3:!SSLv2'),
);

my $client = sub {
    my ($i,$expect_reuse,$desc) = @_;
    my $cl = IO::Socket::SSL->new(
	PeerAddr => $saddr[$i],
	SSL_reuse_ctx => $clctx,
	SSL_session_key => 'server', # single key for both @saddr
    );
    <$cl>; # read something, incl. TLS 1.3 ticket
    my $reuse = $cl && Net::SSLeay::session_reused($cl->_get_ssl_object);
    diag("connect to $i: ".  ($cl
	? "success reuse=$reuse version=".$cl->get_sslversion()
	: "error: $!,$SSL_ERROR"
    ));
    is($reuse,$expect_reuse,$desc);
    close($cl);
};


$client->(0,0,"no initial session -> no reuse");
$client->(0,1,"reuse with the next session and secret[0]");
$client->(1,1,"reuse even though server changed, since they share ticket secret");
$client->(1,0,"reports non-reuse since server1 changed secret to secret[1]");
$client->(0,0,"reports non-reuse on server0 since got ticket with secret[1] in last step");
$client->(0,1,"reuse again since got ticket with secret[0] in last step");


sub _server {

    # create the secrets for handling session tickets
    my @secrets;
    for(qw(key1 key2)) {
	my $name = pack("a16",$_);
	Net::SSLeay::RAND_bytes(my $key,32);
	push @secrets, [ $key,$name ];
    }

    my $get_ticket_key = sub {
	my (undef,$name) = @_;
	if (!defined $name) {
	    print "creating new ticket $secrets[0][1]\n";
	    return @{$secrets[0]};
	}
	for(my $i=0;$i<@secrets;$i++) {
	    next if $secrets[$i][1] ne $name;
	    if ($i == 0) {
		print "using current ticket secret\n";
		return @{$secrets[0]};
	    } else {
		print "using non-current ticket secret\n";
		return ($secrets[0][0],$secrets[$i][1]);
	    }
	}
	print "unknown ticket key name\n";
	return;
    };

    # create the SSL context
    for(@server) {
	$_->{sslctx} = IO::Socket::SSL::SSL_Context->new(
	    SSL_server => 1,
	    SSL_cert => $server_cert,
	    SSL_key => $server_key,
	    SSL_ca => [ $cert ],
	    SSL_verify_mode => SSL_VERIFY_PEER|SSL_VERIFY_FAIL_IF_NO_PEER_CERT,
	    SSL_ticket_keycb => $get_ticket_key,
	    SSL_session_id_context => 'foobar',
	) or die "failed to create SSL context: $SSL_ERROR";
    }

    my $rin = '';
    vec($rin,fileno($_->{fd}),1) = 1 for @server;
    while (1) {	
	select(my $rout = $rin,undef,undef,10)
	    or die "select failed or timed out: $!";
	for(my $i=0;$i<@server;$i++) {
	    next if ! vec($rout,fileno($server[$i]{fd}),1);

	    alarm(10);
	    local $SIG{ALRM} = sub { die "server[$i] timed out" };
	    print "access to server[$i]\n";

	    my $cl = $server[$i]{fd}->accept or do {
		print "failed to TCP accept: $!\n";
		last;
	    };
	    IO::Socket::SSL->start_SSL($cl, 
		SSL_server => 1, 
		SSL_reuse_ctx => $server[$i]{sslctx}
	    ) or do {
		print "failed to SSL accept: $SSL_ERROR\n";
		last;
	    };

	    print $cl "hi\n";
	    my $reuse = Net::SSLeay::session_reused($cl->_get_ssl_object);
	    print "server[$i] reused=$reuse\n";

	    # after access to server[1] rotate the secrets 
	    if ($i == 1) {
		print "rotate secrets\n";
		push @secrets, shift(@secrets);
	    }
	    close($cl);
	    alarm(0);
	    last;
	}
    }
    exit(0);
}
