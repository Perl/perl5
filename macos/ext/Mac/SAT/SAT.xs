/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <QuickDraw.h>
#include <Icons.h>

#undef dirty

#include <SAT.h>

typedef struct {
	SATSprite	sprite;
	SV *		task;
	SV *		hitTask;
	SV *		destructTask;
} XSATSprite, *XSpritePtr;

static SpritePtr NewXSprite()
{
	return (SpritePtr)calloc(1, sizeof(XSATSprite));
}

static void DisposeXSprite(SpritePtr sp)
{
	XSpritePtr	sprite = (XSpritePtr)sp;
	sv_free(sprite->task);
	sv_free(sprite->hitTask);
	sv_free(sprite->destructTask);
	free(sprite);
}

typedef struct {
	Face	face;
	SV * 	redrawProc;
	SV *	drawProc;
} XSATFace, *XFacePtr;

static FacePtr NewXFace()
{
	return (FacePtr)calloc(1, sizeof(XSATFace));
}

static void DisposeXFace(FacePtr fa)
{
	XFacePtr	face = (XFacePtr)fa;
	sv_free(face->redrawProc);
	sv_free(face->drawProc);
	free(face);
}

static SV *	sSetupProc;
static SV *	sEmergencyProc;
static SV * sSynchProc;

#define	SATFace		FacePtr
#define SATSprite	SpritePtr
#define SATPort		SATPort *
#define SATGlobals	SATglobalsRec *

static void CallTask(SV * task, SATSprite sprite)
{
	if (SvTRUE(task)) {
		dSP ;
	
		PUSHMARK(sp) ;
		XS_XPUSH(SATSprite, sprite);
		PUTBACK ;
	
		perl_call_sv(task, G_DISCARD);
	}
}

static int CopySV(SV ** dest, SV * src)
{
	if (*dest)
		sv_setsv(*dest, src);
	else
		*dest = newSVsv(src);
	return SvTRUE(*dest);
}

static pascal void DestructProc(SATSprite sprite)
{
	CallTask(((XSpritePtr)sprite)->destructTask, sprite);
	DisposeXSprite(sprite);
}

static pascal void SetupProc(SATSprite sprite)
{
	sprite->destructTask = DestructProc;
	CallTask(sSetupProc, sprite);
}

static pascal Boolean SynchProc()
{
	Boolean res;
	
	dSP ;

	ENTER ;
	SAVETMPS;

	PUSHMARK(sp) ;

	perl_call_sv(sSynchProc, G_SCALAR|G_NOARGS);

	SPAGAIN ;

	res = SvTRUE(POPs);

	PUTBACK ;
	FREETMPS ;
	LEAVE ;
	
	return res;
}

static pascal void EmergencyProc()
{
	dSP ;

	PUSHMARK(sp) ;

	perl_call_sv(sEmergencyProc, G_DISCARD|G_NOARGS);
}

static pascal void RedrawProc(SATFace face, short depth)
{
	dSP ;

	PUSHMARK(sp) ;
	XS_XPUSH(SATFace, face);
	XS_XPUSH(short,   depth);
	PUTBACK ;

	perl_call_sv(((XFacePtr)face)->redrawProc, G_DISCARD);
}

static pascal void DrawProc(SATFace face, SATSprite sprite, SATPort port, Point srcPt, Point dstPt, short width, short height)
{
	dSP ;

	PUSHMARK(sp) ;
	XS_XPUSH(SATFace, 	face);
	XS_XPUSH(SATSprite, sprite);
	XS_XPUSH(SATPort,	port);
	XS_XPUSH(Point,		srcPt);
	XS_XPUSH(Point,		dstPt);
	XS_XPUSH(short,		width);
	XS_XPUSH(short,		height);
	PUTBACK ;

	perl_call_sv(((XFacePtr)face)->drawProc, G_DISCARD);
}

static pascal void TaskProc(SATSprite sprite)
{
	CallTask(((XSpritePtr)sprite)->task, sprite);
}

static pascal void HitTaskProc(SATSprite sprite, SATSprite other)
{
	dSP ;

	PUSHMARK(sp) ;
	XS_XPUSH(SATSprite, sprite);
	XS_XPUSH(SATSprite, other);
	PUTBACK ;

	perl_call_sv(((XSpritePtr)sprite)->hitTask, G_DISCARD);
}

MODULE = Mac::SAT	PACKAGE = Mac::SAT

=head2 Functions

=over 4

=cut
STRUCT * SATPort
	GrafPtr		port;
		READ_ONLY
	GDHandle	device;
		READ_ONLY
	Ptr			rows;
		READ_ONLY
	Rect		bounds;
		READ_ONLY
	Ptr			baseAddr;
		READ_ONLY
	short		rowBytes;
		READ_ONLY

STRUCT * SATFace
	short		resNum;
	BitMap		iconMask;
	short		rowBytes; 
		READ_ONLY
	SATFace		next;
	RgnHandle	maskRgn;
	Ptr			rows;
	Ptr			maskRows;
	SV *		redrawProc;
		INPUT:
		STRUCT->redrawProc = 
			CopySV(&((XFacePtr)STRUCT)->redrawProc, $arg) ? RedrawProc : nil;
		OUTPUT:
		sv_setsv($arg, ((XFacePtr)STRUCT)->redrawProc);
	SV *		drawProc;
		INPUT:
		STRUCT->drawProc = 
			CopySV(&((XFacePtr)STRUCT)->drawProc, $arg) ? DrawProc : nil;
		OUTPUT:
		sv_setsv($arg, ((XFacePtr)STRUCT)->drawProc);

STRUCT * SATSprite
	short		kind;
	Point		position;
	Rect		hotRect;
	SATFace		face;
	SV *		task;
		INPUT:
		STRUCT->task = 
			CopySV(&((XSpritePtr)STRUCT)->task, $arg) ? TaskProc : nil;
		OUTPUT:
		sv_setsv($arg, ((XSpritePtr)STRUCT)->task);
	SV *		hitTask;
		INPUT:
		STRUCT->hitTask = 
			CopySV(&((XSpritePtr)STRUCT)->hitTask, $arg) ? HitTaskProc : nil;
		OUTPUT:
		sv_setsv($arg, ((XSpritePtr)STRUCT)->hitTask);
	SV *		destructTask;
		INPUT:
		CopySV(&((XSpritePtr)STRUCT)->destructTask, $arg);
		OUTPUT:
		sv_setsv($arg, ((XSpritePtr)STRUCT)->destructTask);
	RgnHandle	clip; 	
	Boolean		dirty;
	short		layer;
	Point		speed;
	short		mode;
	Ptr			appPtr;
	long		appLong;

STRUCT * SATGlobals
	SATPort		wind;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(SATPort, &STRUCT->wind, $arg);
	short		offSizeH;
		READ_ONLY
	short		offSizeV;
		READ_ONLY
	SATPort		offScreen;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(SATPort, &STRUCT->offScreen, $arg);
	SATPort		backScreen;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(SATPort, &STRUCT->backScreen, $arg);
	short		initDepth;
	Boolean		anyMonsters;

SATGlobals
gSAT()
	CODE:
#ifdef __CFM68K__
	RETVAL = nil;
#else
	RETVAL = &gSAT;
#endif
	OUTPUT:
	RETVAL

void
SATConfigure(PICTfit, newSorting, newCollision, searchWidth)
	Boolean	PICTfit
	short	newSorting
	short	newCollision
	short	searchWidth

void
SATInit(pictID, bwpictID, Xsize, Ysize)
	short	pictID
	short	bwpictID
	short	Xsize
	short	Ysize

void
SATCustomInit(pictID, bwpictID, SATdrawingArea, preloadedWind, gd, useMenuBar, centerDrawingArea, fillScreen, dither4bit, beSmart)
	short		pictID
	short		bwpictID
	Rect 	   &SATdrawingArea
	GrafPtr		preloadedWind
	GDHandle	gd
	Boolean		useMenuBar
	Boolean		centerDrawingArea
	Boolean		fillScreen
	Boolean		dither4bit
	Boolean		beSmart

Boolean
SATDepthChangeTest()

void
SATDrawPICTs(pictID, bwpictID)
	short	pictID
	short	bwpictID

void
SATRedraw()

void
SATPlotFace(theFace, theGrafPtr, where, fast)
	SATFace	theFace
	SATPort	theGrafPtr
	Point	where
	Boolean fast

void
SATPlotFaceToScreen(theFace, where, fast)
	SATFace	theFace
	Point	where
	Boolean	fast

void
SATCopyBits(src, dest, srcRect, destRect, fast)
	SATPort		src
	SATPort		dest
	Rect	   &srcRect
	Rect	   &destRect
	Boolean		fast

void
SATCopyBitsToScreen(src, srcRect, destRect, fast)
	SATPort		src
	Rect	   &srcRect
	Rect	   &destRect
	Boolean		fast

void
SATBackChanged(r)
	Rect   &r

void
SATGetPort(port)
	SATPort	port

void
SATSetPort(port)
	SATPort	port

void
SATSetPortOffScreen()

void
SATSetPortBackScreen()

void
SATSetPortScreen()

SATFace
SATGetFace(resNum)
	short	resNum
	CODE:
	RETVAL = SATGetFacePP(resNum, (Ptr)NewXFace());
	OUTPUT:
	RETVAL

void
SATDisposeFace(theFace)
	SATFace	theFace
	CODE:
	SATDisposeFacePP(theFace);
	DisposeXFace(theFace);

SATSprite
SATNewSprite(kind, hpos, vpos, setup)
	short	kind
	short	hpos
	short	vpos
	SV *	setup
	CODE:
	sSetupProc = setup;
	RETVAL= SATNewSpritePP(nil, (Ptr)NewXSprite(), kind, hpos, vpos, SetupProc);
	OUTPUT:
	RETVAL

SATSprite
SATNewSpriteAfter(afterthis, kind, hpos, vpos, setup)
	SATSprite	afterthis
	short	kind
	short	hpos
	short	vpos
	SV *	setup
	CODE:
	sSetupProc = setup;
	RETVAL = SATNewSpritePP(afterthis, (Ptr)NewXSprite(), kind, hpos, vpos, SetupProc);
	OUTPUT:
	RETVAL

void
SATKillSprite(who)
	SATSprite	who

void
SATRun(fast)
	Boolean	fast

void
SATRun2(fast)
	Boolean	fast

void
SATInstallSynch(theSynchProc)
	SV *	theSynchProc
	CODE:
	SATInstallSynch(CopySV(&sSynchProc, theSynchProc) ? SynchProc : nil);

void
SATInstallEmergency(theEmergencyProc)
	SV *	theEmergencyProc
	CODE:
	SATInstallEmergency(
		CopySV(&sEmergencyProc, theEmergencyProc) ? EmergencyProc : nil);

void
SATSetSpriteRecSize(theSize)
	long	theSize

void
SATSkip()

void
SATKill()

void
SATWindMoved()

void
SATSetPortMask(theFace)
	SATFace	theFace

void
SATSetPortFace(theFace)
	SATFace	theFace

void
SATSetPortFace2(theFace)
	SATFace	theFace

SATFace
SATNewFace(FaceBounds)
	Rect   &FaceBounds

void
SATChangedFace(theFace)
	SATFace	theFace

void
SATSafeRectBlit(srcPort, dstPort, r)
	SATPort	srcPort
	SATPort	dstPort
	Rect   &r

void
SATSafeMaskBlit(face, theSprite, dstPort, srcPt, dstPt, width, height)
	SATFace		face
	SATSprite	theSprite
	SATPort		dstPort
	Point		srcPt
	Point		dstPt
	short		width
	short		height

void
SATCopySprite(destSprite, srcSprite)
	SATSprite	destSprite
	SATSprite	srcSprite

void
SATCopyFace(destFace, srcFace)
	SATFace	destFace
	SATFace	srcFace

CIconHandle
SATGetCicn(cicnId)
	short	cicnId

void
SATPlotCicn(theCicn, dest, destGD, r)
	CIconHandle	theCicn
	GrafPtr		dest
	GDHandle	destGD
	Rect	   &r

void
SATDisposeCicn(theCicn)
	CIconHandle	theCicn

void
SATSetStrings(ok, yes, no, quit, memerr, noscreen, nopict, nowind)
	Str255	ok
	Str255	yes
	Str255	no
	Str255	quit
	Str255	memerr
	Str255	noscreen
	Str255	nopict
	Str255	nowind

Boolean
SATTrapAvailable(theTrap)
	short	theTrap

void
SATDrawInt(i)
	short	i

void
SATDrawLong(l)
	long	l

short
SATRand(n)
	short	n

short
SATRand10()
		

short
SATRand100()
		

void
SATReportStr(str)
	Str255	str

Boolean
SATQuestionStr(str)
	Str255	str

void
CheckNoMem(p)
	Ptr	p

short
SATFakeAlert(s1, s2, s3, s4, nButtons, defButton, cancelButton, t1, t2, t3)
	Str255	s1
	Str255	s2
	Str255	s3
	Str255	s4
	short	nButtons
	short	defButton
	short	cancelButton
	Str255	t1
	Str255	t2
	Str255	t3

void
SATSetMouse(where)
	Point	where

void
SATInitToolbox()
		

void
SATGetVersion(versionString)
	Str255	versionString

void
SATPenPat(SATpat)
	SATPatHandle	SATpat

void
SATBackPat(SATpat)
	SATPatHandle	SATpat

SATPatHandle
SATGetPat(patID)
	short	patID

void
SATDisposePat(SATpat)
	SATPatHandle	SATpat

void
SATShowMBar(wind)
	GrafPtr	wind

void
SATHideMBar(wind)
	GrafPtr	wind

void
SATGetandDrawPICTRes(id)
	short	id

void
SATGetandDrawPICTResInRect(id, frame)
	short	id
	Rect   &frame

void
SATGetandCenterPICTResInRect(id, frame)
	short	id
	Rect   &frame

void
SATSoundPlay(theSound, priority, canWait)
	Handle	theSound
	short	priority
	Boolean	canWait

void
SATSoundShutup()

void
SATSoundEvents()

Boolean
SATSoundDone()

Handle
SATGetSound(sndID)
	short	sndID

Handle
SATGetNamedSound(name)
	Str255	name

void
SATDisposeSound(theSnd)
	Handle	theSnd

void
SATSoundOn()

void
SATSoundOff()

short
SATSoundInitChannels(num)
	short	num

Boolean
SATSoundDoneChannel(chanNum)
	short	chanNum

void
SATSoundPlayChannel(theSound, chanNum)
	Handle	theSound
	short	chanNum

void
SATSoundReserveChannel(chanNum, reserve)
	short	chanNum
	Boolean	reserve

void
SATSoundShutupChannel(chanNum)
	short	chanNum

void
SATPreloadChannels()

void
SATSoundPlay2(theSound, priority, canWait, skipIfSame)
	Handle	theSound
	short	priority
	Boolean	canWait
	Boolean	skipIfSame

void
SATSoundPlayEasy(theSound, canWait)
	Handle	theSound
	Boolean	canWait

int
SATGetNumChannels()

Ptr
SATGetChannel(chanNum)
	int	chanNum

void
SATSetSoundInitParams(params)
	long	params

void
SATSoundPlayVolume(theSound, priority, canWait, skipIfSame, volume)
	Handle	theSound
	short	priority
	Boolean	canWait
	Boolean	skipIfSame
	Point	volume

void
SATSoundFadeChannel(chanNum, volume)
	short	chanNum
	Point	volume

void
SATSoundLoop(firstSound, loopSound, chanNum)
	Handle	firstSound
	Handle	loopSound
	short	chanNum

Boolean
SATStepScroll(viewPoint, marginH, marginV, scrollSpeed)
	Point	viewPoint
	short	marginH
	short	marginV
	short	scrollSpeed

=back

=cut
