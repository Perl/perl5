#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}


use Test::More tests => 3;
use Test::Builder;
use Test::Builder::Provider;

provides qw/foo bar/;
sub foo { builder()->croak("foo") }
sub bar { builder()->carp("bar")  }

eval { foo() };
is $@, sprintf "foo at %s line %s.\n", $0, __LINE__ - 1;

eval { builder()->croak("this") };
is $@, sprintf "this at %s line %s.\n", $0, __LINE__ - 1;

{
    my $warning = '';
    local $SIG{__WARN__} = sub {
        $warning .= join '', @_;
    };

    bar();
    is $warning, sprintf "bar at %s line %s.\n", $0, __LINE__ - 1;
}
