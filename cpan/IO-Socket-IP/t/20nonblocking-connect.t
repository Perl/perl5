#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

use IO::Socket::IP;

use IO::Socket::INET;
use Errno qw( EINPROGRESS EWOULDBLOCK );

my $testserver = IO::Socket::INET->new(
   Listen    => 1,
   LocalHost => "127.0.0.1",
   Type      => SOCK_STREAM,
) or die "Cannot listen on PF_INET - $@";

my $socket = IO::Socket::IP->new(
   PeerHost    => "127.0.0.1",
   PeerService => $testserver->sockport,
   Type        => SOCK_STREAM,
   Blocking    => 0,
);

ok( defined $socket, 'IO::Socket::IP->new( Blocking => 0 ) constructs a socket' ) or
   diag( "  error was $@" );

while( !$socket->connect and ( $! == EINPROGRESS || $! == EWOULDBLOCK ) ) {
   my $wvec = '';
   vec( $wvec, fileno $socket, 1 ) = 1;
   my $evec = '';
   vec( $evec, fileno $socket, 1 ) = 1;

   select( undef, $wvec, $evec, undef ) or die "Cannot select() - $!";
}

ok( !$!, 'Repeated ->connect eventually succeeds' );

is( $socket->sockdomain, AF_INET,     '$socket->sockdomain' );
is( $socket->socktype,   SOCK_STREAM, '$socket->socktype' );

is_deeply( [ unpack_sockaddr_in $socket->peername ],
           [ unpack_sockaddr_in $testserver->sockname ],
           '$socket->peername' );

is( $socket->peerhost, "127.0.0.1",           '$socket->peerhost' );
is( $socket->peerport, $testserver->sockport, '$socket->peerport' );

ok( !$socket->blocking, '$socket->blocking' );
