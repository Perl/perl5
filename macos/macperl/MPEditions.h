/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPEditions.h	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPEditions.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:57:55  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:41  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:03:07  neeri
Initial revision

Revision 0.2  1993/09/16  00:00:00  neeri
Runtime doesn't support Editions

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <Types.h>
#include <QuickDraw.h>
#include <Files.h>
#include <Packages.h>
#include <Gestalt.h>
#include <Printing.h>

#ifndef __MPEDITIONS__
#define __MPEDITIONS__

#include "MPGlobals.h"
#include "MPUtils.h"

pascal Handle GetHandleToText(TEHandle aTEHandle, short theStart, short theEnd);

pascal Boolean KeyOKinSubscriber(char whatKey);

#endif