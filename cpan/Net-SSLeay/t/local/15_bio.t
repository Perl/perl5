use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(initialise_libssl);

plan tests => 7;

initialise_libssl();

my $data = '0123456789' x 100;
my $len  = length $data;

ok( my $bio = Net::SSLeay::BIO_new( &Net::SSLeay::BIO_s_mem ), 'BIO_new' );
is( Net::SSLeay::BIO_write($bio, $data), $len, 'BIO_write' );
is( Net::SSLeay::BIO_pending($bio), $len, 'BIO_pending' );

my $read_len = 9;
is( Net::SSLeay::BIO_read($bio, $read_len), substr($data, 0, $read_len), 'BIO_read part' );
is( Net::SSLeay::BIO_pending($bio), $len - $read_len, 'BIO_pending' );

is( Net::SSLeay::BIO_read($bio), substr($data, $read_len), 'BIO_read rest' );

ok( Net::SSLeay::BIO_free($bio), 'BIO_free' );
