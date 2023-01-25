#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/readline.t'

# This tests the behavior of readline with the variety of
# cases with $/:
# $/ undef - read all
# $/ ''    - read up to next nonempty line: .*?\n\n+
# $/ s     - read up to string s
# $/ \$num - read $num bytes
# scalar context - get first match
# array context  - get all matches

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

my @tests;
push @tests, [
    "multi\nple\n\n1234567890line\n\n\n\nbla\n\nblubb\n\nblip",
    sub {
	my $c = shift;
	local $/ = "\n\n";
	my $b;
	($b=<$c>) eq "multi\nple\n\n" || die "LFLF failed ($b)";
	$/ = \"10";
	($b=<$c>) eq "1234567890" || die "\\size failed ($b)";
	$/ = '';
	($b=<$c>) eq "line\n\n\n\n" || die "'' failed ($b)";
	my @c = <$c>;
	die "'' @ failed: @c" unless $c[0] eq "bla\n\n" &&
	    $c[1] eq "blubb\n\n" &&
	    $c[2] eq "blip" && @c == 3;
    },
];

push @tests, [
    "some\nstring\nwith\nsome\nlines\nwhatever",
    sub {
	my $c = shift;
	local $/ = "\n";
	my $b;
	($b=<$c>) eq "some\n" || die "LF failed ($b)";
	$/ = undef;
	($b=<$c>) eq "string\nwith\nsome\nlines\nwhatever" || die "undef failed ($b)";
    },
];

push @tests, [
    "some\nstring\nwith\nsome\nlines\nwhatever",
    sub {
	my $c = shift;
	local $/ = "\n";
	my @c = <$c>;
	die "LF @ failed: @c" unless $c[0] eq "some\n" &&
	    $c[1] eq "string\n" && $c[2] eq "with\n" && $c[3] eq "some\n" &&
	    $c[4] eq "lines\n" && $c[5] eq "whatever" && @c == 6;

    },
];

push @tests, [
    "some\nstring\nwith\nsome\nlines\nwhatever",
    sub {
	my $c = shift;
	local $/;
	my @c = <$c>;
	die "undef @ failed: @c" unless
	    $c[0] eq "some\nstring\nwith\nsome\nlines\nwhatever"
	    && @c == 1;

    },
];

push @tests, [
    "1234567890",
    sub {
	my $c = shift;
	local $/ = \2;
	my @c = <$c>;
	die "\\2 @ failed: @c" unless
	    $c[0] eq '12' && $c[1] eq '34' && $c[2] eq '56' &&
	    $c[3] eq '78' && $c[4] eq '90' && @c == 5;

    },
];

push @tests, [
    [ "bla\n","0","blubb\n","no newline" ],
    sub {
	my $c = shift;
	my $l = <$c>;
	$l eq "bla\n" or die "'bla\\n' failed";
	$l = <$c>;
	$l eq "0blubb\n" or die "'0blubb\\n' failed";
	$l = <$c>;
	$l eq "no newline" or die "'no newline' failed";
    },
];

$|=1;
print "1..".(1+3*@tests)."\n";


# first create simple ssl-server
my $ID = 'server';
my $addr = '127.0.0.1';
my $server = IO::Socket::SSL->new(
    LocalAddr => $addr,
    Listen => 2,
    ReuseAddr => 1,
    SSL_cert_file => "t/certs/server-cert.pem",
    SSL_key_file  => "t/certs/server-key.pem",
) || do {
    notok($!);
    exit
};
ok("Server Initialization");

# add server port to addr
$addr.= ':'.(sockaddr_in( getsockname( $server )))[0];

my $pid = fork();
if ( !defined $pid ) {
    die $!; # fork failed

} elsif ( $pid ) {    ###### Server

    foreach my $test (@tests) {
	my $to_client = $server->accept || do {
	    notok( "accept failed: ".$server->errstr() );
	    kill(9,$pid);
	    exit;
	};
	ok( "Server accepted" );
	$to_client->autoflush;
	my $t = $test->[0];
	$t = [$t] if ! ref($t);
	for(@$t) {
	    $to_client->print($_);
	    select(undef,undef,undef,0.1);
	}
    }
    wait;
    exit;
}

$ID = 'client';
close($server);
my $testid = "Test00";
foreach my $test (@tests) {
    my $to_server = IO::Socket::SSL->new(
	PeerAddr => $addr,
	Domain => AF_INET,
	SSL_verify_mode => 0 ) || do {
	notok( "connect failed: ".IO::Socket::SSL->errstr() );
	exit
    };
    ok( "client connected" );
    eval { $test->[1]( $to_server ) };
    $@ ? notok( "$testid $@" ) : ok( $testid );
    $testid++
}



sub ok { print "ok # [$ID] @_\n"; }
sub notok { print "not ok # [$ID] @_\n"; }
