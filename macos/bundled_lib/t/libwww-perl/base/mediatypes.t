use LWP::MediaTypes;

require URI::URL;

$url1 = new URI::URL 'http://www/foo/test.gif?search+x#frag';
$url2 = new URI::URL 'http:test';

my $pwd if $^O eq "MacOS";

unless ($^O eq "MacOS") {
    $file = "/etc/passwd";
    -r $file or $file = "./README";
} else {
    require Mac::Files;
    $pwd = `pwd`;
    chomp($pwd);
    my $dir = Mac::Files::FindFolder(Mac::Files::kOnSystemDisk(),
	                             Mac::Files::kDesktopFolderType());
    chdir($dir);
    $file = "README";
    open(README,">$file") or die "Unable to open $file";
    print README "This is a dummy file for LWP testing purposes\n";
    close README;
    open(README,">/dev/null") or die "Unable to open /dev/null";
    print README "This is a dummy file for LWP testing purposes\n";
    close README;
}

@tests =
(
 ["/this.dir/file.html" => "text/html",],
 ["test.gif.htm"        => "text/html",],
 ["test.txt.gz"         => "text/plain", "gzip"],
 ["gif.foo"             => "application/octet-stream",],
 ["lwp-0.03.tar.Z"      => "application/x-tar", "compress"],
 [$file		        => "text/plain",],
 ["/random/file"        => "application/octet-stream",],
 [($^O eq 'VMS'? "nl:" : "/dev/null") => "text/plain",],
 [$url1	        	=> "image/gif",],
 [$url2	        	=> "application/octet-stream",],
 ["x.ppm.Z.UU"		=> "image/x-portable-pixmap","compress","x-uuencode",],
);

$notests = @tests + 3;
print "1..$notests\n";

if (-f "$ENV{HOME}/.mime.types") {
   warn "
The MediaTypes test might fail because you have a private ~/.mime.types file
If you get a failed test, try to move it away while testing.
";
}


$testno = 1;
for (@tests) {
    ($file, $expectedtype, @expectedEnc) = @$_;
    $type1 = guess_media_type($file);
    ($type, @enc) = guess_media_type($file);
    if ($type1 ne $type) {
       print "guess_media_type does not return same content-type in scalar and array conext.\n";
	next;
    }
    $type = "undef" unless defined $type;
    if ($type eq $expectedtype and "@enc" eq "@expectedEnc") {
	print "ok $testno\n";
    } else {
	print "expected '$expectedtype' for '$file', got '$type'\n";
	print "encoding: expected: '@expectedEnc', got '@enc'\n"
	  if @expectedEnc || @enc;
	print "nok ok $testno\n";
    }
    $testno++;
}

@imgSuffix = media_suffix('image/*');
print "Image suffixes: @imgSuffix\n";

print "\n";
require HTTP::Response;
$r = new HTTP::Response 200, "Document follows";
$r->title("file.tar.gz.uu");
guess_media_type($r->title, $r);
print $r->as_string;

print "not " unless $r->content_type eq "application/x-tar";
print "ok $testno\n"; $testno++;

@enc = $r->header("Content-Encoding");
print "not " unless "@enc" eq "gzip x-uuencode";
print "ok $testno\n"; $testno++;

#
use LWP::MediaTypes qw(add_type add_encoding);
add_type("x-world/x-vrml", qw(wrl vrml));
add_encoding("x-gzip" => "gz");
add_encoding(rot13 => "r13");

@x = guess_media_type("foo.vrml.r13.gz");
#print "@x\n";
print "not " unless "@x" eq "x-world/x-vrml rot13 x-gzip";
print "ok $testno\n"; $testno++;

#print LWP::MediaTypes::_dump();

if($^O eq "MacOS") {
    unlink "README";
    unlink "/dev/null";
    chdir($pwd);
}

