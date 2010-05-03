#!./perl

# A place to put some simple leak tests. Uses XS::APItest to make
# PL_sv_count available, allowing us to run a bit a code multiple times and
# see if the count increases.

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';

    eval { require XS::APItest; XS::APItest->import('sv_count'); 1 }
	or skip_all("XS::APItest not available");
}

plan tests => 5;

# run some code N times. If the number of SVs at the end of loop N is
# greater than (N-1)*delta at the end of loop 1, we've got a leak
#
sub leak {
    my ($n, $delta, $code, @rest) = @_;
    my $sv0 = 0;
    my $sv1 = 0;
    for my $i (1..$n) {
	&$code();
	$sv1 = sv_count();
	$sv0 = $sv1 if $i == 1;
    }
    cmp_ok($sv1-$sv0, '<=', ($n-1)*$delta, @rest);
}

# run some expression N times. The expr is concatenated N times and then
# evaled, ensuring that that there are no scope exits between executions.
# If the number of SVs at the end of expr N is greater than (N-1)*delta at
# the end of expr 1, we've got a leak
#
sub leak_expr {
    my ($n, $delta, $expr, @rest) = @_;
    my $sv0 = 0;
    my $sv1 = 0;
    my $true = 1; # avoid stuff being optimised away
    my $code1 = "($expr || \$true)";
    my $code = "$code1 && (\$sv0 = sv_count())" . ("&& $code1" x 4)
		. " && (\$sv1 = sv_count())";
    if (eval $code) {
	cmp_ok($sv1-$sv0, '<=', ($n-1)*$delta, @rest);
    }
    else {
	fail("eval @rest: $@");
    }
}


my @a;

leak(5, 0, sub {},                 "basic check 1 of leak test infrastructure");
leak(5, 0, sub {push @a,1;pop @a}, "basic check 2 of leak test infrastructure");
leak(5, 1, sub {push @a,1;},       "basic check 3 of leak test infrastructure");

sub TIEARRAY	{ bless [], $_[0] }
sub FETCH	{ $_[0]->[$_[1]] }
sub STORE	{ $_[0]->[$_[1]] = $_[2] }

# local $tied_elem[..] leaks <20020502143736.N16831@dansat.data-plan.com>"
{
    tie my @a, 'main';
    leak(5, 0, sub {local $a[0]}, "local \$tied[0]");
}

# [perl #74484]  repeated tries leaked SVs on the tmps stack

leak_expr(5, 0, q{"YYYYYa" =~ /.+?(a(.+?)|b)/ }, "trie leak");
