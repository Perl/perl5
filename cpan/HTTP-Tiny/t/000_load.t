#!perl
#
# This file is part of HTTP-Tiny
#
# This software is copyright (c) 2011 by Christian Hansen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('HTTP::Tiny');
}

diag("HTTP::Tiny $HTTP::Tiny::VERSION, Perl $], $^X");

