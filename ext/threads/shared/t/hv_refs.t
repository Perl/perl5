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

sub skip {
    my ($id, $ok, $name) = @_;
    print "ok $id # skip _thrcnt - $name \n";
}

use ExtUtils::testlib;
use strict;
BEGIN { print "1..17\n" };
use threads;
use threads::shared qw(:DEFAULT _thrcnt _refcnt _id);
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
skip(5, _thrcnt($foo) == 2, "Check refcount");
my $bar = delete($foo{foo});
ok(6, $$bar eq "test2", "check delete");
skip(7, _thrcnt($foo) == 1, "Check refcount after delete");
threads->create( sub {
   my $test;
   share($test);
   $test = "thread3";
   $foo{test} = \$test;
   })->join();
ok(8, ${$foo{test}} eq "thread3", "Check reference created in another thread");
my $gg = $foo{test};
$$gg = "test";
ok(9, ${$foo{test}} eq "test", "Check reference");
skip(10, _thrcnt($gg) == 2, "Check refcount");
my $gg2 = delete($foo{test});
skip(11, _thrcnt($gg) == 1, "Check refcount");
ok(12, _id($gg) == _id($gg2),
       sprintf("Check we get the same thing (%x vs %x)",
       _id($$gg),_id($$gg2)));
ok(13, $$gg eq $$gg2, "And check the values are the same");
ok(14, keys %foo == 0, "And make sure we realy have deleted the values");
{
    my (%hash1, %hash2);
    share(%hash1);
    share(%hash2);
    $hash1{hash} = \%hash2;
    $hash2{"bar"} = "foo";
    ok(15, $hash1{hash}->{bar} eq "foo", "Check hash references work");
    threads->create(sub { $hash2{"bar2"} = "foo2"})->join();
    ok(16, $hash1{hash}->{bar2} eq "foo2", "Check hash references work");
    threads->create(sub { my (%hash3); share(%hash3); $hash2{hash} = \%hash3; $hash3{"thread"} = "yes"})->join();
    ok(17, $hash1{hash}->{hash}->{thread} eq "yes", "Check hash created in another thread");
}

