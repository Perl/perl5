#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (exists $open::layers{'perlio'}) {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

$| = 1;
print "1..10\n";

my $fh;
my $var = "ok 2\n";
open($fh,"+<",\$var) or print "not ";
print "ok 1\n";
print <$fh>;
print "not " unless eof($fh);
print "ok 3\n";
seek($fh,0,0) or print "not ";
print "not " if eof($fh);
print "ok 4\n";
print "ok 5\n";
print $fh "ok 7\n" or print "not ";
print "ok 6\n";
print $var;
$var = "foo\nbar\n";
seek($fh,0,0) or print "not ";
print "not " if eof($fh);
print "ok 8\n";
print "not " unless <$fh> eq "foo\n";
print "ok 9\n";
# Test multiple consecutive writes to $var
$var = "";
seek($fh, 0, 0);
print $fh "Fred and Wilma ";
print $fh "Flintstone";
print "not " unless $var eq "Fred and Wilma Flintstone";
print "ok 10\n";
