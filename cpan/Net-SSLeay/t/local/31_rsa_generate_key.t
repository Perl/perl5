use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( dies_like initialise_libssl lives_ok );

plan tests => 14;

initialise_libssl();

lives_ok(sub {
        Net::SSLeay::RSA_generate_key(2048, 0x10001);
}, 'RSA_generate_key with valid callback');

dies_like(sub {
        Net::SSLeay::RSA_generate_key(2048, 0x10001, 1);
}, qr/Undefined subroutine &main::1 called/, 'RSA_generate_key with invalid callback');

{
    my $called = 0;

    lives_ok(sub {
            Net::SSLeay::RSA_generate_key(2048, 0x10001, \&cb);
    }, 'RSA_generate_key with valid callback');

    cmp_ok( $called, '>', 0, 'callback has been called' );

    sub cb {
        my ($i, $n, $d) = @_;

        if ($called == 0) {
            is( wantarray(), undef, 'RSA_generate_key callback is executed in void context' );
            is( $d, undef, 'userdata will be undef if no userdata was given' );

            ok( defined $i, 'first argument is defined' );
            ok( defined $n, 'second argument is defined' );
        }

        $called++;
    }
}

{
    my $called   = 0;
    my $userdata = 'foo';

    lives_ok(sub {
            Net::SSLeay::RSA_generate_key(2048, 0x10001, \&cb_data, $userdata);
    }, 'RSA_generate_key with valid callback and userdata');

    cmp_ok( $called, '>', 0, 'callback has been called' );

    sub cb_data {
        my ($i, $n, $d) = @_;

        if ($called == 0) {
            is( wantarray(), undef, 'RSA_generate_key callback is executed in void context' );

            ok( defined $i, 'first argument is defined' );
            ok( defined $n, 'second argument is defined' );
            is( $d, $userdata, 'third argument is the userdata we passed in' );
        }

        $called++;
    }
}
