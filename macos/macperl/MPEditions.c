/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPEditions.c	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPEditions.c,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:57:54  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:39  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:50:54  neeri
Fix segment names.

Revision 1.1  1994/02/27  23:00:31  neeri
Initial revision

Revision 0.3  1993/09/18  00:00:00  neeri
Runtime

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <OSUtils.h>
#include <Resources.h>
#include <Errors.h>
#include <AppleEvents.h>

#include "MPEditions.h"

/**-----------------------------------------------------------------------
		Name: 		KeyOKinSubscriber
		Purpose:		Detects arrow keys.
 -----------------------------------------------------------------------**/
#define kChLeft	28
#define kChRight	29
#define kChUp		30
#define kChDown	31

#if !defined(powerc) && !defined(__powerc)
#pragma segment Editions
#endif

pascal Boolean KeyOKinSubscriber(char whatKey)
{
	return( 	(whatKey==kChUp) 
		|| 	(whatKey==kChDown) 
		|| 	(whatKey==kChLeft) 
		|| 	(whatKey==kChRight));
} /*KeyOKinSubscriber*/

/**-----------------------------------------------------------------------
Name: 		GetHandleToText
Purpose:		Get a handle to the current text selection.
				Used to provide a preview on Create Publisher...
-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Editions
#endif

pascal Handle GetHandleToText(TEHandle aTEHandle, short theStart, short theEnd)
{
	OSErr     err;
	Handle    myHandle;
	Ptr       p;

	HLock((*aTEHandle)->hText);
	p  = *((*aTEHandle)->hText);
	p  += theStart;
	err = PtrToHand(p, &myHandle, (theEnd - theStart));
	HUnlock((*aTEHandle)->hText);
	return(myHandle);
} /* GetHandleToText */

/**-----------------------------------------------------------------------
		Name: 		FindLine
		Purpose:		Find the line a character is in.
						Used to find to calculate the region to use for the Publisher/
						Subscriber borders.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Editions
#endif

pascal short FindLine(short thePos,TEHandle theTEHandle)
{
	short    index;
	short    theFirstPos;
	short    theNextPos;

	index = 0;

	do {
		theFirstPos = (*theTEHandle)->lineStarts[index];
		theNextPos  = (*theTEHandle)->lineStarts[index + 1];
		index++;
	} while (! (((thePos >= theFirstPos) && (thePos < theNextPos)) ||
					(index > (*theTEHandle)->nLines)));

	return(index);
}

