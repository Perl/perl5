#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);
use Net::SSLeay::Handle;

my @sites = qw(
	www.google.com
	www.microsoft.com
	www.kernel.org
);
@sites = split(/:/, $ENV{SSLEAY_SITES}) if exists $ENV{SSLEAY_SITES};
if (@sites) {
    plan tests => scalar @sites * 7;
}
else {
    plan skip_all => 'No external hosts specified for SSL testing';
}


for my $site (@sites) {
    SKIP: {
        my $ssl = gensym();
        eval {
            tie(*$ssl, 'Net::SSLeay::Handle', $site, 443);
        };

        skip('could not connect to '.$site, 2) if $@;
        pass('connection to '.$site);

        print $ssl "GET / HTTP/1.0\r\n\r\n";
        my $resp = do { local $/ = undef; <$ssl> };

        like( $resp, qr/^HTTP\/1/, 'response' );
    }
}

{
    my @sock;
    for (my $i = 0; $i < scalar @sites; $i++) {
        SKIP: {
            my $ssl = gensym();
            eval {
                tie(*$ssl, 'Net::SSLeay::Handle', $sites[$i], 443);
            };

            $sock[$i] = undef; #so scalar @sock == scalar @sites

            skip('could not connect', 2) if $@;
            pass('connection');

            $sock[$i] = $ssl;

            ok( $ssl, 'got handle' );
        }
    }

    for my $sock (@sock) {
        SKIP : {
            skip('not connected', 2) unless defined $sock;
            pass('connected');

            print $sock "GET / HTTP/1.0\r\n\r\n";

            my $resp = do { local $/ = undef; <$sock> };
            like( $resp, qr/^HTTP\/1/, 'response' );
        }
    }

    for my $sock (@sock) {
        SKIP : {
            skip('not connected', 1) unless defined $sock;
            ok(close($sock), 'socket closed'); 
	}
    }
}
