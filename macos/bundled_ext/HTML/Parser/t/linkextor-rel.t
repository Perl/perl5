print "1..4\n";

require HTML::LinkExtor;

$HTML = <<HTML;
<head>
<base href="http://www.sn.no/">
</head>
<body background="http://www.sn.no/sn.gif">

This is <A HREF="link.html">link</a> and an <img SRC="img.jpg"
lowsrc="img.gif" alt="Image">.
HTML


# Try the callback interface
$links = "";
$p = HTML::LinkExtor->new(
  sub {
      my($tag, %links) = @_;
      print "$tag @{[%links]}\n";
      $links .= "$tag @{[%links]}\n";
  });

$p->parse($HTML); $p->eof;

$links =~ m|^base href http://www\.sn\.no/$|m or print "not ";
print "ok 1\n";
$links =~ m|^body background http://www\.sn\.no/sn\.gif$|m or print "not ";
print "ok 2\n";
$links =~ m|^a href link\.html$|m or print "not ";
print "ok 3\n";

# Used to be problems when using the links method on a document with
# no links it it.  This is a test to prove that it works.
$p = new HTML::LinkExtor;
$p->parse("this is a document with no links"); $p->eof;
@a = $p->links;
print "not " if @a != 0;
print "ok 4\n";
