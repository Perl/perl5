#
# t/test.pl - most of Test::More functionality without the fuss
#

my $test = 1;
my $planned;

$TODO = 0;

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
    my ($pass, $where, $name, @mess) = @_;
    # Do not try to microoptimize by factoring out the "not ".
    # VMS will avenge.
    my $out;
    if ($name) {
	$out = $pass ? "ok $test - $name" : "not ok $test - $name";
    } else {
	$out = $pass ? "ok $test" : "not ok $test";
    }

    $out .= " # TODO $TODO" if $TODO;
    print "$out\n";

    unless ($pass) {
	print "# Failed $where\n";
    }

    # Ensure that the message is properly escaped.
    print map { /^#/ ? "$_\n" : "# $_\n" } 
          map { split /\n/ } @mess if @mess;

    $test++;

    return $pass;
}

sub _where {
    my @caller = caller(1);
    return "at $caller[1] line $caller[2]";
}

sub ok {
    my ($pass, $name, @mess) = @_;
    _ok($pass, _where(), $name, @mess);
}

sub _q {
    my $x = shift;
    return 'undef' unless defined $x;
    my $q = $x;
    $q =~ s/'/\\'/;
    return "'$q'";
}

sub is {
    my ($got, $expected, $name, @mess) = @_;
    my $pass = $got eq $expected;
    unless ($pass) {
	unshift(@mess, "#      got "._q($got)."\n",
		       "# expected "._q($expected)."\n");
    }
    _ok($pass, _where(), $name, @mess);
}

sub isnt {
    my ($got, $isnt, $name, @mess) = @_;
    my $pass = $got ne $isnt;
    unless( $pass ) {
        unshift(@mess, "# it should not be "._q($got)."\n",
                       "# but it is.\n");
    }
    _ok($pass, _where(), $name, @mess);
}

# Note: this isn't quite as fancy as Test::More::like().
sub like {
    my ($got, $expected, $name, @mess) = @_;
    my $pass;
    if (ref $expected eq 'Regexp') {
	$pass = $got =~ $expected;
	unless ($pass) {
	    unshift(@mess, "#      got '$got'\n");
	}
    } else {
	$pass = $got =~ /$expected/;
	unless ($pass) {
	    unshift(@mess, "#      got '$got'\n",
		           "# expected /$expected/\n");
	}
    }
    _ok($pass, _where(), $name, @mess);
}

sub pass {
    _ok(1, '', @_);
}

sub fail {
    _ok(0, _where(), @_);
}

sub next_test {
    $test++
}

# Note: can't pass multipart messages since we try to
# be compatible with Test::More::skip().
sub skip {
    my $why = shift;
    my $n    = @_ ? shift : 1;
    for (1..$n) {
	print "ok $test # skip: $why\n";
        $test++;
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
    _ok(!$@, _where(), "require $require");
}

sub use_ok {
    my ($use) = @_;
    eval <<USE_OK;
use $use;
USE_OK
    _ok(!$@, _where(), "use $use");
}

# runperl - Runs a separate perl interpreter.
# Arguments :
#   switches => [ command-line switches ]
#   nolib    => 1 # don't use -I../lib (included by default)
#   prog     => one-liner (avoid quotes)
#   progfile => perl script
#   stdin    => string to feed the stdin
#   stderr   => redirect stderr to stdout
#   args     => [ command-line arguments to the perl program ]

my $is_mswin    = $^O eq 'MSWin32';
my $is_netware  = $^O eq 'NetWare';
my $is_macos    = $^O eq 'MacOS';
my $is_vms      = $^O eq 'VMS';

sub runperl {
    my %args = @_;
    my $runperl = $^X;
    if (defined $args{switches}) {
	$runperl .= ' ' . join ' ', map qq("$_"), @{ $args{switches} };
    }
    unless (defined $args{nolib}) {
	if ($is_macos && $args{stderr}) {
	    $runperl .= ' -I::lib -MMac::err=unix';
	}
	else {
	    $runperl .= ' "-I../lib"';
	}
    }
    if (defined $args{prog}) {
	if ($is_mswin || $is_netware || $is_vms) {
	    $runperl .= qq( -e ") . $args{prog} . qq(");
	}
	else {
	    $runperl .= qq( -e ') . $args{prog} . qq(');
	}
    } elsif (defined $args{progfile}) {
	$runperl .= qq( "$args{progfile}");
    }
    if (defined $args{stdin}) {
	if ($is_mswin || $is_netware || $is_vms) {
	    $runperl = qq{$^X -e "print q(} .
		$args{stdin} . q{)" | } . $runperl;
	}
	else {
	    $runperl = qq{$^X -e 'print q(} .
		$args{stdin} . q{)' | } . $runperl;
	}
    }
    if (defined $args{args}) {
	$runperl .= ' ' . join ' ', map qq("$_"), @{ $args{args} };
    }
    $runperl .= ' 2>&1' if $args{stderr} && !$is_macos;
    $runperl .= " \xB3 Dev:Null" if !defined $args{stderr} && $is_macos;
    my $result = `$runperl`;
    $result =~ s/\n\n/\n/ if $is_vms; # XXX pipes sometimes double these
    return $result;
}

1;
