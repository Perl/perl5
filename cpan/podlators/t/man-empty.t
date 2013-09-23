#!/usr/bin/perl -w
#
# man-empty.t -- Test Pod::Man with a document that produces only errors.
#
# Copyright 2013 Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    chdir 't' if -d 't';
    if ($ENV{PERL_CORE}) {
        @INC = '../lib';
    }
    unshift (@INC, '../blib/lib');
    $| = 1;
}

use strict;

use Test::More tests => 8;
BEGIN { use_ok ('Pod::Man') }

# Set up Pod::Man to output to a string.
my $parser = Pod::Man->new;
isa_ok ($parser, 'Pod::Man');
my $output;
$parser->output_string (\$output);

# Try a POD document where the only command is invalid.
ok (eval { $parser->parse_string_document("=\xa0") },
    'Parsed invalid document');
is ($@, '', '...with no errors');
like ($output, qr{\.SH \"POD ERRORS\"},
      '...and output contains a POD ERRORS section');

# Try with a document containing only =cut.
ok (eval { $parser->parse_string_document("=cut") },
    'Parsed invalid document');
is ($@, '', '...with no errors');
like ($output, qr{\.SH \"POD ERRORS\"},
      '...and output contains a POD ERRORS section');
