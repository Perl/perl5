# This is a replacement for the old BEGIN preamble which heads (or
# should head) up every core test program to prep it for running.  
# Now instead of:
#
# BEGIN {
#   chdir 't' if -d 't';
#   @INC = '../lib';
# }
#
# t/TEST will use -MTestInit.  It also doesn't hurt if you "use TestInit"
# (not require) in the test scripts.
#
# PS this is not POD because this should be a very minimalist module in
# case of funaemental perl breakage.

chdir 't' if -d 't';
@INC = '../lib';
$0 =~ s/\.dp$//; # for the test.deparse make target
1;

