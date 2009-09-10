#!perl -w

=head1 DESCRIPTION

This test tests against a regular expression bug
that leads to a segfault

The bug was reported in [perl #69056] by Niko Tyni

=cut

use strict;
require 't/test.pl';

fresh_perl_is(
    '$_=q(foo);s/(.)\G//g;print'
        => 'foo',
    '[perl #69056] positive GPOS regex segfault'
);
