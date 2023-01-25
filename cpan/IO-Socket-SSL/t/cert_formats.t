use strict;
use warnings;
use Test::More;
use IO::Socket::SSL;
use File::Temp 'tempfile';
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

my $srv = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    Listen => 10,
);
plan skip_all => "server creation failed: $!" if ! $srv;
my $saddr = $srv->sockhost.':'.$srv->sockport;

my ($fh,$pemfile) = tempfile();
my $master = $$;
END { unlink($pemfile) if $$ == $master };
for ('t/certs/server-cert.pem','t/certs/server-key.pem') {
    open( my $pf,'<',$_ ) or die "open $_: $!";
    print $fh do { local $/; <$pf> };
}
close($fh);

my @tests = (
    'PEM' => {
	SSL_cert_file => 't/certs/server-cert.pem',
	SSL_key_file => 't/certs/server-key.pem',
    },
    'PEM_one_file' => {
	SSL_cert_file => $pemfile,
    },
    'PEM_keyenc' => {
	SSL_cert_file => 't/certs/server-cert.pem',
	SSL_key_file => 't/certs/server-key.enc',
	SSL_passwd_cb => sub { "bluebell" },
    },
    'DER' => {
	SSL_cert_file => 't/certs/server-cert.der',
	SSL_key_file => 't/certs/server-key.der',
    },
    'PKCS12' => {
	SSL_cert_file => 't/certs/server.p12',
    },
    'PKCS12_enc' => {
	SSL_cert_file => 't/certs/server_enc.p12',
	SSL_passwd_cb => sub { "bluebell" },
    },
);
plan tests => @tests/2;

while (my ($name,$sslargs) = splice(@tests,0,2)) {
    defined(my $pid = fork()) or die "fork failed: $!";
    if ($pid == 0) {
	# child = server
	my $cl = $srv->accept or die "accept $!";
	if (!IO::Socket::SSL->start_SSL($cl,
	    SSL_server => 1,
	    Timeout => 10,
	    %$sslargs
	)) {
	    diag("start_SSL failed: $SSL_ERROR");
	}
	exit(0);
    } else {
	# parent = client
	my $cl = IO::Socket::INET->new($saddr) or die "connect: $!";
	if (!IO::Socket::SSL->start_SSL($cl,
	    SSL_verify_mode => 0
	)) {
	    fail("[$name] ssl connect failed: $SSL_ERROR");
	} else {
	    pass("[$name] ssl connect success");
	}
	wait;
    }
}
