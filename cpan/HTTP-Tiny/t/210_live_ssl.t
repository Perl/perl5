#!perl

use strict;
use warnings;

use Test::More 0.96;
use IO::Socket::INET;
BEGIN {
    eval { require IO::Socket::SSL; IO::Socket::SSL->VERSION(1.56); 1 };
    plan skip_all => 'IO::Socket::SSL 1.56 required for SSL tests' if $@;
    # $IO::Socket::SSL::DEBUG = 3;

    eval { require Net::SSLeay; Net::SSLeay->VERSION(1.49); 1};
    plan skip_all => 'Net::SSLeay 1.49 required for SSL tests' if $@;

    eval { require Mozilla::CA; 1 };
    plan skip_all => 'Mozilla::CA required for SSL tests' if $@;
}
use HTTP::Tiny;

delete $ENV{PERL_HTTP_TINY_INSECURE_BY_DEFAULT};

plan skip_all => 'Only run for $ENV{AUTOMATED_TESTING}'
  unless $ENV{AUTOMATED_TESTING};

use IPC::Cmd qw/can_run/;

if ( can_run('openssl') ) {
  diag "\nNote: running test with ", qx/openssl version/;
}

test_ssl('https://cpan.org/' => {
    host => 'cpan.org',
    pass => { verify_SSL => 1 },
    fail => { verify_SSL => 1, SSL_options => { SSL_ca_file => "corpus/snake-oil.crt" } },
    default_verify_should_return => !!1,
});

test_ssl('https://github.com/' => {
    host => 'github.com',
    pass => { verify_SSL => 1 },
    fail => { verify_SSL => 1, SSL_options => { SSL_ca_file => "corpus/snake-oil.crt" } },
    default_verify_should_return => !!1,
});

test_ssl('https://wrong.host.badssl.com/' => {
    host => 'wrong.host.badssl.com',
    pass => { SSL_options => { SSL_verifycn_scheme => 'none', SSL_verifycn_name => 'wrong.host.badssl.com', SSL_verify_mode => 0x00 } },
    fail => { SSL_options => { SSL_verifycn_scheme => 'http', SSL_verifycn_name => 'wrong.host.badssl.com', SSL_verify_mode => 0x01, SSL_ca_file => Mozilla::CA::SSL_ca_file() } },
    default_verify_should_return => !!0,
});

test_ssl('https://untrusted-root.badssl.com/' => {
    host => 'untrusted-root.badssl.com',
    pass => { verify_SSL => 0 },
    fail => { verify_SSL => 1 },
    default_verify_should_return => !!0,
});

test_ssl('https://mozilla-modern.badssl.com/' => {
    host => 'mozilla-modern.badssl.com',
    pass => { verify_SSL => 1 },
    fail => { verify_SSL => 1, SSL_options => { SSL_ca_file => "corpus/snake-oil.crt" } },
    default_verify_should_return => !!1,
});

{
    local $ENV{PERL_HTTP_TINY_INSECURE_BY_DEFAULT} = 1;
    test_ssl('https://wrong.host.badssl.com/' => {
        host => 'wrong.host.badssl.com',
        pass => { verify_SSL => 0 },
        fail => { verify_SSL => 1 },
        default_verify_should_return => !!1,
    });
    test_ssl('https://expired.badssl.com/' => {
        host => 'expired.badssl.com',
        pass => { verify_SSL => 0 },
        fail => { verify_SSL => 1 },
        default_verify_should_return => !!1,
    });

}

test_ssl('https://wrong.host.badssl.com/' => {
    host => 'wrong.host.badssl.com',
    pass => { verify_SSL => 0 },
    fail => { verify_SSL => 1 },
    default_verify_should_return => !!0,
});

test_ssl('https://expired.badssl.com/' => {
    host => 'expired.badssl.com',
    pass => { verify_SSL => 0 },
    fail => { verify_SSL => 1 },
    default_verify_should_return => !!0,
});



subtest "can_ssl" => sub {
    ok( HTTP::Tiny->can_ssl, "class method" );
    ok( HTTP::Tiny->new->can_ssl, "object method, default params" );
    ok( HTTP::Tiny->new(verify_SSL => 1)->can_ssl, "object method, verify_SSL" );

    my $ht = HTTP::Tiny->new(
        verify_SSL => 1,
        SSL_options => { SSL_ca_file => 'adlfadkfadlfad' },
    );
    my ($ok, $why) = $ht->can_ssl;
    ok( ! $ok, "object methods, verify_SSL, bogus CA file (FAILS)" );
    like( $why, qr/not found or not readable/, "failure reason" );
};

done_testing();

sub test_ssl {
    my ($url, $data) = @_;
    subtest $url => sub {
        plan 'skip_all' => 'Internet connection timed out'
            unless IO::Socket::INET->new(
                PeerHost  => $data->{host},
                PeerPort  => 443,
                Proto     => 'tcp',
                Timeout   => 10,
        );

        # the default verification
        my $response = HTTP::Tiny->new()->get($url);
        is $response->{success}, $data->{default_verify_should_return}, "Request to $url passed/failed using default as expected"
            or do {
                # $response->{content} = substr $response->{content}, 0, 50;
                $response->{content} =~ s{\n.*}{}s;
                diag explain [IO::Socket::SSL::errstr(), $response]
            };

        # force validation to succeed
        if ($data->{pass}) {
            my $pass = HTTP::Tiny->new( %{$data->{pass}} )->get($url);
            isnt $pass->{status}, '599', "Request to $url completed (forced pass)"
              or do {
                  $pass->{content} =~ s{\n.*}{}s;
                  diag explain $pass
              };
            ok $pass->{content}, 'Got some content';
        }

        # force validation to fail
        if ($data->{fail}) {
            my $fail = HTTP::Tiny->new( %{$data->{fail}} )->get($url);
            is $fail->{status}, '599', "Request to $url failed (forced fail)"
              or do {
                  $fail->{content} =~ s{\n.*}{}s;
                  diag explain [IO::Socket::SSL::errstr(), $fail]
              };
            ok $fail->{content}, 'Got some content';
        }
    };
}
