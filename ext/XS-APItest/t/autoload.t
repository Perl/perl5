#!perl

use strict;
use warnings;

use Test::More tests => 3;

use XS::APItest;

is XS::APItest::AutoLoader::frob(), 'frob', 'name passed to XS AUTOLOAD';
is "XS::APItest::AutoLoader::fr\0b"->(), "fr\0b",
  'name with embedded null passed to XS AUTOLOAD';
is "XS::APItest::AutoLoader::fr\x{1ed9}b"->(), "fr\x{1ed9}b",
  'Unicode name passed to XS AUTOLOAD';
