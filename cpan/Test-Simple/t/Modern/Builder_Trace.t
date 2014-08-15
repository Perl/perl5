#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'modern';

my $CLASS = 'Test::Builder::Trace';
require_ok $CLASS;

my $one = bless {}, $CLASS;

is_deeply($one->$_, [], "Default stack $_") for qw/anointed full level tools transitions stack/;

# See t/Modern/tracing.t for most of the tests

done_testing;
