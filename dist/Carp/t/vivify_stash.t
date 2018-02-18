BEGIN { print "1..6\n"; }

our $has_utf8; BEGIN { $has_utf8 = exists($::{"utf8::"}); }
our $has_overload; BEGIN { $has_overload = exists($::{"overload::"}); }
our $has_B; BEGIN { $has_B = exists($::{"B::"}); }
our $has_UNIVERSAL_isa; BEGIN { $has_UNIVERSAL_isa = exists($UNIVERSAL::{"isa::"}); }

use Carp;
sub { sub { Carp::longmess("x") }->() }->(\1, "\x{2603}", qr/\x{2603}/);

print !(exists($::{"utf8::"}) xor $has_utf8) ? "" : "not ", "ok 1 # used utf8\n";
print !(exists($::{"overload::"}) xor $has_overload) ? "" : "not ", "ok 2 # used overload\n";
print !(exists($::{"B::"}) xor $has_B) ? "" : "not ", "ok 3 # used B\n";
print !(exists($UNIVERSAL::{"isa::"}) xor $has_UNIVERSAL_isa) ? "" : "not ", "ok 4 # used UNIVERSAL::isa\n";

# Autovivify $::{"overload::"}
() = \$::{"overload::"};
() = \$::{"utf8::"};
eval { sub { Carp::longmess() }->(\1) };
print $@ eq '' ? "ok 5 # longmess check1\n" : "not ok 5 # longmess check1\n# $@";

# overload:: glob without hash
undef *{"overload::"};
eval { sub { Carp::longmess() }->(\1) };
print $@ eq '' ? "ok 6 # longmess check2\n" : "not ok 6 # longmess check2\n# $@";

1;
