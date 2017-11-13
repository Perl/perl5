#!./perl -w
# Test that there are no missing authors in AUTHORS

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc('../lib', '..');
}

use TestInit qw(T);    # T is chdir to the top level
use strict;

find_git_or_skip('all');
skip_all(
    "This distro may have modified some files in cpan/. Skipping validation.")
  if $ENV{'PERL_BUILD_PACKAGING'};

# This is the subset of "pretty=fuller" that checkAUTHORS.pl actually needs:
print qx{git log --pretty=format:"Author: %an <%ae>" | $^X Porting/checkAUTHORS.pl --tap -};

# EOF
