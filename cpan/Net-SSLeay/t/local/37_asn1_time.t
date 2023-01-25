use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw(initialise_libssl);

plan tests => 10;

initialise_libssl();

my $atime1 = Net::SSLeay::ASN1_TIME_new();
ok($atime1, 'ASN1_TIME_new [1]');

Net::SSLeay::ASN1_TIME_set($atime1, 1999888777);
SKIP: {
  skip 'openssl-0.9.8i is buggy', 2 if Net::SSLeay::SSLeay == 0x0090809f;
  is(Net::SSLeay::P_ASN1_TIME_put2string($atime1),    'May 16 20:39:37 2033 GMT', 'P_ASN1_TIME_put2string');
  is(Net::SSLeay::P_ASN1_UTCTIME_put2string($atime1), 'May 16 20:39:37 2033 GMT', 'P_ASN1_UTCTIME_put2string');
}
SKIP: {
  skip 'openssl-0.9.7e required', 1 unless Net::SSLeay::SSLeay >= 0x0090705f;
  is(Net::SSLeay::P_ASN1_TIME_get_isotime($atime1), '2033-05-16T20:39:37Z', 'P_ASN1_TIME_get_isotime');
}
Net::SSLeay::ASN1_TIME_free($atime1);

my $atime2 = Net::SSLeay::ASN1_TIME_new();
ok($atime2, 'ASN1_TIME_new [2]');
SKIP: {
  skip 'openssl-0.9.7e required', 2 unless Net::SSLeay::SSLeay >= 0x0090705f;
  Net::SSLeay::P_ASN1_TIME_set_isotime($atime2, '2075-06-19T13:08:52Z');
  SKIP: {
    skip 'openssl-0.9.8i is buggy', 1 if Net::SSLeay::SSLeay == 0x0090809f;
    is(Net::SSLeay::P_ASN1_TIME_put2string($atime2),  'Jun 19 13:08:52 2075 GMT', 'P_ASN1_TIME_put2string y=2075');
  }
  is(Net::SSLeay::P_ASN1_TIME_get_isotime($atime2), '2075-06-19T13:08:52Z', 'P_ASN1_TIME_get_isotime y=2075');
}
Net::SSLeay::ASN1_TIME_free($atime2);

my $atime3 = Net::SSLeay::ASN1_TIME_new();
ok($atime1, 'ASN1_TIME_new [3]');
ok(Net::SSLeay::X509_gmtime_adj($atime3, 60*60*24*365*2));
like(Net::SSLeay::P_ASN1_TIME_put2string($atime3), qr/[A-Z][a-z]+ +\d+ +\d+:\d+:\d+ +20\d\d/, 'X509_gmtime_adj');
Net::SSLeay::ASN1_TIME_free($atime3);
