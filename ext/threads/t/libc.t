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

use threads;

BEGIN {
    $| = 1;
    print("1..12\n");   ### Number of tests that will be run ###
};

ok(1, 1, 'Loaded');

### Start of Testing ###

my $i = 10;
my $y = 20000;

my %localtime;
for (0..$i) {
    $localtime{$_} = localtime($_);
};

my @threads;
for (0..$i) {
    my $thread = threads->create(sub {
                    my $arg = $_;
                    my $localtime = $localtime{$arg};
                    my $error = 0;
                    for (0..$y) {
                        my $lt = localtime($arg);
                        if ($localtime ne $lt) {
                            $error++;
                        }
                    }
                    return $error;
                  });
    push @threads, $thread;
}

for (0..$i) {
    my $result = $threads[$_]->join();
    ok($_ + 2, defined($result) && ("$result" eq '0'), 'localtime safe');
}

# EOF
