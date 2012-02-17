#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;
use IO::Socket::INET;
use Socket;
use Test::More;

plan tests => 7;

my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1',
                                     Proto => 'udp');
ok(defined($listener), 'socket created');

my $p = $listener->protocol();
ok(defined($p), 'protocol defined');
my $d = $listener->sockdomain();
ok(defined($d), 'domain defined');
my $s = $listener->socktype();
ok(defined($s), 'type defined');

my $new = IO::Socket::INET->new_from_fd($listener->fileno(), 'r+');

is($new->sockdomain(), $d, 'domain match');
SKIP: {
    skip "no Socket::SO_PROTOCOL", 1 if !defined(eval { Socket::SO_PROTOCOL });
    is($new->protocol(), $p, 'protocol match');
}
SKIP: {
    skip "no Socket::SO_TYPE", 1 if !defined(eval { Socket::SO_TYPE });
    is($new->socktype(), $s, 'type match');
}
