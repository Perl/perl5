#!./perl -w

# Test that there are no missing authors in AUTHORS
BEGIN {
    chdir '..' unless -d 't';
    unshift @INC, 'lib';
}

use strict;
use warnings;

if (! -d '.git' ) {
    print "1..0 # SKIP: not being run from a git checkout\n";
    exit 0;
}

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";
system("git log --pretty=fuller | ${dotslash}perl -Ilib Porting/checkAUTHORS.pl --tap -");

# EOF
