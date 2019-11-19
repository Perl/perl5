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

my $revision_range = ''; # could use 'v5.22.0..' as default, no reason to recheck all previous commits...
if ( $ENV{TRAVIS} && defined $ENV{TRAVIS_COMMIT_RANGE} ) {
	# travisci is adding a merge commit when smoking a pull request
	#	unfortunately it's going to use the default GitHub email from the author
	#	which can differ from the one the author wants to use as part of the pull request
	#	let's simply use the TRAVIS_COMMIT_RANGE which list the commits we want to check
	#	all the more a pull request should not be impacted by blead being incorrect
	$revision_range = $ENV{TRAVIS_COMMIT_RANGE};
}
elsif( $ENV{GITHUB_ACTIONS} && defined $ENV{GITHUB_HEAD_REF} ) {
    # Same as above, except for Github Actions
    # https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-environment-variables
    system(qw( git switch -c  ), $ENV{GITHUB_HEAD_REF});
    system(qw( git checkout ), $ENV{GITHUB_HEAD_REF});

    # This hardcoded origin/ isn't great, but I'm not sure how to better fix it
    my $common_ancestor = `git merge-base origin/$ENV{GITHUB_BASE_REF} $ENV{GITHUB_HEAD_REF}`
    $common_ancestor =~ s!\s+!!g;

    # We want one before the GITHUB_SHA, as the github-SHA is a merge commit
	$revision_range = join '..', $common_ancestor, 'HEAD^1';
}

# This is the subset of "pretty=fuller" that checkAUTHORS.pl actually needs:
print qx{git log --pretty=format:"Author: %an <%ae>" $revision_range | $^X Porting/checkAUTHORS.pl --tap -};

# EOF
