#
# Trigonometric functions, mostly inherited from Math::Complex.
# -- Jarkko Hietaniemi, April 1997
#

require Exporter;
package Math::Trig;

use strict;

use Math::Complex qw(:trig);

use vars qw($VERSION $PACKAGE
	    @ISA
	    @EXPORT
	    $pi2 $DR $RD $DG $GD $RG $GR);

@ISA = qw(Exporter);

$VERSION = 1.00;

my @angcnv = qw(rad_to_deg rad_to_grad
	     deg_to_rad deg_to_grad
	     grad_to_rad grad_to_dec);

@EXPORT = (@{$Math::Complex::EXPORT_TAGS{'trig'}},
	   @angcnv);

sub pi2 () {
    $pi2 = 2 * pi unless ($pi2);
    $pi2;
}

sub DR () {
    $DR = pi2/360 unless ($DR);
    $DR;
}

sub RD () {
    $RD = 360/pi2 unless ($RD);
    $RD;
}

sub DG () {
    $DG = 400/360 unless ($DG);
    $DG;
}

sub GD () {
    $GD = 360/400 unless ($GD);
    $GD;
}

sub RG () {
    $RG = 400/pi2 unless ($RG);
    $RG;
}

sub GR () {
    $GR = pi2/400 unless ($GR);
    $GR;
}

#
# Truncating remainder.
#

sub remt ($$) {
    # Oh yes, POSIX::fmod() would be faster. Possibly. If it is available.
    $_[0] - $_[1] * int($_[0] / $_[1]);
}

#
# Angle conversions.
#

sub rad_to_deg ($) {
    remt(RD * $_[0], 360);
}

sub deg_to_rad ($) {
    remt(DR * $_[0], pi2);
}

sub grad_to_deg ($) {
    remt(GD * $_[0], 360);
}

sub deg_to_grad ($) {
    remt(DG * $_[0], 400);
}

sub rad_to_grad ($) {
    remt(RG * $_[0], 400);
}

sub grad_to_rad ($) {
    remt(GR * $_[0], pi2);
}

=head1 NAME

Math::Trig - trigonometric functions

=head1 SYNOPSIS

	use Math::Trig;
	
	$x = tan(0.9);
	$y = acos(3.7);
	$z = asin(2.4);
	
	$halfpi = pi/2;

	$rad = deg_to_rad(120);

=head1 DESCRIPTION

C<Math::Trig> defines many trigonometric functions not defined by the
core Perl (which defines only the C<sin()> and C<cos()>.  The constant
B<pi> is also defined as are a few convenience functions for angle
conversions.

=head1 TRIGONOMETRIC FUNCTIONS

The tangent

	tan

The cofunctions of the sine, cosine, and tangent (cosec/csc and cotan/cot
are aliases)

	csc cosec sec cot cotan

The arcus (also known as the inverse) functions of the sine, cosine,
and tangent

	asin acos atan

The principal value of the arc tangent of y/x

	atan2(y, x)

The arcus cofunctions of the sine, cosine, and tangent (acosec/acsc
and acotan/acot are aliases)

	acsc acosec asec acot acotan

The hyperbolic sine, cosine, and tangent

	sinh cosh tanh

The cofunctions of the hyperbolic sine, cosine, and tangent (cosech/csch
and cotanh/coth are aliases)

	csch cosech sech coth cotanh

The arcus (also known as the inverse) functions of the hyperbolic
sine, cosine, and tangent

	asinh acosh atanh

The arcus cofunctions of the hyperbolic sine, cosine, and tangent
(acsch/acosech and acoth/acotanh are aliases)

	acsch acosech asech acoth acotanh

The trigonometric constant B<pi> is also defined.

	$pi2 = 2 * pi;

=head2 SIMPLE ARGUMENTS, COMPLEX RESULTS

Please note that some of the trigonometric functions can break out
from the B<real axis> into the B<complex plane>. For example
C<asin(2)> has no definition for plain real numbers but it has
definition for complex numbers.

In Perl terms this means that supplying the usual Perl numbers (also
known as scalars, please see L<perldata>) as input for the
trigonometric functions might produce as output results that no more
are simple real numbers: instead they are complex numbers.

The C<Math::Trig> handles this by using the C<Math::Complex> package
which knows how to handle complex numbers, please see L<Math::Complex>
for more information. In practice you need not to worry about getting
complex numbers as results because the C<Math::Complex> takes care of
details like for example how to display complex numbers. For example:

	print asin(2), "\n";
    
should produce something like this (take or leave few last decimals):

	1.5707963267949-1.31695789692482i

That is, a complex number with the real part of approximately E<1.571>
and the imaginary part of approximately E<-1.317>.

=head1 ANGLE CONVERSIONS

(Plane, 2-dimensional) angles may be converted with the following functions.

	$radians  = deg_to_rad($degrees);
	$radians  = grad_to_rad($gradians);
	
	$degrees  = rad_to_deg($radians);
	$degrees  = grad_to_deg($gradians);
	
	$gradians = deg_to_grad($degrees);
	$gradians = rad_to_grad($radians);

The full circle is 2 B<pi> radians or E<360> degrees or E<400> gradians.

=head1

The following functions

	tan
	sec
	csc
	cot
	atan
	acot
	tanh
	sech
	csch
	coth
	atanh
	asech
	acsch
	acoth

cannot be computed for all arguments because that would mean dividing
by zero. These situations cause fatal runtime errors looking like this

	cot(0): Division by zero.
	(Because in the definition of cot(0), sin(0) is 0)
	Died at ...

=cut

# eof
