package Socket;

=head1 NAME

Socket - load the C socket.h defines

=head1 SYNOPSIS

    use Socket;

    $proto = (getprotobyname('udp'))[2];         
    socket(Socket_Handle, PF_INET, SOCK_DGRAM, $proto); 

=head1 DESCRIPTION

This module is just a translation of the C F<socket.h> file.
Unlike the old mechanism of requiring a translated F<socket.ph>
file, this uses the B<h2xs> program (see the Perl source distribution)
and your native C compiler.  This means that it has a 
far more likely chance of getting the numbers right.

=head1 NOTE

Only C<#define> symbols get translated; you must still correctly
pack up your own arguments to pass to bind(), etc.

=cut

use Carp;

require Exporter;
use AutoLoader;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
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


# pack a sockaddr_in structure for use in bind() calls.
# (here to hide the 'S n C4 x8' magic from applications)
sub sockaddr_in{
    my($af, $port, @quad) = @_;
    my $pack = 'S n C4 x8'; # lookup $pack from hash using $af?
    pack($pack, $af, $port, @quad);
}


bootstrap Socket;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
