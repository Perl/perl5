use strict;
use warnings;

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    }
    else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..19\n");    ### Number of tests that will be run ###
}

use Scalar::Util qw(dualvar);

use threads;
use threads::shared;

ok(1, 1, 'Loaded');

### Start of Testing ###

my $dv = dualvar(42, 'Fourty-Two');
my $pi = dualvar(3.14, 'PI');

my @a :shared;

# Individual assignment
# Verify that dualvar preserved during individual element assignment
$a[0] = $dv;
$a[1] = $pi;

ok(2, $a[0] == 42, 'IV number preserved');
ok(3, $a[0] eq 'Fourty-Two', 'string preserved');
ok(4, $a[1] == 3.14, 'NV number preserved');
ok(5, $a[1] eq 'PI', 'string preserved');

#-- List initializer
# Verify that dualvar preserved during initialization
my @a2 :shared = ($dv, $pi);

ok(6, $a2[0] == 42, 'IV number preserved');
ok(7, $a2[0] eq 'Fourty-Two', 'string preserved');
ok(8, $a2[1] == 3.14, 'NV number preserved');
ok(9, $a2[1] eq 'PI', 'string preserved');

#-- List assignment
# Verify that dualvar preserved during list assignment
my @a3 :shared = (0, 0);
@a3 = ($dv, $pi);

ok(10, $a3[0] == 42, 'IV number preserved');
ok(11, $a3[0] eq 'Fourty-Two', 'string preserved');
ok(12, $a3[1] == 3.14, 'NV number preserved');
ok(13, $a3[1] eq 'PI', 'string preserved');

# Back to non-shared
# Verify that entries are still dualvar when leaving the array
my @nsa = @a3;
ok(14, $nsa[0] == 42, 'IV number preserved');
ok(15, $nsa[0] eq 'Fourty-Two', 'string preserved');
ok(16, $nsa[1] == 3.14, 'NV number preserved');
ok(17, $nsa[1] eq 'PI', 'string preserved');

# $! behaves like a dualvar, but is really implemented as a tied SV.
# As a result sharing $! directly only propagates the string value.
# However, we can create a dualvar from it.
$! = 1;
my $ss :shared = dualvar($!,$!);
ok(18, $ss == 1, 'IV number preserved');
ok(19, $ss eq $!, 'string preserved');

exit(0);
