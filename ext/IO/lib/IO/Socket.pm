#

package IO::Socket;

=head1 NAME

IO::Socket - supply object methods for sockets

=head1 SYNOPSIS

    use IO::Socket;

=head1 DESCRIPTION

C<IO::Socket> provides an object interface to creating and using sockets. It
is built upon the L<IO::Handle> interface and inherits all the methods defined
by L<IO::Handle>.

C<IO::Socket> only defines methods for those operations which are common to all
types of socket. Operations which are specified to a socket in a particular 
domain have methods defined in sub classes of C<IO::Socket>

See L<perlfunc> for complete descriptions of each of the following
supported C<IO::Seekable> methods, which are just front ends for the
corresponding built-in functions:

    socket
    socketpair
    bind
    listen
    accept
    send
    recv
    peername (getpeername)
    sockname (getsockname)

Some methods take slightly different arguments to those defined in L<perlfunc>
in attempt to make the interface more flexible. These are

=item accept([PKG])

perform the system call C<accept> on the socket and return a new object. The
new object will be created in the same class as the listen socket, unless
C<PKG> is specified. This object can be used to communicate with the client
that was trying to connect. In a scalar context the new socket is returned,
or undef upon failure. In an array context a two-element array is returned
containing the new socket and the peer address, the list will
be empty upon failure.

Additional methods that are provided are

=item timeout([VAL])

Set or get the timeout value associated with this socket. If called without
any arguments then the current setting is returned. If called with an argument
the current setting is changed and the previous value returned.

=item sockopt(OPT [, VAL])

Unified method to both set and get options in the SOL_SOCKET level. If called
with one argument then getsockopt is called, otherwise setsockopt is called

=cut


require 5.000;

use Config;
use IO::Handle;
use Socket 1.3;
use Carp;
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
use Exporter;

@ISA = qw(IO::Handle);

# This one will turn 1.2 => 1.02 and 1.2.3 => 1.0203 and so on ...

$VERSION = do{my @r=(q$Revision: 1.9 $=~/(\d+)/g);sprintf "%d."."%02d"x$#r,@r};

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export 'Socket', $callpkg, @_;
}

sub new {
    my($class,%arg) = @_;
    my $fh = $class->SUPER::new();

    ${*$fh}{'io_socket_timeout'} = delete $arg{Timeout};

    return scalar(%arg) ? $fh->configure(\%arg)
			: $fh;
}

sub configure {
    croak 'IO::Socket: Cannot configure a generic socket';
}

sub socket {
    @_ == 4 or croak 'usage: $fh->socket(DOMAIN, TYPE, PROTOCOL)';
    my($fh,$domain,$type,$protocol) = @_;

    socket($fh,$domain,$type,$protocol) or
    	return undef;

    ${*$fh}{'io_socket_type'} = $type;
    $fh;
}

sub socketpair {
    @_ == 4 || croak 'usage: IO::Socket->pair(DOMAIN, TYPE, PROTOCOL)';
    my($class,$domain,$type,$protocol) = @_;
    my $fh1 = $class->new();
    my $fh2 = $class->new();

    socketpair($fh1,$fh1,$domain,$type,$protocol) or
    	return ();

    ${*$fh1}{'io_socket_type'} = ${*$fh2}{'io_socket_type'} = $type;

    ($fh1,$fh2);
}

sub connect {
    @_ == 2 || @_ == 3 or croak 'usage: $fh->connect(NAME) or $fh->connect(PORT, ADDR)';
    my $fh = shift;
    my $addr = @_ == 1 ? shift : sockaddr_in(@_);
    my $timeout = ${*$fh}{'io_socket_timeout'};
    local($SIG{ALRM}) = $timeout ? sub { undef $fh; }
				 : $SIG{ALRM} || 'DEFAULT';

     eval {
    	croak 'connect: Bad address'
    	    if(@_ == 2 && !defined $_[1]);

    	if($timeout) {
    	    defined $Config{d_alarm} && defined alarm($timeout) or
    	    	$timeout = 0;
    	}

	my $ok = connect($fh, $addr);

    	alarm(0)
    	    if($timeout);

	croak "connect: timeout"
	    unless defined $fh;

	undef $fh unless $ok;
    };

    $fh;
}

sub bind {
    @_ == 2 || @_ == 3 or croak 'usage: $fh->bind(NAME) or $fh->bind(PORT, ADDR)';
    my $fh = shift;
    my $addr = @_ == 1 ? shift : sockaddr_in(@_);

    return bind($fh, $addr) ? $fh
			    : undef;
}

sub listen {
    @_ >= 1 && @_ <= 2 or croak 'usage: $fh->listen([QUEUE])';
    my($fh,$queue) = @_;
    $queue = 5
	unless $queue && $queue > 0;

    return listen($fh, $queue) ? $fh
			       : undef;
}

sub accept {
    @_ == 1 || @_ == 2 or croak 'usage $fh->accept([PKG])';
    my $fh = shift;
    my $pkg = shift || $fh;
    my $timeout = ${*$fh}{'io_socket_timeout'};
    my $new = $pkg->new(Timeout => $timeout);
    my $peer = undef;

    eval {
    	if($timeout) {
    	    my $fdset = "";
    	    vec($fdset, $fh->fileno,1) = 1;
    	    croak "accept: timeout"
    	    	unless select($fdset,undef,undef,$timeout);
    	}
    	$peer = accept($new,$fh);
    };

    return wantarray ? defined $peer ? ($new, $peer)
    	    	    	    	     : () 
    	      	     : defined $peer ? $new
    	    	    	    	     : undef;
}

sub sockname {
    @_ == 1 or croak 'usage: $fh->sockname()';
    getsockname($_[0]);
}

sub peername {
    @_ == 1 or croak 'usage: $fh->peername()';
    my($fh) = @_;
    getpeername($fh)
      || ${*$fh}{'io_socket_peername'}
      || undef;
}

sub send {
    @_ >= 2 && @_ <= 4 or croak 'usage: $fh->send(BUF, [FLAGS, [TO]])';
    my $fh    = $_[0];
    my $flags = $_[2] || 0;
    my $peer  = $_[3] || $fh->peername;

    croak 'send: Cannot determine peer address'
	 unless($peer);

    my $r = send($fh, $_[1], $flags, $peer);

    # remember who we send to, if it was sucessful
    ${*$fh}{'io_socket_peername'} = $peer
	if(@_ == 4 && defined $r);

    $r;
}

sub recv {
    @_ == 3 || @_ == 4 or croak 'usage: $fh->recv(BUF, LEN [, FLAGS])';
    my $sock  = $_[0];
    my $len   = $_[2];
    my $flags = $_[3] || 0;

    # remember who we recv'd from
    ${*$sock}{'io_socket_peername'} = recv($sock, $_[1]='', $len, $flags);
}


sub setsockopt {
    @_ == 4 or croak '$fh->setsockopt(LEVEL, OPTNAME)';
    setsockopt($_[0],$_[1],$_[2],$_[3]);
}

my $intsize = length(pack("i",0));

sub getsockopt {
    @_ == 3 or croak '$fh->getsockopt(LEVEL, OPTNAME)';
    my $r = getsockopt($_[0],$_[1],$_[2]);
    # Just a guess
    $r = unpack("i", $r)
	if(defined $r && length($r) == $intsize);
    $r;
}

sub sockopt {
    my $fh = shift;
    @_ == 1 ? $fh->getsockopt(SOL_SOCKET,@_)
	    : $fh->setsockopt(SOL_SOCKET,@_);
}

sub timeout {
    @_ == 1 || @_ == 2 or croak 'usage: $fh->timeout([VALUE])';
    my($fh,$val) = @_;
    my $r = ${*$fh}{'io_socket_timeout'} || undef;

    ${*$fh}{'io_socket_timeout'} = 0 + $val
	if(@_ == 2);

    $r;
}

sub socktype {
    @_ == 1 or croak '$fh->socktype()';
    ${*{$_[0]}}{'io_socket_type'} || undef;
}

=head1 SUB-CLASSES

=cut

##
## AF_INET
##

package IO::Socket::INET;

use strict;
use vars qw(@ISA $VERSION);
use Socket;
use Carp;
use Exporter;

@ISA = qw(IO::Socket);

my %socket_type = ( tcp => SOCK_STREAM,
		    udp => SOCK_DGRAM,
		  );

=head2 IO::Socket::INET

C<IO::Socket::INET> provides a constructor to create an AF_INET domain socket
and some related methods. The constructor can take the following options

    PeerAddr	Remote host address
    PeerPort	Remote port or service
    LocalPort	Local host bind	port
    LocalAddr	Local host bind	address
    Proto	Protocol name (eg tcp udp etc)
    Type	Socket type (SOCK_STREAM etc)
    Listen	Queue size for listen
    Timeout	Timeout	value for various operations

If Listen is defined then a listen socket is created, else if the socket
type,   which is derived from the protocol, is SOCK_STREAM then a connect
is called

Only one of C<Type> or C<Proto> needs to be specified, one will be assumed
from the other.

=head2 METHODS

=item sockaddr()

Return the address part of the sockaddr structure for the socket

=item sockport()

Return the port number that the socket is using on the local host

=item sockhost()

Return the address part of the sockaddr structure for the socket in a
text form xx.xx.xx.xx

=item peeraddr(), peerport(), peerhost()

Same as for the sock* functions, but returns the data about the peer
host instead of the local host.

=cut


sub _sock_info {
  my($addr,$port,$proto) = @_;
  my @proto = ();
  my @serv = ();

  $port = $1
	if(defined $addr && $addr =~ s,:([\w\(\)/]+)$,,);

  if(defined $proto) {
    @proto = $proto =~ m,\D, ? getprotobyname($proto)
			     : getprotobynumber($proto);

    $proto = $proto[2] || undef;
  }

  if(defined $port) {
    $port =~ s,\((\d+)\)$,,;

    my $defport = $1 || undef;
    my $pnum = ($port =~ m,^(\d+)$,)[0];

    @serv= getservbyname($port, $proto[0] || "")
	if($port =~ m,\D,);

    $port = $pnum || $serv[2] || $defport || undef;

    $proto = (getprotobyname($serv[3]))[2] || undef
	if @serv && !$proto;
  }

 return ($addr || undef,
	 $port || undef,
	 $proto || undef
	);
}

sub configure {
    my($fh,$arg) = @_;
    my($lport,$rport,$laddr,$raddr,$proto,$type);


    ($laddr,$lport,$proto) = _sock_info($arg->{LocalAddr},
					$arg->{LocalPort},
					$arg->{Proto});

    $laddr = defined $laddr ? inet_aton($laddr)
			    : INADDR_ANY;

    unless(exists $arg->{Listen}) {
	($raddr,$rport,$proto) = _sock_info($arg->{PeerAddr},
					    $arg->{PeerPort},
					    $proto);
    }

    croak 'IO::Socket: Cannot determine protocol'
	unless($proto);

    my $pname = (getprotobynumber($proto))[0];
    $type = $arg->{Type} || $socket_type{$pname};

    $fh->socket(AF_INET, $type, $proto) or
	return undef;

    $fh->bind($lport || 0, $laddr) or
	return undef;

    if(exists $arg->{Listen}) {
	$fh->listen($arg->{Listen} || 5) or
	    return undef;
    }
    else {
	croak "IO::Socket: Cannot determine remote port"
		unless($rport || $type == SOCK_DGRAM);

	if($type == SOCK_STREAM || defined $raddr) {
	    croak "IO::Socket: Bad peer address"
		unless defined $raddr;

	    $fh->connect($rport,inet_aton($raddr)) or
		return undef;
	}
    }

    $fh;
}

sub sockaddr {
    @_ == 1 or croak 'usage: $fh->sockaddr()';
    my($fh) = @_;
    (sockaddr_in($fh->sockname))[1];
}

sub sockport {
    @_ == 1 or croak 'usage: $fh->sockport()';
    my($fh) = @_;
    (sockaddr_in($fh->sockname))[0];
}

sub sockhost {
    @_ == 1 or croak 'usage: $fh->sockhost()';
    my($fh) = @_;
    inet_ntoa($fh->sockaddr);
}

sub peeraddr {
    @_ == 1 or croak 'usage: $fh->peeraddr()';
    my($fh) = @_;
    (sockaddr_in($fh->peername))[1];
}

sub peerport {
    @_ == 1 or croak 'usage: $fh->peerport()';
    my($fh) = @_;
    (sockaddr_in($fh->peername))[0];
}

sub peerhost {
    @_ == 1 or croak 'usage: $fh->peerhost()';
    my($fh) = @_;
    inet_ntoa($fh->peeraddr);
}

##
## AF_UNIX
##

package IO::Socket::UNIX;

use strict;
use vars qw(@ISA $VERSION);
use Socket;
use Carp;
use Exporter;

@ISA = qw(IO::Socket);

=head2 IO::Socket::UNIX

C<IO::Socket::UNIX> provides a constructor to create an AF_UNIX domain socket
and some related methods. The constructor can take the following options

    Type    	Type of socket (eg SOCK_STREAM or SOCK_DGRAM)
    Local   	Path to local fifo
    Peer    	Path to peer fifo
    Listen  	Create a listen socket

=head2 METHODS

=item hostpath()

Returns the pathname to the fifo at the local end

=item peerpath()

Returns the pathanme to the fifo at the peer end

=cut

sub configure {
    my($fh,$arg) = @_;
    my($bport,$cport);

    my $type = $arg->{Type} || SOCK_STREAM;

    $fh->socket(AF_UNIX, $type, 0) or
	return undef;

    if(exists $arg->{Local}) {
	my $addr = sockaddr_un($arg->{Local});
	$fh->bind($addr) or
	    return undef;
    }
    if(exists $arg->{Listen}) {
	$fh->listen($arg->{Listen} || 5) or
	    return undef;
    }
    elsif(exists $arg->{Peer}) {
	my $addr = sockaddr_un($arg->{Peer});
	$fh->connect($addr) or
	    return undef;
    }

    $fh;
}

sub hostpath {
    @_ == 1 or croak 'usage: $fh->hostpath()';
    (sockaddr_un($_[0]->hostname))[0];
}

sub peerpath {
    @_ == 1 or croak 'usage: $fh->peerpath()';
    (sockaddr_un($_[0]->peername))[0];
}

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 1.9 $

The VERSION is derived from the revision turning each number after the
first dot into a 2 digit number so

	Revision 1.8   => VERSION 1.08
	Revision 1.2.3 => VERSION 1.0203

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1; # Keep require happy
