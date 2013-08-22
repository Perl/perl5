BEGIN { print "1..2\n"; }

our $has_utf8; BEGIN { $has_utf8 = exists($::{"utf8::"}); }
our $has_overload; BEGIN { $has_overload = exists($::{"overload::"}); }

use Carp;
sub { Carp::longmess() }->(\1);

print !(exists($::{"utf8::"}) xor $has_utf8) ? "" : "not ", "ok 1\n";
print !(exists($::{"overload::"}) xor $has_overload) ? "" : "not ", "ok 2\n";

1;
