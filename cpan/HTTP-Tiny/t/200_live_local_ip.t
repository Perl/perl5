#!perl

use strict;
use warnings;

use IO::Socket::INET;
use Test::More 0.88;
use HTTP::Tiny;

my $test_host = "www.google.com";
my $test_url  = "http://www.google.com/";

plan 'skip_all' => "Only run for \$ENV{AUTOMATED_TESTING}"
  unless $ENV{AUTOMATED_TESTING};

plan 'skip_all' => "Internet connection timed out"
  unless IO::Socket::INET->new(
    PeerHost  => $test_host,
    PeerPort  => 80,
    Proto     => 'tcp',
    Timeout   => 10,
  );

my ($tiny, $response);

# default local address should work; try three times since the test url
# can have intermittent failures
$tiny = HTTP::Tiny->new;
for (1 .. 3) {
    $response = $tiny->get($test_url);
    last if $response->{success};
    sleep 2;
}
isnt( $response->{status}, '599', "Request to $test_url completed (default local address)" );

# bad local IP should fail
$tiny = HTTP::Tiny->new(local_address => '999.999.999.999'); # bad IP is error
$response = $tiny->get($test_url);
is( $response->{status}, '599', "Request to $test_url failed (invalid local address)" )
  or diag explain $response;

done_testing;
