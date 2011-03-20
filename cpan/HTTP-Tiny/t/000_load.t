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

use Test::More 0.88 tests => 1;

require_ok('HTTP::Tiny');

local $HTTP::Tiny::VERSION = $HTTP::Tiny::VERSION || 'from repo';
note("HTTP::Tiny $HTTP::Tiny::VERSION, Perl $], $^X");

