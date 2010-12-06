#!./perl

#
# This test checks for $@ being set early during an exceptional
# unwinding, and that this early setting doesn't affect the late
# setting used to emit the exception from eval{}.  The early setting is
# a backward-compatibility hack to satisfy modules that were relying on
# the historical early setting in order to detect exceptional unwinding.
# This hack should be removed when a proper way to detect exceptional
# unwinding has been developed.
#

print "1..12\n";
my $test_num = 0;
sub ok {
    print $_[0] ? "" : "not ", "ok ", ++$test_num, "\n";
}

{
    package End;
    sub DESTROY { $_[0]->() }
    sub main::end(&) {
	my($cleanup) = @_;
	return bless(sub { $cleanup->() }, "End");
    }
}

my($uerr, $val, $err);

$@ = "";
$val = eval {
	my $c = end { $uerr = $@; $@ = "t2\n"; };
	1;
}; $err = $@;
ok $uerr eq "";
ok $val == 1;
ok $err eq "";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $uerr = $@; $@ = "t2\n"; };
	1;
}; $err = $@;
ok $uerr eq "t1\n";
ok $val == 1;
ok $err eq "";

$@ = "";
$val = eval {
	my $c = end { $uerr = $@; $@ = "t2\n"; };
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
ok $uerr eq "t3\n";
ok !defined($val);
ok $err eq "t3\n";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $uerr = $@; $@ = "t2\n"; };
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
ok $uerr eq "t3\n";
ok !defined($val);
ok $err eq "t3\n";

1;
