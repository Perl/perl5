BEGIN {
        chdir 't' if -d 't';
        @INC = '../lib';
}

print "1..2\n";

use strict;
use Digest::MD5 qw(md5 md5_hex);

#
# This is the output of: 'md5sum MD5.pm MD5.xs'
#
my $EXPECT = <<EOT;
9e1d1183ff41717c91a563c41e08d672  ext/Digest/MD5/MD5.pm
61debd0ec12e131e1ba220e2f3ad2d26  ext/Digest/MD5/MD5.xs
EOT

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
     my $failed;

     if (digest_file($file, 'digest') ne $md5bin) {
	 print "$file: Bad digest\n";
	 $failed++;
     }

     if (digest_file($file, 'hexdigest') ne $md5hex) {
	 print "$file: Bad hexdigest\n";
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

     if (Digest::MD5->new->add($data)->digest ne $md5bin) {
	 print "$file: MD5->new->add(...)->digest failed\n";
	 $failed++;
     }
     if (Digest::MD5->new->add($data)->hexdigest ne $md5hex) {
	 print "$file: MD5->new->add(...)->hexdigest failed\n";
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

