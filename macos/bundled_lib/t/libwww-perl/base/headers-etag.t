print "1..4\n";

require HTTP::Headers::ETag;

$h = HTTP::Headers->new;
$h->etag("tag1");
print "not " unless $h->etag eq qq("tag1");
print "ok 1\n";

$h->etag("w/tag2");
print "not " unless $h->etag eq qq(W/"tag2");
print "ok 2\n";

$h->if_match(qq(W/"foo", bar, baz), "bar");
$h->if_none_match(333);

$h->if_range("tag3");
print "not " unless $h->if_range eq qq("tag3");
print "ok 3\n";

$t = time;
$h->if_range($t);
print "not " unless $h->if_range == $t;
print "ok 4\n";


print $h->as_string;

