#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}   

plan tests => 4;

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
{
	chop(my $utf8_format = "%-3s\x{100}");
	is(
		sprintf($utf8_format, "\xe4"),
		"\xe4  ",
		q(width calculation under utf8 upgrade)
	);
}

# Used to mangle PL_sv_undef
fresh_perl_is(
    'print sprintf "xxx%n\n"; print undef',
    'Modification of a read-only value attempted at - line 1.',
    { switches => [ '-w' ] },
    q(%n should not be able to modify read-only constants),
)
