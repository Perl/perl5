/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPAEUtils.c		-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPAEUtils.c,v $
Revision 1.1  2000/11/30 08:37:28  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:28  neeri
Checked into CVS

Revision 1.1  1994/02/27  22:59:32  neeri
Initial revision

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

#include "MPAEUtils.h"
#include "MPUtils.h"

#include <AERegistry.h>


/**-----------------------------------------------------------------------
	Utility Routines for getting data from AEDesc's
  -----------------------------------------------------------------------**/

pascal void GetRawDataFromDescriptor(
	const AEDesc *theDesc,
	Ptr     destPtr,
	Size    destMaxSize,
	Size    *actSize)
{
	Size copySize;

	if (theDesc->dataHandle) {
		HLock((Handle)theDesc->dataHandle);
		*actSize = GetHandleSize((Handle)theDesc->dataHandle);

		copySize = LesserOf(*actSize, destMaxSize);

		BlockMove(*theDesc->dataHandle, destPtr, copySize);

		HUnlock((Handle)theDesc->dataHandle);
	} else
		*actSize = 0;
} /*GetRawDataFromDescriptor*/

pascal OSErr GetPStringFromDescriptor(const AEDesc *sourceDesc, char *resultStr)
{
	OSErr		myErr;
	Size     stringSize;
	AEDesc   resultDesc;

	resultStr[0] = 0;

	if (myErr = AECoerceDesc(sourceDesc, typeChar, &resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)&resultStr[1], 255, &stringSize);

	if (stringSize<256)
		resultStr[0] = (char)stringSize;
	else
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
}

pascal OSErr GetIntegerFromDescriptor(const AEDesc *sourceDesc, short *result)
{
	OSErr   myErr;
	Size    intSize;
	AEDesc  resultDesc;

	*result = 0;

	if (myErr = AECoerceDesc(sourceDesc, typeShortInteger, &resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)result, 2, &intSize);
	if (intSize>2)
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
}

pascal OSErr GetBooleanFromDescriptor(const AEDesc *sourceDesc, Boolean *result)
{
	OSErr  myErr;
	Size   boolSize;
	AEDesc resultDesc;

	*result = false;

	if (myErr = AECoerceDesc(sourceDesc, typeBoolean,&resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)result, sizeof(Boolean), &boolSize);
	if (boolSize>sizeof(Boolean))
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
}

pascal OSErr GetLongIntFromDescriptor(const AEDesc *sourceDesc, long   *result)
{
	OSErr   myErr;
	Size    intSize;
	AEDesc  resultDesc;

	*result = 0;

	if (myErr = AECoerceDesc(sourceDesc, typeLongInteger, &resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)result, 4, &intSize);
	if (intSize>4)
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
} /*GetLongIntFromDescriptor*/

pascal OSErr GetRectFromDescriptor(const AEDesc *sourceDesc, Rect *result)
{
	OSErr   myErr;
	Size    rectSize;
	AEDesc  resultDesc;

	SetRect(result,0,0,0,0);

	if (myErr = AECoerceDesc(sourceDesc,typeQDRectangle,&resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)result, sizeof(Rect),  &rectSize);
	if (rectSize<sizeof(Rect))
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
} /*GetRectFromDescriptor*/

pascal OSErr GetPointFromDescriptor(const AEDesc *sourceDesc, Point  *result)
{
	OSErr   myErr;
	Size    ptSize;
	AEDesc  resultDesc;

	SetPt(result,0,0);

	if (myErr = AECoerceDesc(sourceDesc,typeQDPoint,&resultDesc))
		return myErr;

	GetRawDataFromDescriptor(&resultDesc, (Ptr)result, sizeof(Point), &ptSize);
	if (ptSize<sizeof(Point))
		myErr = errAECoercionFail;

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
} /*GetPointFromDescriptor*/


/*
	Name:    PutStyledTextFromDescIntoTEHandle
	Purpose: Takes the text in an AEDesc containing typeIntlText and puts it in
	         a styled text edit record at the current insertion point.
					 Looks for typeIntlText, typeStyledText, typeChar in that order.
*/

pascal OSErr GetTextFromDescIntoTEHandle(const AEDesc *sourceTextDesc, TEHandle theHTE)
{
	AEDesc rawTextDesc;
	OSErr  myErr;

	if (myErr = AECoerceDesc(sourceTextDesc, typeChar, &rawTextDesc))
		return myErr;

	HLock((Handle)rawTextDesc.dataHandle);
	TEInsert((*rawTextDesc.dataHandle), GetHandleSize(rawTextDesc.dataHandle), theHTE);
	HUnlock((Handle)rawTextDesc.dataHandle);

	if (rawTextDesc.dataHandle)
		AEDisposeDesc(&rawTextDesc);

	return noErr;
}

