
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
BEGIN { print "1..21\n" };
use threads;
use threads::shared;
ok(1,1,"loaded");
my %hash;
share(%hash);
$hash{"foo"} = "bar";
ok(2,$hash{"foo"} eq "bar","Check hash get");
threads->create(sub { $hash{"bar"} = "thread1"})->join();
threads->create(sub { ok(3,$hash{"bar"} eq "thread1", "Check thread get and write")})->join();
{
    my $foo = delete($hash{"bar"});
    ok(4, $foo eq "thread1", "Check delete, want 'thread1' got '$foo'");
    $foo = delete($hash{"bar"});
    ok(5, $foo == undef, "Check delete on empty value");
}
ok(6, keys %hash == 1, "Check keys");
$hash{"1"} = 1;
$hash{"2"} = 2;
$hash{"3"} = 3;
ok(7, keys %hash == 4, "Check keys");
ok(8, exists($hash{"1"}) == 1, "Exist on existing key");
ok(9, exists($hash{"4"}) == undef, "Exists on non existing key");
my %seen;
foreach my $key ( keys %hash) {
    $seen{$key}++;
}
ok(10, $seen{1} == 1, "Keys..");
ok(11, $seen{2} == 1, "Keys..");
ok(12, $seen{3} == 1, "Keys..");
ok(13, $seen{"foo"} == 1, "Keys..");
threads->create(sub { %hash = () })->join();
ok(14, keys %hash == 0, "Check clear");
ok(15, threads::shared::_thrcnt(\%hash) == 1, "thrcnt");
threads->create(sub { ok(16, threads::shared::_thrcnt(\%hash) == 2, "thrcnt is up")})->join();
ok(17, threads::shared::_thrcnt(\%hash) == 1, "thrcnt is down");
{ 
	my $test;
	my $test2;
	share($test);
	$test = \%hash;
	$test2 = \%hash;
	ok(18, threads::shared::_thrcnt(\%hash) == 2, "thrcnt is up on shared reference");
	$test = "bar";
	ok(19 , threads::shared::_thrcnt(\%hash) == 1, "thrcnt is down when shared reference is dropped");
	$test = $test2;
	ok(20, threads::shared::_thrcnt(\%hash) == 2, "thrcnt is up on shared reference");
}
ok(21 , threads::shared::_thrcnt(\%hash) == 1, "thrcnt is down when shared reference is killed");
