BEGIN {
	if ($ENV{PERL_CORE}) {
        	chdir 't' if -d 't';
        	@INC = '../lib';
        }
}

print "1..5\n";

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);

# To update the EBCDIC section even on a Latin 1 platform,
# run this script with $ENV{EBCDIC_MD5SUM} set to a true value.
# (You'll need to have Perl 5.7.3 or later, to have the Encode installed.)
# (And remember that under the Perl core distribution you should
#  also have the $ENV{PERL_CORE} set to a true value.)
# Similarly, to update MacOS section, run with $ENV{MAC_MD5SUM} set.

my $EXPECT;
if (ord "A" == 193) { # EBCDIC
    $EXPECT = <<EOT;
aab6fda26844b46ca878f46394c52bb2  Changes
0565ec21b15c0f23f4c51fb327c8926d  README
5d2a638a7323f5bd5b5c120c9330b99d  MD5.pm
de2c149900efee0fbb39ad87dea68a43  MD5.xs
276da0aa4e9a08b7fe09430c9c5690aa  rfc1321.txt
EOT
} elsif ("\n" eq "\015") { # MacOS
    $EXPECT = <<EOT;
48ce3d9c310bd3173f6fe0a336f349cf  Changes
53a0461b093f6c9d3e03d31f7133e62c  README
7dcff59ab5cb7ad4998fb518047b2e59  MD5.pm
10542966f7609cb13816dc6a18527775  MD5.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT
} else {
    # This is the output of: 'md5sum Changes README MD5.pm MD5.xs rfc1321.txt'
    $EXPECT = <<EOT;
d286d6c6a61e44e88d1deba9954ce37a  Changes
6c950a0211a5a28f023bb482037698cd  README
d31c9aefa1a9e40beda9fff1e1d9c02d  MD5.pm
df178436ead9d354d63089fa0e01af27  MD5.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT
}

if (!(-f "README") && -f "../README") {
   chdir("..") or die "Can't chdir: $!";
}

my $testno = 0;

my $B64 = 1;
eval { require MIME::Base64; };
if ($@) {
    print "# $@: Will not test base64 methods\n";
    $B64 = 0;
}

for (split /^/, $EXPECT) {
     my($md5hex, $file) = split ' ';
     my $base = $file;
     print "# $base\n";
     if ($ENV{PERL_CORE}) {
         if ($file eq 'rfc1321.txt') { # Don't have it in core.
	     print "ok ", ++$testno, " # Skip: PERL_CORE\n";
	     next;
	 }
         use File::Spec;
	 my @path = qw(ext Digest MD5);
	 my $path = File::Spec->updir;
	 while (@path) {
	   $path = File::Spec->catdir($path, shift @path);
	 }
	 $file = File::Spec->catfile($path, $file);
     }
#     print "# file = $file\n";
     unless (-f $file) {
	warn "No such file: $file\n";
	next;
     }
     if ($ENV{EBCDIC_MD5SUM}) {
         require Encode;
	 my $data = cat_file($file);	
	 Encode::from_to($data, 'latin1', 'cp1047');
	 print md5_hex($data), "  $base\n";
	 next;
     }
     if ($ENV{MAC_MD5SUM}) {
	 my $data = cat_file($file);	
	 print md5_hex($data), "  $base\n";
	 next;
     }
     my $md5bin = pack("H*", $md5hex);
     my $md5b64;
     if ($B64) {
	 $md5b64 = MIME::Base64::encode($md5bin, "");
	 chop($md5b64); chop($md5b64);   # remove padding
     }
     my $failed;
     my $got;

     if (digest_file($file, 'digest') ne $md5bin) {
	 print "$file: Bad digest\n";
	 $failed++;
     }

     if (($got = digest_file($file, 'hexdigest')) ne $md5hex) {
	 print "$file: Bad hexdigest: got $got expected $md5hex\n";
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
    my $digest = Digest::MD5->new->addfile(*FILE)->$method();
    close(FILE);

    $digest;
}

sub cat_file
{
    my($file) = @_;
    local $/;  # slurp
    open(FILE, $file) or die "Can't open $file: $!";

    # For PerlIO in case of UTF-8 locales.
    eval 'binmode(FILE, ":bytes")' if $] >= 5.008;

    my $tmp = <FILE>;
    close(FILE);
    $tmp;
}

