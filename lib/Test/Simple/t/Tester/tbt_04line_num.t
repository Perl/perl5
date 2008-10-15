#!/usr/bin/perl
# $Id: /mirror/googlecode/test-more/t/Tester/tbt_04line_num.t 60331 2008-09-09T12:17:12.607612Z schwern  $

use Test::More tests => 3;
use Test::Builder::Tester;

is(line_num(),7,"normal line num");
is(line_num(-1),7,"line number minus one");
is(line_num(+2),11,"line number plus two");
