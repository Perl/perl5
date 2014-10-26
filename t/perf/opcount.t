#!./perl
#
# opcount.t
#
# Test whether various constructs have the right numbers of particular op
# types. This is chiefly to test that various optimisations are not
# inadvertently removed.
#
# For example the array access in sub { $a[0] } should get optimised from
# aelem into aelemfast. So we want to test that there are 1 aelemfast, 0
# aelem and 1 ex-aelem ops in the optree for that sub.

BEGIN {
    chdir 't';
    require './test.pl';
    skip_all_if_miniperl("No B under miniperl");
    @INC = '../lib';
}

plan 3;

use B ();


{
    my %counts;

    # for a given op, increment $count{opname}. Treat null ops
    # as "ex-foo" where possible

    sub B::OP::test_opcount_callback {
        my ($op) = @_;
        my $name = $op->name;
        if ($name eq 'null') {
            my $targ = $op->targ;
            if ($targ) {
                $name = "ex-" . substr(B::ppname($targ), 3);
            }
        }
        $counts{$name}++;
    }

    # Given a code ref and a hash ref of expected op counts, check that
    # for each opname => count pair, whether that op appears that many
    # times in the op tree for that sub. If $debug is 1, display all the
    # op counts for the sub.

    sub test_opcount {
        my ($debug, $desc, $coderef, $expected_counts) = @_;

        %counts = ();
        B::walkoptree(B::svref_2object($coderef)->ROOT,
                        'test_opcount_callback');

        if ($debug) {
            note(sprintf "%3d %s", $counts{$_}, $_) for sort keys %counts;
        }

        for (sort keys %$expected_counts) {
            is ($counts{$_}//0, $expected_counts->{$_}, "$desc: $_");
        }
    }    
}

# aelem => aelemfast: a basic test that this test file works

test_opcount(0, "basic aelemfast",
                sub { $a[0] = 1 }, 
                {
                    aelem      => 0,
                    aelemfast  => 1,
                    'ex-aelem' => 1,
                }
            );
