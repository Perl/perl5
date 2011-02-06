#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Test::More tests =>  7;
use lib qw( lib );
use ExtUtils::ParseXS::Utilities qw(
  process_typemaps
  process_single_typemap
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
    like( $@, qr/Can't find $typemap in $tdir/, #'
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
    like( $@, qr/Can't find pseudo in $tdir/, #'
        "Got expected result for no typemap in current directory" );
    chdir $startdir;
}

{
    my ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref);
    my $typemap = File::Spec->catfile( qw| t pseudotypemap1 | );
    my @capture = ();
    local $SIG{__WARN__} = sub { push @capture, $_[0] };
    ($type_kind_ref, $proto_letter_ref, $input_expr_ref, $output_expr_ref)
            = process_single_typemap( $typemap, {}, {}, {}, {}  );
    like( $capture[0],
        qr/TYPEMAP entry needs 2 or 3 columns/,
        "Got expected warning for insufficient columns"
    );
    my $t = 'unsigned long';
    is( $type_kind_ref->{$t}, 'T_UV',
        "type_kind:  got expected value for <$t>" );
    is( $proto_letter_ref->{$t}, '$',
        "proto_letter:  got expected value for <$t>" );
    is( scalar keys %{ $input_expr_ref }, 0,
        "Nothing assigned to input_expr" );
    is( scalar keys %{ $output_expr_ref }, 0,
        "Nothing assigned to output_expr" );
}

