/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPAEUtils.h		-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPAEUtils.h,v $
Revision 1.1  2000/11/30 08:37:28  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:57:46  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:29  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:02:37  neeri
Initial revision

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/


#include <Types.h>
#include <QuickDraw.h>
#include <Packages.h>
#include <Gestalt.h>
#include <Printing.h>
#include <AppleEvents.h>
#include <ToolUtils.h>

#ifndef __MPAEUTILS__
#define __MPAEUTILS__

/**-----------------------------------------------------------------------
	Utility Routines for getting data from AEDesc's
  -----------------------------------------------------------------------**/

pascal void GetRawDataFromDescriptor(	const AEDesc *theDesc,
													Ptr     destPtr,
													Size    destMaxSize,
													Size    *actSize);

pascal OSErr GetPStringFromDescriptor(	const AEDesc *sourceDesc, char *resultStr);

pascal OSErr GetIntegerFromDescriptor(	const AEDesc *sourceDesc, short *result);

pascal OSErr GetBooleanFromDescriptor(	const AEDesc *sourceDesc,
													Boolean *result);

pascal OSErr GetLongIntFromDescriptor(	const AEDesc *sourceDesc,
                                      	long   *result);

pascal OSErr GetRectFromDescriptor(		const AEDesc *sourceDesc, Rect *result);

pascal OSErr GetPointFromDescriptor(	const AEDesc *sourceDesc,
													Point  *result);

pascal OSErr GetTextFromDescIntoTEHandle(
													const AEDesc *sourceTextDesc,
													TEHandle theHTE);

#endif