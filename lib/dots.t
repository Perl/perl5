#!./perl

# This tests syntax under variations of "use dots".

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

use strict;
use warnings;

use Test::More tests => 9;

my $a = ['foo', 'bar'];
my $h = { corge => 1, grault => 2 };
my $c = sub { '"Bob"' };

eval q{
     use strict;
     use dots;
     ok($a.[0] eq 'foo');
     ok($h.{corge} == 1);
     ok($c.() eq '"Bob"');
};
diag($@) if $@;
ok(!$@, "dots");

eval q{
     use strict;
     use dots;
     is('Praise ' ~ '"Bob"!', 'Praise "Bob"!', "~ concat");
};
diag($@) if $@;
ok(!$@, "dots");

eval q{
     use strict;
     use dots 'mixed';
     my $x = [ sub { "hi" } ];
     is($x.[0]->(), 'hi', "mixed expression");
};
diag($@) if $@;
ok(!$@, "use dots 'mixed'");

eval q{ use dots; [0]->[0] };
ok($@, "mixed is off by default");
