#!./perl -w

# Original by slaven@rezic.de, modified by jhi and matt.w.johnson@gmail.com
#
# Adapted from Porting/cmpVERSION.pl by Abigail
# Changes folded back into that by Nicholas

use strict;

chdir '..' unless -d 't';

if (! -d '.git' ) {
    print "1..0 # SKIP: not being run from a git checkout\n";
    exit 0;
}

my $dotslash = $^O eq "MSWin32" ? ".\\" : "./";

system "${dotslash}perl -Ilib Porting/cmpVERSION.pl --exclude --tap";
