#!/usr/bin/perl -w

# A test to make sure the new Test::Harness was installed properly.

use Test::More;
plan tests => 1;

require Test::Harness;
unless( cmp_ok( $Test::Harness::VERSION, '>', 1.20, "T::H version" ) ) {
    diag <<INSTRUCTIONS;

Test::Simple/More/Builder has features which depend on a version of
Test::Harness greater than 1.20.  You have $Test::Harness::VERSION.
Please install a new version from CPAN.

If you've already tried to upgrade Test::Harness and still get this
message, the new version may be "shadowed" by the old.  Check the
output of Test::Harness's "make install" for "## Differing version"
messages.  You can delete the old version by running 
"make install UNINST=1".

INSTRUCTIONS
}

