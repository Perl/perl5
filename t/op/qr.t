#!./perl -w

use strict;

require './test.pl';

plan(tests => 12);

sub r {
    return qr/Good/;
}

my $a = r();
isa_ok($a, 'Regexp');
my $b = r();
isa_ok($b, 'Regexp');

my $b1 = $b;

isnt($a + 0, $b + 0, 'Not the same object');

bless $b, 'Pie';

isa_ok($b, 'Pie');
isa_ok($a, 'Regexp');
isa_ok($b1, 'Pie');

my $c = r();
like("$c", qr/Good/);
my $d = r();
like("$d", qr/Good/);

my $d1 = $d;

isnt($c + 0, $d + 0, 'Not the same object');

$$d = 'Bad';

like("$c", qr/Good/);
like("$d", qr/Bad/);
like("$d1", qr/Bad/);
