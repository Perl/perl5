#!perl

use strict;
use warnings;

use Test::More tests => 16;

use XS::APItest qw(DEFSV);

is $_, undef;
is DEFSV, undef;
is \DEFSV, \$_;

DEFSV = "foo";
is DEFSV, "foo";
is $_, "foo";

$_ = "bar";
is DEFSV, "bar";
is $_, "bar";

{
    no warnings 'experimental::lexical_topic';
    my $_;

    is $_, undef;
    is DEFSV, undef;
    is \DEFSV, \$_;

    DEFSV = "lex-foo";
    is DEFSV, "lex-foo";
    is $_, "lex-foo";

    $_ = "lex-bar";
    is DEFSV, "lex-bar";
    is $_, "lex-bar";
}

is DEFSV, "bar";
is $_, "bar";
