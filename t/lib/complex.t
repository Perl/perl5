#!./perl

# $RCSfile$
#
# Regression tests for the new Math::Complex pacakge
# -- Raphael Manfredi, Sept 1996
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}
use Math::Complex;

$test = 0;
$| = 1;
$script = '';
$epsilon = 1e-10;

while (<DATA>) {
	next if /^#/ || /^\s*$/;
	chop;
	$set_test = 0;			# Assume not a test over a set of values
	if (/^&(.*)/) {
		$op = $1;
		next;
	}
	elsif (/^\{(.*)\}/) {
		set($1, \@set, \@val);
		next;
	}
	elsif (s/^\|//) {
		$set_test = 1;		# Requests we loop over the set...
	}
	my @args = split(/:/);
	if ($set_test) {
		my $i;
		for ($i = 0; $i < @set; $i++) {
			$target = $set[$i];		# complex number
			$zvalue = $val[$i];		# textual value as found in set definition
			test($zvalue, $target, @args);
		}
	} else {
		test($op, undef, @args);
	}
}

print "1..$test\n";
eval $script;
die $@ if $@;

sub test {
	my ($op, $z, @args) = @_;
	$test++;
	my $i;
	for ($i = 0; $i < @args; $i++) {
		$val = value($args[$i]);
		$script .= "\$z$i = $val;\n";
	}
	if (defined $z) {
		$args = "'$op'";		# Really the value
		$try = "abs(\$z0 - \$z1) <= 1e-10 ? \$z1 : \$z0";
		$script .= "\$res = $try; ";
		$script .= "check($test, $args[0], \$res, \$z$#args, $args);\n";
	} else {
		my ($try, $args);
		if (@args == 2) {
			$try = "$op \$z0";
			$args = "'$args[0]'";
		} else {
			$try = ($op =~ /^\w/) ? "$op(\$z0, \$z1)" : "\$z0 $op \$z1";
			$args = "'$args[0]', '$args[1]'";
		}
		$script .= "\$res = $try; ";
		$script .= "check($test, '$try', \$res, \$z$#args, $args);\n";
	}
}

sub set {
	my ($set, $setref, $valref) = @_;
	@{$setref} = ();
	@{$valref} = ();
	my @set = split(/;\s*/, $set);
	my @res;
	my $i;
	for ($i = 0; $i < @set; $i++) {
		push(@{$valref}, $set[$i]);
		my $val = value($set[$i]);
		$script .= "\$s$i = $val;\n";
		push(@{$setref}, "\$s$i");
	}
}

sub value {
	local ($_) = @_;
	if (/^\s*\((.*),(.*)\)/) {
		return "cplx($1,$2)";
	}
	elsif (/^\s*\[(.*),(.*)\]/) {
		return "cplxe($1,$2)";
	}
	elsif (/^\s*'(.*)'/) {
		my $ex = $1;
		$ex =~ s/\bz\b/$target/g;
		$ex =~ s/\br\b/abs($target)/g;
		$ex =~ s/\bt\b/arg($target)/g;
		$ex =~ s/\ba\b/Re($target)/g;
		$ex =~ s/\bb\b/Im($target)/g;
		return $ex;
	}
	elsif (/^\s*"(.*)"/) {
		return "\"$1\"";
	}
	return $_;
}

sub check {
	my ($test, $try, $got, $expected, @z) = @_;
	if ("$got" eq "$expected" || ($expected =~ /^-?\d/ && $got == $expected)) {
		print "ok $test\n";
	} else {
		print "not ok $test\n";
		my $args = (@z == 1) ? "z = $z[0]" : "z0 = $z[0], z1 = $z[1]";
		print "# '$try' expected: '$expected' got: '$got' for $args\n";
	}
}
__END__
&+
(3,4):(3,4):(6,8)
(-3,4):(3,-4):(0,0)
(3,4):-3:(0,4)
1:(4,2):(5,2)
[2,0]:[2,pi]:(0,0)

&++
(2,1):(3,1)

&-
(2,3):(-2,-3)
[2,pi/2]:[2,-(pi)/2]
2:[2,0]:(0,0)
[3,0]:2:(1,0)
3:(4,5):(-1,-5)
(4,5):3:(1,5)

&--
(1,2):(0,2)
[2,pi]:[3,pi]

&*
(0,1):(0,1):(-1,0)
(4,5):(1,0):(4,5)
[2,2*pi/3]:(1,0):[2,2*pi/3]
2:(0,1):(0,2)
(0,1):3:(0,3)
(0,1):(4,1):(-1,4)
(2,1):(4,-1):(9,2)

&/
(3,4):(3,4):(1,0)
(4,-5):1:(4,-5)
1:(0,1):(0,-1)
(0,6):(0,2):(3,0)
(9,2):(4,-1):(2,1)
[4,pi]:[2,pi/2]:[2,pi/2]
[2,pi/2]:[4,pi]:[0.5,-(pi)/2]

&abs
(3,4):5
(-3,4):5

&~
(4,5):(4,-5)
(-3,4):(-3,-4)
[2,pi/2]:[2,-(pi)/2]

&<
(3,4):(1,2):0
(3,4):(3,2):0
(3,4):(3,8):1
(4,4):(5,129):1

&==
(3,4):(4,5):0
(3,4):(3,5):0
(3,4):(2,4):0
(3,4):(3,4):1

&sqrt
(-100,0):(0,10)
(16,-30):(5,-3)

&stringify_cartesian
(-100,0):"-100"
(0,1):"i"
(4,-3):"4-3i"
(4,0):"4"
(-4,0):"-4"
(-2,4):"-2+4i"
(-2,-1):"-2-i"

&stringify_polar
[-1, 0]:"[1,pi]"
[1, pi/3]:"[1,pi/3]"
[6, -2*pi/3]:"[6,-2pi/3]"
[0.5, -9*pi/11]:"[0.5,-9pi/11]"

{ (4,3); [3,2]; (-3,4); (0,2); [2,1] }

|'z + ~z':'2*Re(z)'
|'z - ~z':'2*i*Im(z)'
|'z * ~z':'abs(z) * abs(z)'

{ (4,3); [3,2]; (-3,4); (0,2); 3; 1; (-5, 0); [2,1] }

|'exp(z)':'exp(a) * exp(i * b)'
|'abs(z)':'r'
|'sqrt(z) * sqrt(z)':'z'
|'sqrt(z)':'sqrt(r) * exp(i * t/2)'
|'cbrt(z)':'cbrt(r) * exp(i * t/3)'
|'log(z)':'log(r) + i*t'
|'sin(asin(z))':'z'
|'cos(acos(z))':'z'
|'tan(atan(z))':'z'
|'cotan(acotan(z))':'z'
|'cos(z) ** 2 + sin(z) ** 2':1
|'cosh(z) ** 2 - sinh(z) ** 2':1
|'cos(z)':'cosh(i*z)'
|'cotan(z)':'1 / tan(z)'
|'cotanh(z)':'1 / tanh(z)'
|'i*sin(z)':'sinh(i*z)'
|'z**z':'exp(z * log(z))'
|'log(exp(z))':'z'
|'exp(log(z))':'z'
|'log10(z)':'log(z) / log(10)'
|'logn(z, 3)':'log(z) / log(3)'
|'logn(z, 2)':'log(z) / log(2)'
|'(root(z, 4))[1] ** 4':'z'
|'(root(z, 8))[7] ** 8':'z'

{ (1,1); [1,0.5]; (-2, -1); 2; (-1,0.5); (0,0.5); 0.5; (2, 0) }

|'sinh(asinh(z))':'z'
|'cosh(acosh(z))':'z'
|'tanh(atanh(z))':'z'
|'cotanh(acotanh(z))':'z'

{ (0.2,-0.4); [1,0.5]; -1.2; (-1,0.5); (0,-0.5); 0.5; (1.1, 0) }

|'asin(sin(z))':'z'
|'acos(cos(z)) ** 2':'z * z'
|'atan(tan(z))':'z'
|'asinh(sinh(z))':'z'
|'acosh(cosh(z)) ** 2':'z * z'
|'atanh(tanh(z))':'z'

