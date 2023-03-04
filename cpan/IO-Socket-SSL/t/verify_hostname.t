#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

# if we have an IDN library max the IDN tests too
my $can_idn  = eval { require Encode } && (
    eval { require Net::LibIDN }
    || eval { require Net::IDN::Encode }
    || eval { require URI; URI->VERSION(1.50) }
);

$|=1;
my $max = 42;
$max+=3 if $can_idn;
print "1..$max\n";

my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    ReuseAddr => 1,
);
warn "\$!=$!, \$\@=$@, S\$SSL_ERROR=$SSL_ERROR" if ! $server;
print "not ok\n", exit if !$server;
ok("Server Initialization");
my $saddr = $server->sockhost.':'.$server->sockport;

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {
    close($server);
    my $client = IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_verify_mode => 0
    ) || print "not ";
    ok( "client ssl connect" );

    my $issuer = $client->peer_certificate( 'issuer' );
    print "not " if $issuer !~m{IO::Socket::SSL Demo CA};
    ok("issuer");

    my $cn = $client->peer_certificate( 'cn' );
    print "not " unless $cn eq "server.local";
    ok("cn");

    my @alt = $client->peer_certificate( 'subjectAltNames' );
    my @want = (
	GEN_DNS() => '*.server.local',
	GEN_IPADD() => '127.0.0.1',
	GEN_DNS() => 'www*.other.local',
	GEN_DNS() => 'smtp.mydomain.local',
	GEN_DNS() => 'xn--lwe-sna.idntest.local',
    );
    while (@want) {
	my ($typ,$text) = splice(@want,0,2);
	my $data = ($typ == GEN_IPADD() ) ? inet_aton($text):$text;
	my ($th,$dh) = splice(@alt,0,2);
	$th == $typ and $dh eq $data or print "not ";
	ok( $text );
    }
    @alt and print "not ";
    ok( 'no more altSubjectNames' );

    my @tests = (
	'127.0.0.1' => [qw( smtp ldap www)],
	'server.local' => [qw(smtp ldap)],
	'blafasel.server.local' => [qw(smtp ldap www)],
	'lala.blafasel.server.local' => [],
	'www.other.local' => [qw()],
	'www-13.other.local' => [qw(www)],
	'www-13.lala.other.local' => [],
	'smtp.mydomain.local' => [qw(smtp ldap www)],
	'xn--lwe-sna.idntest.local' => [qw(smtp ldap www)],
	'smtp.mydomain.localizing.useless.local' => [],
    );
    if ( $can_idn ) {
	# check IDN handling
	my $loewe = "l\366we.idntest.local";
	push @tests, ( $loewe => [qw(smtp ldap www)] );
    }

    while (@tests) {
	my ($host,$expect) = splice(@tests,0,2);
	my %expect = map { $_=>1 } @$expect;
	for my $typ (qw( smtp ldap www)) {
	    my $is = $client->verify_hostname( $host, $typ ) ? 'pass':'fail';
	    my $want = $expect{$typ} ? 'pass':'fail';
	    print "not " if $is ne $want;
	    ok( "$want $host $typ" );
	}
    }
    exit;
}

my $accept = sub {
    my $csock = $server->accept;
    IO::Socket::SSL->start_SSL($csock,
	SSL_server => 1,
	SSL_ca_file => "t/certs/test-ca.pem",
	SSL_cert_file => "t/certs/server-wildcard.pem",
	SSL_key_file => "t/certs/server-wildcard.pem",
    );
};

my $csock = &$accept;
wait;

# try with implicit checking
# Should succeed
defined( $pid = fork() ) || die $!;
if ( $pid == 0 ) {
    close($server);
    IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_ca_file => "t/certs/test-ca.pem",
	SSL_verify_mode => 1,
	SSL_verifycn_scheme => 'www',
	SSL_verifycn_name => 'www.server.local'
    ) || print "not ";
    ok("implicit hostname check www.server.local");
    exit;
}
$csock = &$accept;
wait;

# Should fail
defined( $pid = fork() ) || die $!;
if ( $pid == 0 ) {
    close($server);
    if (IO::Socket::SSL->new(
	PeerAddr => $saddr,
	Domain => AF_INET,
	SSL_ca_file => "t/certs/test-ca.pem",
	SSL_verify_mode => 1,
	SSL_verifycn_scheme => 'www',
	SSL_verifycn_name => 'does.not.match.server.local'
    )) {
	print "not ";
    } elsif ($SSL_ERROR !~ /hostname verification failed/) {
	print "# wrong error(should be hostname verification failed): $SSL_ERROR\n";
	print "not ";
    }
    ok("implicit hostname check does.not.match.server.local");
    exit;
}
$csock = &$accept;
wait;



sub ok { print "ok #$_[0]\n"; }
