# This is a replacement for the old BEGIN preamble which heads (or
# should head) up every core test program to prepare it for running.
# Now instead of:
#
# BEGIN {
#   chdir 't' if -d 't';
#   @INC = '../lib';
# }
#
# Its primary purpose is to clear @INC so core tests don't pick up
# modules from an installed Perl.
#
# t/TEST will use -MTestInit.  You may "use TestInit" in the test
# programs but it is not required.
#
# P.S. This documentation is not in POD format in order to avoid
# problems when there are fundamental bugs in perl.

package TestInit;

$VERSION = 1.01;

chdir 't' if -d 't';
@INC = '../lib';

# Don't interfere with the taintedness of %ENV, this could perturbate tests.
# This feels like a better solution than the original, from
# http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2003-07/msg00154.html
$ENV{PERL_CORE} = $^X;

$0 =~ s/\.dp$//; # for the test.deparse make target
1;

