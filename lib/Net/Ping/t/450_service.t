# Testing tcp_service_check method using tcp and syn protocols.

BEGIN {
  unless (eval "require IO::Socket") {
    print "1..0 \# Skip: no IO::Socket\n";
    exit;
  }
  unless (getservbyname('echo', 'tcp')) {
    print "1..0 \# Skip: no echo port\n";
    exit;
  }
  unless (0) {
    print "1..0 \# Skip: too many problems right now\n";
    exit;
  }
}

use strict;
use Test;
use Net::Ping;
use IO::Socket;

# I'm lazy so I'll just use IO::Socket
# for the TCP Server stuff instead of doing
# all that direct socket() junk manually.

plan tests => 37;

# Everything loaded fine
ok 1;

"0" =~ /(0)/; # IO::Socket::INET ephemeral buttwag hack

# Start a tcp listen server on ephemeral port
my $sock1 = new IO::Socket::INET
  LocalAddr => "127.1.1.1",
  Proto => "tcp",
  Listen => 8,
  Reuse => 1,
  Type => SOCK_STREAM,
  ;

# Make sure it worked.
ok !!$sock1;

"0" =~ /(0)/; # IO::Socket::INET ephemeral buttwag hack

# Start listening on another ephemeral port
my $sock2 = new IO::Socket::INET
  LocalAddr => "127.2.2.2",
  Proto => "tcp",
  Listen => 8,
  Reuse => 1,
  Type => SOCK_STREAM,
  ;

# Make sure it worked too.
ok !!$sock2;

my $port1 = $sock1->sockport;
ok $port1;

my $port2 = $sock2->sockport;
ok $port2;

# Make sure the sockets are listening on different ports.
ok ($port1 != $port2);

# This is how it should be:
# 127.1.1.1:$port1 - service ON
# 127.2.2.2:$port2 - service ON
# 127.1.1.1:$port2 - service OFF
# 127.2.2.2:$port1 - service OFF

#####
# First, we test using the "tcp" protocol.
# (2 seconds should be long enough to connect to loopback.)
my $p = new Net::Ping "tcp", 2;

# new() worked?
ok !!$p;

# Disable service checking
$p->tcp_service_check(0);

# Try on the first port
$p->{port_num} = $port1;

# Make sure IP1 is reachable
ok $p -> ping("127.1.1.1");

# Make sure IP2 is reachable
ok $p -> ping("127.2.2.2");

# Try on the other port
$p->{port_num} = $port2;

# Make sure IP1 is reachable
ok $p -> ping("127.1.1.1");

# Make sure IP2 is reachable
ok $p -> ping("127.2.2.2");


# Enable service checking
$p->tcp_service_check(1);

# Try on the first port
$p->{port_num} = $port1;

# Make sure service on IP1 
ok $p -> ping("127.1.1.1");

# Make sure not service on IP2
ok !$p -> ping("127.2.2.2");

# Try on the other port
$p->{port_num} = $port2;

# Make sure not service on IP1
ok !$p -> ping("127.1.1.1");

# Make sure service on IP2
ok $p -> ping("127.2.2.2");


#####
# Lastly, we test using the "syn" protocol.
$p = new Net::Ping "syn", 2;

# new() worked?
ok !!$p;

# Disable service checking
$p->tcp_service_check(0);

# Try on the first port
$p->{port_num} = $port1;

# Send SYN to both IPs
ok $p -> ping("127.1.1.1");
ok $p -> ping("127.2.2.2");

# Both IPs should be reachable
ok $p -> ack();
ok $p -> ack();
# No more sockets?
ok !$p -> ack();

###
# Get a fresh object
$p = new Net::Ping "syn", 2;

# new() worked?
ok !!$p;

# Disable service checking
$p->tcp_service_check(0);

# Try on the other port
$p->{port_num} = $port2;

# Send SYN to both IPs
ok $p -> ping("127.1.1.1");
ok $p -> ping("127.2.2.2");

# Both IPs should be reachable
ok $p -> ack();
ok $p -> ack();
# No more sockets?
ok !$p -> ack();


###
# Get a fresh object
$p = new Net::Ping "syn", 2;

# new() worked?
ok !!$p;

# Enable service checking
$p->tcp_service_check(1);

# Try on the first port
$p->{port_num} = $port1;

# Send SYN to both IPs
ok $p -> ping("127.1.1.1");
ok $p -> ping("127.2.2.2");

# Only IP1 should have service
ok "127.1.1.1",$p -> ack();
# No more good sockets?
ok !$p -> ack();


###
# Get a fresh object
$p = new Net::Ping "syn", 2;

# new() worked?
ok !!$p;

# Enable service checking
$p->tcp_service_check(1);

# Try on the other port
$p->{port_num} = $port2;

# Send SYN to both IPs
ok $p -> ping("127.1.1.1");
ok $p -> ping("127.2.2.2");

# Only IP2 should have service
ok "127.2.2.2",$p -> ack();
# No more good sockets?
ok !$p -> ack();
