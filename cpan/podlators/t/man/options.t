#!/usr/bin/perl
#
# Test Pod::Man behavior with various options
#
# Copyright 2002, 2004, 2006, 2008, 2009, 2012, 2013, 2015, 2016
#     Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 31;
use Test::Podlators qw(test_snippet);

# Load the module.
BEGIN {
    use_ok('Pod::Man');
}

# List of snippets run by this test.
my @snippets = qw(
  bullet-after-nonbullet error-die error-none error-normal
  error-pod error-stderr error-stderr-opt fixed-font long-quote
  lquote-and-quote lquote-rquote nourls rquote-none
);

# Run all the tests.
for my $snippet (@snippets) {
    test_snippet('Pod::Man', "man/$snippet");
}
