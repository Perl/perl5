package Math::Trig::Radial;

use strict;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT =
    qw(
       cartesian_to_cylindrical
       cartesian_to_spherical
       cylindrical_to_cartesian
       cylindrical_to_spherical
       spherical_to_cartesian
       spherical_to_cylindrical
       great_circle_distance
      );

use Math::Trig;

sub pip2 { pi/2 }

=pod

=head1 NAME

Math::Trig::Radial - spherical and cylindrical trigonometry

=head1 SYNOPSIS

    use Math::Trig::Radial;

    ($rho, $theta, $z)     = cartesian_to_cylindrical($x, $y, $z);
    ($rho, $theta, $phi)   = cartesian_to_spherical($x, $y, $z);
    ($x, $y, $z)           = cylindrical_to_cartesian($rho, $theta, $z);
    ($rho_s, $theta, $phi) = cylindrical_to_spherical($rho_c, $theta, $z);
    ($x, $y, $z)           = spherical_to_cartesian($rho, $theta, $phi);
    ($rho_c, $theta, $z)   = spherical_to_cylindrical($rho_s, $theta, $phi);

=head1 DESCRIPTION

This module contains a few basic spherical and cylindrical
trigonometric formulas.  B<All angles are in radians>, if needed
use C<Math::Trig> angle unit conversions.

=head2 COORDINATE SYSTEMS

B<Cartesian> coordinates are the usual rectangular I<xyz>-coordinates.

Spherical coordinates are three-dimensional coordinates which define a
point in three-dimensional space.  They are based on a sphere surface.
The radius of the sphere is B<rho>, also known as the I<radial>
coordinate.  The angle in the I<xy>-plane (around the I<z>-axis) is
B<theta>, also known as the I<azimuthal> coordinate.  The angle from
the I<z>-axis is B<phi>, also known as the I<polar> coordinate.  The
`North Pole' is therefore I<0, 0, rho>, and the `Bay of Guinea' (think
Africa) I<0, pi/2, rho>.

Cylindrical coordinates are three-dimensional coordinates which define
a point in three-dimensional space.  They are based on a cylinder
surface.  The radius of the cylinder is B<rho>, also known as the
I<radial> coordinate.  The angle in the I<xy>-plane (around the
I<z>-axis) is B<theta>, also known as the I<azimuthal> coordinate.
The third coordinate is the I<z>.

=head2 CONVERSIONS

Conversions to and from spherical and cylindrical coordinates are
available.  Please notice that the conversions are not necessarily
reversible because of the equalities like I<pi> angles equals I<-pi>
angles.

=over 4

=item cartesian_to_cylindrical

	($rho, $theta, $z) = cartesian_to_cylindrical($x, $y, $z);

=item cartesian_to_spherical

	($rho, $theta, $phi) = cartesian_to_spherical($x, $y, $z);

=item cylindrical_to_cartesian

	($x, $y, $z) = cylindrical_to_cartesian($rho, $theta, $z);

=item cylindrical_to_spherical

	($rho_s, $theta, $phi) = cylindrical_to_spherical($rho_c, $theta, $z);

Notice that when C<$z> is not 0 C<$rho_s> is not equal to C<$rho_c>.

=item spherical_to_cartesian

	($x, $y, $z) = spherical_to_cartesian($rho, $theta, $phi);

=item spherical_to_cylindrical

	($rho_c, $theta, $z) = spherical_to_cylindrical($rho_s, $theta, $phi);

Notice that when C<$z> is not 0 C<$rho_c> is not equal to C<$rho_s>.

=back

=head2 GREAT CIRCLE DISTANCE

    $distance = great_circle_distance($x0, $y0, $z0, $x1, $y1, $z1 [, $rho]);

The I<great circle distance> is the shortest distance between two
points on a sphere.  The distance is in C<$rho> units.  The C<$rho> is
optional, it defaults to 1 (the unit sphere), therefore the distance
defaults to radians.  The coordinates C<$x0> ... C<$z1> are in
cartesian coordinates.

=head EXAMPLES

To calculate the distance between London (51.3N 0.5W) and Tokyo (35.7N
139.8E) in kilometers:

	use Math::Trig::Radial;
	use Math::Trig;

	my @L = spherical_to_cartesian(1, map { deg2rad $_ } qw(51.3  -0.5));
	my @T = spherical_to_cartesian(1, map { deg2rad $_ } qw(35.7 139.8));

	$km = great_circle_distance(@L, @T, 6378);

The answer may be off by up to 0.3% because of the irregular (slightly
aspherical) form of the Earth.

=head2 AUTHOR

Jarkko Hietaniemi F<E<lt>jhi@iki.fiE<gt>>

=cut

sub cartesian_to_spherical {
    my ( $x, $y, $z ) = @_;

    my $rho = sqrt( $x * $x + $y * $y + $z * $z );

    return ( $rho,
	     atan2( $y, $x ),
	     $rho ? acos( $z / $rho ) : 0 );
}

sub spherical_to_cartesian {
    my ( $rho, $theta, $phi ) = @_;

    return ( $rho * cos( $theta ) * sin( $phi ),
	     $rho * sin( $theta ) * sin( $phi ),
	     $rho * cos( $phi   ) );
}

sub spherical_to_cylindrical {
    my ( $x, $y, $z ) = spherical_to_cartesian( @_ );

    return ( sqrt( $x * $x + $y * $y ), $_[1], $z );
}

sub cartesian_to_cylindrical {
    my ( $x, $y, $z ) = @_;

    return ( sqrt( $x * $x + $y * $y ), atan2( $y, $x ), $z );
}

sub cylindrical_to_cartesian {
    my ( $rho, $theta, $z ) = @_;

    return ( $rho * cos( $theta ), $rho * sin( $theta ), $z );
}

sub cylindrical_to_spherical {
    return ( cartesian_to_spherical( cylindrical_to_cartesian( @_ ) ) );
}

sub great_circle_distance {
    my ( $x0, $y0, $z0, $x1, $y1, $z1, $rho ) = @_;

    $rho = 1 unless defined $rho; # Default to the unit sphere.

    my ( $r0, $theta0, $phi0 ) = cartesian_to_spherical( $x0, $y0, $z0 );
    my ( $r1, $theta1, $phi1 ) = cartesian_to_spherical( $x1, $y1, $z1 );

    my $lat0 = pip2 - $phi0;
    my $lat1 = pip2 - $phi1;

    return $rho *
	acos(cos( $lat0 ) * cos( $lat1 ) * cos( $theta0 - $theta1 ) +
	     sin( $lat0 ) * sin( $lat1 ) );
}

1;

