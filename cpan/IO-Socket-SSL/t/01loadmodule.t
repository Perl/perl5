use strict;
use warnings;
no warnings 'once';
use Test::More;

plan tests => 3;

ok( eval { require IO::Socket::SSL },"loaded");

diag( sprintf( "openssl version compiled=0x%0x linked=0x%0x -- %s", 
    Net::SSLeay::OPENSSL_VERSION_NUMBER(),
    Net::SSLeay::SSLeay(),
    Net::SSLeay::SSLeay_version(0)));

diag( sprintf( "Net::SSLeay version=%s", $Net::SSLeay::VERSION));
diag( sprintf( "parent %s version=%s", $_, $_->VERSION))
    for (@IO::Socket::SSL::ISA);

IO::Socket::SSL->import(':debug1');
is( $IO::Socket::SSL::DEBUG,1, "IO::Socket::SSL::DEBUG 1");
is( $Net::SSLeay::trace,1, "Net::SSLeay::trace 1");

