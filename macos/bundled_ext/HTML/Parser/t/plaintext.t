print "1..1\n";

use strict;
use HTML::Parser;

my @a;
my $p = HTML::Parser->new(api_version => 3);
$p->handler(default => \@a, '@{event, text, is_cdata}');
$p->parse(<<EOT)->eof;
<xmp><foo></xmp>x<plaintext><foo>
</plaintext>
foo
EOT

for (@a) {
    $_ = "" unless defined;
}

my $doc = join(":", @a);

#print "$doc\n";

print "not " unless $doc eq "start_document:::start:<xmp>::text:<foo>:1:end:</xmp>::text:x::start:<plaintext>::text:<foo>
</plaintext>
foo
:1:end_document::";
print "ok 1\n";

