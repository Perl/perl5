use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

my $TEST = 1;

sub is {
    my ($got, $exp, $name) = @_;

    my $ok = ($got eq $exp);

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $TEST - $name\n");
    } else {
        print("not ok $TEST - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
        print("#   Got:      $got\n");
        print("#   Expected: $exp\n");
    }

    $TEST++;

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..12\n");   ### Number of tests that will be run ###
};

use threads;
use threads::shared;

### Start of Testing ###

binmode STDOUT, ":utf8";

my $plain = 'foo';
my $utf8 = "\x{123}\x{84}\x{20F}\x{2C1}";

my %a :shared;
$a{$plain} = $plain;
$a{$utf8} = $utf8;
$a{\&is} = 'code';

is(exists($a{$plain}), 1, 'Found plain key in shared hash');
is(exists($a{$utf8}), 1, 'Found UTF-8 key in shared hash');
is(exists($a{\&is}), 1, 'Found code ref key in shared hash');

while (my ($key, $value) = each (%a)) {
    if ($key eq $plain) {
        is($key, $plain, 'Plain key in shared hash');
    } elsif ($key eq $utf8) {
        is($key, $utf8, 'UTF-8 key in shared hash');
    } else {
        is($key, \&is, 'Code ref key in shared hash');
    }
}

my $a = &share({});
$$a{$plain} = $plain;
$$a{$utf8} = $utf8;
$$a{\&is} = 'code';

is(exists($$a{$plain}), 1, 'Found plain key in shared hash ref');
is(exists($$a{$utf8}), 1, 'Found UTF-8 key in shared hash ref');
is(exists($$a{\&is}), 1, 'Found code ref key in shared hash ref');

while (my ($key, $value) = each (%$a)) {
    if ($key eq $plain) {
        is($key, $plain, 'Plain key in shared hash ref');
    } elsif ($key eq $utf8) {
        is($key, $utf8, 'UTF-8 key in shared hash ref');
    } else {
        is($key, \&is, 'Code ref key in shared hash ref');
    }
}

exit(0);

# EOF
