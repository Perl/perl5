#!/usr/bin/perl
#
# Test the "none" encoding option of Pod::Text.
#
# This only makes sense in combination with output_string to produce output
# that's still in Perl's internal encoding.
#
# Copyright 2025 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.012;
use utf8;
use warnings;

use Encode qw(encode);
use Test::More tests => 4;

BEGIN {
    use_ok('Pod::Text');
}

# Set up Pod::Text to output to a string.
my $parser = Pod::Text->new(encoding => 'none');
isa_ok($parser, 'Pod::Text');
my $output;
$parser->output_string(\$output);

# Parse a document containing UTF-8.
my $input = "=encoding utf-8\n\nrésumé\n";
my $result = eval { $parser->parse_string_document($input) };
ok($result, 'Parsed document');
is($output, "    résumé\n\n", 'Produced correct output');
