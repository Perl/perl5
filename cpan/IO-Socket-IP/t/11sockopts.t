#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use IO::Socket::IP;

use Socket qw( SOL_SOCKET SO_REUSEADDR SO_REUSEPORT SO_BROADCAST );

{
   my $sock = IO::Socket::IP->new(
      LocalHost => "127.0.0.1",
      Type      => SOCK_STREAM,
      Listen    => 1,
      ReuseAddr => 1,
   ) or die "Cannot socket() - $@";

   ok( $sock->getsockopt( SOL_SOCKET, SO_REUSEADDR ), 'SO_REUSEADDR set' );
}

SKIP: {
   # Some OSes don't implement SO_REUSEPORT
   skip "No SO_REUSEPORT", 1 unless defined eval { SO_REUSEPORT };

   my $sock = IO::Socket::IP->new(
      LocalHost => "127.0.0.1",
      Type      => SOCK_STREAM,
      Listen    => 1,
      ReusePort => 1,
   ) or die "Cannot socket() - $@";

   ok( $sock->getsockopt( SOL_SOCKET, SO_REUSEPORT ), 'SO_REUSEPORT set' );
}

{
   my $sock = IO::Socket::IP->new(
      LocalHost => "127.0.0.1",
      Type      => SOCK_DGRAM,
      Broadcast => 1,
   ) or die "Cannot socket() - $@";

   ok( $sock->getsockopt( SOL_SOCKET, SO_BROADCAST ), 'SO_BROADCAST set' );
}
