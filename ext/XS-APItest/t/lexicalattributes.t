use v5.40;

use Test::More;
use XS::APItest;

our %ATTRIBUTES_APPLIED;

BEGIN {
    XS::APItest::LexicalAttributes->import_attributes( 'red' );
}

# Attributes on package subs
{
    sub SUBROUTINE :red(c-arg) { }

    my $refaddr = builtin::refaddr \&SUBROUTINE;

    is( $ATTRIBUTES_APPLIED{sprintf "red/%x=SUBROUTINE", $refaddr}, "c-arg",
        ':red attribute applied to package subroutine' );
}

done_testing;
