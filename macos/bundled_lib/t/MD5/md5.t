######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..14\n";}
END {print "not ok 1\n" unless $loaded;}
use MD5;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MD5Test;

# 2: Constructor

print (($md5 = new MD5) ? "ok 2\n" : "not ok 2\n");

# 3: Basic test data as defined in RFC 1321

%data = (
	 ""	=> "d41d8cd98f00b204e9800998ecf8427e",
	 "a"	=> "0cc175b9c0f1b6a831c399e269772661",
	 "abc"	=> "900150983cd24fb0d6963f7d28e17f72",
	 "message digest"
		=> "f96b697d7cb7938d525a2f31aaf161d0",
	 "abcdefghijklmnopqrstuvwxyz"
		=> "c3fcd3d76192e4007dfb496cca67e13b",
	 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
		=> "d174ab98d277d9f5a5611c2c9f419d9f",
	 "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		=> "57edf4a22be3c955ac49da2e2107b67a",
);

$failed = 0;
foreach (sort(keys(%data)))
{
    $md5->reset;
    $md5->add($_);
    $digest = $md5->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne $data{$_}) {
        print STDERR "\$md5->digest: $_\n";
        print STDERR "expected: $data{$_}\n",
                     "got     : $hex\n";
	$failed++;
    }

    if (Digest::MD5::md5($_) ne $digest) {
	print STDERR "md5($_) failed\n";
	$failed++;
    }

    if (Digest::MD5::md5_hex($_) ne $hex) {
	print STDERR "md5_hex($_) failed\n";
	$failed++;
    }

    # same stuff ending with $md5->hexdigest instead
    $md5->reset;
    $md5->add($_);
    $hex = $md5->hexdigest;
    if ($hex ne $data{$_}) {
        print STDERR "\$md5->hexdigest: $_\n";
        print STDERR "expected: $data{$_}\n",
                     "got     : $hex\n";
	$failed++;
    }
}
print ($failed ? "not ok 3\n" : "ok 3\n");

# 4: Various flavours of file-handle to addfile

open(F, "<$0");

$md5->reset;

$md5->addfile(F);
$hex = $md5->hexdigest;
print ($hex ne '' ? "ok 4\n" : "not ok 4\n");

$orig = $hex;

# 5: Fully qualified with ' operator

seek(F, 0, 0);
$md5->reset;
$md5->addfile(MD5Test'F);
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 5\n" : "not ok 5\n");

# 6: Fully qualified with :: operator

seek(F, 0, 0);
$md5->reset;
$md5->addfile(MD5Test::F);
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 6\n" : "not ok 6\n");

# 7: Type glob

seek(F, 0, 0);
$md5->reset;
$md5->addfile(*F);
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 7\n" : "not ok 7\n");

# 8: Type glob reference (the prefered mechanism)

seek(F, 0, 0);
$md5->reset;
$md5->addfile(\*F);
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 8\n" : "not ok 8\n");

# 9: File-handle passed by name (really the same as 6)

seek(F, 0, 0);
$md5->reset;
$md5->addfile("MD5Test::F");
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 9\n" : "not ok 9\n");

# 10: Other ways of reading the data -- line at a time

seek(F, 0, 0);
$md5->reset;
while (<F>)
{
    $md5->add($_);
}
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 10\n" : "not ok 10\n");

# 11: Input lines as a list to add()

seek(F, 0, 0);
$md5->reset;
$md5->add(<F>);
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 11\n" : "not ok 11\n");

# 12: Random chunks up to 128 bytes

seek(F, 0, 0);
$md5->reset;
while (read(F, $hexata, (rand % 128) + 1))
{
    $md5->add($hexata);
}
$hex = $md5->hexdigest;
print ($hex eq $orig ? "ok 12\n" : "not ok 12\n");

# 13: All the data at once

seek(F, 0, 0);
$md5->reset;
undef $/;
$data = <F>;
$hex = $md5->hexhash($data);
print ($hex eq $orig ? "ok 13\n" : "not ok 13\n");

close(F);

# 14: Using static member function

$hex = MD5->hexhash($data);
print ($hex eq $orig ? "ok 14\n" : "not ok 14\n");
