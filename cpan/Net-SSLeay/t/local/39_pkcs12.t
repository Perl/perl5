use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

plan tests => 17;

initialise_libssl();

# Encrypted PKCS#12 archive, no chain:
my $filename1          = data_file_path('simple-cert.enc.p12');
my $filename1_password = 'test';

# Encrypted PKCS#12 archive, full chain:
my $filename2          = data_file_path('simple-cert.certchain.enc.p12');
my $filename2_password = 'test';

# PKCS#12 archive, no chain:
my $filename3 = data_file_path('simple-cert.p12');

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename1, 1, $filename1_password);
  ok($privkey, '$privkey [1]');
  ok($cert, '$cert [1]');
  is(scalar(@cachain), 0, 'size of @cachain [1]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [1]");
}

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename2, 1, $filename2_password);
  ok($privkey, '$privkey [2]');
  ok($cert, '$cert [2]');
  is(scalar(@cachain), 2, 'size of @cachain [2]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  my $ca1_subj_name = Net::SSLeay::X509_get_subject_name($cachain[0]);
  my $ca2_subj_name = Net::SSLeay::X509_get_subject_name($cachain[1]);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [2/1]");
  # OpenSSL versions 1.0.0-beta2 to 3.0.0-alpha6 inclusive and all versions of
  # LibreSSL return the CA certificate chain with the root CA certificate at the
  # end; all other versions return the certificate chain with the root CA
  # certificate at the start
  if (
         Net::SSLeay::SSLeay < 0x10000002
      || (
                Net::SSLeay::SSLeay == 0x30000000
             && Net::SSLeay::SSLeay_version( Net::SSLeay::SSLEAY_VERSION() ) !~ /-alpha[1-6] /
         )
      || Net::SSLeay::SSLeay > 0x30000000
  ) {
      is(Net::SSLeay::X509_NAME_oneline($ca1_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Intermediate CA', "X509_NAME_oneline [2/3]");
      is(Net::SSLeay::X509_NAME_oneline($ca2_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Root CA', "X509_NAME_oneline [2/4]");
  }
  else {
      is(Net::SSLeay::X509_NAME_oneline($ca1_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Root CA', "X509_NAME_oneline [2/3]");
      is(Net::SSLeay::X509_NAME_oneline($ca2_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Intermediate CA', "X509_NAME_oneline [2/4]");
  }
}

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename3, 1);
  ok($privkey, '$privkey [3]');
  ok($cert, '$cert [3]');
  is(scalar(@cachain), 0, 'size of @cachain [3]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [3]");
}

{
  my($privkey, $cert, @should_be_empty) = Net::SSLeay::P_PKCS12_load_file($filename2, 0, $filename2_password);
  ok($privkey, '$privkey [4]');
  ok($cert, '$cert [4]');
  is(scalar(@should_be_empty), 0, 'size of @should_be_empty');
}
