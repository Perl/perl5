/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.1 1997/04/07 20:49:35 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <QDOffscreen.h>

MODULE = Mac::QDOffscreen	PACKAGE = Mac::QDOffscreen

=head2 Functions

=over 4

=item GWORLD = NewGWorld PIXELDEPTH, BOUNDS [, CTABLE [, GDEVICE [, FLAGS]]]

=cut
GWorldPtr
NewGWorld(PixelDepth, boundsRect, cTable=nil, aGDevice=nil, flags=0)
	short		PixelDepth
	Rect 		&boundsRect
	CTabHandle	cTable
	GDHandle	aGDevice
	long	flags
	CODE:
	gMacPerl_OSErr =
		NewGWorld(&RETVAL, PixelDepth, &boundsRect, cTable, aGDevice, flags);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

=item OK = LockPixels PIXMAP

=cut
Boolean
LockPixels(pm)
	PixMapHandle	pm

=item UnlockPixels PIXMAP

=cut
void
UnlockPixels(pm)
	PixMapHandle	pm

=item (FLAGS, GWORLD) = UpdateGWorld GWORLD, PIXELDEPTH, BOUNDS [, CTABLE [, GDEVICE [, FLAGS]]]

=cut
void
UpdateGWorld(offscreenGWorld, pixelDepth, boundsRect, cTable=nil, aGDevice=nil, flags=0)
	GWorldPtr  &offscreenGWorld
	short		pixelDepth
	Rect 	   &boundsRect
	CTabHandle	cTable
	GDHandle	aGDevice
	long	flags
	PPCODE:
	{
		long res = 
			UpdateGWorld(&offscreenGWorld, pixelDepth, &boundsRect, cTable, aGDevice, flags);
		EXTEND(sp, 2);
		XS_PUSH(short, res);
		XS_PUSH(GWorldPtr, offscreenGWorld);
	}

=item DisposeGWorld GWORLD

=cut
void
DisposeGWorld(offscreenGWorld)
	GWorldPtr	offscreenGWorld

=item (PORT, GDEV) = GetGWorld()

=cut
void
GetGWorld()
	PPCODE:
	{
		CGrafPtr	port;
		GDHandle	gdh;
		
		GetGWorld(&port, &gdh);
		EXTEND(sp, 2);
		XS_PUSH(GrafPtr,   port);
		XS_PUSH(GDHandle, gdh);
	}

=item SetGWorld PORT [, GDEV]

=cut
void
SetGWorld(port, gdh=nil)
	GrafPtr		port
	GDHandle	gdh
	CODE:
	SetGWorld((CGrafPtr)port, gdh);

=item PortChanged PORT

=cut
void
PortChanged(port)
	GrafPtr	port

=item AllowPurgePixels PIXMAP

=cut
void
AllowPurgePixels(pm)
	PixMapHandle	pm

=item NoPurgePixels PIXMAP

=cut
void
NoPurgePixels(pm)
	PixMapHandle	pm

=item STATE = GetPixelsState PIXMAP

=cut
long
GetPixelsState(pm)
	PixMapHandle	pm

=item SetPixelsState PIXMAP, STATE

=cut
void
SetPixelsState(pm, state)
	PixMapHandle	pm
	long	state

=item Ptr = GetPixBaseAddr PIXMAP

=cut
Ptr
GetPixBaseAddr(pm)
	PixMapHandle	pm

=item GDEV = GetGWorldDevice GWORLD

=cut
GDHandle
GetGWorldDevice(offscreenGWorld)
	GWorldPtr	offscreenGWorld

=item DONE = QDDone PORT

=cut
Boolean
QDDone(port)
	GrafPtr	port

=item VERSION = OffscreenVersion()

=cut
long
OffscreenVersion()

=item 32BIT = PixMap32Bit PIXMAP

=cut
Boolean
PixMap32Bit(pmHandle)
	PixMapHandle	pmHandle

=item PIXMAP = GetGWorldPixMap GWORLD

=cut
PixMapHandle
GetGWorldPixMap(offscreenGWorld)
	GWorldPtr	offscreenGWorld

=back

=cut
