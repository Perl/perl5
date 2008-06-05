use Test::More tests => 4;

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3);

ok(!$p->handler("start"), "API version 3");

my $failed;
eval {
   my $p = HTML::Parser->new(api_version => 4);
   $failed++;
};
like($@, qr/^API version 4 not supported/);
ok(!$failed, "API version 4");

$p = HTML::Parser->new(api_version => 2);

is($p->handler("start"), "start", "API version 2");


