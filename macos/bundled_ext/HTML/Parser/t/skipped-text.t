print "1..3\n";

use strict;
use HTML::Parser;

my $p = HTML::Parser->new(api_version => 3);

$p->report_tags("a");

my @doc;

$p->handler(start => \&a_handler, "skipped_text, text");
$p->handler(end_document => \@doc, '@{skipped_text}');

$p->parse(<<EOT)->eof;
<title>hi<title>
<h1><a href="foo">link</a></h1>
and <a foo="">some</a> text.
EOT

sub a_handler {
    push(@doc, shift);
    my $text = shift;
    push(@doc, uc($text));
}


print "not " unless join("", @doc) eq <<'EOT'; print "ok 1\n";
<title>hi<title>
<h1><A HREF="FOO">link</a></h1>
and <A FOO="">some</a> text.
EOT

#
# Comment stripper.  Interaction with "" handlers.
#
my $doc = <<EOT;
<html>text</html>
<!-- comment -->
and some more <b>text</b>.
EOT
(my $expected = $doc) =~ s/<!--.*?-->//;

$p = HTML::Parser->new(api_version => 3);
$p->handler(comment => "");
$p->handler(end_document => sub {
		                my $stripped = shift;
				#print $stripped;
	                        print "not " unless $stripped eq $expected;
                                print "ok 2\n";
			    }, "skipped_text");
for (split(//, $doc)) {
    $p->parse($_);
}
$p->eof;

#
# Interaction with unbroken text
#
my @x;
$p = HTML::Parser->new(api_version => 3, unbroken_text => 1);
$p->handler(text => \@x, '@{"X", skipped_text, text}');
$p->handler(end => "");
$p->handler(end_document => \@x, '@{"Y", skipped_text}');

$doc = "a a<a>b b</a>c c<x>d d</x>e";

for (split(//, $doc)) {
   $p->parse($_);
}
$p->eof;

#print join(":", @x), "\n";
print "not " unless join(":", @x) eq "X::a a:X:<a>:b bc c:X:<x>:d de:Y:";
print "ok 3\n";

