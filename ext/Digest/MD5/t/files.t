BEGIN {
        chdir 't' if -d 't';
        @INC = '../lib';
}

print "1..2\n";

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);

#
# This is the output of: 'md5sum MD5.pm MD5.xs'
#
my $EXPECT;

if (ord('A') == 193) { # EBCDIC
$EXPECT = <<EOT;
????????????????????????????????  ext/Digest/MD5/MD5.pm
????????????????????????????????  ext/Digest/MD5/MD5.xs
EOT
} else { # ASCII
$EXPECT = <<EOT;
bf8c3c72d071d1c0303fc9e311820708  ext/Digest/MD5/MD5.pm
dc50ae0aea3182f4d5f1ec368b67918b  ext/Digest/MD5/MD5.xs
EOT
}

my $B64 = 1;
eval { require MIME::Base64; };
if ($@) {
    print $@;
    print "# Will not test base64 methods\n";
    $B64 = 0;
}

my $testno = 0;

use File::Spec;

for (split /^/, $EXPECT) {
     my($md5hex, $file) = split ' ';
     my @path = split(m:/:, $file);
     my $last = pop @path;
     my $path = File::Spec->updir;
     while (@path) {
	 $path = File::Spec->catdir($path, shift @path);
     }
     $file = File::Spec->catfile($path, $last);
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
# Digests above are generated on UNIX without CRLF
# so leave handles in text mode
#    binmode(FILE);
    my $digest = Digest::MD5->new->addfile(*FILE)->$method();
    close(FILE);

    $digest;
}

sub cat_file
{
    my($file) = @_;
    local $/;  # slurp
    open(FILE, $file) or die "Can't open $file: $!";
# Digests above are generated on UNIX without CRLF
# so leave handles in text mode
#    binmode(FILE);
    my $tmp = <FILE>;
    close(FILE);
    $tmp;
}

