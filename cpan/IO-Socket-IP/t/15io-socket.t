#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use IO::Socket;
use IO::Socket::IP -register;

my $sock = IO::Socket->new(
   Domain    => AF_INET,
   Type      => SOCK_STREAM,
   LocalHost => "127.0.0.1",
   LocalPort => 0,
);

isa_ok( $sock, "IO::Socket::IP", 'IO::Socket->new( Domain => AF_INET )' );

SKIP: {
   my $AF_INET6 = eval { Socket::AF_INET6() } ||
                  eval { require Socket6; Socket6::AF_INET6() };
   $AF_INET6 or skip "No AF_INET6", 1;
   eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
      skip "Unable to bind to ::1", 1;

   my $sock = IO::Socket->new(
      Domain    => $AF_INET6,
      Type      => SOCK_STREAM,
      LocalHost => "::1",
      LocalPort => 0,
   );

   isa_ok( $sock, "IO::Socket::IP", 'IO::Socket->new( Domain => AF_INET6 )' ) or
      diag( "  error was $@" );
}
