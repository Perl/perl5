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



use ExtUtils::testlib;
use strict;
BEGIN { print "1..7\n" };
use threads;
use threads::shared;
ok(1,1,"loaded");
my $foo;
share($foo);
my %foo;
share(%foo);
$foo{"foo"} = \$foo;
ok(2, ${$foo{foo}} == undef, "Check deref");
$foo = "test";
ok(3, ${$foo{foo}} eq "test", "Check deref after assign");
threads->create(sub{${$foo{foo}} = "test2";})->join();
ok(4, $foo eq "test2", "Check after assign in another thread");
ok(5, threads::shared::_thrcnt($foo) == 2, "Check refcount");
my $bar = delete($foo{foo});
ok(6, $$bar eq "test2", "check delete");
ok(7, threads::shared::_thrcnt($foo) == 1, "Check refcount after delete");
threads->create( sub {
my $test;
share($test);
$test = "thread3";
$foo{test} = \$test;
})->join();
ok(8, ${$foo{test}} eq "thread3", "Check refernece created in another thread");
my $gg = $foo{test};
$$gg = "test";
ok(9, ${$foo{test}} eq "test", "Check refernece");
ok(10, threads::shared::_thrcnt($gg) == 2, "Check refcount");
my $gg2 = delete($foo{test});
ok(11, threads::shared::_thrcnt($gg) == 1, "Check refcount");
ok(12, $gg == $gg2, "Check we get the same reference ($gg == $gg2)");
ok(13, $$gg eq $$gg2, "And check the values are the same");
ok(14, keys %foo == 0, "And make sure we realy have deleted the values");


