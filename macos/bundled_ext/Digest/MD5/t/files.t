print "1..5\n";

use strict;
use File::Spec::Functions;
use Digest::MD5 qw(md5 md5_hex md5_base64);

#
# This is the output of: 'md5sum Changes README MD5.pm MD5.xs rfc1321.txt'
#
my $EXPECT = "\n" eq chr(10) ? <<EOT1 : <<EOT2;  # Mac OS \n is chr(13)
df6bb160e273cbf342bd1a947ebb155f  Changes
e2447354c8b24340bc49e38f8d00bf3b  README
bf8c3c72d071d1c0303fc9e311820708  MD5.pm
abcee0576dd82eca765f54bace61c434  MD5.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT1
3f33c2d0e531cc5902ae9832014a11e3  Changes
5b79ce6f90834381208fb7d67c4a262e  README
b69835aa8b73fc5ed8055f23462aaa47  MD5.pm
81fbd61766e2c876349c358cced6052f  MD5.xs
f9a35714ee1d1d0c5a3a80f4dbea956a  rfc1321.txt
EOT2

if (!(-f "README") && -f catfile(updir(), "README")) {
   chdir(updir()) or die "Can't chdir: $!";
}

my $testno = 0;

my $B64 = 1;
eval { require MIME::Base64; };
if ($@) {
    print $@;
    print "Will not test base64 methods\n";
    $B64 = 0;
}

for (split /^/, $EXPECT) {
     my($md5hex, $file) = split ' ';
     my $md5bin = pack("H*", $md5hex);
     my $md5b64;
     if ($B64) {
	 $md5b64 = MIME::Base64::encode($md5bin, "");
	 chop($md5b64); chop($md5b64);   # remove padding
     }
     my $failed;

     if (digest_file($file, 'digest') ne $md5bin) {
	 print "$file: Bad digest\n";
	 $failed++;
     }

     if (digest_file($file, 'hexdigest') ne $md5hex) {
	 print "$file: Bad hexdigest\n";
	 $failed++;
     }

     if ($B64 && digest_file($file, 'b64digest') ne $md5b64) {
	 print "$file: Bad b64digest\n";
	 $failed++;
     }

     my $data = cat_file($file);
     if (md5($data) ne $md5bin) {
	 print "$file: md5() failed\n";
	 $failed++;
     }
     if (md5_hex($data) ne $md5hex) {
	 print "$file: md5_hex() failed\n";
	 $failed++;
     }
     if ($B64 && md5_base64($data) ne $md5b64) {
	 print "$file: md5_base64() failed\n";
	 $failed++;
     }

     if (Digest::MD5->new->add($data)->digest ne $md5bin) {
	 print "$file: MD5->new->add(...)->digest failed\n";
	 $failed++;
     }
     if (Digest::MD5->new->add($data)->hexdigest ne $md5hex) {
	 print "$file: MD5->new->add(...)->hexdigest failed\n";
	 $failed++;
     }
     if ($B64 && Digest::MD5->new->add($data)->b64digest ne $md5b64) {
	 print "$file: MD5->new->add(...)->b64digest failed\n";
	 $failed++;
     }

     my @data = split //, $data;
     if (md5(@data) ne $md5bin) {
	 print "$file: md5(\@data) failed\n";
	 $failed++;
     }
     if (Digest::MD5->new->add(@data)->digest ne $md5bin) {
	 print "$file: MD5->new->add(\@data)->digest failed\n";
	 $failed++;
     }
     my $md5 = Digest::MD5->new;
     for (@data) {
	 $md5->add($_);
     }
     if ($md5->digest ne $md5bin) {
	 print "$file: $md5->add()-loop failed\n";
	 $failed++;
     }

     print "not " if $failed;
     print "ok ", ++$testno, "\n";
}


sub digest_file
{
    my($file, $method) = @_;
    $method ||= "digest";
    #print "$file $method\n";

    open(FILE, $file) or die "Can't open $file: $!";
    binmode(FILE);
    my $digest = Digest::MD5->new->addfile(*FILE)->$method();
    close(FILE);

    $digest;
}

sub cat_file
{
    my($file) = @_;
    local $/;  # slurp
    open(FILE, $file) or die "Can't open $file: $!";
    binmode(FILE);
    my $tmp = <FILE>;
    close(FILE);
    $tmp;
}

