package Socket;

=head1 NAME

Socket - load the C socket.h defines and structure manipulators

=head1 SYNOPSIS

    use Socket;

    $proto = (getprotobyname('udp'))[2];         
    socket(Socket_Handle, PF_INET, SOCK_DGRAM, $proto);
    $sockaddr_in = pack_sockaddr_in(AF_INET,7,inet_aton("localhost"));
    $sockaddr_in = pack_sockaddr_in(AF_INET,7,INADDR_LOOPBACK);
    connect(Socket_Handle,$sockaddr_in);
    $peer = inet_ntoa((unpack_sockaddr_in(getpeername(Socket_Handle)))[2]);


=head1 DESCRIPTION

This module is just a translation of the C F<socket.h> file.
Unlike the old mechanism of requiring a translated F<socket.ph>
file, this uses the B<h2xs> program (see the Perl source distribution)
and your native C compiler.  This means that it has a 
far more likely chance of getting the numbers right.

In addition, some structure manipulation functions are available:

=item inet_aton HOSTNAME

Takes a string giving the name of a host, and translates that
to the 4-byte string (structure). Takes arguments of both
the 'rtfm.mit.edu' type and '18.181.0.24'. If the host name
cannot be resolved, returns undef.

=item inet_ntoa IP_ADDRESS

Takes a four byte ip address (as returned by inet_aton())
and translates it into a string of the form 'd.d.d.d'
where the 'd's are numbers less than 256 (the normal
readable four dotted number notation for internet addresses).

=item INADDR_ANY

Note - does not return a number.

Returns the 4-byte wildcard ip address which specifies any
of the hosts ip addresses. (A particular machine can have
more than one ip address, each address corresponding to
a particular network interface. This wildcard address
allows you to bind to all of them simultaneously.)
Normally equivalent to inet_aton('0.0.0.0').

=item INADDR_LOOPBACK

Note - does not return a number.

Returns the 4-byte loopback address. Normally equivalent
to inet_aton('localhost').

=item INADDR_NONE

Note - does not return a number.

Returns the 4-byte invalid ip address. Normally equivalent
to inet_aton('255.255.255.255').

=item pack_sockaddr_in FAMILY, PORT, IP_ADDRESS

Takes three arguments, an address family (normally AF_INET),
a port number, and a 4 byte IP_ADDRESS (as returned by
inet_aton()). Returns the sockaddr_in structure with those
arguments packed in. For internet domain sockets, this structure
is normally what you need for the arguments in bind(), connect(),
and send(), and is also returned by getpeername(), getsockname()
and recv().

=item unpack_sockaddr_in SOCKADDR_IN

Takes a sockaddr_in structure (as returned by pack_sockaddr_in())
and returns an array of three elements: the address family,
the port, and the 4-byte ip-address.

=cut

use Carp;

require Exporter;
use AutoLoader;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
	inet_aton inet_ntoa pack_sockaddr_in unpack_sockaddr_in
	INADDR_ANY INADDR_LOOPBACK INADDR_NONE
	AF_802
	AF_APPLETALK
	AF_CCITT
	AF_CHAOS
	AF_DATAKIT
	AF_DECnet
	AF_DLI
	AF_ECMA
	AF_GOSIP
	AF_HYLINK
	AF_IMPLINK
	AF_INET
	AF_LAT
	AF_MAX
	AF_NBS
	AF_NIT
	AF_NS
	AF_OSI
	AF_OSINET
	AF_PUP
	AF_SNA
	AF_UNIX
	AF_UNSPEC
	AF_X25
	MSG_DONTROUTE
	MSG_MAXIOVLEN
	MSG_OOB
	MSG_PEEK
	PF_802
	PF_APPLETALK
	PF_CCITT
	PF_CHAOS
	PF_DATAKIT
	PF_DECnet
	PF_DLI
	PF_ECMA
	PF_GOSIP
	PF_HYLINK
	PF_IMPLINK
	PF_INET
	PF_LAT
	PF_MAX
	PF_NBS
	PF_NIT
	PF_NS
	PF_OSI
	PF_OSINET
	PF_PUP
	PF_SNA
	PF_UNIX
	PF_UNSPEC
	PF_X25
	SOCK_DGRAM
	SOCK_RAW
	SOCK_RDM
	SOCK_SEQPACKET
	SOCK_STREAM
	SOL_SOCKET
	SOMAXCONN
	SO_ACCEPTCONN
	SO_BROADCAST
	SO_DEBUG
	SO_DONTLINGER
	SO_DONTROUTE
	SO_ERROR
	SO_KEEPALIVE
	SO_LINGER
	SO_OOBINLINE
	SO_RCVBUF
	SO_RCVLOWAT
	SO_RCVTIMEO
	SO_REUSEADDR
	SO_SNDBUF
	SO_SNDLOWAT
	SO_SNDTIMEO
	SO_TYPE
	SO_USELOOPBACK
);

sub AUTOLOAD {
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    croak "Your vendor has not defined Socket macro $constname, used";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Socket;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
