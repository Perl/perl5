#!perl

use 5.008001;

use strict;
use warnings;

use Net::FTP;
use Test::More;
use File::Temp;
use IO::Socket::INET;

my $server = 'test.rebex.net';
my $debug = 0;

plan skip_all => "no SSL support" if ! Net::FTP->can_ssl;
require IO::Socket::SSL;


# first try to connect w/o ftp
# plain
diag( "connect inet to $server:21" );
IO::Socket::INET->new( "$server:21" ) or do {
    plan skip_all => "$server:21 not reachable";
};

# ssl to the right host
diag( "connect inet to $server:990" );
my $sock = IO::Socket::INET->new( "$server:990") or do {
    plan skip_all => "$server:990 not reachable";
};

# now we need CAs
my $cafh = File::Temp->new( UNLINK => 0, SUFFIX => '.crt' );
my %sslargs = ( SSL_ca_file => $cafh->filename );
print $cafh <DATA>;
close($cafh);

diag( "upgrade to ssl $server:990" );
IO::Socket::SSL->start_SSL($sock,
    SSL_verify_mode => 1,
    SSL_verifycn_name => $server,
    SSL_verifycn_scheme => 'ftp',
    %sslargs,
) or do {
    plan skip_all => "$server:990 not upgradable to SSL: ".
	$IO::Socket::SSL::SSL_ERROR;
};

plan tests => 9;

# first direct SSL
diag( "connect ftp over ssl to $server" );
my $ftp = Net::FTP->new($server,
    SSL => 1,
    %sslargs,
    Debug => $debug,
    Passive => 1,
);
ok($ftp,"ftp ssl connect $server");
$ftp->login("anonymous",'net-sslglue-ftp@test.perl')
    or die "login to $server failed";
diag("logged in");
# check that we can talk on connection
ok(~~$ftp->ls,"directory listing protected");
$ftp->prot('C');
ok(~~$ftp->ls,"directory listing clear");

# then TLS upgrade inside plain connection
$ftp = Net::FTP->new($server,
    Passive => 1,
    Debug => $debug,
    %sslargs
);
ok($ftp,"ftp plain connect $server");
my $ok = $ftp->starttls;
ok($ok,"ssl upgrade");
$ftp->login("anonymous",'net-sslglue-ftp@test.perl')
    or die "login to $server failed";
diag("logged in");
# check that we can talk on connection
ok(~~$ftp->ls,"directory listing protected");
$ftp->prot('C');
ok(~~$ftp->ls,"directory listing clear");
$ok = $ftp->stoptls;
ok($ok,"ssl downgrade");
ok(~~$ftp->ls,"directory listing after downgrade");


__DATA__
# Subject: C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Class 2 Primary Intermediate Server CA
# Issuer:  C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Certification Authority
-----BEGIN CERTIFICATE-----
MIIGNDCCBBygAwIBAgIBGjANBgkqhkiG9w0BAQUFADB9MQswCQYDVQQGEwJJTDEW
MBQGA1UEChMNU3RhcnRDb20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERpZ2l0YWwg
Q2VydGlmaWNhdGUgU2lnbmluZzEpMCcGA1UEAxMgU3RhcnRDb20gQ2VydGlmaWNh
dGlvbiBBdXRob3JpdHkwHhcNMDcxMDI0MjA1NzA5WhcNMTcxMDI0MjA1NzA5WjCB
jDELMAkGA1UEBhMCSUwxFjAUBgNVBAoTDVN0YXJ0Q29tIEx0ZC4xKzApBgNVBAsT
IlNlY3VyZSBEaWdpdGFsIENlcnRpZmljYXRlIFNpZ25pbmcxODA2BgNVBAMTL1N0
YXJ0Q29tIENsYXNzIDIgUHJpbWFyeSBJbnRlcm1lZGlhdGUgU2VydmVyIENBMIIB
IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4k85L6GMmoWtCA4IPlfyiAEh
G5SpbOK426oZGEY6UqH1D/RujOqWjJaHeRNAUS8i8gyLhw9l33F0NENVsTUJm9m8
H/rrQtCXQHK3Q5Y9upadXVACHJuRjZzArNe7LxfXyz6CnXPrB0KSss1ks3RVG7RL
hiEs93iHMuAW5Nq9TJXqpAp+tgoNLorPVavD5d1Bik7mb2VsskDPF125w2oLJxGE
d2H2wnztwI14FBiZgZl1Y7foU9O6YekO+qIw80aiuckfbIBaQKwn7UhHM7BUxkYa
8zVhwQIpkFR+ZE3EMFICgtffziFuGJHXuKuMJxe18KMBL47SLoc6PbQpZ4rEAwID
AQABo4IBrTCCAakwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYD
VR0OBBYEFBHbI0X9VMxqcW+EigPXvvcBLyaGMB8GA1UdIwQYMBaAFE4L7xqkQFul
F2mHMMo0aEPQQa7yMGYGCCsGAQUFBwEBBFowWDAnBggrBgEFBQcwAYYbaHR0cDov
L29jc3Auc3RhcnRzc2wuY29tL2NhMC0GCCsGAQUFBzAChiFodHRwOi8vd3d3LnN0
YXJ0c3NsLmNvbS9zZnNjYS5jcnQwWwYDVR0fBFQwUjAnoCWgI4YhaHR0cDovL3d3
dy5zdGFydHNzbC5jb20vc2ZzY2EuY3JsMCegJaAjhiFodHRwOi8vY3JsLnN0YXJ0
c3NsLmNvbS9zZnNjYS5jcmwwgYAGA1UdIAR5MHcwdQYLKwYBBAGBtTcBAgEwZjAu
BggrBgEFBQcCARYiaHR0cDovL3d3dy5zdGFydHNzbC5jb20vcG9saWN5LnBkZjA0
BggrBgEFBQcCARYoaHR0cDovL3d3dy5zdGFydHNzbC5jb20vaW50ZXJtZWRpYXRl
LnBkZjANBgkqhkiG9w0BAQUFAAOCAgEAnQfh7pB2MWcWRXCMy4SLS1doRKWJwfJ+
yyiL9edwd9W29AshYKWhdHMkIoDW2LqNomJdCTVCKfs5Y0ULpLA4Gmj0lRPM4EOU
7Os5GuxXKdmZbfWEzY5zrsncavqenRZkkwjHHMKJVJ53gJD2uSl26xNnSFn4Ljox
uMnTiOVfTtIZPUOO15L/zzi24VuKUx3OrLR2L9j3QGPV7mnzRX2gYsFhw3XtsntN
rCEnME5ZRmqTF8rIOS0Bc2Vb6UGbERecyMhK76F2YC2uk/8M1TMTn08Tzt2G8fz4
NVQVqFvnhX76Nwn/i7gxSZ4Nbt600hItuO3Iw/G2QqBMl3nf/sOjn6H0bSyEd6Si
BeEX/zHdmvO4esNSwhERt1Axin/M51qJzPeGmmGSTy+UtpjHeOBiS0N9PN7WmrQQ
oUCcSyrcuNDUnv3xhHgbDlePaVRCaHvqoO91DweijHOZq1X1BwnSrzgDapADDC+P
4uhDwjHpb62H5Y29TiyJS1HmnExUdsASgVOb7KD8LJzaGJVuHjgmQid4YAjff20y
6NjAbx/rJnWfk/x7G/41kNxTowemP4NVCitOYoIlzmYwXSzg+RkbdbmdmFamgyd6
0Y+NWZP8P3PXLrQsldiL98l+x/ydrHIEH9LMF/TtNGCbnkqXBP7dcg5XVFEGcE3v
qhykguAzx/Q=
-----END CERTIFICATE-----
# Subject: C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Certification Authority
# Issuer:  C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Certification Authority
-----BEGIN CERTIFICATE-----
MIIHhzCCBW+gAwIBAgIBLTANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQGEwJJTDEW
MBQGA1UEChMNU3RhcnRDb20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERpZ2l0YWwg
Q2VydGlmaWNhdGUgU2lnbmluZzEpMCcGA1UEAxMgU3RhcnRDb20gQ2VydGlmaWNh
dGlvbiBBdXRob3JpdHkwHhcNMDYwOTE3MTk0NjM3WhcNMzYwOTE3MTk0NjM2WjB9
MQswCQYDVQQGEwJJTDEWMBQGA1UEChMNU3RhcnRDb20gTHRkLjErMCkGA1UECxMi
U2VjdXJlIERpZ2l0YWwgQ2VydGlmaWNhdGUgU2lnbmluZzEpMCcGA1UEAxMgU3Rh
cnRDb20gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUA
A4ICDwAwggIKAoICAQDBiNsJvGxGfHiflXu1M5DycmLWwTYgIiRezul38kMKogZk
pMyONvg45iPwbm2xPN1yo4UcodM9tDMr0y+v/uqwQVlntsQGfQqedIXWeUyAN3rf
OQVSWff0G0ZDpNKFhdLDcfN1YjS6LIp/Ho/u7TTQEceWzVI9ujPW3U3eCztKS5/C
Ji/6tRYccjV3yjxd5srhJosaNnZcAdt0FCX+7bWgiA/deMotHweXMAEtcnn6RtYT
Kqi5pquDSR3l8u/d5AGOGAqPY1MWhWKpDhk6zLVmpsJrdAfkK+F2PrRt2PZE4XNi
HzvEvqBTViVsUQn3qqvKv3b9bZvzndu/PWa8DFaqr5hIlTpL36dYUNk4dalb6kMM
Av+Z6+hsTXBbKWWc3apdzK8BMewM69KN6Oqce+Zu9ydmDBpI125C4z/eIT574Q1w
+2OqqGwaVLRcJXrJosmLFqa7LH4XXgVNWG4SHQHuEhANxjJ/GP/89PrNbpHoNkm+
Gkhpi8KWTRoSsmkXwQqQ1vp5Iki/untp+HDH+no32NgN0nZPV/+Qt+OR0t3vwmC3
Zzrd/qqc8NSLf3Iizsafl7b4r4qgEKjZ+xjGtrVcUjyJthkqcwEKDwOzEmDyei+B
26Nu/yYwl/WL3YlXtq09s68rxbd2AvCl1iuahhQqcvbjM4xdCUsT37uMdBNSSwID
AQABo4ICEDCCAgwwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYD
VR0OBBYEFE4L7xqkQFulF2mHMMo0aEPQQa7yMB8GA1UdIwQYMBaAFE4L7xqkQFul
F2mHMMo0aEPQQa7yMIIBWgYDVR0gBIIBUTCCAU0wggFJBgsrBgEEAYG1NwEBATCC
ATgwLgYIKwYBBQUHAgEWImh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL3BvbGljeS5w
ZGYwNAYIKwYBBQUHAgEWKGh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL2ludGVybWVk
aWF0ZS5wZGYwgc8GCCsGAQUFBwICMIHCMCcWIFN0YXJ0IENvbW1lcmNpYWwgKFN0
YXJ0Q29tKSBMdGQuMAMCAQEagZZMaW1pdGVkIExpYWJpbGl0eSwgcmVhZCB0aGUg
c2VjdGlvbiAqTGVnYWwgTGltaXRhdGlvbnMqIG9mIHRoZSBTdGFydENvbSBDZXJ0
aWZpY2F0aW9uIEF1dGhvcml0eSBQb2xpY3kgYXZhaWxhYmxlIGF0IGh0dHA6Ly93
d3cuc3RhcnRzc2wuY29tL3BvbGljeS5wZGYwEQYJYIZIAYb4QgEBBAQDAgAHMDgG
CWCGSAGG+EIBDQQrFilTdGFydENvbSBGcmVlIFNTTCBDZXJ0aWZpY2F0aW9uIEF1
dGhvcml0eTANBgkqhkiG9w0BAQsFAAOCAgEAjo/n3JR5fPGFf59Jb2vKXfuM/gTF
wWLRfUKKvFO3lANmMD+x5wqnUCBVJX92ehQN6wQOQOY+2IirByeDqXWmN3PH/UvS
Ta0XQMhGvjt/UfzDtgUx3M2FIk5xt/JxXrAaxrqTi3iSSoX4eA+D/i+tLPfkpLst
0OcNOrg+zvZ49q5HJMqjNTbOx8aHmNrs++myziebiMMEofYLWWivydsQD032ZGNc
pRJvkrKTlMeIFw6Ttn5ii5B/q06f/ON1FE8qMt9bDeD1e5MNq6HPh+GlBEXoPBKl
CcWw0bdT82AUuoVpaiF8H3VhFyAXe2w7QSlc4axa0c2Mm+tgHRns9+Ww2vl5GKVF
P0lDV9LdJNUso/2RjSe15esUBppMeyG7Oq0wBhjA2MFrLH9ZXF2RsXAiV+uKa0hK
1Q8p7MZAwC+ITGgBF3f0JBlPvfrhsiAhS90a2Cl9qrjeVOwhVYBsHvUwyKMQ5bLm
KhQxw4UtjJixhlpPiVktucf3HMiKf8CdBUrmQk9io20ppB+Fq9vlgcitKj1MXVuE
JnHEhV5xJMqlG2zYYdMa4FTbzrqpMrUi9nNBCV24F10OD5mQ1kfabwo6YigUZ4LZ
8dCAWZvLMdibD4x3TrVoivJs9iQOLWxwxXPR3hTQcY+203sC9uO41Alua551hDnm
fyWl8kgAwKQB2j8=
-----END CERTIFICATE-----
