#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

my $tmp = "via$$";

print "1..3\n";

$a = join("", map { chr } 0..255) x 10;

use MIME::QuotedPrint;
open(my $fh,">Via(MIME::QuotedPrint)", $tmp);
print $fh $a;
close($fh);
print "ok 1\n";

open(my $fh,"<Via(MIME::QuotedPrint)", $tmp);
{ local $/; $b = <$fh> }
close($fh);
print "ok 2\n";

print "ok 3\n" if $a eq $b;

END {
    1 while unlink $tmp;
}
