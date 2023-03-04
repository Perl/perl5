#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/compatibility.t'

use strict;
use warnings;
use IO::Socket::SSL;
use Socket;

do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

use Test::More tests => 9;
Test::More->builder->use_numbers(0);
Test::More->builder->no_ending(1);

$SIG{'CHLD'} = "IGNORE";

IO::Socket::SSL::context_init(SSL_verify_mode => 0x01);

my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 1,
) or do {
    plan skip_all => "Bail out!".
	"Setup of test IO::Socket::INET client and server failed.  All the rest of".
	"the tests in this suite will fail also unless you change the values in".
	"ssl_settings.req in the t/ directory.";
};
pass("server create");

{
    package MyClass;
    use IO::Socket::SSL;
    our @ISA = "IO::Socket::SSL";
}

my $saddr = $server->sockhost.':'.$server->sockport;
unless (fork) {
    close $server;
    my $client = IO::Socket::INET->new($saddr);
    ok( MyClass->start_SSL($client, SSL_verify_mode => 0), "ssl upgrade");
    is( ref( $client ), "MyClass", "class MyClass");
    ok( $client->issuer_name, "issuer_name");
    ok( $client->subject_name, "subject_name");
    ok( $client->opened, "opened");
    print $client "Ok to close\n";
    close $client;
    exit(0);
}

my $contact = $server->accept;
my $socket_to_ssl = IO::Socket::SSL::socketToSSL($contact, {
    SSL_server => 1,
    SSL_verify_mode => 0,
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
});
ok( $socket_to_ssl, "socketToSSL");
<$contact>;
close $contact;
close $server;

bless $contact, "MyClass";
ok( !IO::Socket::SSL::socket_to_SSL($contact, SSL_server => 1), "socket_to_SSL");
is( ref($contact), "MyClass", "upgrade is MyClass");
