use warnings;
use strict;

our $has_is_utf8;
BEGIN { $has_is_utf8 = exists($utf8::{"is_utf8"}); }

our $has_downgrade;
BEGIN { $has_downgrade = exists($utf8::{"downgrade"}); }

use Test::More tests => 3;

BEGIN { use_ok "Carp"; }
ok(!(exists($utf8::{"is_utf8"}) xor $has_is_utf8));
ok(!(exists($utf8::{"downgrade"}) xor $has_downgrade));

1;
