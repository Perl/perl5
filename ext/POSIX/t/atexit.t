use strict;
use warnings;

use Test::More tests => 11;
use POSIX qw(atexit);

package CodeRefObject;

use overload '&{}' => sub { sub {} };

package main;

note "Exactly one argument is required and the type must be either a coderef, or an object that can be used as a coderef.";

eval {
    atexit();
    1;
} or do {
    pass "wrong number of arguments";
};

eval {
    atexit(sub {}, sub {});
    1;
} or do {
    pass "wrong number of arguments";
};

eval {
    atexit(bless {});
    1;
} or do {
    pass "non-coderef should result in errors"
};

eval {
    atexit("str");
    1;
} or do {
    pass "non-coderef should result in errors";
};

ok(
    eval {
        atexit(sub {});
        1;
    },
    "plain coderefs are acceptable"
);

ok(
    eval {
        atexit(bless {}, 'CodeRefObject');
        1;
    },
    "objects that can be de-ref as subs are acceptable"
);

ok(
    eval {
        atexit(bless sub {});
        1;
    },
    "objects that are blessed coderefs are acceptable"
);

note "The following code test the order of execution, which should be the reverse of insertion order.";
pipe my $fr, my $fw;

my $child_pid = fork();
if ($child_pid) {
    close $fw;
    my $pid = wait();
    is $pid, $child_pid;

    my $out1 = <$fr>;
    is $out1, "child ${pid} exit (3)\n";

    my $out2 = <$fr>;
    is $out2, "child ${pid} exit (2)\n";

    my $out3 = <$fr>;
    is $out3, "child ${pid} exit (1)\n";
} else {
    close $fr;

    atexit(sub { print $fw "child $$ exit (1)\n" });
    atexit(sub { print $fw "child $$ exit (2)\n" });
    atexit(sub { print $fw "child $$ exit (3)\n" });
    exit(0);
}
