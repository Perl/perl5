=head1 NAME

Mac::Fonts - Macintosh Toolbox Interface to Font Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut
	
use strict;
	
package Mac::Fonts;

BEGIN {
	use Exporter    ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		GetFontName
		GetFNum
		RealFont
		SetFScaleDisable
		SetFractEnable
		GetDefFontSize
		IsOutline
		SetOutlinePreferred
		GetOutlinePreferred
		SetPreserveGlyph
		GetPreserveGlyph
		GetSysFont
		GetAppFont
		
		systemFont
		applFont
		newYork
		geneva
		monaco
		helvetica
		courier
		symbol
		commandMark
		checkMark
		diamondMark
		appleMark
	);
	@EXPORT_OK = qw(
		times
	);
}

bootstrap Mac::Fonts;

=head2 Constants

=over 4

=item systemFont

=item applFont

=item newYork

=item geneva

=item monaco

=item times

=item helvetica

=item courier

=item symbol

Font IDs.

=cut
sub systemFont ()                  {          0; }
sub applFont ()                    {          1; }
sub newYork ()                     {          2; }
sub geneva ()                      {          3; }
sub monaco ()                      {          4; }
sub times ()                       {         20; }
sub helvetica ()                   {         21; }
sub courier ()                     {         22; }
sub symbol ()                      {         23; }


=item commandMark

=item checkMark

=item diamondMark

=item appleMark

Menu mark characters available in the system font.

=cut
sub commandMark ()                 {         17; }
sub checkMark ()                   {         18; }
sub diamondMark ()                 {         19; }
sub appleMark ()                   {         20; }

=back

=include Fonts.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

__END__
