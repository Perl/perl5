print "1..6\n";

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

eval {
   $p->handler(end => "end", q(xyzzy));
};
print $@;
print "not " unless $@ && $@ =~ /^Unrecognized identifier xyzzy in argspec/;
print "ok 1\n";


eval {
   $p->handler(end => "end", q(tagname text));
};
print $@;
print "not " unless $@ && $@ =~ /^Missing comma separator in argspec/;
print "ok 2\n";


eval {
   $p->handler(end => "end", q(tagname, "text));
};
print $@;
print "not " unless $@ && $@ =~ /^Unterminated literal string in argspec/;
print "ok 3\n";


eval {
   $p->handler(end => "end", q(tagname, "t\\t"));
};
print $@;
print "not " unless $@ && $@ =~ /^Backslash reserved for literal string in argspec/;
print "ok 4\n";

eval {
   $p->handler(end => "end", '"' . ("x" x 256) . '"');
};
print $@;
print "not " unless $@ && $@ =~ /^Literal string is longer than 255 chars in argspec/;
print "ok 5\n";

$p->handler(end => sub { print "ok 6\n" if length(shift) eq 255 },
	           '"' . ("x" x 255) . '"');
$p->parse("</x>");


