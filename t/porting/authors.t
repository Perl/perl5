#!./perl -w
# Test that there are no missing authors in AUTHORS

BEGIN {
    @INC = '..' if -f '../TestInit.pm';
}
use TestInit 'T'; # T is chdir to the top level
use strict;

if (! -d '.git' ) {
    print "1..0 # SKIP: not being run from a git checkout\n";
    exit 0;
}

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";
system("git log --pretty=fuller | ${dotslash}perl Porting/checkAUTHORS.pl --tap -");

# EOF
