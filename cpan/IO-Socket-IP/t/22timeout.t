#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
plan skip_all => "CPAN RT#98976" if $^O eq "MSWin32";

use IO::Socket::IP;

my $server = IO::Socket::IP->new(
   Listen    => 1,
   LocalHost => "127.0.0.1",
   LocalPort => 0,
) or die "Cannot listen on PF_INET - $!";

my $client = IO::Socket::IP->new(
   PeerHost => $server->sockhost,
   PeerPort => $server->sockport,
   Timeout  => 0.1,
) or die "Cannot connect on PF_INET - $!";

ok( defined $client, 'client constructed with Timeout' );

my $accepted = $server->accept
   or die "Cannot accept - $!";

ok( defined $accepted, 'accepted a client' );

done_testing;
