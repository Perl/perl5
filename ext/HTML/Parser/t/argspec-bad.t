use Test::More tests => 6;

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

eval {
   $p->handler(end => "end", q(xyzzy));
};
like($@, qr/^Unrecognized identifier xyzzy in argspec/);


eval {
   $p->handler(end => "end", q(tagname text));
};
like($@, qr/^Missing comma separator in argspec/);


eval {
   $p->handler(end => "end", q(tagname, "text));
};
like($@, qr/^Unterminated literal string in argspec/);


eval {
   $p->handler(end => "end", q(tagname, "t\\t"));
};
like($@, qr/^Backslash reserved for literal string in argspec/);

eval {
   $p->handler(end => "end", '"' . ("x" x 256) . '"');
};
like($@, qr/^Literal string is longer than 255 chars in argspec/);

$p->handler(end => sub { is(length(shift), 255) },
	           '"' . ("x" x 255) . '"');
$p->parse("</x>");


