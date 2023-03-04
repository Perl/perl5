#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/nonblock.t'

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use IO::Socket::SSL;
use IO::Select;
do './testlib.pl' || do './t/testlib.pl' || die "no testlib";

my $getsize;
if ( -f "/proc/$$/statm" ) {
    $getsize = sub {
	my $pid = shift;
	open( my $fh,'<', "/proc/$pid/statm");
	my $line = <$fh>;
	return (split(' ',$line))[0] * 4;
    };
} elsif ( ! grep { $^O =~m{$_}i } qw( MacOS VOS vmesa riscos amigaos mswin32) ) {
    $getsize = sub {
	my $pid = shift;
	open( my $ps,'-|',"ps -o vsize -p $pid 2>/dev/null" ) or return;
	$ps && <$ps> or return; # header
	return int(<$ps>); # size
    };
} else {
    print "1..0 # Skipped: ps not implemented on this platform\n";
    exit
}

if ( $^O =~m{aix}i ) {
    print "1..0 # Skipped: might hang, see https://rt.cpan.org/Ticket/Display.html?id=72170\n";
    exit
}


$|=1;
if ( ! $getsize->($$) ) {
    print "1..0 # Skipped: no usable ps\n";
    exit;
}

my $server = IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 200,
    SSL_cert_file => 't/certs/server-cert.pem',
    SSL_key_file => 't/certs/server-key.pem',
);

my $saddr = $server->sockhost.':'.$server->sockport;
defined( my $pid = fork()) or die "fork failed: $!";
if ( $pid == 0 ) {
    # server
    while (1) {
	# socket accept, client handshake and client close
	$server->accept;
    }
    exit(0);
}


close($server);
# plain non-SSL connect and close w/o sending data
for(1..100) {
    IO::Socket::INET->new( $saddr ) or next;
}
my $size100 = $getsize->($pid);
if ( ! $size100 ) {
    print "1..0 # Skipped: cannot get size of child process\n";
    goto done;
}

for(100..200) {
    IO::Socket::INET->new( $saddr ) or next;
}
my $size200 = $getsize->($pid);

for(200..300) {
    IO::Socket::INET->new( $saddr ) or next;
}
my $size300 = $getsize->($pid);
if ($size100>$size200 or $size200<$size300) {;
    print "1..0 # skipped  - do we measure the right thing?\n";
    goto done;
}

print "1..1\n";
print "not " if $size100 < $size200 and $size200 < $size300;
print "ok # check memleak failed handshake ($size100,$size200,$size300)\n";

done:
kill(9,$pid);
wait;
exit;


