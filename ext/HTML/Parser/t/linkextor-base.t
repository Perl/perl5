# This test that HTML::LinkExtor really absolutize links correctly
# when a base URL is given to the constructor.

use Test::More tests => 5;
require HTML::LinkExtor;

SKIP: {
eval {
   require URI;
};
skip $@, 5 if $@;

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
is(@p, 4);

for (@p) {
    ($t, %attr) = @$_ if $_->[0] eq 'img';
}

is($t, 'img');

is(delete $attr{src}, "http://www.sn.no/foo/img.jpg");

is(delete $attr{lowsrc}, "http://www.sn.no/foo/img.gif");

ok(!scalar(keys %attr)); # there should be no more attributes
}
