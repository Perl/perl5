#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

plan 5;

my $err = "Unimplemented at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ... };

is $@, $err;

$err = "foo at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { !!! "foo" };

is $@, $err;

$err = "Died at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { !!! };

is $@, $err;

my $warning;

local $SIG{__WARN__} = sub { $warning = shift };

$err = "bar at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ??? "bar" };

is $warning, $err;

$err = "Warning: something's wrong at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ??? };

is $warning, $err;
