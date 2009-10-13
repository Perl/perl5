#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = ('.', '../lib');
}

require 'test.pl';

plan (11);

my $blank = "";
eval {select undef, $blank, $blank, 0};
is ($@, "");
eval {select $blank, undef, $blank, 0};
is ($@, "");
eval {select $blank, $blank, undef, 0};
is ($@, "");

eval {select "", $blank, $blank, 0};
is ($@, "");
eval {select $blank, "", $blank, 0};
is ($@, "");
eval {select $blank, $blank, "", 0};
is ($@, "");

eval {select "a", $blank, $blank, 0};
like ($@, qr/^Modification of a read-only value attempted/);
eval {select $blank, "a", $blank, 0};
like ($@, qr/^Modification of a read-only value attempted/);
eval {select $blank, $blank, "a", 0};
like ($@, qr/^Modification of a read-only value attempted/);

my $sleep = 3;
my $t = time;
select(undef, undef, undef, $sleep);
ok(time-$t >= $sleep, "$sleep seconds have passed");

my $empty = "";
vec($empty,0,1) = 0;
$t = time;
select($empty, undef, undef, $sleep);
ok(time-$t >= $sleep, "$sleep seconds have passed");
