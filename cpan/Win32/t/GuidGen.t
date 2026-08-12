use strict;
use Test::More tests => 3;
use Win32;

my $guid1 = Win32::GuidGen();
my $guid2 = Win32::GuidGen();

# {FB9586CD-273B-43BE-A20C-485A6BD4FCD6}
like($guid1, qr/^{\w{8}(-\w{4}){3}-\w{12}}$/);
like($guid2, qr/^{\w{8}(-\w{4}){3}-\w{12}}$/);

# Every GUID is unique
ok($guid1 ne $guid2);
