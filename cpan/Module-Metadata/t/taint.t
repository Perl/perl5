#!/usr/bin/perl -T
use strict;
use warnings;

use 5.008000;   # for ${^TAINT}
use Module::Metadata;
use Test::More;
use Test::Fatal;

ok(${^TAINT}, 'taint flag is set');

# without the fix, we get:
# Insecure dependency in eval while running with -T switch at lib/Module/Metadata.pm line 668, <GEN0> line 15.
is(
    exception { Module::Metadata->new_from_module( "Module::Metadata" )->version },
    undef,
    'no exception',
);

done_testing;
