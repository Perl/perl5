use Test::CanThread qw/AUTHOR_TESTING/;
use Test::More;

# basic tests
{
    pass('Test starts');
    my $ct_num = Test::More->builder->current_test;

    my $newthread = async {
        my $out = '';

        #simulate a  subtest to not confuse the parent TAP emission
        my $tb = Test::More->builder;
        $tb->reset;

        Test::More->builder->current_test(0);
        for (qw/output failure_output todo_output/) {
            close $tb->$_;
            open($tb->$_, '>', \$out);
        }

        pass("In-thread ok") for (1, 2, 3);

        done_testing;

        close $tb->$_ for (qw/output failure_output todo_output/);
        sleep(1);    # tasty crashes without this

        $out;
    };
    die "Thread creation failed: $! $@" if !defined $newthread;

    my $out = $newthread->join;
    $out =~ s/^/   /gm;

    print $out;

    # workaround for older Test::More confusing the plan under threads
    Test::More->builder->current_test($ct_num);

    pass("Made it to the end");
}

done_testing;
