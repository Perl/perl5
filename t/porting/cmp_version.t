#!./perl -w

# Original by slaven@rezic.de, modified by jhi and matt.w.johnson@gmail.com
#
# Adapted from Porting/cmpVERSION.pl by Abigail
# Changes folded back into that by Nicholas

BEGIN {
    @INC = '..' if -f '../TestInit.pm';
}
use TestInit 'T'; # T is chdir to the top level
use strict;

require 't/test.pl';
find_git_or_skip('all');

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";

system "${dotslash}perl Porting/cmpVERSION.pl --exclude --tap";
