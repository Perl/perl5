if ($] < 5.007) {
    print "1..0\n";
    exit;
}

print "1..1\n";

require MIME::Base64;

eval {
    MIME::Base64::encode(v300);
};

print $@;
print "not " unless $@;
print "ok 1\n";

