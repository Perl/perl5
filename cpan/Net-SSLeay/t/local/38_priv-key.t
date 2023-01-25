use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

plan tests => 10;

initialise_libssl();

my $key_pem           = data_file_path('simple-cert.key.pem');
my $key_pem_encrypted = data_file_path('simple-cert.key.enc.pem');
my $key_password      = 'test';

{
  ok(my $bio_pem                 = Net::SSLeay::BIO_new_file($key_pem, 'r'), "BIO_new_file 3");
  ok(Net::SSLeay::PEM_read_bio_PrivateKey($bio_pem), "PEM_read_bio_PrivateKey no password");
}

{
  ok(my $bio_pem_encrypted = Net::SSLeay::BIO_new_file($key_pem_encrypted, 'r'), "BIO_new_file");
  ok(Net::SSLeay::PEM_read_bio_PrivateKey($bio_pem_encrypted, sub { $key_password }), "PEM_read_bio_PrivateKey encrypted - callback");
}

{
  ok(my $bio_pem_encrypted = Net::SSLeay::BIO_new_file($key_pem_encrypted, 'r'), "BIO_new_file");
  ok(Net::SSLeay::PEM_read_bio_PrivateKey($bio_pem_encrypted, undef, $key_password), "PEM_read_bio_PrivateKey encrypted - password");
}

{
  ok(my $bio_pem_encrypted = Net::SSLeay::BIO_new_file($key_pem_encrypted, 'r'), "BIO_new_file");
  ok(!Net::SSLeay::PEM_read_bio_PrivateKey($bio_pem_encrypted, sub { $key_password . 'invalid' }), "PEM_read_bio_PrivateKey encrypted - callback (wrong password)");
}

{
  ok(my $bio_pem_encrypted = Net::SSLeay::BIO_new_file($key_pem_encrypted, 'r'), "BIO_new_file");
  ok(!Net::SSLeay::PEM_read_bio_PrivateKey($bio_pem_encrypted, undef, $key_password . 'invalid'), "PEM_read_bio_PrivateKey encrypted - password (wrong password)");
}
