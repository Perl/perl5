print "1..3\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Digest;

print "not " unless Digest->MD5->add("abc")->hexdigest eq "900150983cd24fb0d6963f7d28e17f72";
print "ok 1\n";

print "not " unless Digest->MD5->add("abc")->hexdigest eq "900150983cd24fb0d6963f7d28e17f72";
print "ok 2\n";

eval {
    print "not " unless Digest->new("HMAC-MD5" => "Jefe")->add("what do ya want for nothing?")->hexdigest eq "750c783e6ab0b503eaa86e310a5db738";
    print "ok 3\n";
};
print "ok 3\n" if $@ && $@ =~ /^Can't locate/;

