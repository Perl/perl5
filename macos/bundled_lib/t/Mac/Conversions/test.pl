#!/usr/local/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mac::Conversions;
$loaded = 1;
$count = 1;

print "ok $count\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

if (-e ":testfiles:earthrise.jpg.bin" && ! -e ":testfiles:earthrise.jpg") {
    print << "EOBLURB";
    Before this test can be run, :testfiles:earthrise.jpg.bin must be decoded.
    Please drop :testfiles:earthrise.jpg.bin onto any MacBinary decoder,
    for example Stuffit Expander.
EOBLURB
    exit(0);
}
my $cn = Mac::Conversions->new;

$cn->binhex(":testfiles:earthrise.jpg");
$cn->macbinary(":testfiles:earthrise.jpg");

#Test 2: test invertability of BinHex
$cn->debinhex(":testfiles:earthrise.jpg.hqx");
binary_compare(":testfiles:earthrise.jpg",":testfiles:earthrise.jpg.1",++$count);
unlink(":testfiles:earthrise.jpg.1");

#Test 3: test invertability of MacBinary II
$cn->demacbinary(":testfiles:earthrise.jpg.bin");
binary_compare(":testfiles:earthrise.jpg",":testfiles:earthrise.jpg.1",++$count);
unlink(":testfiles:earthrise.jpg.1");

#Test 4: test macb2hex
$cn->macb2hex(":testfiles:earthrise.jpg.bin");
$cn->debinhex(":testfiles:earthrise.jpg.1.hqx");
binary_compare(":testfiles:earthrise.jpg",":testfiles:earthrise.jpg.1",++$count);
unlink(":testfiles:earthrise.jpg.1.hqx");
unlink(":testfiles:earthrise.jpg.1");

#Test 5: test hex2macb
$cn->hex2macb(":testfiles:earthrise.jpg.hqx");
$cn->demacbinary(":testfiles:earthrise.jpg.1.bin");
binary_compare(":testfiles:earthrise.jpg",":testfiles:earthrise.jpg.1",++$count);

#Test 6, 7: test is_macbinary
print "not " unless $cn->is_macbinary(":testfiles:earthrise.jpg.bin");
print "ok ",++$count,"\n";

print "not " if $cn->is_macbinary("README");
print "ok ",++$count,"\n";


unlink(":testfiles:earthrise.jpg.1.bin");
unlink(":testfiles:earthrise.jpg.1");
unlink(":testfiles:earthrise.jpg.bin");
unlink(":testfiles:earthrise.jpg.hqx");

#Tests 8, 9, 10: Make sure that headerless MacBinaries don't make it through
#First create an empty file
open(TST,">empty.bin");
close(TST);
eval {
    $cn->demacbinary("empty.bin");
};

print "not " unless $@ =~ /Headerless/;
print "ok ",++$count,"\n";
eval {
    $cn->macb2hex("empty.bin");
};

print "not " unless $@ =~ /Headerless/;
print "ok ",++$count,"\n";

print "not " if $cn->is_macbinary("empty.bin");
print "ok ",++$count,"\n";

unlink "empty.bin";

#Tests 11, 12.  Make sure that the MacBinary decoders handle files with
#whitespace at the end of the name correctly
rename(":testfiles:earthrise.jpg",":testfiles:earthrise.jpg   ");
$cn->macbinary(":testfiles:earthrise.jpg   ");
#Test 11: test invertability of MacBinary II
$cn->demacbinary(":testfiles:earthrise.jpg   .bin");
binary_compare(":testfiles:earthrise.jpg   ",":testfiles:earthrise.jpg   .1",++$count);
unlink(":testfiles:earthrise.jpg   .1");
#Test 12: same for BinHex
$cn->macb2hex(":testfiles:earthrise.jpg   .bin");
$cn->debinhex(":testfiles:earthrise.jpg   .hqx");
binary_compare(":testfiles:earthrise.jpg   ",":testfiles:earthrise.jpg   .1",++$count);

unlink(":testfiles:earthrise.jpg   .bin");
unlink(":testfiles:earthrise.jpg   .hqx");
unlink(":testfiles:earthrise.jpg   .1");

rename(":testfiles:earthrise.jpg   ",":testfiles:earthrise.jpg");

#Test 13: Make sure that a file with a data fork of exactly 128 bytes gets
#handled properly.  The MacBinary file is named "128.bn" to ensure that it
#doesn't get decoded by cpan-mac or untargzipme.
#
#Unfortunately, this test can't be distributed with Mac::Conversions 1.04 
#because there's no good way to transmit the original ALFA/TEXT file in a
#tarball, since previous versions of Mac::Conversions will botch the decoding.
#The test worked locally, though, with 1.04, and failed with 1.03.  I'll turn
#it on in the future when Mac::Conversion 1.04 or later is shipped with
#cpan-mac.
#
#rename(":testfiles:128.bn",":testfiles:128.bin");
#$cn->demacbinary(":testfiles:128.bin");
#binary_compare(":testfiles:128",":testfiles:128.1",++$count);
#unlink(":testfiles:128.1");
#rename(":testfiles:128.bin",":testfiles:128.bn");


sub binary_compare {
    use POSIX;
    use Fcntl;
    
    my ($orig, $copy, $num) = @_;
    my ($buf, $buf2, $n, $fdorig, $fdcopy);
    
    if(open(ORIG,"<$orig\0") and open(COPY,"<$copy\0")) {
	while($n = read(ORIG,$buf,2048)) {
	    read(COPY,$buf2,$n);
	    unless ($buf eq $buf2) {
		print "not ok $num";
		return;
	    }
	}
	#print "ok $num\n";
    } else {
	print "not ok $num\n";
	return;
    }
    if($fdorig = POSIX::open($orig,&POSIX::O_RDONLY | &Fcntl::O_RSRC) and
       $fdcopy = POSIX::open($copy,&POSIX::O_RDONLY | &Fcntl::O_RSRC)) {
    $n = POSIX::read($fdorig,$buf,128);
#
#  Matthias says the first 128 bytes of the resource fork are reserved
#  and might be different between OS 7 and OS 8, so skip them
#
	   unless ($n == 128) {
	    print "not ok $num\n";
	    return;
    }
    $n = POSIX::read($fdcopy,$buf2,128);
	   unless ($n == 128) {
	    print "not ok $num\n";
	    return;
    }
	while (($n = POSIX::read($fdorig, $buf, 2048)) > 0) {
	    POSIX::read($fdcopy, $buf2, $n);
	    unless ($buf eq $buf2) {
		print "not ";
		last;
	    }
	}
	print "ok $num\n";
    } else {
	print "not ok $num\n";
    }
}