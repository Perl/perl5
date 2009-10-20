#!perl -w
use strict;
use Module::CoreList;
use Test::More tests => 3;

is(Module::CoreList->is_deprecated('Switch',5.011),'5.011','Switch is deprecated');
is(Module::CoreList->is_deprecated('Switch',5.011000),'5.011','Switch is deprecated using $]');
is(Module::CoreList->is_deprecated('Switch',5.010),'','Switch is not deprecated');
