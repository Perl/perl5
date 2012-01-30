#!perl

use Test::More;

eval "use AnyEvent; 1" or
    plan skip_all => "AnyEvent is not installed.";

# seeing as the entire point of this test is to test the event handler,
# we need to mock as little as possible.  To keep things tightly controlled,
# we'll use the Stub directly.
BEGIN {
    $ENV{PERL_RL} = 'Stub o=0';
}
plan tests => 3;

# need to delay this so that AE is loaded first.
require Term::ReadLine;
use File::Spec;

my $t = Term::ReadLine->new('AE');
ok($t, "Created object");
is($t->ReadLine, 'Term::ReadLine::Stub', 'Correct type');
$t->tkRunning(1);

my $text = 'some text';
my $T = $text . "\n";
my $w = AE::timer(0,1,sub { 
pass("Event loop called");
exit 0;
});

my $result = $t->readline('Do not press enter>');
fail("Should not get here.");
