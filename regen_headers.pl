#!/usr/bin/perl -w
require 5.003;	# keep this compatible, an old perl is all we may have before
                # we build the new one

# The idea is to move the regen_headers target out of the Makefile so that
# it is possible to rebuild the headers before the Makefile is available.
# (and the Makefile is unavailable until after Configure is run, and we may
# wish to make a clean source tree but with current headers without running
# anything else.

use strict;
my $perl = $^X;

require 'regen.pl';
# keep warnings.pl in sync with the CPAN distribution by not requiring core
# changes
safer_unlink ("warnings.h", "lib/warnings.pm");

foreach (qw (keywords.pl opcode.pl embed.pl bytecode.pl regcomp.pl
	     warnings.pl autodoc.pl)) {
  print "$^X $_\n";
  system "$^X $_";
}
