#!/usr/bin/perl -w

use Test::More 'no_diag', tests => 1;

pass('foo');
diag('This should not be displayed');
