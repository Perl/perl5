use warnings;
use strict;
use Test::More tests => 19;

use XS::APItest;
use B qw(opnumber OPpCONST_FOLDED);
use constant OP_CONST => opnumber('const');

XS::APItest::test_op_list();
ok 1;

XS::APItest::test_op_linklist();
ok 1;

# This is somwhat a hack. It's unclear what the right answer here is, but
# creating OPs in an XS routine ends up using the caller's pad. This can
# result in the pad being resized and moved. This then breaks the
# implementation of for() below, which has stored the address of the SV's
# pointer - ie SV **. So for now, wrap each in a dummy subroutine to ensure
# it uses a distinct pad.

sub {
    is (eval {XS::APItest::test_fold_constants(-1); 1;}, undef,
	'case -1 croaks');
    like ($@,
	  qr/panic: fold_constants called when IN_PERL_COMPILETIME is false/,
	  'with expected panic message');
}->();

for my $case (0..4, 54) {
    my (@got) = sub {XS::APItest::test_fold_constants($case)}->();
    my $expect = (!$case or $case & 1) ? 1 : 2;
    is (scalar @got, $expect, "expected $expect return value(s) for case $case");
    if ($expect == 2) {
        is($got[0], $case, "case $case folds to correct constant");
        is($got[1] & OPpCONST_FOLDED, OPpCONST_FOLDED,
           "OPpCONST_FOLDED flag is set");
    } else {
        isnt($got[0], OP_CONST, 'Do not expect OP_CONST');
    }
}

1;
