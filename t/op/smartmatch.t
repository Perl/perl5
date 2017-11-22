#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
use strict;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

my @notov = (
    undef,
    0,
    1,
    "",
    "abc",
    *foo,
    ${qr/./},
    \undef,
    \0,
    \1,
    \"",
    \"abc",
    \*foo,
    [],
    {},
    sub { 1 },
    \*STDIN,
    bless({}, "NotOverloaded"),
);

package MatchAbc { use overload "~~" => sub { $_[1] eq "abc" }, fallback => 1; }
my $matchabc = bless({}, "MatchAbc");
my $regexpabc = qr/\Aabc\z/;

plan tests => (2+@notov)*@notov + 4*(2+@notov) + 7;

foreach my $matcher (@notov) {
    foreach my $matchee ($matchabc, $regexpabc, @notov) {
	my $res = eval { $matchee ~~ $matcher };
	like $@, qr/\ACannot smart match without a matcher object /;
    }
}
foreach my $matchee ($matchabc, $regexpabc, @notov) {
    my $res = eval { $matchee ~~ $matchabc };
    is $@, "";
    is $res, $matchee eq "abc";
    $res = eval { $matchee ~~ $regexpabc };
    is $@, "";
    is $res, $matchee eq "abc";
}

ok "abc" ~~ qr/\Aabc/;
ok "abcd" ~~ qr/\Aabc/;
ok !("xabc" ~~ qr/\Aabc/);

package MatchRef { use overload "~~" => sub { ref($_[1]) }; }
my $matchref = bless({}, "MatchRef");
package MatchThree { use overload "~~" => sub { !ref($_[1]) && $_[1] == 3 }; }
my $matchthree = bless({}, "MatchThree");

my @a = qw(x y z);
ok @a ~~ $matchthree;
ok !(@a ~~ $matchref);
my %h = qw(a b c d);
ok !(%h ~~ $matchref);
my $res = eval { "abc" ~~ %$matchabc };
like $@, qr/\ACannot smart match without a matcher object /;

1;
