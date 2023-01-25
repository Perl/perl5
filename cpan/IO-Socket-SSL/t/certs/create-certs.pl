use strict;
use warnings;
use IO::Socket::SSL::Utils;
use Net::SSLeay;

my $dir = "./";
my $now = time();
my $later = $now + 10*365*86400;

Net::SSLeay::SSLeay_add_ssl_algorithms();
my $sha256 = Net::SSLeay::EVP_get_digestbyname('sha256') or die;
my $printfp = sub {
    my ($w,$cert) = @_;
    print $w.' sha256$'.unpack('H*',Net::SSLeay::X509_digest($cert, $sha256))."\n"
};

my %time_valid = (not_before => $now, not_after => $later);

my @ca = CERT_create(
    CA => 1,
    subject => { CN => 'IO::Socket::SSL Demo CA' },
    %time_valid,
);
save('test-ca.pem',PEM_cert2string($ca[0]));

my @server = CERT_create(
    CA => 0,
    subject => { CN => 'server.local' },
    subjectAltNames => [ [ DNS => 'server.local' ], [ IP => '127.0.0.1' ] ],
    purpose => 'server',
    issuer => \@ca,
    %time_valid,
);
save('server-cert.pem',PEM_cert2string($server[0]));
save('server-key.pem',PEM_key2string($server[1]));
$printfp->(server => $server[0]);

@server = CERT_create(
    CA => 0,
    subject => { CN => 'server2.local' },
    subjectAltNames => [ [ DNS => 'server2.local' ], [ IP => '127.0.0.1' ] ],
    purpose => 'server',
    issuer => \@ca,
    %time_valid,
);
save('server2-cert.pem',PEM_cert2string($server[0]));
save('server2-key.pem',PEM_key2string($server[1]));
$printfp->(server2 => $server[0]);

@server = CERT_create(
    CA => 0,
    subject => { CN => 'server-ecc.local' },
    subjectAltNames => [ [ DNS => 'server-ecc.local' ], [ IP => '127.0.0.1' ] ],
    purpose => 'server',
    issuer => \@ca,
    key => KEY_create_ec(),
    %time_valid,
);
save('server-ecc-cert.pem',PEM_cert2string($server[0]));
save('server-ecc-key.pem',PEM_key2string($server[1]));
$printfp->('server-ecc' => $server[0]);


my @client = CERT_create(
    CA => 0,
    subject => { CN => 'client.local' },
    purpose => 'client',
    issuer => \@ca,
    %time_valid,
);
save('client-cert.pem',PEM_cert2string($client[0]));
save('client-key.pem',PEM_key2string($client[1]));
$printfp->(client => $client[0]);

my @swc = CERT_create(
    CA => 0,
    subject => { CN => 'server.local' },
    purpose => 'server',
    issuer => \@ca,
    subjectAltNames => [ 
	[ DNS => '*.server.local' ],
	[ IP => '127.0.0.1' ],
	[ DNS => 'www*.other.local' ],
	[ DNS => 'smtp.mydomain.local' ],
	[ DNS => 'xn--lwe-sna.idntest.local' ]
    ],
    %time_valid,
);
save('server-wildcard.pem',PEM_cert2string($swc[0]),PEM_key2string($swc[1]));


my @subca = CERT_create(
    CA => 1,
    issuer => \@ca,
    subject => { CN => 'IO::Socket::SSL Demo Sub CA' },
    %time_valid,
);
save('test-subca.pem',PEM_cert2string($subca[0]));
@server = CERT_create(
    CA => 0,
    subject => { CN => 'server.local' },
    subjectAltNames => [ [ DNS => 'server.local' ], [ IP => '127.0.0.1' ] ],
    purpose => 'server',
    issuer => \@subca,
    %time_valid,
);
save('sub-server.pem',PEM_cert2string($server[0]).PEM_key2string($server[1]));



my @cap = CERT_create(
    CA => 1,
    subject => { CN => 'IO::Socket::SSL::Intercept' },
    %time_valid,
);
save('proxyca.pem',PEM_cert2string($cap[0]).PEM_key2string($cap[1]));

sub save {
    my $file = shift;
    open(my $fd,'>',$dir.$file) or die $!;
    print $fd @_;
}

system(<<CMD);
cd $dir
set -x
openssl x509 -in server-cert.pem -out server-cert.der -outform der
openssl rsa -in server-key.pem -out server-key.der -outform der
openssl rsa -in server-key.pem -out server-key.enc -passout pass:bluebell
openssl rsa -in client-key.pem -out client-key.enc -passout pass:opossum
openssl pkcs12 -export -in server-cert.pem -inkey server-key.pem -out server.p12 -descert -passout pass:
openssl pkcs12 -export -in server-cert.pem -inkey server-key.pem -out server_enc.p12 -descert -passout pass:bluebell
CMD
