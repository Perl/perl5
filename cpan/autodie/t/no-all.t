#!/usr/bin/perl

package foo;
use warnings;
use strict;

use Test::More;

BEGIN {
    eval 'use IPC::System::Simple';  ## no critic
    plan skip_all => "Optional IPC::System::Simple required to do this test" if $@;
}
plan tests => 1;

use autodie qw(:all);

use_system();
ok("system() works with a lexical 'no autodie' block (github issue #69");

sub break_system {
    no autodie;
    open(my $fh, "<", 'NONEXISTENT');
    ok("survived failing open");
}

sub use_system {
    system($^X, '-e' , 1);
}

1;
