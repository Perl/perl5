#!/usr/bin/perl -w

use strict;
use Test::More;

use IO::Socket::IP;
use Socket;

my $AF_INET6 = eval { require Socket and Socket::AF_INET6() } or
   plan skip_all => "No AF_INET6";

eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
   plan skip_all => "Unable to bind to ::1";

plan tests => 26;

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::IP->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Type      => Socket->$socktype,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $socktype socket" ) or
      diag( "  error was $@" );

   is( $testserver->sockdomain, $AF_INET6,         "\$testserver->sockdomain for $socktype" );
   is( $testserver->socktype,   Socket->$socktype, "\$testserver->socktype for $socktype" );

   is( $testserver->sockhost, "::1",       "\$testserver->sockhost for $socktype" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $socktype" );

   my $socket = IO::Socket->new;
   $socket->socket( $AF_INET6, Socket->$socktype, 0 )
      or die "Cannot socket() - $!";
   $socket->connect( Socket::pack_sockaddr_in6( $testserver->sockport, Socket::inet_pton( $AF_INET6, "::1" ) ) )
      or die "Cannot connect() - $!";

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $socktype" );

   is( $testclient->sockdomain, $AF_INET6,         "\$testclient->sockdomain for $socktype" );
   is( $testclient->socktype,   Socket->$socktype, "\$testclient->socktype for $socktype" );

   is_deeply( [ Socket::unpack_sockaddr_in6( $socket->sockname ) ],
              [ Socket::unpack_sockaddr_in6( $testclient->peername ) ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ Socket::unpack_sockaddr_in6( $socket->peername ) ],
              [ Socket::unpack_sockaddr_in6( $testclient->sockname ) ],
              "\$socket->peername for $socktype" );

   my $peerport = ( Socket::unpack_sockaddr_in6 $socket->peername )[0];
   my $sockport = ( Socket::unpack_sockaddr_in6 $socket->sockname )[0];

   is( $testclient->sockport, $peerport, "\$testclient->sockport for $socktype" );
   is( $testclient->peerport, $sockport, "\$testclient->peerport for $socktype" );
}
