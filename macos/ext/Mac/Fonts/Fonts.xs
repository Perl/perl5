/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Fonts/Fonts.xs,v 1.2 2001/09/26 21:50:13 pudge Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Fonts.xs,v $
 * Revision 1.2  2001/09/26 21:50:13  pudge
 * Sync with perforce maint-5.6/macperl
 *
 * Revision 1.1  2000/08/14 03:39:30  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:52:23  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:41  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Fonts.h>

static Point	sUnityPoint = {1, 1};

MODULE = Mac::Fonts	PACKAGE = Mac::Fonts

=head2 Functions

=over 4

=item GetFontName FAMILY

Returns the name of a numbered font

=cut
Str255
GetFontName(familyID)
	short 	familyID
	CODE:
	GetFontName(familyID, RETVAL);
	OUTPUT:
	RETVAL

=item GetFNum NAME

Returns the number of a named font.

=cut
short
GetFNum(name)
	Str255 	name
	CODE:
	GetFNum(name, &RETVAL);
	OUTPUT:
	RETVAL

=item RealFont FONTNUM, SIZE

Returns whether a font with a certain ID and size really exists or has to be
interpolated.

=cut
Boolean
RealFont(fontNum, size)
	short 	fontNum
	short 	size

=item SetFScaleDisable DISABLE

Enable or disable scaling of fonts.

=cut
void
SetFScaleDisable(fscaleDisable)
	Boolean 	fscaleDisable

=item SetFractEnable ENABLE

Enable or disable fractional widths.

=cut
void
SetFractEnable(fractEnable)
	Boolean 	fractEnable

=item GetDefFontSize()

Get the current size of the system font if not set to 0. If the value is
set to 0 this function will return 12 as the font size.

=cut
short
GetDefFontSize()
		
=item IsOutline NUMER [, DENOM]

Returns whether a font is an outline font.

=cut
Boolean
IsOutline(numer, denom=sUnityPoint)
	Point numer
	Point denom

=item SetOutlinePreferred ENABLE

Set if an outline font should be chosen even if a bitmap font is available.

=cut
void
SetOutlinePreferred(outlinePreferred)
	Boolean 	outlinePreferred

=item GetOutlinePreferred

Returns the state of the outline flag.

=cut
Boolean
GetOutlinePreferred()

=item SetPreserveGlyph ENABLE

Set if glyphs are allowed to exceed the ascent and descent of the font.

=cut
void
SetPreserveGlyph(preserveGlyph)
	Boolean 	preserveGlyph

=item GetPreserveGlyph()

Get the value of the flag set with C<SetPreserveGlyph>.

=cut
Boolean
GetPreserveGlyph()

=item GetSysFont()

Get the ID of the system font.

=cut
short
GetSysFont()

=item GetAppFont()

Get the ID of the default application font.

=cut
short
GetAppFont()

=back

=cut
