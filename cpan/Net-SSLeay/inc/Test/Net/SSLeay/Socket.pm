package Test::Net::SSLeay::Socket;

use 5.008001;
use strict;
use warnings;

use Carp qw(croak);
use English qw( $EVAL_ERROR $OS_ERROR $OUTPUT_AUTOFLUSH -no_match_vars );
use Scalar::Util qw(refaddr reftype);
use SelectSaver;
use Socket qw(
    AF_INET SOCK_DGRAM SOCK_STREAM
    inet_aton inet_ntoa pack_sockaddr_in unpack_sockaddr_in
);

our $VERSION = '1.92';

my %PROTOS = (
    tcp => SOCK_STREAM,
    udp => SOCK_DGRAM,
);

sub new {
    my ( $class, %args ) = @_;

    my $self  = bless {
        addr  => delete $args{addr}  || '127.0.0.1',
        port  => delete $args{port}  || 0,
        proto => delete $args{proto} || 'tcp',
        queue => delete $args{queue} || 5,
    }, $class;

    if ( !exists $PROTOS{ $self->{proto} } ) {
        croak "Unknown protocol '$self->{proto}'";
    }

    $self->_init_server();

    return $self;
}

sub _init_server {
    my ($self) = @_;

    my $addr = eval { inet_aton( $self->{addr} ) }
        or croak 'Could not pack IP address'
        . ( $EVAL_ERROR ? ": $EVAL_ERROR" : q{} );

    my $sockaddr = eval { pack_sockaddr_in( $self->{port}, $addr ) }
        or croak 'Could not create sockaddr_in structure'
        . ( $EVAL_ERROR ? ": $EVAL_ERROR" : q{} );

    socket $self->{sock}, AF_INET, $PROTOS{ $self->{proto} }, 0
        or croak "Could not open server socket: $OS_ERROR";

    if ( $self->{proto} eq 'tcp' ) {
        bind $self->{sock}, $sockaddr
            or croak "Could not bind server socket: $OS_ERROR";

        listen $self->{sock}, $self->{queue}
            or croak "Could not listen on server socket: $OS_ERROR";
    }

    my $sockname = getsockname $self->{sock};
    ( $self->{sport}, $self->{saddr} ) = unpack_sockaddr_in($sockname);
    $self->{saddr} = inet_ntoa( $self->{saddr} );

    return 1;
}

sub get_addr {
    my ($self) = @_;

    return $self->{saddr};
}

sub get_port {
    my ($self) = @_;

    return $self->{sport};
}

sub accept {
    my ( $self, $sock ) = @_;

    if ( defined $sock && reftype($sock) ne 'GLOB' ) {
        croak 'Argument #1 to accept() must be a typeglob reference';
    }

    accept $sock, $self->{sock}
        or croak "Could not accept connection: $OS_ERROR";

    my $saver = SelectSaver->new($sock);
    local $OUTPUT_AUTOFLUSH = 1;

    return $sock;
}

sub connect {
    my ($self) = @_;

    my $addr = eval { inet_aton( $self->{saddr} ) }
        or croak 'Could not pack IP address'
        . ( $EVAL_ERROR ? ": $EVAL_ERROR" : q{} );

    my $sockaddr = eval { pack_sockaddr_in( $self->{sport}, $addr ) }
        or croak 'Could not create sockaddr_in structure'
        . ( $EVAL_ERROR ? ": $EVAL_ERROR" : q{} );

    socket my $sock, AF_INET, $PROTOS{ $self->{proto} }, 0
        or croak "Could not open server socket: $OS_ERROR";
    connect $sock, $sockaddr
        or croak "Could not connect to server socket: $OS_ERROR";

    my $saver = SelectSaver->new($sock);
    local $OUTPUT_AUTOFLUSH = 1;

    return $sock;
}

sub close {
    my ($self) = @_;

    return close $self->{sock};
}

1;

__END__

=head1 NAME

Test::Net::SSLeay::Socket - Socket class for the Net-SSLeay test suite

=head1 VERSION

This document describes version 1.92 of Test::Net::SSLeay::Socket.

=head1 SYNOPSIS

    use Test::Net::SSLeay::Socket;

    # Create TCP server socket listening on localhost on a random unused port
    my $server = Test::Net::SSLeay::Socket->new( protocol => 'tcp' );

    # To wait for a connection to the server socket:
    my $sock = $server->accept();

    # Open a connection to the server socket:
    my $client_sock = $server->connect();

    # Or do so using Net::SSLeay's high-level API:
    use Net::SSLeay qw(tcpcat);
    my ( $response, $err ) =
        tcpcat( $server->get_addr(), $server->get_port(), 'request' );

=head1 DESCRIPTION

Test scripts in the Net-SSLeay test suite commonly need to establish server
and client sockets over which TLS communication can be tested. This module
simplifies the process of creating server sockets and client sockets that know
how to connect to them.

This module is not intended to be used directly by test scripts; use the
helper functions in L<Test::Net::SSLeay|Test::Net::SSLeay/"HELPER FUNCTIONS">
instead.

=head1 CONSTRUCTOR

=head2 new

    # TCP server socket listening on localhost on a random unused port:
    my $server = Test::Net::SSLeay::Socket->new();

    # TCP server socket listening on a private IP address on the standard HTTP
    # port:
    my $server = Test::Net::SSLeay::Socket->new(
        addr  => '10.0.0.1',
        port  => 80,
        proto => 'tcp',
    );

Creates a new C<Test::Net::SSLeay::Socket> object. A server socket is created
that binds to a given (or the default) address and port number.

Supported options:

=over 4

=item *

C<addr> (optional): the IPv4 address that the server socket should bind to.
Defaults to C<'127.0.0.1'>.

=item *

C<port> (optional): the port number that the server socket should bind to.
Defaults to the number of a random unused port chosen by the operating system.

=item *

C<proto> (optional): the transport protocol that the server socket should use;
C<'tcp'> for TCP, C<'udp'> for UDP. Defaults to C<'tcp'>.

=item *

C<queue> (optional): the maximum number of pending connections to allow for
the server socket. Defaults to 5.

=back

Dies on failure.

=head1 METHODS

=head2 get_addr

    my $address = $server->get_addr();

Returns the address on which the server socket is listening. Useful when
manually creating a connection to the server socket (e.g. via one of
Net::SSLeay's high-level API functions) and an address was not specified in
the constructor.

=head2 get_port

    my $port = $server->get_port();

Returns the port number on which the server socket is listening. Useful when
manually creating a client socket to connect to the server socket (e.g. via
one of Net::SSLeay's high-level API functions) and a port number was not
specified in the constructor.

=head2 accept

    # Communicate with the client, creating a new file handle:
    my $sock = $server->accept();

    # Communicate with the client using an existing typeglob as the file
    # handle:
    $server->accept(*Net::SSLeay::SSLCAT_S);

Accepts an incoming connection request to the server socket, and enables
autoflush on the resulting file handle.

If a typeglob is passed as the first argument, it becomes the socket's file
handle. This is useful when creating sockets for testing Net::SSLeay's
high-level API functions, which perform their operations on the
C<Net::SSLeay::SSLCAT_S> typeglob.

Returns the file handle for the new socket. Dies on failure.

=head2 connect

    my $sock = $server->connect();

Creates a new connection to the server socket, and enables autoflush on the
resulting file handle.

Returns the file handle for the new socket. Dies on failure.

=head2 close

    $server->close();

Closes the file handle for the server socket.

Returns true on success, or false on failure (just like Perl's
L<close|perlfunc/close> builtin).

=head1 SEE ALSO

L<Test::Net::SSLeay|Test::Net::SSLeay>, for an easier way to use this module
from Net-SSLeay test scripts.

=head1 BUGS

If you encounter a problem with this module that you believe is a bug, please
L<create a new issue|https://github.com/radiator-software/p5-net-ssleay/issues/new>
in the Net-SSLeay GitHub repository. Please make sure your bug report includes
the following information:

=over

=item *

the code you are trying to run (ideally a minimum working example that
reproduces the problem), or the full output of the Net-SSLeay test suite if
the problem relates to a test failure;

=item *

your operating system name and version;

=item *

the output of C<perl -V>;

=item *

the version of Net-SSLeay you are using;

=item *

the version of OpenSSL or LibreSSL you are using.

=back

=head1 AUTHORS

Originally written by Chris Novakovic.

Maintained by Chris Novakovic, Tuure Vartiainen and Heikki Vatiainen.

=head1 COPYRIGHT AND LICENSE

Copyright 2020- Chris Novakovic <chris@chrisn.me.uk>.

Copyright 2020- Tuure Vartiainen <vartiait@radiatorsoftware.com>.

Copyright 2020- Heikki Vatiainen <hvn@radiatorsoftware.com>.

This module is released under the terms of the Artistic License 2.0. For
details, see the C<LICENSE> file distributed with Net-SSLeay's source code.

=cut
