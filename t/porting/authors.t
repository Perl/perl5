#!./perl -w
# Test that there are no missing authors in AUTHORS

BEGIN {
    @INC = '..' if -f '../TestInit.pm';
}
use TestInit qw(T A); # T is chdir to the top level, A makes paths absolute
use strict;

require 't/test.pl';
find_git_or_skip('all');

# This is the subset of "pretty=fuller" that checkAUTHORS.pl actually needs:
system("git log --pretty=format:'commit %H%nAuthor: %an <%ae>%nAuthor Date:%nCommit: %cn <%cn>%n' | $^X Porting/checkAUTHORS.pl --tap -");

# EOF
