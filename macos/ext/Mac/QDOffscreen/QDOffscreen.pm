=head1 NAME

Mac::QDOffscreen - Macintosh Toolbox Interface to Offscreen QuickDraw

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::QDOffscreen;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		pixPurge
		noNewDevice
		useTempMem
		keepLocal
		pixelsPurgeable
		pixelsLocked
		mapPix
		newDepth
		alignPix
		newRowBytes
		reallocPix
		clipPix
		stretchPix
		ditherPix
		gwFlagErr
	
		NewGWorld
		LockPixels
		UnlockPixels
		UpdateGWorld
		DisposeGWorld
		GetGWorld
		SetGWorld
		PortChanged
		AllowPurgePixels
		NoPurgePixels
		GetPixelsState
		SetPixelsState
		GetPixBaseAddr
		GetGWorldDevice
		QDDone
		OffscreenVersion
		PixMap32Bit
		GetGWorldPixMap
	);
}

bootstrap Mac::QDOffscreen;

=head2 Constants

=over 4

=item pixPurge

=item noNewDevice

=item useTempMem

=item keepLocal

=item pixelsPurgeable

=item pixelsLocked

=item mapPix

=item newDepth

=item alignPix

=item newRowBytes

=item reallocPix

=item clipPix

=item stretchPix

=item ditherPix

=item gwFlagErr

C<GWorld> flags.

=cut
sub pixPurge ()                    { 1 << 0; }
sub noNewDevice ()                 { 1 << 1; }
sub useTempMem ()                  { 1 << 2; }
sub keepLocal ()                   { 1 << 3; }
sub pixelsPurgeable ()             { 1 << 6; }
sub pixelsLocked ()                { 1 << 7; }
sub mapPix ()                      { 1 << 16; }
sub newDepth ()                    { 1 << 17; }
sub alignPix ()                    { 1 << 18; }
sub newRowBytes ()                 { 1 << 19; }
sub reallocPix ()                  { 1 << 20; }
sub clipPix ()                     { 1 << 28; }
sub stretchPix ()                  { 1 << 29; }
sub ditherPix ()                   { 1 << 30; }
sub gwFlagErr ()                   { 1 << 31; }

=back

=head2 Types

=over 4

=cut
package GWorldPtr;

=item GWorldPtr

A pointer to an offscreen graphics world. Can used interchangeably where a 
C<GrafPtr> is asked for.

=cut
BEGIN {
	use vars qw(@ISA);
	
	@ISA = qw(GrafPtr);
}

=back

=include QDOffscreen.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
