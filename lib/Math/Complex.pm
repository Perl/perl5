# $RCSFile$
#
# Complex numbers and associated mathematical functions
# -- Raphael Manfredi, Sept 1996

require Exporter;
package Math::Complex; @ISA = qw(Exporter);

@EXPORT = qw(
	pi i Re Im arg
	log10 logn cbrt root
	tan cotan asin acos atan acotan
	sinh cosh tanh cotanh asinh acosh atanh acotanh
	cplx cplxe
);

use overload
	'+'		=> \&plus,
	'-'		=> \&minus,
	'*'		=> \&multiply,
	'/'		=> \&divide,
	'**'	=> \&power,
	'<=>'	=> \&spaceship,
	'neg'	=> \&negate,
	'~'		=> \&conjugate,
	'abs'	=> \&abs,
	'sqrt'	=> \&sqrt,
	'exp'	=> \&exp,
	'log'	=> \&log,
	'sin'	=> \&sin,
	'cos'	=> \&cos,
	'atan2'	=> \&atan2,
	qw("" stringify);

#
# Package globals
#

$package = 'Math::Complex';		# Package name
$display = 'cartesian';			# Default display format

#
# Object attributes (internal):
#	cartesian	[real, imaginary] -- cartesian form
#	polar		[rho, theta] -- polar form
#	c_dirty		cartesian form not up-to-date
#	p_dirty		polar form not up-to-date
#	display		display format (package's global when not set)
#

#
# ->make
#
# Create a new complex number (cartesian form)
#
sub make {
	my $self = bless {}, shift;
	my ($re, $im) = @_;
	$self->{'cartesian'} = [$re, $im];
	$self->{c_dirty} = 0;
	$self->{p_dirty} = 1;
	return $self;
}

#
# ->emake
#
# Create a new complex number (exponential form)
#
sub emake {
	my $self = bless {}, shift;
	my ($rho, $theta) = @_;
	$theta += pi() if $rho < 0;
	$self->{'polar'} = [abs($rho), $theta];
	$self->{p_dirty} = 0;
	$self->{c_dirty} = 1;
	return $self;
}

sub new { &make }		# For backward compatibility only.

#
# cplx
#
# Creates a complex number from a (re, im) tuple.
# This avoids the burden of writing Math::Complex->make(re, im).
#
sub cplx {
	my ($re, $im) = @_;
	return $package->make($re, $im);
}

#
# cplxe
#
# Creates a complex number from a (rho, theta) tuple.
# This avoids the burden of writing Math::Complex->emake(rho, theta).
#
sub cplxe {
	my ($rho, $theta) = @_;
	return $package->emake($rho, $theta);
}

#
# pi
#
# The number defined as 2 * pi = 360 degrees
#
sub pi () {
	$pi = 4 * atan2(1, 1) unless $pi;
	return $pi;
}

#
# i
#
# The number defined as i*i = -1;
#
sub i () {
	$i = bless {} unless $i;		# There can be only one i
	$i->{'cartesian'} = [0, 1];
	$i->{'polar'} = [1, pi/2];
	$i->{c_dirty} = 0;
	$i->{p_dirty} = 0;
	return $i;
}

#
# Attribute access/set routines
#

sub cartesian {$_[0]->{c_dirty} ? $_[0]->update_cartesian : $_[0]->{'cartesian'}}
sub polar     {$_[0]->{p_dirty} ? $_[0]->update_polar : $_[0]->{'polar'}}

sub set_cartesian { $_[0]->{p_dirty}++; $_[0]->{'cartesian'} = $_[1] }
sub set_polar     { $_[0]->{c_dirty}++; $_[0]->{'polar'} = $_[1] }

#
# ->update_cartesian
#
# Recompute and return the cartesian form, given accurate polar form.
#
sub update_cartesian {
	my $self = shift;
	my ($r, $t) = @{$self->{'polar'}};
	$self->{c_dirty} = 0;
	return $self->{'cartesian'} = [$r * cos $t, $r * sin $t];
}

#
#
# ->update_polar
#
# Recompute and return the polar form, given accurate cartesian form.
#
sub update_polar {
	my $self = shift;
	my ($x, $y) = @{$self->{'cartesian'}};
	$self->{p_dirty} = 0;
	return $self->{'polar'} = [0, 0] if $x == 0 && $y == 0;
	return $self->{'polar'} = [sqrt($x*$x + $y*$y), atan2($y, $x)];
}

#
# (plus)
#
# Computes z1+z2.
#
sub plus {
	my ($z1, $z2, $regular) = @_;
	my ($re1, $im1) = @{$z1->cartesian};
	my ($re2, $im2) = ref $z2 ? @{$z2->cartesian} : ($z2);
	unless (defined $regular) {
		$z1->set_cartesian([$re1 + $re2, $im1 + $im2]);
		return $z1;
	}
	return (ref $z1)->make($re1 + $re2, $im1 + $im2);
}

#
# (minus)
#
# Computes z1-z2.
#
sub minus {
	my ($z1, $z2, $inverted) = @_;
	my ($re1, $im1) = @{$z1->cartesian};
	my ($re2, $im2) = ref $z2 ? @{$z2->cartesian} : ($z2);
	unless (defined $inverted) {
		$z1->set_cartesian([$re1 - $re2, $im1 - $im2]);
		return $z1;
	}
	return $inverted ?
		(ref $z1)->make($re2 - $re1, $im2 - $im1) :
		(ref $z1)->make($re1 - $re2, $im1 - $im2);
}

#
# (multiply)
#
# Computes z1*z2.
#
sub multiply {
	my ($z1, $z2, $regular) = @_;
	my ($r1, $t1) = @{$z1->polar};
	my ($r2, $t2) = ref $z2 ? @{$z2->polar} : (abs($z2), $z2 >= 0 ? 0 : pi);
	unless (defined $regular) {
		$z1->set_polar([$r1 * $r2, $t1 + $t2]);
		return $z1;
	}
	return (ref $z1)->emake($r1 * $r2, $t1 + $t2);
}

#
# (divide)
#
# Computes z1/z2.
#
sub divide {
	my ($z1, $z2, $inverted) = @_;
	my ($r1, $t1) = @{$z1->polar};
	my ($r2, $t2) = ref $z2 ? @{$z2->polar} : (abs($z2), $z2 >= 0 ? 0 : pi);
	unless (defined $inverted) {
		$z1->set_polar([$r1 / $r2, $t1 - $t2]);
		return $z1;
	}
	return $inverted ?
		(ref $z1)->emake($r2 / $r1, $t2 - $t1) :
		(ref $z1)->emake($r1 / $r2, $t1 - $t2);
}

#
# (power)
#
# Computes z1**z2 = exp(z2 * log z1)).
#
sub power {
	my ($z1, $z2, $inverted) = @_;
	return exp($z1 * log $z2) if defined $inverted && $inverted;
	return exp($z2 * log $z1);
}

#
# (spaceship)
#
# Computes z1 <=> z2.
# Sorts on the real part first, then on the imaginary part. Thus 2-4i > 3+8i.
#
sub spaceship {
	my ($z1, $z2, $inverted) = @_;
	my ($re1, $im1) = @{$z1->cartesian};
	my ($re2, $im2) = ref $z2 ? @{$z2->cartesian} : ($z2);
	my $sgn = $inverted ? -1 : 1;
	return $sgn * ($re1 <=> $re2) if $re1 != $re2;
	return $sgn * ($im1 <=> $im2);
}

#
# (negate)
#
# Computes -z.
#
sub negate {
	my ($z) = @_;
	if ($z->{c_dirty}) {
		my ($r, $t) = @{$z->polar};
		return (ref $z)->emake($r, pi + $t);
	}
	my ($re, $im) = @{$z->cartesian};
	return (ref $z)->make(-$re, -$im);
}

#
# (conjugate)
#
# Compute complex's conjugate.
#
sub conjugate {
	my ($z) = @_;
	if ($z->{c_dirty}) {
		my ($r, $t) = @{$z->polar};
		return (ref $z)->emake($r, -$t);
	}
	my ($re, $im) = @{$z->cartesian};
	return (ref $z)->make($re, -$im);
}

#
# (abs)
#
# Compute complex's norm (rho).
#
sub abs {
	my ($z) = @_;
	my ($r, $t) = @{$z->polar};
	return abs($r);
}

#
# arg
#
# Compute complex's argument (theta).
#
sub arg {
	my ($z) = @_;
	return 0 unless ref $z;
	my ($r, $t) = @{$z->polar};
	return $t;
}

#
# (sqrt)
#
# Compute sqrt(z) (positive only).
#
sub sqrt {
	my ($z) = @_;
	my ($r, $t) = @{$z->polar};
	return (ref $z)->emake(sqrt($r), $t/2);
}

#
# cbrt
#
# Compute cbrt(z) (cubic root, primary only).
#
sub cbrt {
	my ($z) = @_;
	return $z ** (1/3) unless ref $z;
	my ($r, $t) = @{$z->polar};
	return (ref $z)->emake($r**(1/3), $t/3);
}

#
# root
#
# Computes all nth root for z, returning an array whose size is n.
# `n' must be a positive integer.
#
# The roots are given by (for k = 0..n-1):
#
# z^(1/n) = r^(1/n) (cos ((t+2 k pi)/n) + i sin ((t+2 k pi)/n))
#
sub root {
	my ($z, $n) = @_;
	$n = int($n + 0.5);
	return undef unless $n > 0;
	my ($r, $t) = ref $z ? @{$z->polar} : (abs($z), $z >= 0 ? 0 : pi);
	my @root;
	my $k;
	my $theta_inc = 2 * pi / $n;
	my $rho = $r ** (1/$n);
	my $theta;
	my $complex = ref($z) || $package;
	for ($k = 0, $theta = $t / $n; $k < $n; $k++, $theta += $theta_inc) {
		push(@root, $complex->emake($rho, $theta));
	}
	return @root;
}

#
# Re
#
# Return Re(z).
#
sub Re {
	my ($z) = @_;
	return $z unless ref $z;
	my ($re, $im) = @{$z->cartesian};
	return $re;
}

#
# Im
#
# Return Im(z).
#
sub Im {
	my ($z) = @_;
	return 0 unless ref $z;
	my ($re, $im) = @{$z->cartesian};
	return $im;
}

#
# (exp)
#
# Computes exp(z).
#
sub exp {
	my ($z) = @_;
	my ($x, $y) = @{$z->cartesian};
	return (ref $z)->emake(exp($x), $y);
}

#
# (log)
#
# Compute log(z).
#
sub log {
	my ($z) = @_;
	my ($r, $t) = @{$z->polar};
	return (ref $z)->make(log($r), $t);
}

#
# log10
#
# Compute log10(z).
#
sub log10 {
	my ($z) = @_;
	$log10 = log(10) unless defined $log10;
	return log($z) / $log10 unless ref $z;
	my ($r, $t) = @{$z->polar};
	return (ref $z)->make(log($r) / $log10, $t / $log10);
}

#
# logn
#
# Compute logn(z,n) = log(z) / log(n)
#
sub logn {
	my ($z, $n) = @_;
	my $logn = $logn{$n};
	$logn = $logn{$n} = log($n) unless defined $logn;	# Cache log(n)
	return log($z) / log($n);
}

#
# (cos)
#
# Compute cos(z) = (exp(iz) + exp(-iz))/2.
#
sub cos {
	my ($z) = @_;
	my ($x, $y) = @{$z->cartesian};
	my $ey = exp($y);
	my $ey_1 = 1 / $ey;
	return (ref $z)->make(cos($x) * ($ey + $ey_1)/2, sin($x) * ($ey_1 - $ey)/2);
}

#
# (sin)
#
# Compute sin(z) = (exp(iz) - exp(-iz))/2.
#
sub sin {
	my ($z) = @_;
	my ($x, $y) = @{$z->cartesian};
	my $ey = exp($y);
	my $ey_1 = 1 / $ey;
	return (ref $z)->make(sin($x) * ($ey + $ey_1)/2, cos($x) * ($ey - $ey_1)/2);
}

#
# tan
#
# Compute tan(z) = sin(z) / cos(z).
#
sub tan {
	my ($z) = @_;
	return sin($z) / cos($z);
}

#
# cotan
#
# Computes cotan(z) = 1 / tan(z).
#
sub cotan {
	my ($z) = @_;
	return cos($z) / sin($z);
}

#
# acos
#
# Computes the arc cosine acos(z) = -i log(z + sqrt(z*z-1)).
#
sub acos {
	my ($z) = @_;
	my $cz = $z*$z - 1;
	$cz = cplx($cz, 0) if !ref $cz && $cz < 0;	# Force complex if <0
	return ~i * log($z + sqrt $cz);				# ~i is -i
}

#
# asin
#
# Computes the arc sine asin(z) = -i log(iz + sqrt(1-z*z)).
#
sub asin {
	my ($z) = @_;
	my $cz = 1 - $z*$z;
	$cz = cplx($cz, 0) if !ref $cz && $cz < 0;	# Force complex if <0
	return ~i * log(i * $z + sqrt $cz);			# ~i is -i
}

#
# atan
#
# Computes the arc tagent atan(z) = i/2 log((i+z) / (i-z)).
#
sub atan {
	my ($z) = @_;
	return i/2 * log((i + $z) / (i - $z));
}

#
# acotan
#
# Computes the arc cotangent acotan(z) = -i/2 log((i+z) / (z-i))
#
sub acotan {
	my ($z) = @_;
	return i/-2 * log((i + $z) / ($z - i));
}

#
# cosh
#
# Computes the hyperbolic cosine cosh(z) = (exp(z) + exp(-z))/2.
#
sub cosh {
	my ($z) = @_;
	my ($x, $y) = ref $z ? @{$z->cartesian} : ($z);
	my $ex = exp($x);
	my $ex_1 = 1 / $ex;
	return ($ex + $ex_1)/2 unless ref $z;
	return (ref $z)->make(cos($y) * ($ex + $ex_1)/2, sin($y) * ($ex - $ex_1)/2);
}

#
# sinh
#
# Computes the hyperbolic sine sinh(z) = (exp(z) - exp(-z))/2.
#
sub sinh {
	my ($z) = @_;
	my ($x, $y) = ref $z ? @{$z->cartesian} : ($z);
	my $ex = exp($x);
	my $ex_1 = 1 / $ex;
	return ($ex - $ex_1)/2 unless ref $z;
	return (ref $z)->make(cos($y) * ($ex - $ex_1)/2, sin($y) * ($ex + $ex_1)/2);
}

#
# tanh
#
# Computes the hyperbolic tangent tanh(z) = sinh(z) / cosh(z).
#
sub tanh {
	my ($z) = @_;
	return sinh($z) / cosh($z);
}

#
# cotanh
#
# Comptutes the hyperbolic cotangent cotanh(z) = cosh(z) / sinh(z).
#
sub cotanh {
	my ($z) = @_;
	return cosh($z) / sinh($z);
}

#
# acosh
#
# Computes the arc hyperbolic cosine acosh(z) = log(z + sqrt(z*z-1)).
#
sub acosh {
	my ($z) = @_;
	my $cz = $z*$z - 1;
	$cz = cplx($cz, 0) if !ref $cz && $cz < 0;	# Force complex if <0
	return log($z + sqrt $cz);
}

#
# asinh
#
# Computes the arc hyperbolic sine asinh(z) = log(z + sqrt(z*z-1))
#
sub asinh {
	my ($z) = @_;
	my $cz = $z*$z + 1;							# Already complex if <0
	return log($z + sqrt $cz);
}

#
# atanh
#
# Computes the arc hyperbolic tangent atanh(z) = 1/2 log((1+z) / (1-z)).
#
sub atanh {
	my ($z) = @_;
	my $cz = (1 + $z) / (1 - $z);
	$cz = cplx($cz, 0) if !ref $cz && $cz < 0;	# Force complex if <0
	return log($cz) / 2;
}

#
# acotanh
#
# Computes the arc hyperbolic cotangent acotanh(z) = 1/2 log((1+z) / (z-1)).
#
sub acotanh {
	my ($z) = @_;
	my $cz = (1 + $z) / ($z - 1);
	$cz = cplx($cz, 0) if !ref $cz && $cz < 0;	# Force complex if <0
	return log($cz) / 2;
}

#
# (atan2)
#
# Compute atan(z1/z2).
#
sub atan2 {
	my ($z1, $z2, $inverted) = @_;
	my ($re1, $im1) = @{$z1->cartesian};
	my ($re2, $im2) = ref $z2 ? @{$z2->cartesian} : ($z2);
	my $tan;
	if (defined $inverted && $inverted) {	# atan(z2/z1)
		return pi * ($re2 > 0 ? 1 : -1) if $re1 == 0 && $im1 == 0;
		$tan = $z2 / $z1;
	} else {
		return pi * ($re1 > 0 ? 1 : -1) if $re2 == 0 && $im2 == 0;
		$tan = $z1 / $z2;
	}
	return atan($tan);
}

#
# display_format
# ->display_format
#
# Set (fetch if no argument) display format for all complex numbers that
# don't happen to have overrriden it via ->display_format
#
# When called as a method, this actually sets the display format for
# the current object.
#
# Valid object formats are 'c' and 'p' for cartesian and polar. The first
# letter is used actually, so the type can be fully spelled out for clarity.
#
sub display_format {
	my $self = shift;
	my $format = undef;

	if (ref $self) {			# Called as a method
		$format = shift;
	} else {					# Regular procedure call
		$format = $self;
		undef $self;
	}

	if (defined $self) {
		return defined $self->{display} ? $self->{display} : $display
			unless defined $format;
		return $self->{display} = $format;
	}

	return $display unless defined $format;
	return $display = $format;
}

#
# (stringify)
#
# Show nicely formatted complex number under its cartesian or polar form,
# depending on the current display format:
#
# . If a specific display format has been recorded for this object, use it.
# . Otherwise, use the generic current default for all complex numbers,
#   which is a package global variable.
#
sub stringify {
	my ($z) = shift;
	my $format;

	$format = $display;
	$format = $z->{display} if defined $z->{display};

	return $z->stringify_polar if $format =~ /^p/i;
	return $z->stringify_cartesian;
}

#
# ->stringify_cartesian
#
# Stringify as a cartesian representation 'a+bi'.
#
sub stringify_cartesian {
	my $z  = shift;
	my ($x, $y) = @{$z->cartesian};
	my ($re, $im);

	$x = int($x + ($x < 0 ? -1 : 1) * 1e-14)
		if int(abs($x)) != int(abs($x) + 1e-14);
	$y = int($y + ($y < 0 ? -1 : 1) * 1e-14)
		if int(abs($y)) != int(abs($y) + 1e-14);

	$re = "$x" if abs($x) >= 1e-14;
	if ($y == 1)				{ $im = 'i' }
	elsif ($y == -1)			{ $im = '-i' }
	elsif (abs($y) >= 1e-14)	{ $im = $y . "i" }

	my $str;
	$str = $re if defined $re;
	$str .= "+$im" if defined $im;
	$str =~ s/\+-/-/;
	$str =~ s/^\+//;
	$str = '0' unless $str;

	return $str;
}

#
# ->stringify_polar
#
# Stringify as a polar representation '[r,t]'.
#
sub stringify_polar {
	my $z  = shift;
	my ($r, $t) = @{$z->polar};
	my $theta;

	return '[0,0]' if $r <= 1e-14;

	my $tpi = 2 * pi;
	my $nt = $t / $tpi;
	$nt = ($nt - int($nt)) * $tpi;
	$nt += $tpi if $nt < 0;			# Range [0, 2pi]

	if (abs($nt) <= 1e-14)			{ $theta = 0 }
	elsif (abs(pi-$nt) <= 1e-14) 	{ $theta = 'pi' }

	if (defined $theta) {
		$r = int($r + ($r < 0 ? -1 : 1) * 1e-14)
			if int(abs($r)) != int(abs($r) + 1e-14);
		$theta = int($theta + ($theta < 0 ? -1 : 1) * 1e-14)
			if int(abs($theta)) != int(abs($theta) + 1e-14);
		return "\[$r,$theta\]";
	}

	#
	# Okay, number is not a real. Try to identify pi/n and friends...
	#

	$nt -= $tpi if $nt > pi;
	my ($n, $k, $kpi);
	
	for ($k = 1, $kpi = pi; $k < 10; $k++, $kpi += pi) {
		$n = int($kpi / $nt + ($nt > 0 ? 1 : -1) * 0.5);
		if (abs($kpi/$n - $nt) <= 1e-14) {
			$theta = ($nt < 0 ? '-':'').($k == 1 ? 'pi':"${k}pi").'/'.abs($n);
			last;
		}
	}

	$theta = $nt unless defined $theta;

	$r = int($r + ($r < 0 ? -1 : 1) * 1e-14)
		if int(abs($r)) != int(abs($r) + 1e-14);
	$theta = int($theta + ($theta < 0 ? -1 : 1) * 1e-14)
		if int(abs($theta)) != int(abs($theta) + 1e-14);

	return "\[$r,$theta\]";
}

1;
__END__

=head1 NAME

Math::Complex - complex numbers and associated mathematical functions

=head1 SYNOPSIS

	use Math::Complex;
	$z = Math::Complex->make(5, 6);
	$t = 4 - 3*i + $z;
	$j = cplxe(1, 2*pi/3);

=head1 DESCRIPTION

This package lets you create and manipulate complex numbers. By default,
I<Perl> limits itself to real numbers, but an extra C<use> statement brings
full complex support, along with a full set of mathematical functions
typically associated with and/or extended to complex numbers.

If you wonder what complex numbers are, they were invented to be able to solve
the following equation:

	x*x = -1

and by definition, the solution is noted I<i> (engineers use I<j> instead since
I<i> usually denotes an intensity, but the name does not matter). The number
I<i> is a pure I<imaginary> number.

The arithmetics with pure imaginary numbers works just like you would expect
it with real numbers... you just have to remember that

	i*i = -1

so you have:

	5i + 7i = i * (5 + 7) = 12i
	4i - 3i = i * (4 - 3) = i
	4i * 2i = -8
	6i / 2i = 3
	1 / i = -i

Complex numbers are numbers that have both a real part and an imaginary
part, and are usually noted:

	a + bi

where C<a> is the I<real> part and C<b> is the I<imaginary> part. The
arithmetic with complex numbers is straightforward. You have to
keep track of the real and the imaginary parts, but otherwise the
rules used for real numbers just apply:

	(4 + 3i) + (5 - 2i) = (4 + 5) + i(3 - 2) = 9 + i
	(2 + i) * (4 - i) = 2*4 + 4i -2i -i*i = 8 + 2i + 1 = 9 + 2i

A graphical representation of complex numbers is possible in a plane
(also called the I<complex plane>, but it's really a 2D plane).
The number

	z = a + bi

is the point whose coordinates are (a, b). Actually, it would
be the vector originating from (0, 0) to (a, b). It follows that the addition
of two complex numbers is a vectorial addition.

Since there is a bijection between a point in the 2D plane and a complex
number (i.e. the mapping is unique and reciprocal), a complex number
can also be uniquely identified with polar coordinates:

	[rho, theta]

where C<rho> is the distance to the origin, and C<theta> the angle between
the vector and the I<x> axis. There is a notation for this using the
exponential form, which is:

	rho * exp(i * theta)

where I<i> is the famous imaginary number introduced above. Conversion
between this form and the cartesian form C<a + bi> is immediate:

	a = rho * cos(theta)
	b = rho * sin(theta)

which is also expressed by this formula:

	z = rho * exp(i * theta) = rho * (cos theta + i * sin theta) 

In other words, it's the projection of the vector onto the I<x> and I<y>
axes. Mathematicians call I<rho> the I<norm> or I<modulus> and I<theta>
the I<argument> of the complex number. The I<norm> of C<z> will be
noted C<abs(z)>.

The polar notation (also known as the trigonometric
representation) is much more handy for performing multiplications and
divisions of complex numbers, whilst the cartesian notation is better
suited for additions and substractions. Real numbers are on the I<x>
axis, and therefore I<theta> is zero.

All the common operations that can be performed on a real number have
been defined to work on complex numbers as well, and are merely
I<extensions> of the operations defined on real numbers. This means
they keep their natural meaning when there is no imaginary part, provided
the number is within their definition set.

For instance, the C<sqrt> routine which computes the square root of
its argument is only defined for positive real numbers and yields a
positive real number (it is an application from B<R+> to B<R+>).
If we allow it to return a complex number, then it can be extended to
negative real numbers to become an application from B<R> to B<C> (the
set of complex numbers):

	sqrt(x) = x >= 0 ? sqrt(x) : sqrt(-x)*i

It can also be extended to be an application from B<C> to B<C>,
whilst its restriction to B<R> behaves as defined above by using
the following definition:

	sqrt(z = [r,t]) = sqrt(r) * exp(i * t/2)

Indeed, a negative real number can be noted C<[x,pi]>
(the modulus I<x> is always positive, so C<[x,pi]> is really C<-x>, a
negative number)
and the above definition states that

	sqrt([x,pi]) = sqrt(x) * exp(i*pi/2) = [sqrt(x),pi/2] = sqrt(x)*i

which is exactly what we had defined for negative real numbers above.

All the common mathematical functions defined on real numbers that
are extended to complex numbers share that same property of working
I<as usual> when the imaginary part is zero (otherwise, it would not
be called an extension, would it?).

A I<new> operation possible on a complex number that is
the identity for real numbers is called the I<conjugate>, and is noted
with an horizontal bar above the number, or C<~z> here.

	 z = a + bi
	~z = a - bi

Simple... Now look:

	z * ~z = (a + bi) * (a - bi) = a*a + b*b

We saw that the norm of C<z> was noted C<abs(z)> and was defined as the
distance to the origin, also known as:

	rho = abs(z) = sqrt(a*a + b*b)

so

	z * ~z = abs(z) ** 2

If z is a pure real number (i.e. C<b == 0>), then the above yields:

	a * a = abs(a) ** 2

which is true (C<abs> has the regular meaning for real number, i.e. stands
for the absolute value). This example explains why the norm of C<z> is
noted C<abs(z)>: it extends the C<abs> function to complex numbers, yet
is the regular C<abs> we know when the complex number actually has no
imaginary part... This justifies I<a posteriori> our use of the C<abs>
notation for the norm.

=head1 OPERATIONS

Given the following notations:

	z1 = a + bi = r1 * exp(i * t1)
	z2 = c + di = r2 * exp(i * t2)
	z = <any complex or real number>

the following (overloaded) operations are supported on complex numbers:

	z1 + z2 = (a + c) + i(b + d)
	z1 - z2 = (a - c) + i(b - d)
	z1 * z2 = (r1 * r2) * exp(i * (t1 + t2))
	z1 / z2 = (r1 / r2) * exp(i * (t1 - t2))
	z1 ** z2 = exp(z2 * log z1)
	~z1 = a - bi
	abs(z1) = r1 = sqrt(a*a + b*b)
	sqrt(z1) = sqrt(r1) * exp(i * t1/2)
	exp(z1) = exp(a) * exp(i * b)
	log(z1) = log(r1) + i*t1
	sin(z1) = 1/2i (exp(i * z1) - exp(-i * z1))
	cos(z1) = 1/2 (exp(i * z1) + exp(-i * z1))
	abs(z1) = r1
	atan2(z1, z2) = atan(z1/z2)

The following extra operations are supported on both real and complex
numbers:

	Re(z) = a
	Im(z) = b
	arg(z) = t

	cbrt(z) = z ** (1/3)
	log10(z) = log(z) / log(10)
	logn(z, n) = log(z) / log(n)

	tan(z) = sin(z) / cos(z)
	cotan(z) = 1 / tan(z)

	asin(z) = -i * log(i*z + sqrt(1-z*z))
	acos(z) = -i * log(z + sqrt(z*z-1))
	atan(z) = i/2 * log((i+z) / (i-z))
	acotan(z) = -i/2 * log((i+z) / (z-i))

	sinh(z) = 1/2 (exp(z) - exp(-z))
	cosh(z) = 1/2 (exp(z) + exp(-z))
	tanh(z) = sinh(z) / cosh(z)
	cotanh(z) = 1 / tanh(z)
	
	asinh(z) = log(z + sqrt(z*z+1))
	acosh(z) = log(z + sqrt(z*z-1))
	atanh(z) = 1/2 * log((1+z) / (1-z))
	acotanh(z) = 1/2 * log((1+z) / (z-1))

The I<root> function is available to compute all the I<n>th
roots of some complex, where I<n> is a strictly positive integer.
There are exactly I<n> such roots, returned as a list. Getting the
number mathematicians call C<j> such that:

	1 + j + j*j = 0;

is a simple matter of writing:

	$j = ((root(1, 3))[1];

The I<k>th root for C<z = [r,t]> is given by:

	(root(z, n))[k] = r**(1/n) * exp(i * (t + 2*k*pi)/n)

The I<spaceshift> operation is also defined. In order to ensure its
restriction to real numbers is conform to what you would expect, the
comparison is run on the real part of the complex number first,
and imaginary parts are compared only when the real parts match. 

=head1 CREATION

To create a complex number, use either:

	$z = Math::Complex->make(3, 4);
	$z = cplx(3, 4);

if you know the cartesian form of the number, or

	$z = 3 + 4*i;

if you like. To create a number using the trigonometric form, use either:

	$z = Math::Complex->emake(5, pi/3);
	$x = cplxe(5, pi/3);

instead. The first argument is the modulus, the second is the angle (in radians).
(Mnmemonic: C<e> is used as a notation for complex numbers in the trigonometric
form).

It is possible to write:

	$x = cplxe(-3, pi/4);

but that will be silently converted into C<[3,-3pi/4]>, since the modulus
must be positive (it represents the distance to the origin in the complex
plane).

=head1 STRINGIFICATION

When printed, a complex number is usually shown under its cartesian
form I<a+bi>, but there are legitimate cases where the polar format
I<[r,t]> is more appropriate.

By calling the routine C<Math::Complex::display_format> and supplying either
C<"polar"> or C<"cartesian">, you override the default display format,
which is C<"cartesian">. Not supplying any argument returns the current
setting.

This default can be overridden on a per-number basis by calling the
C<display_format> method instead. As before, not supplying any argument
returns the current display format for this number. Otherwise whatever you
specify will be the new display format for I<this> particular number.

For instance:

	use Math::Complex;

	Math::Complex::display_format('polar');
	$j = ((root(1, 3))[1];
	print "j = $j\n";		# Prints "j = [1,2pi/3]
	$j->display_format('cartesian');
	print "j = $j\n";		# Prints "j = -0.5+0.866025403784439i"

The polar format attempts to emphasize arguments like I<k*pi/n>
(where I<n> is a positive integer and I<k> an integer within [-9,+9]).

=head1 USAGE

Thanks to overloading, the handling of arithmetics with complex numbers
is simple and almost transparent.

Here are some examples:

	use Math::Complex;

	$j = cplxe(1, 2*pi/3);	# $j ** 3 == 1
	print "j = $j, j**3 = ", $j ** 3, "\n";
	print "1 + j + j**2 = ", 1 + $j + $j**2, "\n";

	$z = -16 + 0*i;			# Force it to be a complex
	print "sqrt($z) = ", sqrt($z), "\n";

	$k = exp(i * 2*pi/3);
	print "$j - $k = ", $j - $k, "\n";

=head1 BUGS

Saying C<use Math::Complex;> exports many mathematical routines in the caller
environment.  This is construed as a feature by the Author, actually... ;-)

The code is not optimized for speed, although we try to use the cartesian
form for addition-like operators and the trigonometric form for all
multiplication-like operators.

The arg() routine does not ensure the angle is within the range [-pi,+pi]
(a side effect caused by multiplication and division using the trigonometric
representation).

All routines expect to be given real or complex numbers. Don't attempt to
use BigFloat, since Perl has currently no rule to disambiguate a '+'
operation (for instance) between two overloaded entities.

=head1 AUTHOR

Raphael Manfredi <F<Raphael_Manfredi@grenoble.hp.com>>
