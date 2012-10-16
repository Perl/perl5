#!./perl -w

use strict;

BEGIN {
    chdir 't';
    require './test.pl';
}

plan(tests => 20);

sub r {
    return qr/Good/;
}

my $a = r();
object_ok($a, 'Regexp');
my $b = r();
object_ok($b, 'Regexp');

my $b1 = $b;

isnt($a + 0, $b + 0, 'Not the same object');

bless $b, 'Pie';

object_ok($b, 'Pie');
object_ok($a, 'Regexp');
object_ok($b1, 'Pie');

my $c = r();
like("$c", qr/Good/);
my $d = r();
like("$d", qr/Good/);

my $d1 = $d;

isnt($c + 0, $d + 0, 'Not the same object');

$$d = 'Bad';

like("$c", qr/Good/);
is($$d, 'Bad');
is($$d1, 'Bad');

# Assignment to an implicitly blessed Regexp object retains the class
# (No different from direct value assignment to any other blessed SV

object_ok($d, 'Regexp');
like("$d", qr/\ARegexp=SCALAR\(0x[0-9a-f]+\)\z/);

# As does an explicitly blessed Regexp object.

my $e = bless qr/Faux Pie/, 'Stew';

object_ok($e, 'Stew');
$$e = 'Fake!';

is($$e, 'Fake!');
object_ok($e, 'Stew');
like("$e", qr/\Stew=SCALAR\(0x[0-9a-f]+\)\z/);

# [perl #96230] qr// should not have the reuse-last-pattern magic
"foo" =~ /foo/;
like "bar",qr//,'[perl #96230] =~ qr// does not reuse last successful pat';
"foo" =~ /foo/;
$_ = "bar";
$_ =~ s/${qr||}/baz/;
is $_, "bazbar", '[perl #96230] s/$qr// does not reuse last pat';
