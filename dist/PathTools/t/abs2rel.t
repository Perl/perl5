#!/usr/bin/perl -w

use strict;
use Test::More;

use Cwd qw(cwd getcwd abs_path);
use File::Spec();
use File::Temp qw(tempdir);
use File::Path qw(make_path);

my $startdir = cwd();

test_rel2abs( {
    startdir        => $startdir,
    first_sub_dir   => 'etc',
    sub_sub_dir     => 'init.d',
    first_file      => 'passwd',
    second_sub_dir  => 'dev',
    second_file     => 'null',
} );

test_rel2abs( {
    startdir        => $startdir,
    first_sub_dir   => 'etc',
    sub_sub_dir     => 'init.d',
    first_file      => './passwd',
    second_sub_dir  => 'dev',
    second_file     => 'null',
} );

test_rel2abs( {
    startdir        => $startdir,
    first_sub_dir   => 'etc',
    sub_sub_dir     => 'init.d',
    first_file      => '../etc/passwd',
    second_sub_dir  => 'dev',
    second_file     => 'null',
} );

test_rel2abs( {
    startdir        => $startdir,
    first_sub_dir   => 'etc',
    sub_sub_dir     => 'init.d',
    first_file      => '../dev/null',
    second_sub_dir  => 'dev',
    second_file     => 'null',
} );

sub test_rel2abs {
    my $args = shift;
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or die "Unable to change to $tdir: $!";

    my @subdirs = (
        $args->{first_sub_dir},
        File::Spec->catdir($args->{first_sub_dir},  $args->{sub_sub_dir}),
        $args->{second_sub_dir}
    );
    make_path(@subdirs, { mode => 0711 })
        or die "Unable to make_path: $!";

    open my $OUT2, '>',
        File::Spec->catfile($args->{second_sub_dir}, $args->{second_file})
        or die "Unable to open $args->{second_file} for writing: $!";
    print $OUT2 "Attempting to resolve RT #121360\n";
    close $OUT2 or die "Unable to close $args->{second_file} after writing: $!";

    chdir $args->{first_sub_dir}
        or die "Unable to change to '$args->{first_sub_dir}': $!";
    open my $OUT1, '>', $args->{first_file}
        or die "Unable to open $args->{first_file} for writing: $!";
    print $OUT1 "Attempting to resolve RT #121360\n";
    close $OUT1 or die "Unable to close $args->{first_file} after writing: $!";

    my $rel_path = $args->{first_file};
    my $rel_base = $args->{sub_sub_dir};
    my $abs_path = File::Spec->rel2abs($rel_path);
    my $abs_base = File::Spec->rel2abs($rel_base);
    ok(-f $rel_path, "'$rel_path' is readable by effective uid/gid");
    ok(-f $abs_path, "'$abs_path' is readable by effective uid/gid");
    is_deeply(
        [ (stat $rel_path)[0..5] ],
        [ (stat $abs_path)[0..5] ],
        "rel_path and abs_path stat same"
    );
    ok(-d $rel_base, "'$rel_base' is a directory");
    ok(-d $abs_base, "'$abs_base' is a directory");
    is_deeply(
        [ (stat $rel_base)[0..5] ],
        [ (stat $abs_base)[0..5] ],
        "rel_base and abs_base stat same"
    );
    my $rr_link = File::Spec->abs2rel($rel_path, $rel_base);
    my $ra_link = File::Spec->abs2rel($rel_path, $abs_base);
    my $ar_link = File::Spec->abs2rel($abs_path, $rel_base);
    my $aa_link = File::Spec->abs2rel($abs_path, $abs_base);
    is($rr_link, $ra_link,
        "rel_path-rel_base '$rr_link' = rel_path-abs_base '$ra_link'");
    is($ar_link, $aa_link,
        "abs_path-rel_base '$ar_link' = abs_path-abs_base '$aa_link'");
    is($rr_link, $aa_link,
        "rel_path-rel_base '$rr_link' = abs_path-abs_base '$aa_link'");

    chdir $args->{startdir} or die "Unable to change back to $args->{startdir}: $!";
}

done_testing();
