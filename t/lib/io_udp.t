#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	unshift @INC, '../lib' if -d '../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        if ( ($Config{'extensions'} !~ /\bSocket\b/ ||
              $Config{'extensions'} !~ /\bIO\b/	||
	      $^O eq 'os2')    &&
              !(($^O eq 'VMS') && $Config{d_socket})) {
	    print "1..0\n";
	    exit 0;
        }
    }
}

sub compare_addr {
    my $a = shift;
    my $b = shift;
    my @a = unpack_sockaddr_in($a);
    my @b = unpack_sockaddr_in($b);
    "$a[0]$a[1]" eq "$b[0]$b[1]";
}

$| = 1;
print "1..7\n";

use Socket;
use IO::Socket qw(AF_INET SOCK_DGRAM INADDR_ANY);

    # This can fail if localhost is undefined or the
    # special 'loopback' address 127.0.0.1 is not configured
    # on your system. (/etc/rc.config.d/netconfig on HP-UX.)
    # As a shortcut (not recommended) you could change 'localhost'
    # here to be the name of this machine eg 'myhost.mycompany.com'.

$udpa = IO::Socket::INET->new(Proto => 'udp', LocalAddr => 'localhost')
    or die "$! (maybe your system does not have the 'localhost' address defined)";

print "ok 1\n";

$udpb = IO::Socket::INET->new(Proto => 'udp', LocalAddr => 'localhost')
    or die "$! (maybe your system does not have the 'localhost' address defined)";

print "ok 2\n";

$udpa->send("ok 4\n",0,$udpb->sockname);

print "not " unless compare_addr($udpa->peername,$udpb->sockname);
print "ok 3\n";

my $where = $udpb->recv($buf="",5);
print $buf;

my @xtra = ();

unless(compare_addr($where,$udpa->sockname)) {
    print "not ";
    @xtra = (0,$udpa->sockname);
}
print "ok 5\n";

$udpb->send("ok 6\n",@xtra);
$udpa->recv($buf="",5);
print $buf;

print "not " if $udpa->connected;
print "ok 7\n";
