use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Event::Note';

can_ok('Test::Builder::Event::Note', qw/message/);

my $one = Test::Builder::Event::Note->new(message => "\nFooo\nBar\nBaz\n");

isa_ok($one, 'Test::Builder::Event::Note');
isa_ok($one, 'Test::Builder::Event');

is($one->to_tap, "\n# Fooo\n# Bar\n# Baz\n", "Got tap output");

done_testing;
