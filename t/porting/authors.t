#!./perl -w
# Test that there are no missing authors in AUTHORS

BEGIN {
    @INC = '..' if -f '../TestInit.pm';
}
use TestInit 'T'; # T is chdir to the top level
use strict;

require 't/test.pl';
find_git_or_skip('all');

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";
system("git log --pretty=fuller | ${dotslash}perl Porting/checkAUTHORS.pl --tap -");

# EOF
