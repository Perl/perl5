package Net::Ping;

# Current maintainer: colinm@cpan.org (Colin McMillen)
#		stream protocol: bronson@trestle.com (Scott Bronson)
#
# Original author:   mose@ccsn.edu (Russell Mosemann)
#
# Authors of the original pingecho():
#           karrer@bernina.ethz.ch (Andreas Karrer)
#           Paul.Marquess@btinternet.com (Paul Marquess)
#
# Copyright (c) 2001, Colin McMillen.  All rights reserved.  This
# program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
use 5.005_64;
require Exporter;

use strict;
our(@ISA, @EXPORT, $VERSION, $def_timeout, $def_proto, $max_datasize);
use FileHandle;
use Socket qw( SOCK_DGRAM SOCK_STREAM SOCK_RAW PF_INET
               inet_aton inet_ntoa sockaddr_in );
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(pingecho);
$VERSION = 2.04;

# Constants

$def_timeout = 5;           # Default timeout to wait for a reply
$def_proto = "udp";         # Default protocol to use for pinging
$max_datasize = 1024;       # Maximum data bytes in a packet

# Description:  The pingecho() subroutine is provided for backward
# compatibility with the original Net::Ping.  It accepts a host
# name/IP and an optional timeout in seconds.  Create a tcp ping
# object and try pinging the host.  The result of the ping is returned.

sub pingecho
{
    my ($host,              # Name or IP number of host to ping
        $timeout            # Optional timeout in seconds
        ) = @_;
    my ($p);                # A ping object

    $p = Net::Ping->new("tcp", $timeout);
    $p->ping($host);        # Going out of scope closes the connection
}

# Description:  The new() method creates a new ping object.  Optional
# parameters may be specified for the protocol to use, the timeout in
# seconds and the size in bytes of additional data which should be
# included in the packet.
#   After the optional parameters are checked, the data is constructed
# and a socket is opened if appropriate.  The object is returned.

sub new
{
    my ($this,
        $proto,             # Optional protocol to use for pinging
        $timeout,           # Optional timeout in seconds
        $data_size          # Optional additional bytes of data
        ) = @_;
    my  $class = ref($this) || $this;
    my  $self = {};
    my ($cnt,               # Count through data bytes
        $min_datasize       # Minimum data bytes required
        );

    bless($self, $class);

    $proto = $def_proto unless $proto;          # Determine the protocol
    croak('Protocol for ping must be "icmp", "udp", "tcp", "stream", or "external"')
        unless $proto =~ m/^(icmp|udp|tcp|stream|external)$/;
    $self->{"proto"} = $proto;

    $timeout = $def_timeout unless $timeout;    # Determine the timeout
    croak("Default timeout for ping must be greater than 0 seconds")
        if $timeout <= 0;
    $self->{"timeout"} = $timeout;

    $min_datasize = ($proto eq "udp") ? 1 : 0;  # Determine data size
    $data_size = $min_datasize unless defined($data_size) && $proto ne "tcp";
    croak("Data for ping must be from $min_datasize to $max_datasize bytes")
        if ($data_size < $min_datasize) || ($data_size > $max_datasize);
    $data_size-- if $self->{"proto"} eq "udp";  # We provide the first byte
    $self->{"data_size"} = $data_size;

    $self->{"data"} = "";                       # Construct data bytes
    for ($cnt = 0; $cnt < $self->{"data_size"}; $cnt++)
    {
        $self->{"data"} .= chr($cnt % 256);
    }

    $self->{"seq"} = 0;                         # For counting packets
    if ($self->{"proto"} eq "udp")              # Open a socket
    {
        $self->{"proto_num"} = (getprotobyname('udp'))[2] ||
            croak("Can't udp protocol by name");
        $self->{"port_num"} = (getservbyname('echo', 'udp'))[2] ||
            croak("Can't get udp echo port by name");
        $self->{"fh"} = FileHandle->new();
        socket($self->{"fh"}, &PF_INET(), &SOCK_DGRAM(),
               $self->{"proto_num"}) ||
            croak("udp socket error - $!");
    }
    elsif ($self->{"proto"} eq "icmp")
    {
        croak("icmp ping requires root privilege") if ($> and $^O ne 'VMS');
        $self->{"proto_num"} = (getprotobyname('icmp'))[2] ||
                    croak("Can't get icmp protocol by name");
        $self->{"pid"} = $$ & 0xffff;           # Save lower 16 bits of pid
        $self->{"fh"} = FileHandle->new();
        socket($self->{"fh"}, &PF_INET(), &SOCK_RAW(), $self->{"proto_num"}) ||
            croak("icmp socket error - $!");
    }
    elsif ($self->{"proto"} eq "tcp" || $self->{"proto"} eq "stream")
    {
        $self->{"proto_num"} = (getprotobyname('tcp'))[2] ||
            croak("Can't get tcp protocol by name");
        $self->{"port_num"} = (getservbyname('echo', 'tcp'))[2] ||
            croak("Can't get tcp echo port by name");
        $self->{"fh"} = FileHandle->new();
    }


    return($self);
}

# Description: Ping a host name or IP number with an optional timeout.
# First lookup the host, and return undef if it is not found.  Otherwise
# perform the specific ping method based on the protocol.  Return the 
# result of the ping.

sub ping
{
    my ($self,
        $host,              # Name or IP number of host to ping
        $timeout            # Seconds after which ping times out
        ) = @_;
    my ($ip,                # Packed IP number of $host
        $ret                # The return value
        );

    croak("Usage: \$p->ping(\$host [, \$timeout])") unless @_ == 2 || @_ == 3;
    $timeout = $self->{"timeout"} unless $timeout;
    croak("Timeout must be greater than 0 seconds") if $timeout <= 0;

    $ip = inet_aton($host);
    return(undef) unless defined($ip);      # Does host exist?

    # Dispatch to the appropriate routine.
    return $self->ping_external($ip, $timeout) if $self->{"proto"} eq "external";
    return $self->ping_udp($ip, $timeout)      if $self->{"proto"} eq "udp";
    return $self->ping_icmp($ip, $timeout)     if $self->{"proto"} eq "icmp";
    return $self->ping_tcp($ip, $timeout)      if $self->{"proto"} eq "tcp";
    return $self->ping_stream($ip, $timeout)   if $self->{"proto"} eq "stream";

    croak("Unknown protocol \"$self->{proto}\" in ping()");
}

# Uses Net::Ping::External to do an external ping.
sub ping_external {
  my ($self,
      $ip,                # Packed IP number of the host
      $timeout            # Seconds after which ping times out
     ) = @_;

  eval { require Net::Ping::External; };
  croak('Protocol "external" not supported on your system: Net::Ping::External not found') if $@;
  return Net::Ping::External::ping(ip => $ip, timeout => $timeout);
}

sub ping_icmp
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which ping times out
        ) = @_;

    my $ICMP_ECHOREPLY = 0; # ICMP packet types
    my $ICMP_ECHO = 8;
    my $icmp_struct = "C2 S3 A";  # Structure of a minimal ICMP packet
    my $subcode = 0;        # No ICMP subcode for ECHO and ECHOREPLY
    my $flags = 0;          # No special flags when opening a socket
    my $port = 0;           # No port with ICMP

    my ($saddr,             # sockaddr_in with port and ip
        $checksum,          # Checksum of ICMP packet
        $msg,               # ICMP packet to send
        $len_msg,           # Length of $msg
        $rbits,             # Read bits, filehandles for reading
        $nfound,            # Number of ready filehandles found
        $finish_time,       # Time ping should be finished
        $done,              # set to 1 when we are done
        $ret,               # Return value
        $recv_msg,          # Received message including IP header
        $from_saddr,        # sockaddr_in of sender
        $from_port,         # Port packet was sent from
        $from_ip,           # Packed IP of sender
        $from_type,         # ICMP type
        $from_subcode,      # ICMP subcode
        $from_chk,          # ICMP packet checksum
        $from_pid,          # ICMP packet id
        $from_seq,          # ICMP packet sequence
        $from_msg           # ICMP message
        );

    $self->{"seq"} = ($self->{"seq"} + 1) % 65536; # Increment sequence
    $checksum = 0;                          # No checksum for starters
    $msg = pack($icmp_struct . $self->{"data_size"}, $ICMP_ECHO, $subcode,
                $checksum, $self->{"pid"}, $self->{"seq"}, $self->{"data"});
    $checksum = Net::Ping->checksum($msg);
    $msg = pack($icmp_struct . $self->{"data_size"}, $ICMP_ECHO, $subcode,
                $checksum, $self->{"pid"}, $self->{"seq"}, $self->{"data"});
    $len_msg = length($msg);
    $saddr = sockaddr_in($port, $ip);
    send($self->{"fh"}, $msg, $flags, $saddr); # Send the message

    $rbits = "";
    vec($rbits, $self->{"fh"}->fileno(), 1) = 1;
    $ret = 0;
    $done = 0;
    $finish_time = time() + $timeout;       # Must be done by this time
    while (!$done && $timeout > 0)          # Keep trying if we have time
    {
        $nfound = select($rbits, undef, undef, $timeout); # Wait for packet
        $timeout = $finish_time - time();   # Get remaining time
        if (!defined($nfound))              # Hmm, a strange error
        {
            $ret = undef;
            $done = 1;
        }
        elsif ($nfound)                     # Got a packet from somewhere
        {
            $recv_msg = "";
            $from_saddr = recv($self->{"fh"}, $recv_msg, 1500, $flags);
            ($from_port, $from_ip) = sockaddr_in($from_saddr);
            ($from_type, $from_subcode, $from_chk,
             $from_pid, $from_seq, $from_msg) =
                unpack($icmp_struct . $self->{"data_size"},
                       substr($recv_msg, length($recv_msg) - $len_msg,
                              $len_msg));
            if (($from_type == $ICMP_ECHOREPLY) &&
                ($from_ip eq $ip) &&
                ($from_pid == $self->{"pid"}) && # Does the packet check out?
                ($from_seq == $self->{"seq"}))
            {
                $ret = 1;                   # It's a winner
                $done = 1;
            }
        }
        else                                # Oops, timed out
        {
            $done = 1;
        }
    }
    return($ret)
}

# Description:  Do a checksum on the message.  Basically sum all of
# the short words and fold the high order bits into the low order bits.

sub checksum
{
    my ($class,
        $msg            # The message to checksum
        ) = @_;
    my ($len_msg,       # Length of the message
        $num_short,     # The number of short words in the message
        $short,         # One short word
        $chk            # The checksum
        );

    $len_msg = length($msg);
    $num_short = int($len_msg / 2);
    $chk = 0;
    foreach $short (unpack("S$num_short", $msg))
    {
        $chk += $short;
    }                                           # Add the odd byte in
    $chk += (unpack("C", substr($msg, $len_msg - 1, 1)) << 8) if $len_msg % 2;
    $chk = ($chk >> 16) + ($chk & 0xffff);      # Fold high into low
    return(~(($chk >> 16) + $chk) & 0xffff);    # Again and complement
}

# Warning: this method may generate false positives.
# It is meant to be a private method and should only
# be invoked by ping_tcp() if $^O =~ /win32/i.

sub _ping_tcp_win
{
    my ($self,
        $ip,                # Packed IP number of the host
        ) = @_;
    my ($saddr,             # sockaddr_in with port and ip
        $ret                # The return value
        );

    socket($self->{"fh"}, &PF_INET(), &SOCK_STREAM(), $self->{"proto_num"}) ||
        croak("tcp socket error - $!");

    $saddr = sockaddr_in($self->{"port_num"}, $ip);

    $ret = 0;               # Default to unreachable

    eval { $ret = connect($self->{"fh"}, $saddr) };

    # If the remote host exists but returns "Connection refused",
    # the call to connect() sets $! to "Unknown error". So, we
    # assume that an "Unknown error" actually means the host is
    # alive. This assumption may occassionally give false positives.
    $ret = 1 if $! =~ /Unknown error/i;

    $self->{"fh"}->close();
    return $ret;
}

# Buggy Winsock API doesn't allow us to use non-blocking connect()
# calls. Hence, if our OS is Windows, we need to create a new process
# to run a blocking connect attempt, and kill it after the timeout has
# passed.  Unfortunately, this won't work with the stream protocol.

sub ping_tcp_win32
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which open times out
        ) = @_;

    socket($self->{"fh"}, &PF_INET(), &SOCK_STREAM(), $self->{"proto_num"}) ||
      croak("tcp socket error - $!");

    my $saddr = sockaddr_in($self->{"port_num"}, $ip);

	my ($child, $ret, $pid, $time);
	my $host = inet_ntoa($ip);

	# The code we will be executing in our new process.
	my $code = '"use Net::Ping; $p = Net::Ping->new(\'tcp\'); ';
	$code .= 'exit($p->_ping_tcp_win(' . $host . '))"';

	# Call the process.
	$pid = system(1, "perl", "-e", $code);

	# Import the POSIX version of <sys/wait.h>
	require POSIX;
	import POSIX qw(:sys_wait_h);

	# Get the current time; will be used to tell if we've timed out.
	$time = time;

	# Wait for the child to return or for the timeout to expire.
	do {
		$child = waitpid($pid, &WNOHANG);
		$ret = $?;
	} until time > ($time + $timeout) or $child;

	# Return an appropriate value; 0 if the child didn't return,
	# the return value of the child otherwise.
	return $ret >> 8 if $child;

	kill $pid;
	return 0;
}

# This writes the given string to the socket and then reads it
# back.  It returns 1 on success, 0 on failure.
sub tcp_echo
{
	my $self = shift;
	my $timeout = shift;
	my $pingstring = shift;

	my $ret = undef;
	my $time = time;
	my $wrstr = $pingstring;
	my $rdstr = "";

    eval <<'EOM';
	do {
		my $rin = "";
		vec($rin, $self->{"fh"}->fileno(), 1) = 1;

		my $rout = undef;
		if($wrstr) {
			$rout = "";
			vec($rout, $self->{"fh"}->fileno(), 1) = 1;
		}

		if(select($rin, $rout, undef, ($time + $timeout) - time())) {

			if($rout && vec($rout,$self->{"fh"}->fileno(),1)) {
				my $num = syswrite($self->{"fh"}, $wrstr);
				if($num) {
					# If it was a partial write, update and try again.
					$wrstr = substr($wrstr,$num);
				} else {
					# There was an error.
					$ret = 0;
				}
			}

			if(vec($rin,$self->{"fh"}->fileno(),1)) {
				my $reply;
				if(sysread($self->{"fh"},$reply,length($pingstring)-length($rdstr))) {
					$rdstr .= $reply;
					$ret = 1 if $rdstr eq $pingstring;
				} else {
					# There was an error.
					$ret = 0;
				}
			}

		}
	} until time() > ($time + $timeout) || defined($ret);
EOM

	return $ret;
}

sub tcp_connect
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which open times out
        ) = @_;

	# Should we go back to using blocking IO and alarms to implement
	# the stream protocol on win32?
    croak "no nonblocking io -- can't stream ping on win32"
		if ($^O =~ /win32/i);

	$self->{"ip"} = $ip;

    socket($self->{"fh"}, &PF_INET(), &SOCK_STREAM(), $self->{"proto_num"}) ||
      croak("tcp socket error - $!");

    my $saddr = sockaddr_in($self->{"port_num"}, $ip);
    my $ret = 0;

	# Try a non-blocking TCP connect to the remote echo port.
	# Our call to select() below will stop after the timeout has
	# passed or set the return value to true if the connection
	# succeeds in time.
	$self->{"fh"}->blocking(0);
	connect($self->{"fh"}, $saddr);

	# This replaces the breakage where we were listening on a
	# socket that would never produce any data.  This works, but
	# it's now quite a bit heavier than the old Net::Ping.  I'd
	# like to see it reverted.
	return $self->tcp_echo($timeout, "ping!\n");
}

# Description:  Perform a tcp echo ping.  Since a tcp connection is
# host specific, we have to open and close each connection here.  We
# can't just leave a socket open.  Because of the robust nature of
# tcp, it will take a while before it gives up trying to establish a
# connection.  Therefore, we use select() on a non-blocking socket to
# check against our timeout. No data bytes are actually
# sent since the successful establishment of a connection is proof
# enough of the reachability of the remote host.  Also, tcp is
# expensive and doesn't need our help to add to the overhead.

sub ping_tcp
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which ping times out
       ) = @_;

	my $ret;

	# tcp_connect won't work on win32, so special-case it if need be.
    if ($^O =~ /win32/i) {
		$ret = $self->ping_tcp_win32($ip, $timeout);
	} else {
    	$ret = $self->tcp_connect($ip, $timeout);
    	$self->{"fh"}->close();
	}

    return $ret;
}

# Description: Perform a stream ping.  If the tcp connection isn't
# already open, it opens it.  It then sends some data and waits for
# a reply.  It leaves the stream open on exit.

sub ping_stream
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which ping times out
        ) = @_;

    my $pingstring = "ping!\n";   # The data we exchange with the server

    # Open the stream if it's not already open
    if(!defined $self->{"fh"}->fileno()) {
        $self->tcp_connect($ip, $timeout) or return 0;
    }

    croak "tried to switch servers while stream pinging"
       if $self->{"ip"} ne $ip;

    return $self->tcp_echo($timeout, "pingschwingping!\n");
}

# Description: opens the stream.  You would do this if you want to
# separate the overhead of opening the stream from the first ping.

sub open
{
   my ($self,
       $ip,                # Packed IP number of the host
        $timeout            # Seconds after which open times out
       ) = @_;

   $timeout = $self->{"timeout"} unless $timeout;

   if($self->{"proto"} eq "stream") {
       if(defined($self->{"fh"}->fileno())) {
           croak("socket is already open");
       } else {
           $self->tcp_connect($ip, $timeout);
       }
   }
}

# Description:  Perform a udp echo ping.  Construct a message of
# at least the one-byte sequence number and any additional data bytes.
# Send the message out and wait for a message to come back.  If we
# get a message, make sure all of its parts match.  If they do, we are
# done.  Otherwise go back and wait for the message until we run out
# of time.  Return the result of our efforts.

sub ping_udp
{
    my ($self,
        $ip,                # Packed IP number of the host
        $timeout            # Seconds after which ping times out
        ) = @_;

    my $flags = 0;          # Nothing special on open

    my ($saddr,             # sockaddr_in with port and ip
        $ret,               # The return value
        $msg,               # Message to be echoed
        $finish_time,       # Time ping should be finished
        $done,              # Set to 1 when we are done pinging
        $rbits,             # Read bits, filehandles for reading
        $nfound,            # Number of ready filehandles found
        $from_saddr,        # sockaddr_in of sender
        $from_msg,          # Characters echoed by $host
        $from_port,         # Port message was echoed from
        $from_ip            # Packed IP number of sender
        );

    $saddr = sockaddr_in($self->{"port_num"}, $ip);
    $self->{"seq"} = ($self->{"seq"} + 1) % 256;    # Increment sequence
    $msg = chr($self->{"seq"}) . $self->{"data"};   # Add data if any
    send($self->{"fh"}, $msg, $flags, $saddr);      # Send it

    $rbits = "";
    vec($rbits, $self->{"fh"}->fileno(), 1) = 1;
    $ret = 0;                   # Default to unreachable
    $done = 0;
    $finish_time = time() + $timeout;       # Ping needs to be done by then
    while (!$done && $timeout > 0)
    {
        $nfound = select($rbits, undef, undef, $timeout); # Wait for response
        $timeout = $finish_time - time();   # Get remaining time

        if (!defined($nfound))  # Hmm, a strange error
        {
            $ret = undef;
            $done = 1;
        }
        elsif ($nfound)         # A packet is waiting
        {
            $from_msg = "";
            $from_saddr = recv($self->{"fh"}, $from_msg, 1500, $flags)
		or last; # For example an unreachable host will make recv() fail.
	    ($from_port, $from_ip) = sockaddr_in($from_saddr);
	    if (($from_ip eq $ip) &&        # Does the packet check out?
		($from_port == $self->{"port_num"}) &&
		($from_msg eq $msg))
	    {
		$ret = 1;       # It's a winner
		$done = 1;
	    }
	}
        else                    # Oops, timed out
        {
            $done = 1;
        }
    }
    return($ret);
}   

# Description:  Close the connection unless we are using the tcp
# protocol, since it will already be closed.

sub close
{
    my ($self) = @_;

    $self->{"fh"}->close() unless $self->{"proto"} eq "tcp";
}


1;
__END__

=head1 NAME

Net::Ping - check a remote host for reachability

=head1 SYNOPSIS

    use Net::Ping;

    $p = Net::Ping->new();
    print "$host is alive.\n" if $p->ping($host);
    $p->close();

    $p = Net::Ping->new("icmp");
    foreach $host (@host_array)
    {
        print "$host is ";
        print "NOT " unless $p->ping($host, 2);
        print "reachable.\n";
        sleep(1);
    }
    $p->close();
    
    $p = Net::Ping->new("tcp", 2);
    while ($stop_time > time())
    {
        print "$host not reachable ", scalar(localtime()), "\n"
            unless $p->ping($host);
        sleep(300);
    }
    undef($p);
    
    # For backward compatibility
    print "$host is alive.\n" if pingecho($host);

=head1 DESCRIPTION

This module contains methods to test the reachability of remote
hosts on a network.  A ping object is first created with optional
parameters, a variable number of hosts may be pinged multiple
times and then the connection is closed.

Ping supports five ping protocols, each with its own strengths
and weaknesses.  The "udp" protocol is the default.  A host
may be configured to respond to only a few of these protocols,
or even none at all.  For example, www.microsoft.com is generally
alive but not pingable.

=over 4

=item icmp

The C<ping()> method sends an icmp echo message to the remote host
(this is what the UNIX ping program does).
If the echoed message is received from the remote host and
the echoed information is correct, the remote host is considered
reachable.  Specifying this protocol requires that the program
be run as root or that the program be setuid to root.

=item udp

The C<ping()> method sends a udp
packet to the remote host's echo port.  If the echoed packet is
received from the remote host and the received packet contains the
same data as the packet that was sent, the remote host is considered
reachable.  This protocol does not require any special privileges.

It should be borne in mind that, for both udp and tcp ping, a host
will be reported as unreachable if it is not running the
appropriate echo service.  For Unix-like systems see L<inetd(8)> for
more information.

=item tcp

The C<ping()> method attempts to establish a
connection to the remote host's echo port.  If the connection is
successfully established, the remote host is considered reachable.
Once the connection is made, it is torn down immediately -- no data
is actually echoed.  This protocol does not require any special
privileges but has highest overhead of the protocols.

=item stream

This is just like the tcp protocol, except that once it establishes
the tcp connection, it keeps it up.  Each subsequent ping
request re-uses the existing connection.  stream
provides better performance than tcp since the connection
doesn't need to be created and torn down with every ping.  It is
also the only protocol that will recognize that the original host is
gone, even if it is immediately replaced by an
identical host responding in exactly the same way.  The drawback
is that you can only ping one host per Ping instance.  You will get
an error if you neglect to call C<close()> before trying to ping
a different network device.

=item external

The ping() method attempts to use the C<Net::Ping::External> module to ping
the remote host.  C<Net::Ping::External> interfaces with your system's default
L<ping(8)> utility to perform the ping, and generally produces relatively
accurate results. If C<Net::Ping::External> if not installed on your
system, specifying the "external" protocol will result in an error.

=head2 Functions

=over 4

=item Net::Ping->new([$proto [, $def_timeout [, $bytes]]]);

Create a new ping object.  All of the parameters are optional.  $proto
specifies the protocol to use when doing a ping.  The current choices
are "tcp", "udp" or "icmp".  The default is "udp".

If a default timeout ($def_timeout) in seconds is provided, it is used
when a timeout is not given to the ping() method (below).  The timeout
must be greater than 0 and the default, if not specified, is 5 seconds.

If the number of data bytes ($bytes) is given, that many data bytes
are included in the ping packet sent to the remote host. The number of
data bytes is ignored if the protocol is "tcp".  The minimum (and
default) number of data bytes is 1 if the protocol is "udp" and 0
otherwise.  The maximum number of data bytes that can be specified is
1024.

=item $p->ping($host [, $timeout]);

Ping the remote host and wait for a response.  $host can be either the
hostname or the IP number of the remote host.  The optional timeout
must be greater than 0 seconds and defaults to whatever was specified
when the ping object was created.  If the hostname cannot be found or
there is a problem with the IP number, undef is returned.  Otherwise,
1 is returned if the host is reachable and 0 if it is not.  For all
practical purposes, undef and 0 and can be treated as the same case.

=item $p->open($host);

When you are using the stream protocol, this call pre-opens the
tcp socket.  It's only necessary to do this if you want to
provide a different timeout when creating the connection, or
remove the overhead of establishing the connection from the
first ping.  If you don't call C<open()>, the connection is
automatically openeed the first time C<ping()> is called.
This call simply does nothing if you are using any protocol other
than stream.

=item $p->close();

Close the network connection for this ping object.  The network
connection is also closed by "undef $p".  The network connection is
automatically closed if the ping object goes out of scope (e.g. $p is
local to a subroutine and you leave the subroutine).

=item pingecho($host [, $timeout]);

To provide backward compatibility with the previous version of
Net::Ping, a pingecho() subroutine is available with the same
functionality as before.  pingecho() uses the tcp protocol.  The
return values and parameters are the same as described for the ping()
method.  This subroutine is obsolete and may be removed in a future
version of Net::Ping.

=back

=head1 NOTES

There will be less network overhead (and some efficiency in your
program) if you specify either the udp or the icmp protocol.  The tcp
protocol will generate 2.5 times or more traffic for each ping than
either udp or icmp.  If many hosts are pinged frequently, you may wish
to implement a small wait (e.g. 25ms or more) between each ping to
avoid flooding your network with packets.

The icmp protocol requires that the program be run as root or that it
be setuid to root.  The other protocols do not require special
privileges, but not all network devices implement tcp or udp echo.

Local hosts should normally respond to pings within milliseconds.
However, on a very congested network it may take up to 3 seconds or
longer to receive an echo packet from the remote host.  If the timeout
is set too low under these conditions, it will appear that the remote
host is not reachable (which is almost the truth).

Reachability doesn't necessarily mean that the remote host is actually
functioning beyond its ability to echo packets.  tcp is slightly better
at indicating the health of a system than icmp because it uses more
of the networking stack to respond.

Because of a lack of anything better, this module uses its own
routines to pack and unpack ICMP packets.  It would be better for a
separate module to be written which understands all of the different
kinds of ICMP packets.

=cut
