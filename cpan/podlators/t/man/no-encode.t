#!/usr/bin/perl
#
# Test for graceful degradation to non-utf8 output without Encode module.
#
# Copyright 2016 Niko Tyni <ntyni@iki.fi>
# Copyright 2016, 2018-2019 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.006;
use strict;
use warnings;

use Test::More;

# Force the Encode module to be impossible to import.  Sometimes Encode is
# already loaded before the test suite runs (this seems common for CPAN
# Testers tests for some reason), so skip the test if that's the case.
BEGIN {
    if ($INC{'Encode.pm'}) {
        plan skip_all => 'Encode is already loaded';
    } else {
        plan tests => 5;
    }
    my $reject_encode = sub {
        if ($_[1] eq 'Encode.pm') {
            die "refusing to load Encode\n";
        }
    };
    unshift(@INC, $reject_encode);
    ok(!eval { require Encode }, 'Cannot load Encode any more');
}

# Load the module.
BEGIN {
    use_ok('Pod::Man');
}

# Ensure we don't get warnings by throwing an exception if we see any.  This
# is overridden below when we enable utf8 and do expect a warning.
local $SIG{__WARN__} = sub { die "No warnings expected\n" };

# First, check that everything works properly when utf8 isn't set.  We expect
# to get accent-mangled ASCII output.  Don't use Test::Podlators, since it
# wants to import Encode.
#
## no critic (ValuesAndExpressions::ProhibitEscapedCharacters)
my $pod = "=encoding latin1\n\n=head1 NAME\n\nBeyonc\xE9!";
my $parser = Pod::Man->new(utf8 => 0, name => 'test');
my $output;
$parser->output_string(\$output);
$parser->parse_string_document($pod);
like(
    $output,
    qr{ Beyonce\\[*]\' }xms,
    'Works without Encode for non-utf8 output'
);

# Now, try with the utf8 option set.  We should then get a warning that we're
# falling back to non-utf8 output.
{
    local $SIG{__WARN__} = sub {
        like(
            $_[0],
            qr{ falling [ ] back [ ] to [ ] non-utf8 }xms,
            'Pod::Man warns on utf8 option with no Encode module'
        );
    };
    $parser = Pod::Man->new(utf8 => 1, name => 'test');
}
my $output_fallback;
$parser->output_string(\$output_fallback);
$parser->parse_string_document($pod);
is($output_fallback, $output, 'Degraded gracefully to non-utf8 output');
