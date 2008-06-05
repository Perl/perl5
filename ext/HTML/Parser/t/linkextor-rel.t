use Test::More tests => 4;

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
      #diag "$tag @{[%links]}";
      $links .= "$tag @{[%links]}\n";
  });

$p->parse($HTML); $p->eof;

ok($links =~ m|^base href http://www\.sn\.no/$|m);
ok($links =~ m|^body background http://www\.sn\.no/sn\.gif$|m);
ok($links =~ m|^a href link\.html$|m);

# Used to be problems when using the links method on a document with
# no links it it.  This is a test to prove that it works.
$p = new HTML::LinkExtor;
$p->parse("this is a document with no links"); $p->eof;
@a = $p->links;
is(@a, 0);
