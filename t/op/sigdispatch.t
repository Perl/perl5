#!perl -w

# We assume that TestInit has been used.

BEGIN {
      require './test.pl';
}

use strict;

plan tests => 4;

watchdog(10);

$SIG{ALRM} = sub {
    die "Alarm!\n";
};

pass('before the first loop');

alarm 2;

eval {
    1 while 1;
};

is($@, "Alarm!\n", 'after the first loop');

pass('before the second loop');

alarm 2;

eval {
    while (1) {
    }
};

is($@, "Alarm!\n", 'after the second loop');
