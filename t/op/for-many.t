#!./perl

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc('../lib');
}

use strict;
use warnings;

my @have;

{
    my @warnings;
    BEGIN { $SIG{__WARN__} = sub { push @warnings, shift; }; }

    # This should not warn
    for my $q ('A', 'B', 'C', 'D') {
        push @have, "$q";
    }
    is ("@have", 'A B C D', 'no list');

    @have = ();
    # This should warn
    my $warn0 = __LINE__ + 1;
    for my ($q) ('A', 'B', 'C', 'D') {
        push @have, "$q";
    }
    is ("@have", 'A B C D', 'list of 1');

    @have = ();

    # Simplest case is an explicit list:
    my $warn1 = __LINE__ + 1;
    for my ($q, $r) ('A', 'B', 'C', 'D') {
        push @have, "$q;$r";
    }
    is ("@have", 'A;B C;D', 'list of 2');

    is(scalar @warnings, 2, "2 warnings");
    is($warnings[0], "for my (...) is experimental at $0 line $warn0.\n",
       'for my ($q) warned');
    is($warnings[1], "for my (...) is experimental at $0 line $warn1.\n",
       'for my ($q, $r) warned');
    BEGIN { undef $SIG{__WARN__}; }
}

no warnings 'experimental::for_list';

@have = ();

# Simplest case is an explicit list:
for my ($q, $r) ('A', 'B', 'C', 'D') {
    push @have, "$q;$r";
}
is("@have", 'A;B C;D', 'explicit list');

@have = ();

for my ($q, $r) (reverse 'A', 'B', 'C', 'D') {
    push @have, "$q;$r";
}
is("@have", 'D;C B;A', 'explicit list reversed');

@have = ();

for my ($q, $r) ('A', 'B', 'C', 'D', 'E', 'F') {
    push @have, "$q;$r";
}
is("@have", 'A;B C;D E;F', 'explicit list three iterations');

@have = ();

for my ($q, $r, $s) ('A', 'B', 'C', 'D', 'E', 'F') {
    push @have, "$q;$r;$s";
}
is("@have", 'A;B;C D;E;F', 'explicit list triplets');

@have = ();

for my ($q, $r, $s,) ('A', 'B', 'C', 'D', 'E', 'F') {
    push @have, "$q;$r;$s";
}
is("@have", 'A;B;C D;E;F', 'trailing comma n-fold');

@have = ();

for my ($q, $r, $s) ('A', 'B', 'C', 'D', 'E') {
    push @have, join ';', map { $_ // 'undef' } $q, $r, $s;
}

is("@have", 'A;B;C D;E;undef', 'incomplete explicit list');

@have = ();

for my ($q, $r, $s) (reverse 'A', 'B', 'C', 'D', 'E') {
    push @have, join ';', map { $_ // 'undef' } $q, $r, $s;
}

is("@have", 'E;D;C B;A;undef', 'incomplete explicit list reversed');

# This two are legal syntax and actually indistinguishable from for my $q () ...
@have = ();

for my ($q,) ('A', 'B', 'C', 'D', 'E', 'F') {
    push @have, $q;
}
is("@have", 'A B C D E F', 'trailing comma one-at-a-time');

@have = ();

for my ($q) ('A', 'B', 'C', 'D', 'E', 'F') {
    push @have, $q;
}
is("@have", 'A B C D E F', 'one-at-a-time');


# Arrays have an optimised case in pp_iter:
{
    no strict;

    @array = split ' ', 'Dogs have owners, cats have staff.';

    my $count = scalar @array;

    @have = ();

    for my ($q, $r, $s) (@array) {
        push @have, "$q;$r;$s";
    }
    is("@have", 'Dogs;have;owners, cats;have;staff.', 'package array');
    is(scalar @array, $count, 'package array size unchanged');

    @have = ();

    for my ($q, $r, $s) (reverse @array) {
        push @have, "$q;$r;$s";
    }
    is("@have", 'staff.;have;cats owners,;have;Dogs', 'package array reversed');
    is(scalar @array, $count, 'package array reversed size unchanged');

    @have = ();

    for my ($q, $r, $s, $t) (@array) {
        push @have, join ';', map { $_ // '!' } $q, $r, $s, $t;
    }
    is("@have", 'Dogs;have;owners,;cats have;staff.;!;!', 'incomplete package array');

    @have = ();

    for my ($q, $r, $s, $t) (reverse @array) {
        push @have, join ';', map { $_ // '!' } $q, $r, $s, $t;
    }
    is("@have", 'staff.;have;cats;owners, have;Dogs;!;!', 'incomplete package array reversed');
    is(scalar @array, $count, 'incomplete package array size unchanged');

    # And for our last test, we trash @array
    for my ($q, $r) (@array) {
        ($q, $r) = ($r, $q);
    }
    is("@array", 'have Dogs cats owners, staff. have', 'package array aliased');
    is(scalar @array, $count, 'incomplete package array reversed size unchanged');
}

my @array = split ' ', 'God is real, unless declared integer.';

my $count = scalar @array;

@have = ();

for my ($q, $r, $s) (@array) {
    push @have, "$q;$r;$s";
}
is("@have", 'God;is;real, unless;declared;integer.', 'lexical array');
is(scalar @array, $count, 'lexical array size unchanged');

@have = ();

for my ($q, $r, $s) (reverse @array) {
    push @have, "$q;$r;$s";
}
is("@have", 'integer.;declared;unless real,;is;God', 'lexical array reversed');
is(scalar @array, $count, 'lexical array reversed size unchanged');

@have = ();

for my ($q, $r, $s, $t) (@array) {
    push @have, join ';', map { $_ // '!' } $q, $r, $s, $t;
}
is("@have", 'God;is;real,;unless declared;integer.;!;!', 'incomplete lexical array');
is(scalar @array, $count, 'incomplete lexical array size unchanged');

@have = ();

for my ($q, $r, $s, $t) (reverse @array) {
    push @have, join ';', map { $_ // '!' } $q, $r, $s, $t;
}
is("@have", 'integer.;declared;unless;real, is;God;!;!', 'incomplete lexical array reversed');
is(scalar @array, $count, 'incomplete lexical array reversed size unchanged');

for my ($q, $r) (@array) {
    $q = uc $q;
    $r = ucfirst $r;
}
is("@array", 'GOD Is REAL, Unless DECLARED Integer.', 'lexical array aliased');

# Integer ranges have an optimised case in pp_iter:
@have = ();

for my ($q, $r, $s) (0..5) {
    push @have, "$q;$r;$s";
}

is("@have", '0;1;2 3;4;5', 'integer list');

@have = ();

for my ($q, $r, $s) (reverse 0..5) {
    push @have, "$q;$r;$s";
}

is("@have", '5;4;3 2;1;0', 'integer list reversed');

@have = ();

for my ($q, $r, $s) (1..5) {
    push @have, join ';', map { $_ // 'undef' } $q, $r, $s;
}

is("@have", '1;2;3 4;5;undef', 'incomplete integer list');

@have = ();

for my ($q, $r, $s) (reverse 1..5) {
    push @have, join ';', map { $_ // 'Thunderbirds are go' } $q, $r, $s;
}

is("@have", '5;4;3 2;1;Thunderbirds are go', 'incomplete integer list reversed');

# String ranges have an optimised case in pp_iter:
@have = ();

for my ($q, $r, $s) ('A'..'F') {
    push @have, "$q;$r;$s";
}

is("@have", 'A;B;C D;E;F', 'string list');

@have = ();

for my ($q, $r, $s) (reverse 'A'..'F') {
    push @have, "$q;$r;$s";
}

is("@have", 'F;E;D C;B;A', 'string list reversed');

@have = ();

for my ($q, $r, $s) ('B'..'F') {
    push @have, join ';', map { $_ // 'undef' } $q, $r, $s;
}

is("@have", 'B;C;D E;F;undef', 'incomplete string list');

@have = ();

for my ($q, $r, $s) (reverse 'B'..'F') {
    push @have, join ';', map { $_ // 'undef' } $q, $r, $s;
}

is("@have", 'F;E;D C;B;undef', 'incomplete string list reversed');

# Hashes are expanded as regular lists, so there's nothing particularly
# special here:
{
    no strict;

    %hash = (
        perl => 'rules',
        beer => 'foamy',
    );

    @have = ();

    for my ($key, $value) (%hash) {
        push @have, "$key;$value";
    }

    my $got = "@have";
    if ($got =~ /^perl/) {
        is($got, 'perl;rules beer;foamy', 'package hash key/value iteration');
    }
    else {
        is($got, 'beer;foamy perl;rules', 'package hash key/value iteration');
    }

    @have = ();

    for my ($value, $key) (reverse %hash) {
        push @have, "$key;$value";
    }

    $got = "@have";
    if ($got =~ /^perl/) {
        is($got, 'perl;rules beer;foamy', 'package hash key/value reverse iteration');
    }
    else {
        is($got, 'beer;foamy perl;rules', 'package hash key/value reverse iteration');
    }

    # values are aliases. As ever. Keys are copies.

    for my ($key, $value) (%hash) {
        $key = ucfirst $key;
        $value = uc $value;
    }

    $got = join ';', %hash;

    if ($got =~ /^perl/i) {
        is($got, 'perl;RULES;beer;FOAMY', 'package hash value iteration aliases');
    }
    else {
        is($got, 'beer;FOAMY;perl;RULES', 'package hash value iteration aliases');
    }
}

my %hash = (
    beer => 'street',
    gin => 'lane',
);


@have = ();

for my ($key, $value) (%hash) {
    push @have, "$key;$value";
}

my $got = "@have";
if ($got =~ /^gin/) {
    is($got, 'gin;lane beer;street', 'lexical hash key/value iteration');
}
else {
    is($got, 'beer;street gin;lane', 'lexical hash key/value iteration');
}

@have = ();

for my ($value, $key) (reverse %hash) {
    push @have, "$key;$value";
}

$got = "@have";
if ($got =~ /^gin/) {
    is($got, 'gin;lane beer;street', 'lexical hash key/value reverse iteration');
}
else {
    is($got, 'beer;street gin;lane', 'lexical hash key/value reverse iteration');
}

# values are aliases, keys are copies, so this is a daft thing to do:

for my ($key, $value) (%hash) {
    ($key, $value) = ($value, $key);
}

$got = join ';', %hash;

if ($got =~ /^gin/i) {
    is($got, 'gin;gin;beer;beer', 'lexical hash value iteration aliases');
}
else {
    is($got, 'beer;beer;gin;gin', 'lexical hash value iteration aliases');
}

my $code = 'for my ($q, $r) (6, 9) {}; 42';

$got = eval $code;

is($@, "", 'test code generated no error');
is($got, 42, 'test code ran');

$code =~ s/my/our/;

like($code, qr/for our \(/, 'for our code set up correctly');
$got = eval $code;

like($@, qr/^Missing \$ on loop variable /, 'for our code generated error');
is($got, undef, 'for our did not run');

$code =~ s/ our//;

like($code, qr/for \(/, 'for () () code set up correctly');
$got = eval "no strict 'vars'; $code";

like($@, qr/^syntax error /, 'for () () code generated error');
is($got, undef, 'for () () did not run');

done_testing();
