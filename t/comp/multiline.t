#!./perl

print "1..6\n";
my $test = 0;

sub failed {
    my ($got, $expected, $name) = @_;

    print "not ok $test - $name\n";
    my @caller = caller(1);
    print "# Failed test at $caller[1] line $caller[2]\n";
    if (defined $got) {
	print "# Got '$got'\n";
    } else {
	print "# Got undef\n";
    }
    print "# Expected $expected\n";
    return;
}

sub like {
    my ($got, $pattern, $name) = @_;
    $test = $test + 1;
    if (defined $got && $got =~ $pattern) {
	print "ok $test - ".($name // 'undef')."\n";
	# Principle of least surprise - maintain the expected interface, even
	# though we aren't using it here (yet).
	return 1;
    }
    failed($got, $pattern, $name);
}

sub is {
    my ($got, $expect, $name) = @_;
    $test = $test + 1;
    if (defined $got && $got eq $expect) {
	print "ok $test - ".($name // 'undef')."\n";
	return 1;
    }
    failed($got, "'$expect'", $name);
}

my $filename = "multiline$$";

END {
    1 while unlink $filename;
}

open(TRY,'>',$filename) || (die "Can't open $filename: $!");

my $x = 'now is the time
for all good men
to come to.


!

';

my $y = 'now is the time' . "\n" .
'for all good men' . "\n" .
'to come to.' . "\n\n\n!\n\n";

is($x, $y,  'test data is sane');

print TRY $x;
close TRY or die "Could not close: $!";

open(TRY,$filename) || (die "Can't reopen $filename: $!");
my $count = 0;
my $z = '';
while (<TRY>) {
    $z .= $_;
    $count = $count + 1;
}

is($z, $y,  'basic multiline reading');

is($count, 7,   '    line count');
is($., 7,       '    $.' );

my $out = (($^O eq 'MSWin32') || $^O eq 'NetWare') ? `type $filename`
    : ($^O eq 'VMS') ? `type $filename.;0`   # otherwise .LIS is assumed
    : `cat $filename`;

like($out, qr/.*\n.*\n.*\n$/);

close(TRY) || (die "Can't close $filename: $!");

is($out, $y);
