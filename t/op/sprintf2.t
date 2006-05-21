#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}   

plan tests => 280;

is(
    sprintf("%.40g ",0.01),
    sprintf("%.40g", 0.01)." ",
    q(the sprintf "%.<number>g" optimization)
);
is(
    sprintf("%.40f ",0.01),
    sprintf("%.40f", 0.01)." ",
    q(the sprintf "%.<number>f" optimization)
);

# cases of $i > 1 are against [perl #39126]
for my $i (1, 5, 10, 20, 50, 100) {
    chop(my $utf8_format = "%-*s\x{100}");
    my $string = "\xB4"x$i;        # latin1 ACUTE or ebcdic COPYRIGHT
    my $expect = $string."  "x$i;  # followed by 2*$i spaces
    is(sprintf($utf8_format, 3*$i, $string), $expect,
       "width calculation under utf8 upgrade, length=$i");
}

# Used to mangle PL_sv_undef
fresh_perl_is(
    'print sprintf "xxx%n\n"; print undef',
    'Modification of a read-only value attempted at - line 1.',
    { switches => [ '-w' ] },
    q(%n should not be able to modify read-only constants),
);

# check overflows
for (int(~0/2+1), ~0, "9999999999999999999") {
    is(eval {sprintf "%${_}d", 0}, undef, "no sprintf result expected %${_}d");
    like($@, qr/^Integer overflow in format string for sprintf /, "overflow in sprintf");
    is(eval {printf "%${_}d\n", 0}, undef, "no printf result expected %${_}d");
    like($@, qr/^Integer overflow in format string for prtf /, "overflow in printf");
}

# check %NNN$ for range bounds
{
    my ($warn, $bad) = (0,0);
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ /uninitialized/) {
	    $warn++
	}
	else {
	    $bad++
	}
    };

    my $fmt = join('', map("%$_\$s%" . ((1 << 31)-$_) . '$s', 1..20));
    my $result = sprintf $fmt, qw(a b c d);
    is($result, "abcd", "only four valid values in $fmt");
    is($warn, 36, "expected warnings");
    is($bad,   0, "unexpected warnings");
}

{
    foreach my $ord (0 .. 255) {
	my $bad = 0;
	local $SIG{__WARN__} = sub {
	    if ($_[0] !~ /^Invalid conversion in sprintf/) {
		warn $_[0];
		$bad++;
	    }
	};
	my $r = eval {sprintf '%v' . chr $ord};
	is ($bad, 0, "pattern '%v' . chr $ord");
    }
}
