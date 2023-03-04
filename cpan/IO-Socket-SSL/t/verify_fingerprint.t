use strict;
use warnings;
use Test::More;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
use File::Temp 'tempfile';
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

plan tests => 13;

my ($ca1,$cakey1) = CERT_create( CA => 1, subject => { CN => 'ca1' });
my ($cert1,$key1) = CERT_create( 
    subject => { CN => 'cert1' },
    subjectAltNames => [ [ DNS => 'cert1' ], [ IP => '127.0.0.1' ] ],
    issuer => [ $ca1,$cakey1 ]
);
my ($ca2,$cakey2) = CERT_create( CA => 1, subject => { CN => 'ca2' });
my ($ica2,$icakey2) = CERT_create(
    CA => 1,
    subject => { CN => 'ica2' },
    issuer => [ $ca2,$cakey2 ]
);
my ($cert2,$key2) = CERT_create( 
    subject => { CN => 'cert2' },
    subjectAltNames => [ [ DNS => 'cert2' ], [ IP => '127.0.0.1' ] ],
    issuer => [ $ica2,$icakey2 ]
);

my ($saddr1,$fp1) = _server([$cert1],$key1);
my ($saddr2,$fp2,$ifp2) = _server([$cert2,$ica2],$key2);
my $fp1pub = $fp1->[1];
$_ = $_->[0] for($fp1,$fp2,$ifp2);

for my $test (
    [ $saddr1, undef, $fp1, "accept fp1 for saddr1", 1 ],
    [ $saddr1, undef, $fp1pub, "accept fp1 pubkey for saddr1", 1 ],
    [ $saddr2, undef, $fp2, "accept fp2 for saddr2", 1 ],
    [ $saddr2, undef, $ifp2, "reject ifp2 for saddr2", 0 ],
    [ $saddr1, undef, $fp2, "reject fp2 for saddr1", 0 ],
    [ $saddr2, undef, $fp1, "reject fp1 for saddr2", 0 ],
    [ $saddr1, undef, [$fp1,$fp2], "accept fp1|fp2 for saddr1", 1 ],
    [ $saddr2, undef, [$fp1,$fp2], "accept fp1|fp2 for saddr2", 1 ],
    [ $saddr2, [$ca1],  $fp2, "accept fp2 for saddr2 even if ca1 given", 1 ],
    [ $saddr2, [$ca2], undef, "accept ca2 for saddr2", 1 ],
    [ $saddr1, [$ca2], undef, "reject ca2 for saddr1", 0 ],
    [ $saddr1, [$ca1,$ca2], undef, "accept ca[12] for saddr1", 1 ],
    (defined &Net::SSLeay::X509_V_FLAG_PARTIAL_CHAIN ?
	[ $saddr1, [$cert1], undef, "accept leaf cert1 as trust anchor for saddr1", 1 ] :
	[ $saddr1, [$cert1], undef, "reject leaf cert1 as trust anchor for saddr1", 0 ]
    )
) {
    my ($saddr,$certs,$fp,$what,$expect) = @$test;
    my $cafile;
    my $cl = IO::Socket::INET->new( $saddr ) or die $!;
    syswrite($cl,"X",1);
    my $ok = IO::Socket::SSL->start_SSL($cl,
	SSL_verify_mode => 1,
	SSL_fingerprint => $fp,
	SSL_ca => $certs,
	SSL_ca_file => undef,
	SSL_ca_path => undef,
    );
    ok( ($ok?1:0) == ($expect?1:0),$what);
}

# Notify server children to exit by connecting and disconnecting immediately,
# kill only if they will not exit.
alarm(10);
my @child;
END { kill 9,@child }
IO::Socket::INET->new($saddr1);
IO::Socket::INET->new($saddr2);
while ( @child && ( my $pid = waitpid(-1,0))>0 ) {
    @child = grep { $_ != $pid } @child
}


sub _server {
    my ($certs,$key) = @_;
    my $sock = IO::Socket::INET->new( LocalAddr => '0.0.0.0', Listen => 10 )
	or die $!;
    defined( my $pid = fork()) or die $!;
    if ( $pid ) {
	push @child,$pid;
	my $saddr = '127.0.0.1:'.$sock->sockport;
	close($sock);
	return (
	    $saddr,
	    map { [ 
		'sha1$'.Net::SSLeay::X509_get_fingerprint($_,'sha1'),
		'sha1$pub$'.unpack("H*",Net::SSLeay::X509_pubkey_digest($_,
		    Net::SSLeay::EVP_get_digestbyname('sha1')))
	    ]} @$certs
	);
    }

    # The chain certificates will be added without increasing reference counter
    # and will be destroyed at close of context, so we better have a common
    # context between all start_SSL.
    my $ctx = IO::Socket::SSL::SSL_Context->new(
	SSL_server => 1,
	SSL_cert  => $certs,
	SSL_key   => $key
    );
    while (1) {
	#local $IO::Socket::SSL::DEBUG=10;
	my $cl = $sock->accept or next;
	sysread($cl,my $buf,1) || last;
	IO::Socket::SSL->start_SSL($cl,
	    SSL_server => 1,
	    SSL_reuse_ctx => $ctx,
	);
    }
    exit(0);
}
