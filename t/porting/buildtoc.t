#!./perl

BEGIN {
    chdir '..' unless -d 't';
    unshift @INC, 'lib';
}

use strict;

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";
system("${dotslash}perl -f -Ilib pod/buildtoc --build-toc -q --test");
