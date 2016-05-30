use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Util qw/
    try

    get_tid USE_THREADS

    pkg_to_file

    CAN_FORK
    CAN_THREAD
    CAN_REALLY_FORK

    IS_WIN32
/;

{
    for my $try (\&try, Test2::Util->can('_manual_try'), Test2::Util->can('_local_try')) {
        my ($ok, $err) = $try->(sub { die "xxx" });
        ok(!$ok, "cought exception");
        like($err, qr/xxx/, "expected exception");

        ($ok, $err) = $try->(sub { 0 });
        ok($ok,   "Success");
        ok(!$err, "no error");
    }
}

is(pkg_to_file('A::Package::Name'), 'A/Package/Name.pm', "Converted package to file");

# Make sure running them does not die
# We cannot really do much to test these.
CAN_THREAD();
CAN_FORK();
CAN_REALLY_FORK();
IS_WIN32();

is(IS_WIN32(), ($^O eq 'MSWin32') ? 1 : 0, "IS_WIN32 is correct ($^O)");

done_testing;
