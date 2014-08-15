use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Result::Note';

can_ok('Test::Builder::Result::Note', qw/message/);

my $one = Test::Builder::Result::Note->new(message => "\nFooo\nBar\nBaz\n");

isa_ok($one, 'Test::Builder::Result::Note');
isa_ok($one, 'Test::Builder::Result');

is($one->to_tap, "\n# Fooo\n# Bar\n# Baz\n", "Got tap output");

done_testing;
