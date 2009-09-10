#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib/';
}
chdir 't';

use Test::More tests => 1;
use ExtUtils::MakeMaker;

# dir_target() was typo'd as dir_targets()
can_ok('MM', 'dir_target');
