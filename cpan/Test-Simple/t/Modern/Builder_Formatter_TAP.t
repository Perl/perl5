use strict;
use warnings;

use Test::More;

require_ok 'Test::Builder::Formatter::TAP';

isa_ok('Test::Builder::Formatter::TAP', 'Test::Builder::Formatter');

can_ok(
    'Test::Builder::Formatter::TAP',
    qw{
        no_header no_diag depth use_numbers
        output failure_output todo_output
        bail nest child finish plan ok diag note
        reset_outputs is_fh reset
    }
);

done_testing;
