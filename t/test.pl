#
# t/test.pl - most of Test::More functionality without the fuss
#

my $test = 1;
my $planned;

sub plan {
    my $n;
    if (@_ == 1) {
	$n = shift;
    } else {
	my %plan = @_;
	$n = $plan{tests}; 
    }
    print "1..$n\n";
    $planned = $n;
}

END {
    my $ran = $test - 1;
    if (defined $planned && $planned != $ran) {
	print "# Looks like you planned $planned tests but ran $ran.\n";
    }
}

sub skip_all {
    if (@_) {
	print "1..0 - @_\n";
    } else {
	print "1..0\n";
    }
    exit(0);
}

sub _ok {
    my ($pass, $where, @mess) = @_;
    # Do not try to microoptimize by factoring out the "not ".
    # VMS will avenge.
    if (@mess) {
	print $pass ? "ok $test - @mess\n" : "not ok $test - @mess\n";
    } else {
	print $pass ? "ok $test\n" : "not ok $test\n";
    }
    unless ($pass) {
	print "# Failed $where\n";
    }
    $test++;
}

sub _where {
    my @caller = caller(1);
    return "at $caller[1] line $caller[2]";
}

sub ok {
    my ($pass, @mess) = @_;
    _ok($pass, _where(), @mess);
}

sub _expect {
    my ($got, $pass, @mess) = @_;
    if ($pass) {
	ok(1, @mess);
    } else {
	ok(0, @mess);
    }
} 

sub is {
    my ($got, $expected, @mess) = @_;
    my $pass = $got eq $expected;
    unless ($pass) {
	unshift(@mess, "\n",
		"#      got '$got'\n",
		"# expected '$expected'\n");
    }
    _expect($pass, _where(), @mess);
}

# Note: this isn't quite as fancy as Test::More::like().
sub like {
    my ($got, $expected, @mess) = @_;
    my $pass;
    if (ref $expected eq 'Regexp') {
	$pass = $got =~ $expected;
	unless ($pass) {
	    unshift(@mess, "\n",
		    "#      got '$got'\n");
	}
    } else {
	$pass = $got =~ /$expected/;
	unless ($pass) {
	    unshift(@mess, "\n",
		    "#      got '$got'\n",
		    "# expected /$expected/\n");
	}
    }
    _expect($pass, _where(), @mess);
}

sub pass {
    _ok(1, '', @_);
}

sub fail {
    _ok(0, _where(), @_);
}

# Note: can't pass multipart messages since we try to
# be compatible with Test::More::skip().
sub skip {
    my $mess = shift;
    my $n    = @_ ? shift : 1;
    for (1..$n) {
	ok(1, "# skip:", $mess);
    }
    local $^W = 0;
    last SKIP;
}

sub eq_array {
    my ($ra, $rb) = @_;
    return 0 unless $#$ra == $#$rb;
    for my $i (0..$#$ra) {
	return 0 unless $ra->[$i] eq $rb->[$i];
    }
    return 1;
}

sub require_ok {
    my ($require) = @_;
    eval <<REQUIRE_OK;
require $require;
REQUIRE_OK
    ok(!$@, "require $require");
}

sub use_ok {
    my ($use) = @_;
    eval <<USE_OK;
use $use;
USE_OK
    ok(!$@, "use $use");
}

1;
