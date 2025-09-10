#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Cwd qw(cwd);
use File::Temp qw( tempdir );
use File::Spec;
use Test::More tests =>  6;
use ExtUtils::ParseXS::Utilities qw(
  process_typemaps
);

my $startdir  = cwd();
{
    my ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
    my $typemap = 'typemap';
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or croak "Unable to change to tempdir for testing";
    eval {
        ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref)
            = process_typemaps( $typemap, $tdir );
    };
    like( $@, qr/Can't find \Q$typemap\E in \Q$tdir\E/, #'
        "Got expected result for no typemap in current directory" );
    chdir $startdir;
}

{
    my ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
    my $typemap = [ qw( pseudo typemap ) ];
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or croak "Unable to change to tempdir for testing";
    open my $IN, '>', 'typemap' or croak "Cannot open for writing";
    print $IN "\n";
    close $IN or croak "Cannot close after writing";
    eval {
        ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref)
            = process_typemaps( $typemap, $tdir );
    };
    like( $@, qr/Can't find pseudo in \Q$tdir\E/, #'
        "Got expected result for no typemap in current directory" );
    chdir $startdir;
}

# Confirm that explicit typemaps via -typemap etc override standard
# entries.

{
    my $tm_obj = process_typemaps(
        [ File::Spec->catfile("t", "data", "conflicting.typemap") ], '.');
    ok($tm_obj, "got typemap object");

    my $tm_entry = $tm_obj->get_typemap(ctype => 'double');
    ok($tm_entry, "got typemap entry object");

    my $xs = $tm_entry->xstype;
    ok($xs, "got typemap XS type");
    # should be overridden from T_NV
    is($xs, "T_DIFFERENT", "got typemap XS type");
}
