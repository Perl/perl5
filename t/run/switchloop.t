#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}
use strict;

require './test.pl';

# test the interaction of -F, -a, -n, -p, -N, and -P

sub result {
	my @flags = split //, shift;
	my $has_N = grep { /N/ } @flags;
	my $has_P = grep { /P/ } @flags;
	my $has_p = grep { /p/ } @flags;
	my $has_a = grep { /[Fa]/ } @flags;
	my $has_F = grep { /F/ } @flags;

	my $while = $has_P || ($has_N && !$has_p)
		? 'LINE: while (defined($_ = <<>>)) {'
		: 'LINE: while (defined($_ = readline ARGV)) {';

	my $zero = "    '???';";

	my $body = $has_F ? q{    our @F = split(/,/, $_, 0);} . "\n"
		 : $has_a ? q{    our @F = split(' ', $_, 0);} . "\n"
		 :          "";

	my $while_end = $has_P || $has_p
		? qq/}\ncontinue {\n    die "-p destination: \$!\\n" unless print \$_;\n}/
		: "}";

	return "-e syntax OK\n$while\n$body$zero\n$while_end\n";
}

# XXX this is probably not comprehensive,
# but I think it covers the important interactions
my %tests = (
    pn  => ["-MO=Deparse", "-e0", "-p"],
    np  => ["-MO=Deparse", "-e0", "-p"],
    p   => ["-MO=Deparse", "-e0", "-p"],
    n   => ["-MO=Deparse", "-e0", "-n"],
    a   => ["-MO=Deparse", "-e0", "-a"],
    an  => ["-MO=Deparse", "-e0", "-an"],
    na  => ["-MO=Deparse", "-e0", "-na"],
    ap  => ["-MO=Deparse", "-e0", "-ap"],
    pa  => ["-MO=Deparse", "-e0", "-pa"],
    F   => ["-MO=Deparse", "-e0", "-F,"],
    Fa  => ["-MO=Deparse", "-e0", "-F,", "-a"],
    Fan => ["-MO=Deparse", "-e0", "-F,", "-an"],
    Fp  => ["-MO=Deparse", "-e0", "-F,", "-p"],
    Fpa => ["-MO=Deparse", "-e0", "-F,", "-pa"],
    aF  => ["-MO=Deparse", "-e0", "-a", "-F,"],
    PN  => ["-MO=Deparse", "-e0", "-PN"],
    NP  => ["-MO=Deparse", "-e0", "-NP"],
    pN  => ["-MO=Deparse", "-e0", "-pN"],
    Np  => ["-MO=Deparse", "-e0", "-Np"],
    Pn  => ["-MO=Deparse", "-e0", "-Pn"],
    nP  => ["-MO=Deparse", "-e0", "-nP"],
    P   => ["-MO=Deparse", "-e0", "-P"],
    N   => ["-MO=Deparse", "-e0", "-N"],
    aN  => ["-MO=Deparse", "-e0", "-aN"],
    Na  => ["-MO=Deparse", "-e0", "-Na"],
    aP  => ["-MO=Deparse", "-e0", "-aP"],
    Pa  => ["-MO=Deparse", "-e0", "-Pa"],
    FaN => ["-MO=Deparse", "-e0", "-F,", "-aN"],
    FP  => ["-MO=Deparse", "-e0", "-F,", "-P"],
    FPa => ["-MO=Deparse", "-e0", "-F,", "-Pa"],
);

plan(scalar keys %tests);

for my $flags (keys %tests) {
	my $result = result($flags);
	ok(runperl(switches => $tests{$flags}, stderr => 1) eq $result,
	    "testing $flags flags");
}
