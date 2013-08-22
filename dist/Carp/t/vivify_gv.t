BEGIN { print "1..3\n"; }

our $has_is_utf8; BEGIN { $has_is_utf8 = exists($utf8::{"is_utf8"}); }
our $has_dgrade; BEGIN { $has_dgrade = exists($utf8::{"downgrade"}); }
our $has_strval; BEGIN { $has_strval = exists($overload::{"StrVal"}); }

use Carp;
sub { Carp::longmess() }->(\1);

print !(exists($utf8::{"is_utf8"}) xor $has_is_utf8) ? "" : "not ", "ok 1\n";
print !(exists($utf8::{"downgrade"}) xor $has_dgrade) ? "" : "not ", "ok 2\n";
print !(exists($overload::{"StrVal"}) xor $has_strval) ? "" : "not ", "ok 3\n";

1;
