#!perl -w

if ($] < 5.006) {
    print "1..0\n";
    exit;
}

print "1..3\n";

use strict;
use Digest::MD5 qw(md5_hex);

my $str;
$str = "foo\xFF\x{100}";

eval {
    print md5_hex($str);
    print "not ok 1\n";  # should not run
};
print "not " unless $@ && $@ =~ /^(Big byte|Wide character)/;
print "ok 1\n";

chop($str);  # only bytes left
print "not " unless md5_hex($str) eq "503debffe559537231ed24f25651ec20";
print "ok 2\n";

# reference
print "not " unless md5_hex("foo\xFF") eq "503debffe559537231ed24f25651ec20";
print "ok 3\n";
