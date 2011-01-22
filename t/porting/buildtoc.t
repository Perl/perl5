#!./perl

BEGIN {
    chdir '..' unless -d 't';
    unshift @INC, 'lib';
}

use strict;

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";
system("${dotslash}perl -f -Ilib -I../lib pod/buildtoc --build-toc -q --test --build-all");
