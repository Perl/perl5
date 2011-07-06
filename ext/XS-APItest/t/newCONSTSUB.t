#!perl

use strict;
use warnings;
use utf8;
use open qw( :utf8 :std );
use Test::More "no_plan";

use XS::APItest;

my ($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "sanity_check", 0, 0);

ok $const;
ok *{$glob}{CODE};

($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "\x{30cb}", 0, 0);
ok $const, "newCONSTSUB generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok !$::{"\x{30cb}"}, "...but not the right one";

($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "\x{30cd}", 0, 1);
ok $const, "newCONSTSUB_flags generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok $::{"\x{30cd}"}, "...the right one!";
