use v5.40;

use Test::More;
use XS::APItest;
use Config ();

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

# Attributes on lexical variables
{
    my $lexscalar :red(s-arg);
    my @lexarray  :red(a-arg);
    my %lexhash   :red(h-arg);

    is( $ATTRIBUTES_APPLIED{'red/my $lexscalar'}, "s-arg",
        ':red attribute applied to lexical scalar' );
    is( $ATTRIBUTES_APPLIED{'red/my @lexarray'}, "a-arg",
        ':red attribute applied to lexical array' );
    is( $ATTRIBUTES_APPLIED{'red/my %lexhash'}, "h-arg",
        ':red attribute applied to lexical hash' );
}

# Attribute definitions survive thread cloning
# (this is mostly a test of the underlying SVt_INTERNAL implementation)
SKIP: {
    last SKIP unless $Config::Config{usethreads};

    require threads;
    threads->create( sub { return 123 } )->join;
}

done_testing;
