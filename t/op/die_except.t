#!./perl

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

my($val, $err);

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	1;
}; $err = $@;
ok $val == 1;
ok $err eq "";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
ok !defined($val);
ok $err eq "t3\n";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	local $@ = "t2\n";
	1;
}; $err = $@;
ok $val == 1;
ok $err eq "";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	local $@ = "t2\n";
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
ok !defined($val);
ok $err eq "t3\n";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $@ = "t2\n"; };
	1;
}; $err = $@;
ok $val == 1;
ok $err eq "";

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $@ = "t2\n"; };
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
ok !defined($val);
ok $err eq "t3\n";

1;
