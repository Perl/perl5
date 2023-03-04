#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my @uris = qw(
	www.google.com
	www.microsoft.com
	www.kernel.org
);
@uris = split(/:/, $ENV{SSLEAY_URIS}) if exists $ENV{SSLEAY_URIS};
if (@uris) {
    plan tests => scalar @uris * 2;
}
else {
    plan skip_all => 'No external hosts specified for SSL testing';
}

use File::Spec;
use Symbol qw(gensym);
use Net::SSLeay::Handle;

# On some platforms, such as Solaris, the act of resolving the host name
# opens (and leaves open) a connection to the DNS client, which breaks 
# the fd counting algorithm below. Make sure the DNS is operating before
# we count the FDs for the first time.
for my $uri (@uris) {
    my $dummy = gethostbyname($uri);
}

my $fdcount_start = count_fds();

for my $uri (@uris) {
    {
        my $ssl = gensym();
        tie(*$ssl, "Net::SSLeay::Handle", $uri, 443);
        print $ssl "GET / HTTP/1.0\r\n\r\n";

        my $response = do { local $/ = undef; <$ssl> };
        like( $response, qr/^HTTP\/1/s, 'correct response' );
    }

    my $fdcount_end = count_fds();
    is ($fdcount_end, $fdcount_start, 'handle gets destroyed when it goes out of scope');
}

sub count_fds {
    my $fdpath = File::Spec->devnull();
    my $fh = gensym();
    open($fh, $fdpath) or die;
    my $count = fileno($fh);
    close($fh);
    return $count;
}
