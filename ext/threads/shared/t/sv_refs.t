BEGIN {
#    chdir 't' if -d 't';
#    push @INC ,'../lib';
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no useithreads\n";
        exit 0;
    }
}


sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    print $ok ? "ok $id - $name\n" : "not ok $id - $name\n";

    printf "# Failed test at line %d\n", (caller)[2] unless $ok;

    return $ok;
}

use Devel::Peek;
use ExtUtils::testlib;
use strict;
BEGIN { print "1..9\n" };
use threads;
use threads::shared;
ok(1,1,"loaded");

my $foo;
my $bar = "foo";
share($foo);
eval {
$foo = \$bar;
};
ok(2,my $temp1 = $@ =~/You cannot assign a non shared reference to a shared scalar/, "Check that the warning message is correct");
share($bar);
$foo = \$bar;
ok(3, $temp1 = $foo =~/SCALAR/, "Check that is a ref");
ok(4, $$foo eq "foo", "Check that it points to the correct value");
$bar = "yeah";
ok(5, $$foo eq "yeah", "Check that assignment works");
$$foo = "yeah2";
ok(6, $$foo eq "yeah2", "Check that deref assignment works");
threads->create(sub {$bar = "yeah3"})->join();
ok(7, $$foo eq "yeah3", "Check that other thread assignemtn works");
threads->create(sub {$foo = "artur"})->join();
ok(8, $foo eq "artur", "Check that uncopupling the ref works");
my $baz;
share($baz);
$baz = "original";
$bar = \$baz;
$foo = \$bar;
ok(9,$$$foo eq 'original', "Check reference chain");

