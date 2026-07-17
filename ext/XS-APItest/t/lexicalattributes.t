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

# Attributes on package variables
{
    our $SCALAR :red(s-arg);
    our @ARRAY  :red(a-arg);
    our %HASH   :red(h-arg);

    is( $ATTRIBUTES_APPLIED{'red/$main::SCALAR'}, "s-arg",
        ':red attribute applied to package scalar' );
    is( $ATTRIBUTES_APPLIED{'red/@main::ARRAY'}, "a-arg",
        ':red attribute applied to package array' );
    is( $ATTRIBUTES_APPLIED{'red/%main::HASH'}, "h-arg",
        ':red attribute applied to package hash' );

    our ( $v1, $v2, $v3 ) :red(all);
    ok( $ATTRIBUTES_APPLIED{'red/$main::v1'} &&
        $ATTRIBUTES_APPLIED{'red/$main::v2'} &&
        $ATTRIBUTES_APPLIED{'red/$main::v3'},
        ':red attribute applied to all three vars' );
}

done_testing;
