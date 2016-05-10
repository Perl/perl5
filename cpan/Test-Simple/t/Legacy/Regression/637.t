use strict;
use warnings;

BEGIN {
    my $skip = !eval { require threads; 1 };
    if ($skip) {
        require Test::More;
        Test::More::plan(skip_all => 'no threads');
    }
}

use threads;
use Test::More;

ok 1 for (1 .. 2);

# used to reset the counter after thread finishes
my $ct_num = Test::More->builder->current_test;

my $subtest_out = async {
    my $out = '';

    #simulate a  subtest to not confuse the parent TAP emission
    my $tb = Test::More->builder;
    $tb->reset;
    for (qw/output failure_output todo_output/) {
        close $tb->$_;
        open($tb->$_, '>', \$out);
    }

    ok 1 for (1 .. 3);

    done_testing;

    close $tb->$_ for (qw/output failure_output todo_output/);

    $out;
}
->join;

$subtest_out =~ s/^/   /gm;
print $subtest_out;

# reset as if the thread never "said" anything
Test::More->builder->current_test($ct_num);

ok 1 for (1 .. 4);

done_testing;
