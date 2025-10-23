use v5.36;
use Test2::V0;

my $root = -f 't/TEST' && -f 'MANIFEST' && -d 'lib' && -d 'ext' ? '.' : '..';

# load the script
do("$root/Porting/merge-deltas.pl") or die $@ || $!;

# tree_for & as_pod
{
    my $pod = <<~ 'POD';
    =head2 CVE-2025-xyzzy

    Some CVE was fixed.

    Found by some person.

    =cut
    POD

    # just a single test: we're not testing Pod::Simple::SimpleTree
    is(
        tree_for($pod),
        [
            Document => { start_line => 1 },
            [ head2 => { start_line => 1 }, 'CVE-2025-12345' ],
            [ Para  => { start_line => 3 }, 'Some CVE was fixed.' ],
            [ Para  => { start_line => 5 }, 'Found by some person.' ],
        ],
        'tree_for'
    );

    # as_pod round-trips basic POD
    is( as_pod( tree_for($pod) ), $pod, 'as_pod' );
}

# loop_head1
{
    my $template_file = "$root/Porting/perldelta_template.pod";
    my $template      = tree_for( slurp($template_file) );

    # loop_head1 dies on unexpected =head1
    # the callback is only run on the unskipped sections
    ok(
        lives {
            loop_head1(
                [],
                $template,
                $template_file,
                sub ( $master, $title, $template ) {
                    is( $title, L(), "=head1 $title" );
                }
            );
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
