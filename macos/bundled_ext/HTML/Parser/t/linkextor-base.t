# This test that HTML::LinkExtor really absolutize links correctly
# when a base URL is given to the constructor.

eval {
   require URI;
};
if ($@) {
   print "1..0\n";
   print $@;
   exit;
}

print "1..5\n";
require HTML::LinkExtor;

# Try with base URL and the $p->links interface.
$p = HTML::LinkExtor->new(undef, "http://www.sn.no/foo/foo.html");
$p->parse(<<HTML)->eof;
<head>
<base href="http://www.sn.no/">
</head>
<body background="http://www.sn.no/sn.gif">

This is <A HREF="link.html">link</a> and an <img SRC="img.jpg"
lowsrc="img.gif" alt="Image">.
HTML

@p = $p->links;

# There should be 4 links in the document
print "not " if @p != 4;
print "ok 1\n";

for (@p) {
    ($t, %attr) = @$_ if $_->[0] eq 'img';
    print "@$_\n";
}

$t eq 'img' || print "not ";
print "ok 2\n";

delete $attr{src} eq "http://www.sn.no/foo/img.jpg" || print "not ";
print "ok 3\n";

delete $attr{lowsrc} eq "http://www.sn.no/foo/img.gif" || print "not ";
print "ok 4\n";

scalar(keys %attr) && print "not "; # there should be no more attributes
print "ok 5\n";

