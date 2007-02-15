use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..31\n");   ### Number of tests that will be run ###
};

use threads;
ok(1, 1, 'Loaded');

### Start of Testing ###

my $cnt = 30;

sub stress_re {
    my $s = "abcd" x (1000 + $_[0]);
    my $t = '';
    while ($s =~ /(.)/g) { $t .= $1 }
    return ($s eq $t) ? 'ok' : 'not';
}

my @threads;
for (1..$cnt) {
    push(@threads, threads->create('stress_re', $_));
}

for (1..$cnt) {
    my $result = $threads[$_-1]->join;
    ok($_+1, defined($result) && ($result eq 'ok'), "stress re - iter $_");
}

# EOF
