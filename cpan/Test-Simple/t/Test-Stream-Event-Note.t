use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::Event::Note';

my $note = Test::Stream::Event::Note->new('fake', 'fake', 0, "hello");

is($note->message, 'hello', "got message");

is_deeply(
    [$note->to_tap],
    [[Test::Stream::Event::Note::OUT_STD, "# hello\n"]],
    "Got handle id and message in tap",
);

done_testing;
