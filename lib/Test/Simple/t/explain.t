#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/explain.t 60308 2008-09-07T22:36:18.175234Z schwern  $

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use warnings;

use Test::More tests => 5;

can_ok "main", "explain";

is_deeply [explain("foo")],             ["foo"];
is_deeply [explain("foo", "bar")],      ["foo", "bar"];

# Avoid future dump formatting changes from breaking tests by just eval'ing
# the dump
is_deeply [map { eval $_ } explain([], {})],           [[], {}];

is_deeply [map { eval $_ } explain(23, [42,91], 99)],  [23, [42, 91], 99];
