#!perl -w
BEGIN {
    chdir "t" if -d "t";
    require './test.pl';
    @INC = "../lib";
}
use v5.36;

# load the script
do("../Porting/merge-deltas.pl") or die $@ || $!;

# tree_for & as_pod
{
    my $pod = <<~ 'POD';
    =head2 CVE-2025-xyzzy

    Some CVE was fixed.

    Found by some person.

    =cut
    POD

    # as_pod round-trips basic POD
    is( as_pod( tree_for($pod) ), $pod, 'as_pod( tree_pod ) round-trips' );
}

# loop_head1 (with unexpected head1)
{
    my $template = tree_for( <<~ 'POD' );
    =head1 Unexpected

    =cut
    POD

    # loop_head1 dies on unexpected =head1
    # the callback is only run on the unskipped sections
    ok(
        !eval {
            loop_head1(
                [],
                $template,
                'bogus_delta.pod',
                sub {}
            );
            1;
        },
        'loop_head1 dies on unexpected =head1'
    );
    is(
        $@,
        "Unexpected section '=head1 Unexpected' in bogus_delta.pod\n",
        '.. expected error message for loop_head1'
    );
}

# loop_head1 test contents of template have not changed
{
    my $template_file = "../Porting/perldelta_template.pod";
    my $template      = tree_for( slurp($template_file) );

    # loop_head1 dies on unexpected =head1
    # the callback is only run on the unskipped sections
    ok(
        eval {
            loop_head1(
                [],
                $template,
                $template_file,
                sub ( $master, $title, $template ) {
                    ok( $title, "=head1 $title" );
                }
            );
            1;
        },
        'loop_head1'
    );
}

# copy_section
{
    my $master_pod = <<~ 'POD';
    =head1 NAME

    Master perldelta

    =head1 Notice

    XXX Some notice

    =head1 Acknowledgments
    POD
    my $delta_pod = <<~ 'POD';
    =head1 NAME

    Devel perldelta

    =head1 Notice

    Devel notice

    =head1 Acknowledgments
    POD
    my $master = tree_for($master_pod);
    copy_section( $master, 'Notice', tree_for($delta_pod) );
    is( as_pod($master), <<~ 'EXPECTED', 'copy_section' );
    =head1 NAME

    Master perldelta

    =head1 Notice

    Devel notice

    XXX Some notice

    =head1 Acknowledgments

    =cut
    EXPECTED
}

# remove_identical
{
    my $pod = <<~ 'POD';
    =head1 NAME

    Template perldelta

    =head1 Notice

    XXX Some notice

    =head1 Acknowledgments
    POD

    my $master = tree_for( $pod =~ s/Template/Master/r );
    remove_identical( $master, 'Notice', tree_for($pod) );
    is( as_pod($master), <<~ 'EXPECTED', 'remove_identical' );
    =head1 NAME

    Master perldelta

    =head1 Acknowledgments

    =cut
    EXPECTED
}

done_testing;
