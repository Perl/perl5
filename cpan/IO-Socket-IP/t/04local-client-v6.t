#!/usr/bin/perl -w

use strict;
use Test::More;

use IO::Socket::IP;
use Socket;

my $AF_INET6 = eval { require Socket and Socket::AF_INET6() } or
   plan skip_all => "No AF_INET6";

eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
   plan skip_all => "Unable to bind to ::1";

plan tests => 16;

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket->new;
   $testserver->socket( $AF_INET6, Socket->$socktype, 0 )
      or die "Cannot socket() - $!";
   $testserver->bind( Socket::pack_sockaddr_in6( 0, Socket::inet_pton( $AF_INET6, "::1" ) ) ) or
      die "Cannot bind() - $!";
   if( $socktype eq "SOCK_STREAM" ) {
      $testserver->listen( 1 ) or die "Cannot listen() - $!";
   }

   my $testport = ( Socket::unpack_sockaddr_in6 $testserver->sockname )[0];

   my $socket = IO::Socket::IP->new(
      PeerHost    => "::1",
      PeerService => $testport,
      Type        => Socket->$socktype,
   );

   ok( defined $socket, "IO::Socket::IP->new constructs a $socktype socket" ) or
      diag( "  error was $@" );

   is( $socket->sockdomain, $AF_INET6,         "\$socket->sockdomain for $socktype" );
   is( $socket->socktype,   Socket->$socktype, "\$socket->socktype for $socktype" );

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );

   is_deeply( [ Socket::unpack_sockaddr_in6( $socket->sockname ) ],
              [ Socket::unpack_sockaddr_in6( $testclient->peername ) ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ Socket::unpack_sockaddr_in6( $socket->peername ) ],
              [ Socket::unpack_sockaddr_in6( $testclient->sockname ) ],
              "\$socket->peername for $socktype" );

   is( $socket->peerhost, "::1",     "\$socket->peerhost for $socktype" );
   is( $socket->peerport, $testport, "\$socket->peerport for $socktype" );

   # Can't easily test the non-numeric versions without relying on the system's
   # ability to resolve the name "localhost"
}
