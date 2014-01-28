#!./perl

# Test && in weird situations.

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan( 4 );

$y = " ";
$x = " ";
pos $x = 1;
for (pos $x && pos $y) {
    eval { $_++ };
}
is(pos($y) || $@, 1, "&& propagates lvaluish context to its rhs");

pos $x = 0;
for (pos $x && pos $y) {
    eval { $_++ };
}
is(pos($x) || $@, 1, "&& propagates lvaluish context to its lhs");

for ($h{k} && '') {}
ok(!exists $h{k}, "foreach does not vivify lhs of &&");

for (${\1} && $h{l}) {}
ok(!exists $h{l}, "foreach does not vivify rhs of &&");

