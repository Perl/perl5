use strict;
print "1..3\n";

my $text = "";
use HTML::Parser ();
my $p = HTML::Parser->new(default_h => [sub { $text .= shift }, "text"],
                         );

my $html = <<'EOT';

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
                       "http://www.w3.org/TR/html40/strict.dtd">

<title>foo</title>
<!-- comment <a> -->
<?process instruction>

EOT

$p->parse($html)->eof;

print "not " unless $text eq $html;
print "ok 1\n";

$text = "";
$p->handler(start => sub { }, "");
$p->handler(declaration => sub { }, "");
$p->parse($html)->eof;

my $html2;
$html2 = $html;
$html2 =~ s/<title>//;
$html2 =~ s/<!DOCTYPE[^>]*>//;

print "not " unless $text eq $html2;
print "ok 2\n";

$text = "";
$p->handler(start => undef);
$p->parse($html)->eof;

$html2 = $html;
$html2 =~ s/<!DOCTYPE[^>]*>//;

print "not " unless $text eq $html2;
print "ok 3\n";
