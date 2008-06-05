#!perl -w

# HTML-Parser 3.33 and older used to core dump on this program because
# of missing SPAGAIN calls in parse() XS code.  It was not prepared for
# the stack to get realloced.

$| = 1;

use Test::More tests => 1;

use HTML::Parser;
my $x = HTML::Parser->new(api_version => 3);
my @row;
$x->handler(end => sub { push(@row, (1) x 505); 1 },   "tagname");
$x->parse("</TD>");

pass;
