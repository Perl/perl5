#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

if ( ! IO::Socket::SSL->can_server_sni()
    or ! IO::Socket::SSL->can_client_sni()) {
    print "1..0 # skipped because no full SNI support - openssl/Net::SSleay too old\n";
    exit;
}

if ( ! IO::Socket::SSL->can_multi_cert() ) {
    print "1..0 # no support for multiple certificate types\n";
    exit;
}

print "1..12\n";

my %certs = (
    SSL_cert_file => {
	'' => 't/certs/server-cert.pem',
	'%ecc' => "t/certs/server-ecc-cert.pem",
	'server2.local' => 't/certs/server2-cert.pem',
    },
    SSL_key_file => {
	'' => 't/certs/server-key.pem',
	'%ecc' => 't/certs/server-ecc-key.pem',
	'server2.local' => 't/certs/server2-key.pem',
    }
);

my (%k2fp,%fp2k);
Net::SSLeay::SSLeay_add_ssl_algorithms();
my $sha256 = Net::SSLeay::EVP_get_digestbyname('sha256') or die;
for (keys %{ $certs{SSL_cert_file} }) {
    my $cert = PEM_file2cert($certs{SSL_cert_file}{$_});
    my $fp = 'sha256$'.unpack('H*',Net::SSLeay::X509_digest($cert, $sha256));
    $k2fp{$_} = $fp;
    $fp2k{$fp} = $_;
}

my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    Listen => 2,
    ReuseAddr => 1,
    SSL_server => 1,
    SSL_ca_file => "t/certs/test-ca.pem",
    SSL_honor_cipher_order => 0,
    SSL_cipher_list => 'ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA',
    %certs,
);

warn "\$!=$!, \$\@=$@, S\$SSL_ERROR=$SSL_ERROR" if ! $server;
print "not ok\n", exit if !$server;
print "ok # Server Initialization\n";
my $saddr = $server->sockhost.':'.$server->sockport;

my @tests = (
    [ 'foo.bar', 'ECDHE-ECDSA-AES128-SHA', '%ecc' ],
    [ 'foo.bar', 'ECDHE-RSA-AES128-SHA', '' ],
    [ 'foo.bar', 'ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA', '' ],
    [ 'foo.bar', 'ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA', '%ecc' ],
    [ 'server2.local', 'ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA', 'server2.local' ],
    [ 'server2.local', 'ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA', 'server2.local' ],
    [ 'server2.local', 'ECDHE-ECDSA-AES128-SHA', 'FAIL' ],
    [ undef, 'ECDHE-ECDSA-AES128-SHA', '%ecc' ],
    [ undef, 'ECDHE-RSA-AES128-SHA', '' ],
    [ undef, 'ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA', '' ],
    [ undef, 'ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA', '%ecc' ],
);

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {
    close($server);

    for my $test (@tests) {
	my ($host,$ciphers,$expect) = @$test;
	my $what = ($host || '<no-sni>'). " $ciphers | expect='$expect'";
	my $client = IO::Socket::SSL->new(
	    PeerAddr => $saddr,
	    Domain => AF_INET,
	    SSL_verify_mode => 0,
	    SSL_hostname => $host,
	    SSL_ca_file => 't/certs/test-ca.pem',
	    SSL_cipher_list => $ciphers,
	    # don't use TLS 1.3 since the ciphers there don't specifify the
	    # authentication mechanism
	    SSL_version => 'SSLv23:!TLSv1_3',
	);

	my $fp = $client ? $fp2k{$client->get_fingerprint('sha256')} : 'FAIL';
	$fp = '???' if ! defined $fp;
	my $cipher = $client ? $client->get_cipher() : '';
	print "not " if $fp ne $expect;
	print "ok # fingerprint match - $what - got='$fp' -- $cipher\n";
    }
    exit;
}

for my $host (@tests) {
    $server->accept or next;
}
wait;
