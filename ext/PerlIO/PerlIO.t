BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
	require Config; import Config;
	unless ($Config{'useperlio'}) {
	    print "1..0 # Skip: PerlIO not used\n";
	    exit 0;
	}
}

use PerlIO;

print "1..19\n";

print "ok 1\n";

my $txt = "txt$$";
my $bin = "bin$$";
my $utf = "utf$$";

my $txtfh;
my $binfh;
my $utffh;

print "not " unless open($txtfh, ">:crlf", $txt);
print "ok 2\n";

print "not " unless open($binfh, ">:raw",  $bin);
print "ok 3\n";

print "not " unless open($utffh, ">:utf8", $utf);
print "ok 4\n";

print $txtfh "foo\n";
print $txtfh "bar\n";
print "not " unless close($txtfh);
print "ok 5\n";

print $binfh "foo\n";
print $binfh "bar\n";
print "not " unless close($binfh);
print "ok 6\n";

print $utffh "foo\x{ff}\n";
print $utffh "bar\x{abcd}\n";
print "not " unless close($utffh);
print "ok 7\n";

print "not " unless open($txtfh, "<:crlf", $txt);
print "ok 8\n";

print "not " unless open($binfh, "<:raw",  $bin);
print "ok 9\n";

print "not " unless open($utffh, "<:utf8", $utf);
print "ok 10\n";

print "not " unless <$txtfh> eq "foo\n" && <$txtfh> eq "bar\n";
print "ok 11\n";

print "not " unless <$binfh> eq "foo\n" && <$binfh> eq "bar\n";
print "ok 12\n";

print "not " unless <$utffh> eq "foo\x{ff}\n" && <$utffh> eq "bar\x{abcd}\n";
print "ok 13\n";

print "not " unless eof($txtfh);
print "ok 14\n";

print "not " unless eof($binfh);
print "ok 15\n";

print "not " unless eof($utffh);
print "ok 16\n";

print "not " unless close($txtfh);
print "ok 17\n";

print "not " unless close($binfh);
print "ok 18\n";

print "not " unless close($utffh);
print "ok 19\n";

END {
    1 while unlink $txt;
    1 while unlink $bin;
    1 while unlink $utf;
}

