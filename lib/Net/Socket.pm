package Net::Socket;

=head1 NAME

Net::Socket - TEMPORARY Socket filedescriptor class, so Net::FTP still
works while IO::Socket is having a re-fit <GBARR>

=head1 DESCRIPTION

NO TEXT --- THIS MODULE IS TEMPORARY

=cut

require 5.001;
use Socket 1.3;
use Carp;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = @Socket::EXPORT;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION }

##
## Really WANT FileHandle::new to return this !!!
##
my $seq = 0;
sub _gensym {
    my $pkg = @_ ? ref($_[0]) || $_[0] : "";
    local *{$pkg . "::GLOB" . ++$seq};
    \delete ${$pkg . "::"}{'GLOB' . $seq};
}

my %socket_type = (
 tcp => SOCK_STREAM,
 udp => SOCK_DGRAM,
 rpc => SOCK_DGRAM,
);

# Peer     => remote host name for a 'connect' socket
# Proto    => specifiy protocol by it self (but override by Service)
# Service  => require service eg 'ftp' or 'ftp/tcp', overrides Proto
# Port     => port num for connect eg 'ftp' or 21, defaults to Service
# Bind     => port to bind to, defaults to INADDR_ANY
# Listen   => queue size for listen
#
# if Listen is defined then a listen socket is created, else if the socket
# type, which is derived from the protocol, is SOCK_STREAM then a connect
# is called

=head2 new( %args )

The new constructor takes its arguments in the form of a hash. Accepted 
arguments are

 Peer     => remote host name for a 'connect' socket
 Proto    => specifiy protocol by it self (but override by Service)
 Service  => require service eg 'ftp' or 'ftp/tcp', overrides Proto
 Port     => port num for connect eg 'ftp' or 21, defaults to Service
 Bind     => port to bind to, defaults to INADDR_ANY
 Listen   => queue size for listen

=cut

sub new {
 my $pkg = shift;
 my %arg = @_;

 my $proto    = $arg{Proto} || "";
 my $bindport = $arg{Bind}  || 0;
 my $servport = $arg{Port}  || 0;

 my $service  = $arg{Service} || $servport || $bindport;

 ($service,$proto) = split(m,/,, $service)
	if $service =~ m,/,;

 my @serv  = $service =~ /\D/ ? getservbyname($service,$proto)
                              : getservbyport($service,$proto);

 $proto = $proto || $serv[3];

 croak "cannot determine protocol"
	unless $proto;

 my @proto = $proto =~ /\D/ ? getprotobyname($proto)
                            : getprotobynumber($proto);

 croak "unknown protocol"
	unless @proto;

 my $type = $arg{Type} || $socket_type{$proto[0]} or
	croak "Unknown socket type";

 my $bindaddr = exists $arg{Addr} ? inet_aton($arg{Addr}) 
				  : INADDR_ANY;

 croak "bad bind address $arg{Addr}"
	unless $bindaddr;

 my $sock = bless _gensym(), ref($pkg) || $pkg;

 socket($sock, AF_INET, $type, $proto[2]) or
	croak "socket: $!";
 
 $bindport = (getservbyname($bindport,$proto))[2]
	if $bindport =~ /\D/;

 bind($sock, sockaddr_in($bindport, $bindaddr)) or
	croak "bind: $!";

 if(defined $arg{Listen})
  {
   my $queue = $arg{Listen} || 1;
 
   listen($sock, $queue) or
	croak "listen: $!";
  }
 else
  {
   $servport = $serv[2] || 0
	unless $servport =~ /^\d+$/ && $servport > 0;

   croak "cannot determine port"
	unless($servport);

   my $destaddr = defined $arg{Peer} ? inet_aton($arg{Peer})
				     : undef;

   my $peername = defined $destaddr ? sockaddr_in($servport,$destaddr)
				    : undef;
   
   
   if($type == SOCK_STREAM || $destaddr)
    {
     croak "bad peer address"
	unless defined $destaddr;
     
     connect($sock, $peername) or
	croak "connect: $!";

     ${*$sock}{Peername} = getpeername($sock);
    }
   else
    {
     ${*$sock}{Peername} = $peername;
    }
  }
 
 ${*$sock}{Sockname} = getsockname($sock);

 $sock;
}

=head2 autoflush( [$val] )

Set the file descriptor to autoflush, depending on C<$val>

=cut

sub autoflush {
 my $sock = shift;
 my $val = @_ ? shift : 0;

 select((select($sock), $| = $val)[$[]);
}

=head2 accept

perform the system call C<accept> on the socket and return a new Net::Socket
object. This object can be used to communicate with the client that was trying
to connect.

=cut

sub accept {
 my $sock = shift;

 my $new = bless _gensym();

 accept($new,$sock) or
	croak "accept: $!";

 ${*$new}{Peername} = getpeername($new) or
	croak "getpeername: $!";

 ${*$new}{Sockname} = getsockname($new) or
	croak "getsockname: $!";

 $new;
}

=head2 close

Close the file descriptor

=cut

sub close {
 my $sock = shift;

 delete ${*$sock}{Sockname};
 delete ${*$sock}{Peername};

 close($sock);
}

=head2 dup

Create a duplicate of the socket object

=cut

sub dup {
 my $sock = shift;
 my $dup = bless _gensym(), ref($sock);

 if(open($dup,">&" . fileno($sock))) { 
  # Copy all the internals
  ${*$dup} = ${*$sock};
  @{*$dup} = @{*$sock};
  %{*$dup} = %{*$sock};
 }
 else {
  undef $dup;
 }

 $dup;
}

# Some info about the local socket

=head2 sockname

Return a packed sockaddr structure for the socket

=head2 sockaddr

Return the address part of the sockaddr structure for the socket

=head2 sockport

Return the port number that the socket is using on the local host

=head2 sockhost

Return the address part of the sockaddr structure for the socket in a
text form xx.xx.xx.xx

=cut

sub sockname { my $sock = shift;  ${*$sock}{Sockname} }
sub sockaddr { (sockaddr_in(shift->sockname))[1]}
sub sockport { (sockaddr_in(shift->sockname))[0]}
sub sockhost { inet_ntoa( shift->sockaddr);}

# Some info about the remote socket, for connect-d sockets

=head2 peername, peeraddr, peerport, peerhost

Same as for the sock* functions, but returns the data about the peer
host instead of the local host.

=cut

sub peername { my $sock = shift;  ${*$sock}{Peername} or croak "no peer" }
sub peeraddr { (sockaddr_in(shift->peername))[1]}
sub peerport { (sockaddr_in(shift->peername))[0]}
sub peerhost { inet_ntoa( shift->peeraddr);}

=head2 send( $buf [, $flags [, $to]] )

For a udp socket, send the contents of C<$buf> to the remote host C<$to> using
flags C<$flags>. 

If C<$to> is not specified then the data is sent to the host which the socket
last communicated with, ie sent to or recieved from.

If C<$flags> is ommited then 0 is used

=cut

sub send {
 my $sock = shift;
 local *buf = \$_[0]; shift;
 my $flags = shift || 0;
 my $to = shift || $sock->peername;

 # remember who we send to
 ${*$sock}{Peername} = $to;

 send($sock, $buf, $flags, $to);
}

=head2 recv( $buf, $len [, $flags] )

Receive C<$len> bytes of data from the socket and place into C<$buf>

If C<$flags> is ommited then 0 is used

=cut

sub recv {
 my $sock = shift;
 local *buf = \$_[0]; shift;
 my $len = shift;
 my $flags = shift || 0;

 # remember who we recv'd from
 ${*$sock}{Peername} = recv($sock, $buf='', $len, $flags);
}

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 1.2 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1; # Keep require happy


