#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/Builder/no_diag.t 60332 2008-09-09T12:24:03.060291Z schwern  $

use Test::More 'no_diag', tests => 2;

pass('foo');
diag('This should not be displayed');

is(Test::More->builder->no_diag, 1);
