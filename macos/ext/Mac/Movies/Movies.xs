/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.1 1997/04/07 20:49:35 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.1  1997/04/07 20:49:35  neeri
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Movies.h>

typedef EventRecord	* ToolboxEvent;
typedef short		  Fix16;

static TimeRecord	sNoZero;

#ifndef __CFM68K__
#include <FixMath.h>
#else
#define fixed1				((Fixed) 0x00010000L)
#define fract1				((Fract) 0x40000000L)
#define positiveInfinity	((long)  0x7FFFFFFFL)
#define negativeInfinity	((long)  0x80000000L)

extern pascal long double Frac2X(Fract x) = 0xA845;
extern pascal long double Fix2X(Fixed x) = 0xA843;
extern pascal Fixed X2Fix(long double x) = 0xA844;
extern pascal Fract X2Frac(long double x) = 0xA846;
#endif

pascal Boolean ActionFilter(ComponentInstance mc, short *action, void *params)
{
	Boolean result;
	
	dSP ;

	ENTER ;
	SAVETMPS;

	PUSHMARK(sp) ;
	XS_XPUSH(ComponentInstance, 	mc);
	XS_XPUSH(short,				*action);
	switch (*action) {
	case mcActionIdle:
	case mcActionActivate:
	case mcActionDeactivate:
	case mcActionControllerSizeChanged:
		break;											/* No arguments */
	case mcActionDraw:
		XS_XPUSH(GrafPtr, (GrafPtr)params);				/* Window */
		break;					
	case mcActionMouseDown:
	case mcActionKey:
		XS_XPUSH(ToolboxEvent, (ToolboxEvent)params);	/* Event */
		break;	
	case mcActionPlay:
		XS_XPUSH(Fixed, (Fixed)params);					/* Fixed */
		break;
	case mcActionGoToTime:
	case mcActionSetSelectionBegin:
	case mcActionSetSelectionDuration:
		XS_XPUSH(TimeRecord, *(TimeRecord *)params);		/* TimeRecord */
		break;
	case mcActionSetVolume:
	case mcActionGetVolume:
		XS_XPUSH(Fix16, *(Fix16 *)params);				/* 16 bit fixed */
		break;
	case mcActionStep:
	case mcActionSetLooping:
	case mcActionSetLoopIsPalindrome:
	case mcActionSetKeysEnabled:
	case mcActionSetPlaySelection:
	case mcActionSetUseBadge:
	case mcActionSetFlags:
	case mcActionSetPlayEveryFrame:
	case mcActionSetCursorSettingEnabled:
		XS_XPUSH(long, (long)params);					/* long */
		break;
	case mcActionGetLooping:
	case mcActionGetLoopIsPalindrome:
	case mcActionGetKeysEnabled:
	case mcActionGetPlaySelection:
	case mcActionGetUseBadge:
	case mcActionGetPlayEveryFrame:
	case mcActionGetCursorSettingEnabled:
	case mcActionShowBalloon:
		XS_XPUSH(Boolean, *(Boolean *)params);			/* Ptr to Boolean */
		break;
	case mcActionGetFlags:
		XS_XPUSH(long, *(long *)params);					/* Ptr to long */
		break;
	case mcActionSetGrowBoxBounds:
		XS_XPUSH(Rect, *(Rect *)params);					/* Ptr to Rect */
		break;
	}
	PUTBACK ;

	perl_call_pv("Mac::Movies::_ActionFilter", G_SCALAR);

	SPAGAIN ;

	result = (Boolean)POPi;

	PUTBACK ;
	FREETMPS ;
	LEAVE ;
	
	return result;
}

#if TARGET_RT_MAC_CFM
static RoutineDescriptor	uActionFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppMCActionFilterProcInfo, ActionFilter);
#else
#define uActionFilter *(MCActionFilterUPP)&ActionFilter
#endif

MODULE = Mac::Movies	PACKAGE = Mac::Movies

=head2 Functions

=over 4

=item EnterMovies 

Start QuickTime processing.

=cut
MacOSRet
EnterMovies()

=item ExitMovies 

End QuickTime processing.

=cut
void
ExitMovies()

=item GetMoviesError()

=cut

=item GetMoviesError 

Get error value from last QuickTime call.

=cut
MacOSRet
GetMoviesError()

=item GetMoviesStickyError 

Get first error since last call of C<ClearMoviesStickyError>.

=cut
MacOSRet
GetMoviesStickyError()

=item ClearMoviesStickyError 

Clear sticky error.

=cut
void
ClearMoviesStickyError()

=begin ignore
void
SetMoviesErrorProc(errProc, refcon)
	MoviesErrorUPP	errProc
	long	refcon

=end ignore

=cut

=item MoviesTask [MOVIE [, MAXTIMETOUSE]]

Update a specified movie or all active movies.

=cut
void
MoviesTask(theMovie=nil, maxMilliSecToUse=5000)
	Movie	theMovie
	long	maxMilliSecToUse

=item PrerollMovie MOVIE, TIME [, RATE]

Prepare a portion of a movie for playback.

=cut
MacOSRet
PrerollMovie(theMovie, time, Rate=fixed1)
	Movie	theMovie
	long	time
	Fixed	Rate

=item LoadMovieIntoRam MOVIE, TIME, DURATION, FLAGS

Load a movie's data into memory.

=cut
MacOSRet
LoadMovieIntoRam(theMovie, time, duration, flags)
	Movie	theMovie
	long	time
	long	duration
	long	flags

=item LoadTrackIntoRam TRACK, TIME, DURATION, FLAGS

Load a track's data into memory.

=cut
MacOSRet
LoadTrackIntoRam(theTrack, time, duration, flags)
	Track	theTrack
	long	time
	long	duration
	long	flags

=item LoadMediaIntoRam MEDIA, TIME, DURATION, FLAGS

Load a media's data into memory.

=cut
MacOSRet
LoadMediaIntoRam(theMedia, time, duration, flags)
	Media	theMedia
	long	time
	long	duration
	long	flags

=item SetMovieActive MOVIE, ACTIVE

Activate or deactivate a movie.

=cut
void
SetMovieActive(theMovie, active)
	Movie	theMovie
	Boolean	active

=item GetMovieActive THEMOVIE 

Get activation state of a movie.

=cut
Boolean
GetMovieActive(theMovie)
	Movie	theMovie

=item StartMovie MOVIE

Start a movie.

=cut
void
StartMovie(theMovie)
	Movie	theMovie

=item StopMovie MOVIE

Stop a movie.

=cut
void
StopMovie(theMovie)
	Movie	theMovie

=item GoToBeginningOfMovie MOVIE

Rewind a movie.

=cut
void
GoToBeginningOfMovie(theMovie)
	Movie	theMovie

=item GoToEndOfMovie MOVIE

Go to the end of a movie.

=cut
void
GoToEndOfMovie(theMovie)
	Movie	theMovie

=item IsMovieDone THEMOVIE 

Check whether movie has finished playing.

=cut
Boolean
IsMovieDone(theMovie)
	Movie	theMovie

=item GetMoviePreviewMode THEMOVIE 

=cut
Boolean
GetMoviePreviewMode(theMovie)
	Movie	theMovie

=item SetMoviePreviewMode MOVIE, PREVIEW

Switch movie between preview tracks only and all tracks.

=cut
void
SetMoviePreviewMode(theMovie, usePreview)
	Movie	theMovie
	Boolean	usePreview

=item ShowMoviePoster MOVIE

Show poster view of movie.

=cut
void
ShowMoviePoster(theMovie)
	Movie	theMovie

=item PlayMoviePreview MOVIE

Play a preview of the movie.

=cut
void
PlayMoviePreview(theMovie, callOutProc=0, refcon=0)
	Movie	theMovie
	long	callOutProc
	long	refcon
	CODE:
	PlayMoviePreview(theMovie, 0, refcon);

=item GetMovieTimeBase THEMOVIE 

Returns the time base of a movie.

=cut
TimeBase
GetMovieTimeBase(theMovie)
	Movie	theMovie

=item SetMovieMasterTimeBase MOVIE, BASE [, SLAVEZERO]

Set the time base of a movie.

=cut
void
SetMovieMasterTimeBase(theMovie, tb, slaveZero=sNoZero)
	Movie		theMovie
	TimeBase	tb
	TimeRecord &slaveZero
	CODE:
	SetMovieMasterTimeBase(theMovie, tb, items == 3 ? &slaveZero : nil);

=item SetMovieMasterClock MOVIE, CLOCK [, SLAVEZERO]

Set the master clock component of a movie.

=cut
void
SetMovieMasterClock(theMovie, clockMeister, slaveZero=sNoZero)
	Movie		theMovie
	Component	clockMeister
	TimeRecord &slaveZero
	CODE:
	SetMovieMasterClock(theMovie, clockMeister, items == 3 ? &slaveZero : nil);

=item GetMovieGWorld THEMOVIE 

Get the graphics world of a movie.

	($port,$gdev) = GetMoviewGWorld($movie);

=cut
void
GetMovieGWorld(theMovie)
	Movie	theMovie
	PPCODE:
	{
		GrafPtr		port;
		GDHandle	gdh;
		
		GetMovieGWorld(theMovie, (CGrafPtr *)&port, &gdh);
		EXTEND(sp, 2);
		XS_PUSH(GrafPtr,   port);
		XS_PUSH(GWorldPtr, gdh);
	}


=item SetMovieGWorld THEMOVIE [, PORT [, GDH ]]

Set the graphics world for a movie.

=cut
void
SetMovieGWorld(theMovie, port=nil, gdh=nil)
	Movie		theMovie
	GrafPtr		port
	GDHandle	gdh
	CODE:
	SetMovieGWorld(theMovie, (CGrafPtr)port, gdh);

=begin ignore	
void
SetMovieDrawingCompleteProc(theMovie, flags, proc, refCon)
	Movie	theMovie
	long	flags
	MovieDrawingCompleteUPP	proc
	long	refCon

=end ignore

=cut

=item GetMovieNaturalBoundsRect MOVIE

Rect
GetMovieNaturalBoundsRect(theMovie)
	Movie	theMovie
	CODE:
	GetMovieNaturalBoundsRect(theMovie, &RETVAL);
	OUTPUT:
	RETVAL


=item GetNextTrackForCompositing THEMOVIE, THETRACK 

=cut
Track
GetNextTrackForCompositing(theMovie, theTrack)
	Movie	theMovie
	Track	theTrack


=item GetPrevTrackForCompositing THEMOVIE, THETRACK 

=cut
Track
GetPrevTrackForCompositing(theMovie, theTrack)
	Movie	theMovie
	Track	theTrack

=begin ignore
MacOSRet
SetMovieCompositeBufferFlags(theMovie, flags)
	Movie	theMovie
	long	flags

long
GetMovieCompositeBufferFlags(theMovie)
	Movie	theMovie
	CODE:
	gMacPerl_OSErr = GetMovieCompositeBufferFlags(theMovie, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

void
SetTrackGWorld(theTrack, port, gdh, proc, refCon)
	Track	theTrack
	CGrafPtr	port
	GDHandle	gdh
	TrackTransferUPP	proc
	long	refCon

=end ignore

=cut



=item GetMoviePict THEMOVIE, TIME 

Get a picture of a movie at some specified time.

=cut
PicHandle
GetMoviePict(theMovie, time)
	Movie	theMovie
	long	time


=item GetTrackPict THETRACK, TIME 

Get a picture of a track at some specified time.

=cut
PicHandle
GetTrackPict(theTrack, time)
	Track	theTrack
	long	time


=item GetMoviePosterPict THEMOVIE 

Get the poster picture of a movie.

=cut
PicHandle
GetMoviePosterPict(theMovie)
	Movie	theMovie


=item UpdateMovie THEMOVIE 

Update parts of a movie that need refreshing.

=cut
MacOSRet
UpdateMovie(theMovie)
	Movie	theMovie

=begin ignore
MacOSRet
InvalidateMovieRegion(theMovie, invalidRgn)
	Movie		theMovie
	RgnHandle	invalidRgn

=end ignore

=cut


=item GetMovieBox THEMOVIE 

Return a movie's boundary rectangle.

=cut
Rect
GetMovieBox(theMovie)
	Movie	theMovie
	CODE:
	GetMovieBox(theMovie, &RETVAL);
	OUTPUT:
	RETVAL


=item SetMovieBox THEMOVIE, BOXRECT 

Set the boundary rectangle for a movie.

=cut
void
SetMovieBox(theMovie, boxRect)
	Movie  theMovie
	Rect  &boxRect


=item GetMovieDisplayClipRgn THEMOVIE 

Get the display clip region for a movie.

=cut
RgnHandle
GetMovieDisplayClipRgn(theMovie)
	Movie	theMovie


=item SetMovieDisplayClipRgn THEMOVIE, THECLIP 

Set the display clip region for a movie.

=cut
void
SetMovieDisplayClipRgn(theMovie, theClip)
	Movie		theMovie
	RgnHandle	theClip


=item GetMovieClipRgn THEMOVIE 

Get the clipping region for a movie.

=cut
RgnHandle
GetMovieClipRgn(theMovie)
	Movie	theMovie


=item SetMovieClipRgn THEMOVIE, THECLIP 

Set the clipping region for a movie.

=cut
void
SetMovieClipRgn(theMovie, theClip)
	Movie		theMovie
	RgnHandle	theClip


=item GetTrackClipRgn THETRACK 

Get the clipping region for a track.

=cut
RgnHandle
GetTrackClipRgn(theTrack)
	Track	theTrack


=item SetTrackClipRgn THETRACK, THECLIP 

Set the clipping region for a track.

=cut
void
SetTrackClipRgn(theTrack, theClip)
	Track		theTrack
	RgnHandle	theClip


=item GetMovieDisplayBoundsRgn THEMOVIE 

=cut
RgnHandle
GetMovieDisplayBoundsRgn(theMovie)
	Movie	theMovie


=item GetTrackDisplayBoundsRgn THETRACK 

=cut
RgnHandle
GetTrackDisplayBoundsRgn(theTrack)
	Track	theTrack


=item GetMovieBoundsRgn THEMOVIE 

=cut
RgnHandle
GetMovieBoundsRgn(theMovie)
	Movie	theMovie


=item GetTrackMovieBoundsRgn THETRACK 

=cut
RgnHandle
GetTrackMovieBoundsRgn(theTrack)
	Track	theTrack


=item GetTrackBoundsRgn THETRACK 

=cut
RgnHandle
GetTrackBoundsRgn(theTrack)
	Track	theTrack


=item GetTrackMatte THETRACK 

=cut
PixMapHandle
GetTrackMatte(theTrack)
	Track	theTrack


=item SetTrackMatte THETRACK, THEMATTE 

=cut
void
SetTrackMatte(theTrack, theMatte)
	Track		theTrack
	PixMapHandle	theMatte


=item DisposeMatte THEMATTE 

=cut
void
DisposeMatte(theMatte)
	PixMapHandle	theMatte


=item NewMovie FLAGS 

Create a new movie.

=cut
Movie
NewMovie(flags)
	long	flags


=item PutMovieIntoHandle THEMOVIE, PUBLICMOVIE 

=cut
MacOSRet
PutMovieIntoHandle(theMovie, publicMovie)
	Movie	theMovie
	Handle	publicMovie

=begin ignore
MacOSRet
PutMovieIntoDataFork(theMovie, fRefNum, offset, maxSize)
	Movie	theMovie
	short	fRefNum
	long	offset
	long	maxSize

=end ignore

=cut



=item DisposeMovie THEMOVIE 

Delete a movie.

=cut
void
DisposeMovie(theMovie)
	Movie	theMovie


=item GetMovieCreationTime THEMOVIE 

=cut
long
GetMovieCreationTime(theMovie)
	Movie	theMovie


=item GetMovieModificationTime THEMOVIE 

=cut
long
GetMovieModificationTime(theMovie)
	Movie	theMovie


=item GetMovieTimeScale THEMOVIE 

=cut
long
GetMovieTimeScale(theMovie)
	Movie	theMovie


=item SetMovieTimeScale THEMOVIE, TIMESCALE 

=cut
void
SetMovieTimeScale(theMovie, timeScale)
	Movie		theMovie
	long		timeScale


=item GetMovieDuration THEMOVIE 

=cut
long
GetMovieDuration(theMovie)
	Movie	theMovie


=item GetMovieRate THEMOVIE 

=cut
Fixed
GetMovieRate(theMovie)
	Movie	theMovie


=item SetMovieRate THEMOVIE, RATE 

=cut
void
SetMovieRate(theMovie, rate)
	Movie	theMovie
	Fixed	rate


=item GetMoviePreferredRate THEMOVIE 

=cut
Fixed
GetMoviePreferredRate(theMovie)
	Movie	theMovie


=item SetMoviePreferredRate THEMOVIE, RATE 

=cut
void
SetMoviePreferredRate(theMovie, rate)
	Movie	theMovie
	Fixed	rate


=item GetMoviePreferredVolume THEMOVIE 

=cut
short
GetMoviePreferredVolume(theMovie)
	Movie	theMovie


=item SetMoviePreferredVolume THEMOVIE, VOLUME 

=cut
void
SetMoviePreferredVolume(theMovie, volume)
	Movie	theMovie
	short	volume


=item GetMovieVolume THEMOVIE 

=cut
short
GetMovieVolume(theMovie)
	Movie	theMovie


=item SetMovieVolume THEMOVIE, VOLUME 

=cut
void
SetMovieVolume(theMovie, volume)
	Movie	theMovie
	short	volume


=item GetMovieMatrix THEMOVIE 

=cut
MatrixRecord
GetMovieMatrix(theMovie)
	Movie	theMovie
	CODE:
	GetMovieMatrix(theMovie, &RETVAL);


=item SetMovieMatrix THEMOVIE, MATRIX 

=cut
void
SetMovieMatrix(theMovie, matrix)
	Movie			theMovie
	MatrixRecord &	matrix


=item GetMoviePreviewTime THEMOVIE 

=cut
void
GetMoviePreviewTime(theMovie)
	Movie	theMovie
	PPCODE:
	{
		long  previewTime;
		long  previewDuration;
		
		GetMoviePreviewTime(theMovie, &previewTime, &previewDuration);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(previewTime)));
		PUSHs(sv_2mortal(newSViv(previewDuration)));
	}


=item SetMoviePreviewTime THEMOVIE, PREVIEWTIME, PREVIEWDURATION 

=cut
void
SetMoviePreviewTime(theMovie, previewTime, previewDuration)
	Movie	theMovie
	long	previewTime
	long	previewDuration


=item GetMoviePosterTime THEMOVIE 

=cut
long
GetMoviePosterTime(theMovie)
	Movie	theMovie


=item SetMoviePosterTime THEMOVIE, POSTERTIME 

=cut
void
SetMoviePosterTime(theMovie, posterTime)
	Movie	theMovie
	long	posterTime


=item GetMovieSelection THEMOVIE 

=cut
void
GetMovieSelection(theMovie)
	Movie	theMovie
	PPCODE:
	{
		long  selectionTime;
		long  selectionDuration;
		
		GetMovieSelection(theMovie, &selectionTime, &selectionDuration);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(selectionTime)));
		PUSHs(sv_2mortal(newSViv(selectionDuration)));
	}


=item SetMovieSelection THEMOVIE, SELECTIONTIME, SELECTIONDURATION 

=cut
void
SetMovieSelection(theMovie, selectionTime, selectionDuration)
	Movie	theMovie
	long	selectionTime
	long	selectionDuration


=item SetMovieActiveSegment THEMOVIE, STARTTIME, DURATION 

=cut
void
SetMovieActiveSegment(theMovie, startTime, duration)
	Movie	theMovie
	long	startTime
	long	duration


=item GetMovieActiveSegment THEMOVIE 

=cut
void
GetMovieActiveSegment(theMovie)
	Movie	theMovie
	PPCODE:
	{
		long  startTime;
		long  duration;
		
		GetMovieActiveSegment(theMovie, &startTime, &duration);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(startTime)));
		PUSHs(sv_2mortal(newSViv(duration)));
	}


=item GetMovieTime THEMOVIE 

=cut
void
GetMovieTime(theMovie)
	Movie	theMovie
	PPCODE:
	{
		long		TV;
		TimeRecord	currentTime;
		
		TV = GetMovieTime(theMovie, &currentTime);
		EXTEND(sp, 2);
		XS_PUSH(long, TV);
		XS_PUSH(TimeRecord, currentTime);
	}


=item SetMovieTime THEMOVIE, NEWTIME 

=cut
void
SetMovieTime(theMovie, newtime)
	Movie		theMovie
	TimeRecord &newtime


=item SetMovieTimeValue THEMOVIE, NEWTIME 

=cut
void
SetMovieTimeValue(theMovie, newtime)
	Movie	theMovie
	long	newtime


=item GetMovieUserData THEMOVIE 

=cut
UserData
GetMovieUserData(theMovie)
	Movie	theMovie


=item GetMovieTrackCount THEMOVIE 

=cut
long
GetMovieTrackCount(theMovie)
	Movie	theMovie


=item GetMovieTrack THEMOVIE, TRACKID 

=cut
Track
GetMovieTrack(theMovie, trackID)
	Movie	theMovie
	long	trackID


=item GetMovieIndTrack THEMOVIE, INDEX 

=cut
Track
GetMovieIndTrack(theMovie, index)
	Movie	theMovie
	long	index


=item GetMovieIndTrackType THEMOVIE, INDEX, TRACKTYPE, FLAGS 

=cut
Track
GetMovieIndTrackType(theMovie, index, trackType, flags)
	Movie	theMovie
	long	index
	OSType	trackType
	long	flags


=item GetTrackID THETRACK 

=cut
long
GetTrackID(theTrack)
	Track	theTrack


=item GetTrackMovie THETRACK 

=cut
Movie
GetTrackMovie(theTrack)
	Track	theTrack


=item NewMovieTrack THEMOVIE, WIDTH, HEIGHT, TRACKVOLUME 

=cut
Track
NewMovieTrack(theMovie, width, height, trackVolume)
	Movie	theMovie
	Fixed	width
	Fixed	height
	short	trackVolume


=item DisposeMovieTrack THETRACK 

=cut
void
DisposeMovieTrack(theTrack)
	Track	theTrack


=item GetTrackCreationTime THETRACK 

=cut
long
GetTrackCreationTime(theTrack)
	Track	theTrack


=item GetTrackModificationTime THETRACK 

=cut
long
GetTrackModificationTime(theTrack)
	Track	theTrack


=item GetTrackEnabled THETRACK 

=cut
Boolean
GetTrackEnabled(theTrack)
	Track	theTrack


=item SetTrackEnabled THETRACK, ISENABLED 

=cut
void
SetTrackEnabled(theTrack, isEnabled)
	Track	theTrack
	Boolean	isEnabled


=item GetTrackUsage THETRACK 

=cut
long
GetTrackUsage(theTrack)
	Track	theTrack


=item SetTrackUsage THETRACK, USAGE 

=cut
void
SetTrackUsage(theTrack, usage)
	Track	theTrack
	long	usage


=item GetTrackDuration THETRACK 

=cut
long
GetTrackDuration(theTrack)
	Track	theTrack


=item GetTrackOffset THETRACK 

=cut
long
GetTrackOffset(theTrack)
	Track	theTrack


=item SetTrackOffset THETRACK, MOVIEOFFSETTIME 

=cut
void
SetTrackOffset(theTrack, movieOffsetTime)
	Track	theTrack
	long	movieOffsetTime


=item GetTrackLayer THETRACK 

=cut
short
GetTrackLayer(theTrack)
	Track	theTrack


=item SetTrackLayer THETRACK, LAYER 

=cut
void
SetTrackLayer(theTrack, layer)
	Track	theTrack
	short	layer


=item GetTrackAlternate THETRACK 

=cut
Track
GetTrackAlternate(theTrack)
	Track	theTrack


=item SetTrackAlternate THETRACK, ALTERNATET 

=cut
void
SetTrackAlternate(theTrack, alternateT)
	Track	theTrack
	Track	alternateT


=item SetAutoTrackAlternatesEnabled THEMOVIE, ENABLE 

=cut
void
SetAutoTrackAlternatesEnabled(theMovie, enable)
	Movie	theMovie
	Boolean	enable


=item SelectMovieAlternates THEMOVIE 

=cut
void
SelectMovieAlternates(theMovie)
	Movie	theMovie


=item GetTrackVolume THETRACK 

=cut
short
GetTrackVolume(theTrack)
	Track	theTrack


=item SetTrackVolume THETRACK, VOLUME 

=cut
void
SetTrackVolume(theTrack, volume)
	Track	theTrack
	short	volume


=item GetTrackMatrix THETRACK 

=cut
MatrixRecord
GetTrackMatrix(theTrack)
	Track	theTrack
	CODE:
	GetTrackMatrix(theTrack, &RETVAL);
	OUTPUT:
	RETVAL


=item SetTrackMatrix THETRACK, MATRIX 

=cut
void
SetTrackMatrix(theTrack, matrix)
	Track		  theTrack
	MatrixRecord &matrix


=item GetTrackDimensions THETRACK 

=cut
void
GetTrackDimensions(theTrack)
	Track	theTrack
	PPCODE:
	{
		Fixed	width;
		Fixed	height;
		
		GetTrackDimensions(theTrack, &width, &height);
		
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVnv(Fix2X(width))));
		PUSHs(sv_2mortal(newSVnv(Fix2X(height))));
	}


=item SetTrackDimensions THETRACK, WIDTH, HEIGHT 

=cut
void
SetTrackDimensions(theTrack, width, height)
	Track	theTrack
	Fixed	width
	Fixed	height


=item GetTrackUserData THETRACK 

=cut
UserData
GetTrackUserData(theTrack)
	Track	theTrack

=begin ignore
MatrixRecord
GetTrackDisplayMatrix(theTrack)
	Track	theTrack
	CODE:
	gMacPerl_OSErr = GetTrackDisplayMatrix(theTrack, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

Handle
GetTrackSoundLocalizationSettings(theTrack)
	Track	theTrack
	CODE:
	gMacPerl_OSErr = GetTrackSoundLocalizationSettings(theTrack, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

MacOSRet
SetTrackSoundLocalizationSettings(theTrack, settings)
	Track	theTrack
	Handle	settings

=end ignore

=cut


=item NewTrackMedia THETRACK, MEDIATYPE, TIMESCALE, DATAREF, DATAREFTYPE 

=cut
Media
NewTrackMedia(theTrack, mediaType, timeScale, dataRef, dataRefType)
	Track	theTrack
	OSType	mediaType
	long	timeScale
	Handle	dataRef
	OSType	dataRefType


=item DisposeTrackMedia THEMEDIA 

=cut
void
DisposeTrackMedia(theMedia)
	Media	theMedia


=item GetTrackMedia THETRACK 

=cut
Media
GetTrackMedia(theTrack)
	Track	theTrack


=item GetMediaTrack THEMEDIA 

=cut
Track
GetMediaTrack(theMedia)
	Media	theMedia


=item GetMediaCreationTime THEMEDIA 

=cut
long
GetMediaCreationTime(theMedia)
	Media	theMedia


=item GetMediaModificationTime THEMEDIA 

=cut
long
GetMediaModificationTime(theMedia)
	Media	theMedia


=item GetMediaTimeScale THEMEDIA 

=cut
long
GetMediaTimeScale(theMedia)
	Media	theMedia


=item SetMediaTimeScale THEMEDIA, TIMESCALE 

=cut
void
SetMediaTimeScale(theMedia, timeScale)
	Media	theMedia
	long	timeScale


=item GetMediaDuration THEMEDIA 

=cut
long
GetMediaDuration(theMedia)
	Media	theMedia


=item GetMediaLanguage THEMEDIA 

=cut
short
GetMediaLanguage(theMedia)
	Media	theMedia


=item SetMediaLanguage THEMEDIA, LANGUAGE 

=cut
void
SetMediaLanguage(theMedia, language)
	Media	theMedia
	short	language


=item GetMediaQuality THEMEDIA 

=cut
short
GetMediaQuality(theMedia)
	Media	theMedia


=item SetMediaQuality THEMEDIA, QUALITY 

=cut
void
SetMediaQuality(theMedia, quality)
	Media	theMedia
	short	quality


=item GetMediaHandlerDescription THEMEDIA 

=cut
void
GetMediaHandlerDescription(theMedia)
	Media	theMedia
	PPCODE:
	{
		OSType 	mediaType;
		Str255	creatorName;
		OSType 	creatorManufacturer;
		
		GetMediaHandlerDescription(
			theMedia, &mediaType, creatorName, &creatorManufacturer);
		EXTEND(sp, 3);
		XS_PUSH(OSType, mediaType);
		XS_PUSH(Str255, creatorName);
		XS_PUSH(OSType, creatorManufacturer);
	}


=item GetMediaUserData THEMEDIA 

=cut
UserData
GetMediaUserData(theMedia)
	Media	theMedia


=item BeginMediaEdits THEMEDIA 

=cut
MacOSRet
BeginMediaEdits(theMedia)
	Media	theMedia


=item EndMediaEdits THEMEDIA 

=cut
MacOSRet
EndMediaEdits(theMedia)
	Media	theMedia


=item SetMediaDefaultDataRefIndex THEMEDIA, INDEX 

=cut
MacOSRet
SetMediaDefaultDataRefIndex(theMedia, index)
	Media	theMedia
	short	index


=item GetMediaDataHandlerDescription THEMEDIA, INDEX 

=cut
void
GetMediaDataHandlerDescription(theMedia, index)
	Media	theMedia
	short	index
	PPCODE:
	{
		OSType 	dhType;
		Str255	creatorName;
		OSType 	creatorManufacturer;
		
		GetMediaDataHandlerDescription(
			theMedia, index, &dhType, creatorName, &creatorManufacturer);
		EXTEND(sp, 3);
		XS_PUSH(OSType, dhType);
		XS_PUSH(Str255, creatorName);
		XS_PUSH(OSType, creatorManufacturer);
	}


=item GetMediaSampleDescriptionCount THEMEDIA 

=cut
long
GetMediaSampleDescriptionCount(theMedia)
	Media	theMedia


=item GetMediaSampleDescription THEMEDIA, INDEX 

=cut
SampleDescriptionHandle
GetMediaSampleDescription(theMedia, index)
	Media	theMedia
	long	index
	CODE:
	{
		RETVAL =  (SampleDescriptionHandle) NewHandle(sizeof(SampleDescription));
		GetMediaSampleDescription(theMedia, index, RETVAL);
	}
	OUTPUT:
	RETVAL
		

=item SetMediaSampleDescription THEMEDIA, INDEX, DESC 

=cut
MacOSRet
SetMediaSampleDescription(theMedia, index, desc)
	Media					theMedia
	long					index
	SampleDescriptionHandle	desc


=item GetMediaSampleCount THEMEDIA 

=cut
long
GetMediaSampleCount(theMedia)
	Media	theMedia


=item SampleNumToMediaTime THEMEDIA, LOGICALSAMPLENUM, SAMPLETIME, SAMPLEDURATION 

=cut
void
SampleNumToMediaTime(theMedia, logicalSampleNum, sampleTime, sampleDuration)
	Media	theMedia
	long	logicalSampleNum
	PPCODE:
	{
		long  sampleTime;
		long  sampleDuration;
		
		SampleNumToMediaTime(theMedia, logicalSampleNum, &sampleTime, &sampleDuration);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(sampleTime)));
		PUSHs(sv_2mortal(newSViv(sampleDuration)));
	}


=item MediaTimeToSampleNum THEMEDIA, TIME, SAMPLENUM, SAMPLETIME, SAMPLEDURATION 

=cut
void
MediaTimeToSampleNum(theMedia, time, sampleNum, sampleTime, sampleDuration)
	Media	theMedia
	long	time
	PPCODE:
	{
		long  sampleNum;
		long  sampleTime;
		long  sampleDuration;
		
		MediaTimeToSampleNum(theMedia, time, &sampleNum, &sampleTime, &sampleDuration);
		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSViv(sampleNum)));
		PUSHs(sv_2mortal(newSViv(sampleTime)));
		PUSHs(sv_2mortal(newSViv(sampleDuration)));
	}


=item AddMediaSample THEMEDIA, DATAIN, INOFFSET, SIZE, DURATIONPERSAMPLE, SAMPLEDESCRIPTIONH, NUMBEROFSAMPLES, SAMPLEFLAGS 

=cut
long
AddMediaSample(theMedia, dataIn, inOffset, size, durationPerSample, sampleDescriptionH, numberOfSamples, sampleFlags)
	Media	theMedia
	Handle	dataIn
	long	inOffset
	unsigned long	size
	long	durationPerSample
	SampleDescriptionHandle	sampleDescriptionH
	long	numberOfSamples
	short	sampleFlags
	CODE:
	gMacPerl_OSErr = 
		AddMediaSample(
			theMedia, dataIn, inOffset, size, durationPerSample, 
			sampleDescriptionH, numberOfSamples, sampleFlags, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL
	

=item AddMediaSampleReference THEMEDIA, DATAOFFSET, SIZE, DURATIONPERSAMPLE, SAMPLEDESCRIPTIONH, NUMBEROFSAMPLES, SAMPLEFLAGS 

=cut
long
AddMediaSampleReference(theMedia, dataOffset, size, durationPerSample, sampleDescriptionH, numberOfSamples, sampleFlags)
	Media	theMedia
	long	dataOffset
	unsigned long	size
	long	durationPerSample
	SampleDescriptionHandle	sampleDescriptionH
	long	numberOfSamples
	short	sampleFlags
	CODE:
	gMacPerl_OSErr = 
		AddMediaSampleReference(
			theMedia, dataOffset, size, durationPerSample, 
			sampleDescriptionH, numberOfSamples, sampleFlags, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

=begin ignore
long
AddMediaSampleReferences(theMedia, sampleDescriptionH, numberOfSamples, sampleRefs)
	Media	theMedia
	SampleDescriptionHandle	sampleDescriptionH
	long	numberOfSamples
	SampleReferencePtr	sampleRefs
	CODE:
	gMacPerl_OSErr = 
		AddMediaSampleReferences(
			theMedia, sampleDescriptionH, numberOfSamples, sampleRefs, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL

void
GetMediaSample(theMedia, dataOut, maxSizeToGrow, size, time, sampleTime, durationPerSample, sampleDescriptionH, sampleDescriptionIndex, maxNumberOfSamples, numberOfSamples, sampleFlags)
	Media	theMedia
	Handle	dataOut
	long	maxSizeToGrow
	long *	size
	long	time
	long *	sampleTime
	long *	durationPerSample
	SampleDescriptionHandle	sampleDescriptionH
	long *	sampleDescriptionIndex
	long	maxNumberOfSamples
	long *	numberOfSamples
	short *	sampleFlags
	PPCODE:
	gMacPerl_OSErr = 
	

MacOSRet
GetMediaSampleReference(theMedia, dataOffset, size, time, sampleTime, durationPerSample, sampleDescriptionH, sampleDescriptionIndex, maxNumberOfSamples, numberOfSamples, sampleFlags)
	Media	theMedia
	long *	dataOffset
	long *	size
	long	time
	long *	sampleTime
	long *	durationPerSample
	SampleDescriptionHandle	sampleDescriptionH
	long *	sampleDescriptionIndex
	long	maxNumberOfSamples
	long *	numberOfSamples
	short *	sampleFlags

MacOSRet
GetMediaSampleReferences(theMedia, time, sampleTime, sampleDescriptionH, sampleDescriptionIndex, maxNumberOfEntries, actualNumberofEntries, sampleRefs)
	Media	theMedia
	long	time
	long *	sampleTime
	SampleDescriptionHandle	sampleDescriptionH
	long *	sampleDescriptionIndex
	long	maxNumberOfEntries
	long *	actualNumberofEntries
	SampleReferencePtr	sampleRefs

MacOSRet
SetMediaPreferredChunkSize(theMedia, maxChunkSize)
	Media	theMedia
	long	maxChunkSize

MacOSRet
GetMediaPreferredChunkSize(theMedia, maxChunkSize)
	Media	theMedia
	long *	maxChunkSize

MacOSRet
SetMediaShadowSync(theMedia, frameDiffSampleNum, syncSampleNum)
	Media	theMedia
	long	frameDiffSampleNum
	long	syncSampleNum

MacOSRet
GetMediaShadowSync(theMedia, frameDiffSampleNum, syncSampleNum)
	Media	theMedia
	long	frameDiffSampleNum
	long *	syncSampleNum

MacOSRet
InsertMediaIntoTrack(theTrack, trackStart, mediaTime, mediaDuration, mediaRate)
	Track	theTrack
	long	trackStart
	long	mediaTime
	long	mediaDuration
	Fixed	mediaRate

MacOSRet
InsertTrackSegment(srcTrack, dstTrack, srcIn, srcDuration, dstIn)
	Track	srcTrack
	Track	dstTrack
	long	srcIn
	long	srcDuration
	long	dstIn

MacOSRet
InsertMovieSegment(srcMovie, dstMovie, srcIn, srcDuration, dstIn)
	Movie	srcMovie
	Movie	dstMovie
	long	srcIn
	long	srcDuration
	long	dstIn

MacOSRet
InsertEmptyTrackSegment(dstTrack, dstIn, dstDuration)
	Track	dstTrack
	long	dstIn
	long	dstDuration

MacOSRet
InsertEmptyMovieSegment(dstMovie, dstIn, dstDuration)
	Movie	dstMovie
	long	dstIn
	long	dstDuration

MacOSRet
DeleteTrackSegment(theTrack, startTime, duration)
	Track	theTrack
	long	startTime
	long	duration

MacOSRet
DeleteMovieSegment(theMovie, startTime, duration)
	Movie	theMovie
	long	startTime
	long	duration

MacOSRet
ScaleTrackSegment(theTrack, startTime, oldDuration, newDuration)
	Track	theTrack
	long	startTime
	long	oldDuration
	long	newDuration

MacOSRet
ScaleMovieSegment(theMovie, startTime, oldDuration, newDuration)
	Movie	theMovie
	long	startTime
	long	oldDuration
	long	newDuration

=end ignore

=cut



=item CutMovieSelection THEMOVIE 

=cut
Movie
CutMovieSelection(theMovie)
	Movie	theMovie


=item CopyMovieSelection THEMOVIE 

=cut
Movie
CopyMovieSelection(theMovie)
	Movie	theMovie


=item PasteMovieSelection THEMOVIE, SRC 

=cut
void
PasteMovieSelection(theMovie, src)
	Movie	theMovie
	Movie	src


=item AddMovieSelection THEMOVIE, SRC 

=cut
void
AddMovieSelection(theMovie, src)
	Movie	theMovie
	Movie	src


=item ClearMovieSelection THEMOVIE 

=cut
void
ClearMovieSelection(theMovie)
	Movie	theMovie


=item PasteHandleIntoMovie H, HANDLETYPE, THEMOVIE [, FLAGS [, USERCOMP ]]

=cut
MacOSRet
PasteHandleIntoMovie(h, handleType, theMovie, flags=0, userComp=nil)
	Handle	h
	OSType	handleType
	Movie	theMovie
	long	flags
	ComponentInstance	userComp


=item PutMovieIntoTypedHandle THEMOVIE, TARGETTRACK, HANDLETYPE, PUBLICMOVIE, START, DUR [, FLAGS [, USERCOMP ]]

=cut
MacOSRet
PutMovieIntoTypedHandle(theMovie, targetTrack, handleType, publicMovie, start, dur, flags=0, userComp=0)
	Movie	theMovie
	Track	targetTrack
	OSType	handleType
	Handle	publicMovie
	long	start
	long	dur
	long	flags
	ComponentInstance	userComp


=item IsScrapMovie TARGETTRACK 

=cut
Component
IsScrapMovie(targetTrack)
	Track	targetTrack


=item CopyTrackSettings SRCTRACK, DSTTRACK 

=cut
MacOSRet
CopyTrackSettings(srcTrack, dstTrack)
	Track	srcTrack
	Track	dstTrack


=item CopyMovieSettings SRCMOVIE, DSTMOVIE 

=cut
MacOSRet
CopyMovieSettings(srcMovie, dstMovie)
	Movie	srcMovie
	Movie	dstMovie


=item AddEmptyTrackToMovie SRCTRACK, DSTMOVIE, DATAREF, DATAREFTYPE 

=cut
Track
AddEmptyTrackToMovie(srcTrack, dstMovie, dataRef, dataRefType)
	Track	srcTrack
	Movie	dstMovie
	Handle	dataRef
	OSType	dataRefType
	CODE:
	gMacPerl_OSErr = AddEmptyTrackToMovie(srcTrack, dstMovie, dataRef, dataRefType, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL	


=item NewMovieEditState THEMOVIE 

=cut
MovieEditState
NewMovieEditState(theMovie)
	Movie	theMovie


=item UseMovieEditState THEMOVIE, TOSTATE 

=cut
MacOSRet
UseMovieEditState(theMovie, toState)
	Movie	theMovie
	MovieEditState	toState


=item DisposeMovieEditState STATE 

=cut
MacOSRet
DisposeMovieEditState(state)
	MovieEditState	state


=item NewTrackEditState THETRACK 

=cut
TrackEditState
NewTrackEditState(theTrack)
	Track	theTrack


=item UseTrackEditState THETRACK, STATE 

=cut
MacOSRet
UseTrackEditState(theTrack, state)
	Track	theTrack
	TrackEditState	state


=item DisposeTrackEditState STATE 

=cut
MacOSRet
DisposeTrackEditState(state)
	TrackEditState	state


=item AddTrackReference THETRACK, REFTRACK, REFTYPE 

=cut
long
AddTrackReference(theTrack, refTrack, refType)
	Track	theTrack
	Track	refTrack
	OSType	refType
	CODE:
	gMacPerl_OSErr = AddTrackReference(theTrack, refTrack, refType, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item DeleteTrackReference THETRACK, REFTYPE, INDEX 

=cut
MacOSRet
DeleteTrackReference(theTrack, refType, index)
	Track	theTrack
	OSType	refType
	long	index


=item SetTrackReference THETRACK, REFTRACK, REFTYPE, INDEX 

=cut
MacOSRet
SetTrackReference(theTrack, refTrack, refType, index)
	Track	theTrack
	Track	refTrack
	OSType	refType
	long	index


=item GetTrackReference THETRACK, REFTYPE, INDEX 

=cut
Track
GetTrackReference(theTrack, refType, index)
	Track	theTrack
	OSType	refType
	long	index


=item GetNextTrackReferenceType THETRACK, REFTYPE 

=cut
OSType
GetNextTrackReferenceType(theTrack, refType)
	Track	theTrack
	OSType	refType


=item GetTrackReferenceCount THETRACK, REFTYPE 

=cut
long
GetTrackReferenceCount(theTrack, refType)
	Track	theTrack
	OSType	refType


=item ConvertFileToMovieFile INPUTFILE, OUTPUTFILE, CREATOR, SCRIPTTAG [, FLAGS [, USERCOMP [, REFCON ]]]

=cut
short
ConvertFileToMovieFile(inputFile, outputFile, creator, scriptTag, flags=0, userComp=0, refCon=0)
	FSSpec &inputFile
	FSSpec &outputFile
	OSType	creator
	short	scriptTag
	long	flags
	ComponentInstance	userComp
	long	refCon
	CODE:
	gMacPerl_OSErr = 
		ConvertFileToMovieFile(
			&inputFile, &outputFile, creator, scriptTag, &RETVAL, flags, 
			userComp, 0, refCon);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item ConvertMovieToFile THEMOVIE, ONLYTRACK, OUTPUTFILE, FILETYPE, CREATOR, SCRIPTTAG [, FLAGS [, USERCOMP ]]

=cut
short
ConvertMovieToFile(theMovie, onlyTrack, outputFile, fileType, creator, scriptTag, flags=0, userComp=0)
	Movie	theMovie
	Track	onlyTrack
	FSSpec &outputFile
	OSType	fileType
	OSType	creator
	short	scriptTag
	long	flags
	ComponentInstance	userComp
	CODE:
	gMacPerl_OSErr = 
		ConvertMovieToFile(
			theMovie, onlyTrack, &outputFile, fileType, creator, scriptTag, 
			&RETVAL, flags, userComp);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item TrackTimeToMediaTime VALUE, THETRACK 

=cut
long
TrackTimeToMediaTime(value, theTrack)
	long	value
	Track	theTrack


=item GetTrackEditRate THETRACK, ATTIME 

=cut
Fixed
GetTrackEditRate(theTrack, atTime)
	Track	theTrack
	long	atTime


=item GetMovieDataSize THEMOVIE, STARTTIME, DURATION 

=cut
long
GetMovieDataSize(theMovie, startTime, duration)
	Movie	theMovie
	long	startTime
	long	duration


=item GetTrackDataSize THETRACK, STARTTIME, DURATION 

=cut
long
GetTrackDataSize(theTrack, startTime, duration)
	Track	theTrack
	long	startTime
	long	duration


=item GetMediaDataSize THEMEDIA, STARTTIME, DURATION 

=cut
long
GetMediaDataSize(theMedia, startTime, duration)
	Media	theMedia
	long	startTime
	long	duration


=item PtInMovie THEMOVIE, PT 

=cut
Boolean
PtInMovie(theMovie, pt)
	Movie	theMovie
	Point	pt


=item PtInTrack THETRACK, PT 

=cut
Boolean
PtInTrack(theTrack, pt)
	Track	theTrack
	Point	pt


=item SetMovieLanguage THEMOVIE, LANGUAGE 

=cut
void
SetMovieLanguage(theMovie, language)
	Movie	theMovie
	long	language


=item GetUserData THEUSERDATA, DATA, UDTYPE, INDEX 

=cut
MacOSRet
GetUserData(theUserData, data, udType, index)
	UserData	theUserData
	Handle	data
	OSType	udType
	long	index


=item AddUserData THEUSERDATA, DATA, UDTYPE 

=cut
MacOSRet
AddUserData(theUserData, data, udType)
	UserData	theUserData
	Handle	data
	OSType	udType


=item RemoveUserData THEUSERDATA, UDTYPE, INDEX 

=cut
MacOSRet
RemoveUserData(theUserData, udType, index)
	UserData	theUserData
	OSType	udType
	long	index


=item CountUserDataType THEUSERDATA, UDTYPE 

=cut
short
CountUserDataType(theUserData, udType)
	UserData	theUserData
	OSType	udType


=item GetNextUserDataType THEUSERDATA, UDTYPE 

=cut
long
GetNextUserDataType(theUserData, udType)
	UserData	theUserData
	OSType	udType

=begin ignore
MacOSRet
GetUserDataItem(theUserData, data, size, udType, index)
	UserData	theUserData
	void *	data
	long	size
	OSType	udType
	long	index

MacOSRet
SetUserDataItem(theUserData, data, size, udType, index)
	UserData	theUserData
	void *	data
	long	size
	OSType	udType
	long	index

=end ignore

=cut



=item AddUserDataText THEUSERDATA, DATA, UDTYPE, INDEX, ITLREGIONTAG 

=cut
MacOSRet
AddUserDataText(theUserData, data, udType, index, itlRegionTag)
	UserData	theUserData
	Handle	data
	OSType	udType
	long	index
	short	itlRegionTag


=item GetUserDataText THEUSERDATA, DATA, UDTYPE, INDEX, ITLREGIONTAG 

=cut
MacOSRet
GetUserDataText(theUserData, data, udType, index, itlRegionTag)
	UserData	theUserData
	Handle	data
	OSType	udType
	long	index
	short	itlRegionTag


=item RemoveUserDataText THEUSERDATA, UDTYPE, INDEX, ITLREGIONTAG 

=cut
MacOSRet
RemoveUserDataText(theUserData, udType, index, itlRegionTag)
	UserData	theUserData
	OSType	udType
	long	index
	short	itlRegionTag


=item NewUserData 

=cut
UserData
NewUserData()
	CODE:
	gMacPerl_OSErr = NewUserData(&RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item DisposeUserData THEUSERDATA 

=cut
MacOSRet
DisposeUserData(theUserData)
	UserData	theUserData


=item NewUserDataFromHandle H 

=cut
UserData
NewUserDataFromHandle(h)
	Handle	h
	CODE:
	gMacPerl_OSErr = NewUserDataFromHandle(h, &RETVAL);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item PutUserDataIntoHandle THEUSERDATA, H 

=cut
MacOSRet
PutUserDataIntoHandle(theUserData, h)
	UserData	theUserData
	Handle	h


=item GetMediaNextInterestingTime THEMEDIA, INTERESTINGTIMEFLAGS, TIME, RATE 

=cut
void
GetMediaNextInterestingTime(theMedia, interestingTimeFlags, time, rate)
	Media	theMedia
	short	interestingTimeFlags
	long	time
	Fixed	rate
	PPCODE:
	{
		long	interestingTime;
		long	interestingDuration;
		
		GetMediaNextInterestingTime(theMedia, interestingTimeFlags, time, rate,
			&interestingTime, &interestingDuration);
			
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(interestingTime)));
		PUSHs(sv_2mortal(newSViv(interestingDuration)));
	}


=item GetTrackNextInterestingTime THETRACK, INTERESTINGTIMEFLAGS, TIME, RATE 

=cut
void
GetTrackNextInterestingTime(theTrack, interestingTimeFlags, time, rate)
	Track	theTrack
	short	interestingTimeFlags
	long	time
	Fixed	rate
	PPCODE:
	{
		long	interestingTime;
		long	interestingDuration;
		
		GetTrackNextInterestingTime(theTrack, interestingTimeFlags, time, rate,
			&interestingTime, &interestingDuration);
			
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(interestingTime)));
		PUSHs(sv_2mortal(newSViv(interestingDuration)));
	}


=item GetMovieNextInterestingTime THEMOVIE, INTERESTINGTIMEFLAGS, MEDIATYPES, TIME, RATE 

=cut
void
GetMovieNextInterestingTime(theMovie, interestingTimeFlags, mediaTypes, time, rate)
	Movie	theMovie
	short	interestingTimeFlags
	SV *	mediaTypes;
	long	time
	Fixed	rate
	PPCODE:
	{
		OSType **	theMediaTypes;
		long		interestingTime;
		long		interestingDuration;
		short		numMediaTypes;
		
		if (numMediaTypes = SvCUR(mediaTypes) >> 2) {
			PtrToHand(SvPV_nolen(mediaTypes), (Handle *)&theMediaTypes, numMediaTypes << 2);
			HLock((Handle)theMediaTypes);
			GetMovieNextInterestingTime(theMovie, interestingTimeFlags, 
				numMediaTypes, *theMediaTypes, time, rate,
				&interestingTime, &interestingDuration);
			DisposeHandle((Handle)theMediaTypes);
		} else
			GetMovieNextInterestingTime(theMovie, interestingTimeFlags, 
				0, nil, time, rate,
				&interestingTime, &interestingDuration);
			
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(interestingTime)));
		PUSHs(sv_2mortal(newSViv(interestingDuration)));
	}


=item CreateMovieFile FILESPEC, CREATOR, SCRIPTTAG, CREATEMOVIEFILEFLAGS 

=cut
void
CreateMovieFile(fileSpec, creator, scriptTag, createMovieFileFlags)
	FSSpec   &fileSpec
	OSType		  	creator
	short	  	scriptTag
	long		  	createMovieFileFlags
	PPCODE:
	{
		short	resRefNum;
		Movie	newmovie;
		
		gMacPerl_OSErr = 
			CreateMovieFile(
				&fileSpec, creator, scriptTag, createMovieFileFlags, &resRefNum, &newmovie);
		if (gMacPerl_OSErr) { 
			XSRETURN_UNDEF; 
		}
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(resRefNum)));
		PUSHs(sv_setref_pv(sv_newmortal(), "Movie", newmovie));
	}


=item OpenMovieFile FILESPEC [, PERMISSION ]

=cut
short
OpenMovieFile(fileSpec, permission=fsRdPerm)
	FSSpec 	&fileSpec
	SInt8			permission
	CODE:
	gMacPerl_OSErr = OpenMovieFile(&fileSpec, &RETVAL, permission);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	OUTPUT:
	RETVAL


=item CloseMovieFile RESREFNUM 

=cut
MacOSRet
CloseMovieFile(resRefNum)
	short	resRefNum


=item DeleteMovieFile FILESPEC 

=cut
MacOSRet
DeleteMovieFile(fileSpec)
	FSSpec &fileSpec


=item NewMovieFromFile RESREFNUM, RESID, NEWMOVIEFLAGS 

  $movie = NewMovieFromFile($resourceFileRefNum, $resourceID, $movieFlags);
  
  ($movie,$resourceID,$resourceName,$dataRefWasChanged) =
      NewMovieFromFile($resourceFileRefNum, $resourceID, $movieFlags);
	  
=cut
void
NewMovieFromFile(resRefNum, resId, newMovieFlags)
	short	resRefNum
	short	resId
	short	newMovieFlags
	PPCODE:
	{
		Movie 	theMovie;
		Str255	resName;
		Boolean	dataRefWasChanged;
		
		gMacPerl_OSErr = 
			NewMovieFromFile(
				&theMovie, resRefNum, &resId, resName, newMovieFlags, &dataRefWasChanged);
		if (gMacPerl_OSErr) { 
			XSRETURN_UNDEF; 
		}
		XS_XPUSH(Movie, theMovie);	
		if (GIMME == G_ARRAY) {
			EXTEND(sp, 3);
			XS_PUSH(short, resId);
			XS_PUSH(Str255, resName);
			XS_PUSH(Boolean, dataRefWasChanged);
		}
	}


=item NewMovieFromHandle H, NEWMOVIEFLAGS 

=cut
void
NewMovieFromHandle(h, newMovieFlags)
	Handle	h
	short	newMovieFlags
	PPCODE:
	{
		Movie 	theMovie;
		Boolean	dataRefWasChanged;
		
		gMacPerl_OSErr = 
			NewMovieFromHandle(&theMovie, h, newMovieFlags, &dataRefWasChanged);
		if (gMacPerl_OSErr) { 
			XSRETURN_UNDEF; 
		}
		XS_XPUSH(Movie, theMovie);	
		if (GIMME == G_ARRAY) {
			XS_XPUSH(Boolean, dataRefWasChanged);
		}
	}


=item NewMovieFromDataFork FREFNUM, FILEOFFSET, NEWMOVIEFLAGS 

=cut
void
NewMovieFromDataFork(fRefNum, fileOffset, newMovieFlags)
	short	fRefNum
	long	fileOffset
	short	newMovieFlags
	PPCODE:
	{
		Movie 	theMovie;
		Boolean	dataRefWasChanged;
		
		gMacPerl_OSErr = 
			NewMovieFromDataFork(
				&theMovie, fRefNum, fileOffset, newMovieFlags, &dataRefWasChanged);
		if (gMacPerl_OSErr) { 
			XSRETURN_UNDEF; 
		}
		XS_XPUSH(Movie, theMovie);	
		if (GIMME == G_ARRAY) {
			XS_XPUSH(Boolean, dataRefWasChanged);
		}
	}

=begin ignore
MacOSRet
NewMovieFromUserProc(m, flags, dataRefWasChanged, getProc, refCon, defaultDataRef, dataRefType)
	Movie *	m
	short	flags
	Boolean *	dataRefWasChanged
	GetMovieUPP	getProc
	void *	refCon
	Handle	defaultDataRef
	OSType	dataRefType

MacOSRet
NewMovieFromDataRef(m, flags, id, dataRef, dataRefType)
	Movie *	m
	short	flags
	short *	id
	Handle	dataRef
	OSType	dataRefType

=end ignore

=cut



=item AddMovieResource THEMOVIE, RESREFNUM, RESID, RESNAME 

=cut
short
AddMovieResource(theMovie, resRefNum, resId, resName)
	Movie	theMovie
	short	resRefNum
	short  &resId
	Str255	resName
	CODE:
	gMacPerl_OSErr = AddMovieResource(theMovie, resRefNum, &resId, resName);
	if (gMacPerl_OSErr) { 
		XSRETURN_UNDEF; 
	}
	RETVAL = resId;
	OUTPUT:
	RETVAL


=item UpdateMovieResource THEMOVIE, RESREFNUM, RESID, ... 

=cut
MacOSRet
UpdateMovieResource(theMovie, resRefNum, resId, ...)
	Movie	theMovie
	short	resRefNum
	short	resId
	CODE:
	{
		Str255	resName;
		
		if (items > 3) {
			memcpy(resName+1, SvPV_nolen(ST(3)), SvCUR(ST(3)));
			RETVAL = UpdateMovieResource(theMovie, resRefNum, resId, resName);
		} else
			RETVAL = UpdateMovieResource(theMovie, resRefNum, resId, nil);
	}
	OUTPUT:
	RETVAL


=item RemoveMovieResource RESREFNUM, RESID 

=cut
MacOSRet
RemoveMovieResource(resRefNum, resId)
	short	resRefNum
	short	resId


=item HasMovieChanged THEMOVIE 

=cut
Boolean
HasMovieChanged(theMovie)
	Movie	theMovie


=item ClearMovieChanged THEMOVIE 

=cut
void
ClearMovieChanged(theMovie)
	Movie	theMovie

=begin ignore
MacOSRet
SetMovieDefaultDataRef(theMovie, dataRef, dataRefType)
	Movie	theMovie
	Handle	dataRef
	OSType	dataRefType

MacOSRet
GetMovieDefaultDataRef(theMovie, dataRef, dataRefType)
	Movie	theMovie
	Handle *	dataRef
	OSType *	dataRefType

MacOSRet
SetMovieColorTable(theMovie, ctab)
	Movie	theMovie
	CTabHandle	ctab

MacOSRet
GetMovieColorTable(theMovie, ctab)
	Movie	theMovie
	CTabHandle *	ctab

=end ignore

=cut



=item FlattenMovie THEMOVIE, MOVIEFLATTENFLAGS, THEFILE, CREATOR, SCRIPTTAG, CREATEMOVIEFILEFLAGS, RESID, RESNAME 

=cut
short
FlattenMovie(theMovie, movieFlattenFlags, theFile, creator, scriptTag, createMovieFileFlags, resId, resName)
	Movie	theMovie
	long	movieFlattenFlags
	FSSpec &theFile
	OSType	creator
	short	scriptTag
	long	createMovieFileFlags
	short  &resId
	Str255	resName
	CODE:
	FlattenMovie(
		theMovie, movieFlattenFlags, &theFile, creator, scriptTag, createMovieFileFlags, 
		&resId, resName);
	RETVAL = resId;
	OUTPUT:
	RETVAL


=item FlattenMovieData THEMOVIE, MOVIEFLATTENFLAGS, THEFILE, CREATOR, SCRIPTTAG, CREATEMOVIEFILEFLAGS 

=cut
Movie
FlattenMovieData(theMovie, movieFlattenFlags, theFile, creator, scriptTag, createMovieFileFlags)
	Movie	theMovie
	long	movieFlattenFlags
	FSSpec &theFile
	OSType	creator
	short	scriptTag
	long	createMovieFileFlags

=begin ignore
void
SetMovieProgressProc(theMovie, p, refcon)
	Movie	theMovie
	MovieProgressUPP	p
	long	refcon

=end ignore

=cut


=begin ignore
MacOSRet
MovieSearchText(theMovie, text, size, searchFlags, searchTrack, searchTime, searchOffset)
	Movie	theMovie
	Ptr	text
	long	size
	long	searchFlags
	Track *	searchTrack
	long *	searchTime
	long *	searchOffset

=end ignore

=cut



=item GetPosterBox THEMOVIE 

=cut
Rect
GetPosterBox(theMovie)
	Movie	theMovie
	CODE:
	GetPosterBox(theMovie, &RETVAL);
	OUTPUT:
	RETVAL


=item SetPosterBox THEMOVIE, BOXRECT 

=cut
void
SetPosterBox(theMovie, boxRect)
	Movie	theMovie
	Rect   &boxRect


=item GetMovieSegmentDisplayBoundsRgn THEMOVIE, TIME, DURATION 

=cut
RgnHandle
GetMovieSegmentDisplayBoundsRgn(theMovie, time, duration)
	Movie	theMovie
	long	time
	long	duration


=item GetTrackSegmentDisplayBoundsRgn THETRACK, TIME, DURATION 

=cut
RgnHandle
GetTrackSegmentDisplayBoundsRgn(theTrack, time, duration)
	Track	theTrack
	long	time
	long	duration

=begin ignore
void
SetMovieCoverProcs(theMovie, uncoverProc, coverProc, refcon)
	Movie	theMovie
	MovieRgnCoverUPP	uncoverProc
	MovieRgnCoverUPP	coverProc
	long	refcon

MacOSRet
GetMovieCoverProcs(theMovie, uncoverProc, coverProc, refcon)
	Movie	theMovie
	MovieRgnCoverUPP *	uncoverProc
	MovieRgnCoverUPP *	coverProc
	long *	refcon

=end ignore

=cut



=item GetTrackStatus THETRACK 

=cut
long
GetTrackStatus(theTrack)
	Track	theTrack


=item GetMovieStatus THEMOVIE 

=cut
void
GetMovieStatus(theMovie)
	Movie	theMovie
	PPCODE:
	{
		long	res;
		Track 			firstProblemTrack;
		
		res = GetMovieStatus(theMovie, &firstProblemTrack);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(res)));
		PUSHs(sv_setref_pv(sv_newmortal(), "Track", firstProblemTrack));		
	}


=item NewMovieController THEMOVIE, MOVIERECT [, SOMEFLAGS ]

=cut
ComponentInstance
NewMovieController(theMovie, movieRect, someFlags=0)
	Movie	theMovie
	Rect   &movieRect
	long	someFlags

void
_DisposeMovieController(mc)
	ComponentInstance	mc
	CODE:
	DisposeMovieController(mc);

=begin ignore
void
ShowMovieInformation(theMovie, filterProc, refCon)
	Movie	theMovie
	ModalFilterUPP	filterProc
	long	refCon

=end ignore

=cut



=item PutMovieOnScrap THEMOVIE, MOVIESCRAPFLAGS 

=cut
MacOSRet
PutMovieOnScrap(theMovie, movieScrapFlags)
	Movie	theMovie
	long	movieScrapFlags


=item NewMovieFromScrap NEWMOVIEFLAGS 

=cut
Movie
NewMovieFromScrap(newMovieFlags)
	long	newMovieFlags

=begin ignore
MacOSRet
GetMediaDataRef(theMedia, index, dataRef, dataRefType, dataRefAttributes)
	Media	theMedia
	short	index
	Handle *	dataRef
	OSType *	dataRefType
	long *	dataRefAttributes

MacOSRet
SetMediaDataRef(theMedia, index, dataRef, dataRefType)
	Media	theMedia
	short	index
	Handle	dataRef
	OSType	dataRefType

MacOSRet
SetMediaDataRefAttributes(theMedia, index, dataRefAttributes)
	Media	theMedia
	short	index
	long	dataRefAttributes

MacOSRet
AddMediaDataRef(theMedia, index, dataRef, dataRefType)
	Media	theMedia
	short *	index
	Handle	dataRef
	OSType	dataRefType

MacOSRet
GetMediaDataRefCount(theMedia, count)
	Media	theMedia
	short *	count

=end ignore

=cut



=item SetMoviePlayHints THEMOVIE, FLAGS, FLAGSMASK 

=cut
void
SetMoviePlayHints(theMovie, flags, flagsMask)
	Movie	theMovie
	long	flags
	long	flagsMask


=item SetMediaPlayHints THEMEDIA, FLAGS, FLAGSMASK 

=cut
void
SetMediaPlayHints(theMedia, flags, flagsMask)
	Media	theMedia
	long	flags
	long	flagsMask


=item SetTrackLoadSettings THETRACK, PRELOADTIME, PRELOADDURATION, PRELOADFLAGS, DEFAULTHINTS 

=cut
void
SetTrackLoadSettings(theTrack, preloadTime, preloadDuration, preloadFlags, defaultHints)
	Track	theTrack
	long	preloadTime
	long	preloadDuration
	long	preloadFlags
	long	defaultHints


=item GetTrackLoadSettings THETRACK 

=cut
void
GetTrackLoadSettings(theTrack)
	Track	theTrack
	PPCODE:
	{
		long preloadTime;
		long preloadDuration;
		long preloadFlags;
		long defaultHints;
		
		GetTrackLoadSettings(theTrack, &preloadTime, &preloadDuration, &preloadFlags, &defaultHints);
		
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSViv(preloadTime)));
		PUSHs(sv_2mortal(newSViv(preloadDuration)));
		PUSHs(sv_2mortal(newSViv(preloadFlags)));
		PUSHs(sv_2mortal(newSViv(defaultHints)));
	}

=begin ignore
MacOSRet
BeginFullScreen(restoreState, whichGD, desiredWidth, desiredHeight, newWindow, eraseColor, flags)
	Ptr *	restoreState
	GDHandle	whichGD
	short *	desiredWidth
	short *	desiredHeight
	WindowPtr *	newWindow
	RGBColor *	eraseColor
	long	flags

MacOSRet
EndFullScreen(fullState, flags)
	Ptr	fullState
	long	flags

MacOSRet
NewSpriteWorld(newSpriteWorld, destination, spriteLayer, backgroundColor, background)
	SpriteWorld *	newSpriteWorld
	GWorldPtr	destination
	GWorldPtr	spriteLayer
	RGBColor *	backgroundColor
	GWorldPtr	background

void
DisposeSpriteWorld(theSpriteWorld)
	SpriteWorld	theSpriteWorld

MacOSRet
SetSpriteWorldClip(theSpriteWorld, clipRgn)
	SpriteWorld	theSpriteWorld
	RgnHandle	clipRgn

MacOSRet
SetSpriteWorldMatrix(theSpriteWorld, matrix)
	SpriteWorld	theSpriteWorld
	const MatrixRecord *	matrix

MacOSRet
SpriteWorldIdle(theSpriteWorld, flagsIn, flagsOut)
	SpriteWorld	theSpriteWorld
	long	flagsIn
	long *	flagsOut

MacOSRet
InvalidateSpriteWorld(theSpriteWorld, invalidArea)
	SpriteWorld	theSpriteWorld
	Rect *	invalidArea

MacOSRet
SpriteWorldHitTest(theSpriteWorld, flags, loc, spriteHit)
	SpriteWorld	theSpriteWorld
	long	flags
	Point	loc
	Sprite *	spriteHit

MacOSRet
SpriteHitTest(theSprite, flags, loc, wasHit)
	Sprite	theSprite
	long	flags
	Point	loc
	Boolean *	wasHit

void
DisposeAllSprites(theSpriteWorld)
	SpriteWorld	theSpriteWorld

MacOSRet
NewSprite(newSprite, itsSpriteWorld, idh, imageDataPtr, matrix, visible, layer)
	Sprite *	newSprite
	SpriteWorld	itsSpriteWorld
	ImageDescriptionHandle	idh
	Ptr	imageDataPtr
	MatrixRecord *	matrix
	Boolean	visible
	short	layer

void
DisposeSprite(theSprite)
	Sprite	theSprite

void
InvalidateSprite(theSprite)
	Sprite	theSprite

MacOSRet
SetSpriteProperty(theSprite, propertyType, propertyValue)
	Sprite	theSprite
	long	propertyType
	void *	propertyValue

MacOSRet
GetSpriteProperty(theSprite, propertyType, propertyValue)
	Sprite	theSprite
	long	propertyType
	void *	propertyValue
 *

MacOSRet
QTNewAtomContainer(atomData)
	QTAtomContainer *	atomData

MacOSRet
QTDisposeAtomContainer(atomData)
	QTAtomContainer	atomData

QTAtomType
QTGetNextChildType(container, parentAtom, currentChildType)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomType	currentChildType

short
QTCountChildrenOfType(container, parentAtom, childType)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomType	childType

QTAtom
QTFindChildByIndex(container, parentAtom, atomType, index, id)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomType	atomType
	short	index
	QTAtomID *	id

QTAtom
QTFindChildByID(container, parentAtom, atomType, id, index)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomType	atomType
	QTAtomID	id
	short *	index

MacOSRet
QTNextChildAnyType(container, parentAtom, currentChild, nextChild)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtom	currentChild
	QTAtom *	nextChild

MacOSRet
QTSetAtomData(container, atom, dataSize, atomData)
	QTAtomContainer	container
	QTAtom	atom
	long	dataSize
	void *	atomData

MacOSRet
QTCopyAtomDataToHandle(container, atom, targetHandle)
	QTAtomContainer	container
	QTAtom	atom
	Handle	targetHandle

MacOSRet
QTCopyAtomDataToPtr(container, atom, sizeOrLessOK, size, targetPtr, actualSize)
	QTAtomContainer	container
	QTAtom	atom
	Boolean	sizeOrLessOK
	long	size
	void *	targetPtr
	long *	actualSize

MacOSRet
QTGetAtomTypeAndID(container, atom, atomType, id)
	QTAtomContainer	container
	QTAtom	atom
	QTAtomType *	atomType
	QTAtomID *	id

MacOSRet
QTCopyAtom(container, atom, targetContainer)
	QTAtomContainer	container
	QTAtom	atom
	QTAtomContainer *	targetContainer

MacOSRet
QTLockContainer(container)
	QTAtomContainer	container

MacOSRet
QTGetAtomDataPtr(container, atom, dataSize, atomData)
	QTAtomContainer	container
	QTAtom	atom
	long *	dataSize
	Ptr *	atomData

MacOSRet
QTUnlockContainer(container)
	QTAtomContainer	container

MacOSRet
QTInsertChild(container, parentAtom, atomType, id, index, dataSize, data, newAtom)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomType	atomType
	QTAtomID	id
	short	index
	long	dataSize
	void *	data
	QTAtom *	newAtom

MacOSRet
QTInsertChildren(container, parentAtom, childrenContainer)
	QTAtomContainer	container
	QTAtom	parentAtom
	QTAtomContainer	childrenContainer

MacOSRet
QTRemoveAtom(container, atom)
	QTAtomContainer	container
	QTAtom	atom

MacOSRet
QTRemoveChildren(container, atom)
	QTAtomContainer	container
	QTAtom	atom

MacOSRet
QTReplaceAtom(targetContainer, targetAtom, replacementContainer, replacementAtom)
	QTAtomContainer	targetContainer
	QTAtom	targetAtom
	QTAtomContainer	replacementContainer
	QTAtom	replacementAtom

MacOSRet
QTSwapAtoms(container, atom1, atom2)
	QTAtomContainer	container
	QTAtom	atom1
	QTAtom	atom2

MacOSRet
QTSetAtomID(container, atom, newID)
	QTAtomContainer	container
	QTAtom	atom
	QTAtomID	newID

MacOSRet
SetMediaPropertyAtom(theMedia, propertyAtom)
	Media	theMedia
	QTAtomContainer	propertyAtom

MacOSRet
GetMediaPropertyAtom(theMedia, propertyAtom)
	Media	theMedia
	QTAtomContainer *	propertyAtom

MacOSRet
ITextAddString(container, parentAtom, theRegionCode, theString)
	QTAtomContainer	container
	QTAtom	parentAtom
	short	theRegionCode
	Str255	theString

MacOSRet
ITextRemoveString(container, parentAtom, theRegionCode, flags)
	QTAtomContainer	container
	QTAtom	parentAtom
	short	theRegionCode
	long	flags

MacOSRet
ITextGetString(container, parentAtom, requestedRegion, foundRegion, theString)
	QTAtomContainer	container
	QTAtom	parentAtom
	short	requestedRegion
	short *	foundRegion
	StringPtr	theString

long
VideoMediaResetStatistics(mh)
	ComponentInstance	mh

long
VideoMediaGetStatistics(mh)
	ComponentInstance	mh

long
TextMediaSetTextProc(mh, TextProc, refcon)
	ComponentInstance	mh
	TextMediaUPP	TextProc
	long	refcon
 *
long
TextMediaAddTextSample(mh, text, size, fontNumber, fontSize, textFace, textColor, backColor, textJustification, textBox, displayFlags, scrollDelay, hiliteStart, hiliteEnd, rgbHiliteColor, duration, sampleTime)
	ComponentInstance	mh
	Ptr	text
	unsigned long	size
	short	fontNumber
	short	fontSize
	Style	textFace
	RGBColor *	textColor
	RGBColor *	backColor
	short	textJustification
	Rect *	textBox
	long	displayFlags
	long	scrollDelay
	short	hiliteStart
	short	hiliteEnd
	RGBColor *	rgbHiliteColor
	long	duration
	long *	sampleTime

long
TextMediaAddTESample(mh, hTE, backColor, textJustification, textBox, displayFlags, scrollDelay, hiliteStart, hiliteEnd, rgbHiliteColor, duration, sampleTime)
	ComponentInstance	mh
	TEHandle	hTE
	RGBColor *	backColor
	short	textJustification
	Rect *	textBox
	long	displayFlags
	long	scrollDelay
	short	hiliteStart
	short	hiliteEnd
	RGBColor *	rgbHiliteColor
	long	duration
	long *	sampleTime

long
TextMediaAddHiliteSample(mh, hiliteStart, hiliteEnd, rgbHiliteColor, duration, sampleTime)
	ComponentInstance	mh
	short	hiliteStart
	short	hiliteEnd
	RGBColor *	rgbHiliteColor
	long	duration
	long *	sampleTime

long
TextMediaFindNextText(mh, text, size, findFlags, startTime, foundTime, foundDuration, offset)
	ComponentInstance	mh
	Ptr	text
	long	size
	short	findFlags
	long	startTime
	long *	foundTime
	long *	foundDuration
	long *	offset

long
TextMediaHiliteTextSample(mh, sampleTime, hiliteStart, hiliteEnd, rgbHiliteColor)
	ComponentInstance	mh
	long	sampleTime
	short	hiliteStart
	short	hiliteEnd
	RGBColor *	rgbHiliteColor

long
TextMediaSetTextSampleData(mh, data, dataType)
	ComponentInstance	mh
	void *	data
	OSType	dataType

long
SpriteMediaSetProperty(mh, spriteIndex, propertyType, propertyValue)
	ComponentInstance	mh
	short	spriteIndex
	long	propertyType
	void *	propertyValue

long
SpriteMediaGetProperty(mh, spriteIndex, propertyType, propertyValue)
	ComponentInstance	mh
	short	spriteIndex
	long	propertyType
	void *	propertyValue

long
SpriteMediaHitTestSprites(mh, flags, loc, spriteHitIndex)
	ComponentInstance	mh
	long	flags
	Point	loc
	short *	spriteHitIndex

long
SpriteMediaCountSprites(mh, numSprites)
	ComponentInstance	mh
	short *	numSprites

long
SpriteMediaCountImages(mh, numImages)
	ComponentInstance	mh
	short *	numImages

long
SpriteMediaGetIndImageDescription(mh, imageIndex, imageDescription)
	ComponentInstance	mh
	short	imageIndex
	ImageDescriptionHandle	imageDescription

long
SpriteMediaGetDisplayedSampleNumber(mh, sampleNum)
	ComponentInstance	mh
	long *	sampleNum

=end ignore

=cut



=item NewTimeBase 

=cut
TimeBase
NewTimeBase()	


=item DisposeTimeBase TB 

=cut
void
DisposeTimeBase(tb)
	TimeBase	tb


=item GetTimeBaseTime TB, S 

=cut
void
GetTimeBaseTime(tb, s)
	TimeBase	tb
	long	s
	PPCODE:
	{
		long		ret;
		TimeRecord	tr;
		
		ret = GetTimeBaseTime(tb, s, &tr);
		EXTEND(sp, 2);
		XS_PUSH(long, ret);
		XS_PUSH(TimeRecord, tr);
	}


=item SetTimeBaseTime TB, TR 

=cut
void
SetTimeBaseTime(tb, tr)
	TimeBase	tb
	TimeRecord &tr


=item SetTimeBaseValue TB, T, S 

=cut
void
SetTimeBaseValue(tb, t, s)
	TimeBase	tb
	long		t
	long	s


=item GetTimeBaseRate TB 

=cut
Fixed
GetTimeBaseRate(tb)
	TimeBase	tb


=item SetTimeBaseRate TB, R 

=cut
void
SetTimeBaseRate(tb, r)
	TimeBase	tb
	Fixed	r


=item GetTimeBaseStartTime TB, S 

=cut
void
GetTimeBaseStartTime(tb, s)
	TimeBase	tb
	long	s
	PPCODE:
	{
		long		ret;
		TimeRecord	tr;
		
		ret = GetTimeBaseStartTime(tb, s, &tr);
		EXTEND(sp, 2);
		XS_PUSH(long, ret);
		XS_PUSH(TimeRecord, tr);
	}


=item SetTimeBaseStartTime TB, TR 

=cut
void
SetTimeBaseStartTime(tb, tr)
	TimeBase	tb
	TimeRecord &tr


=item GetTimeBaseStopTime TB, S, TR 

=cut
void
GetTimeBaseStopTime(tb, s)
	TimeBase	tb
	long	s
	PPCODE:
	{
		long		ret;
		TimeRecord	tr;
		
		ret = GetTimeBaseStopTime(tb, s, &tr);
		EXTEND(sp, 2);
		XS_PUSH(long, ret);
		XS_PUSH(TimeRecord, tr);
	}


=item SetTimeBaseStopTime TB, TR 

=cut
void
SetTimeBaseStopTime(tb, tr)
	TimeBase	tb
	TimeRecord &tr


=item GetTimeBaseFlags TB 

=cut
long
GetTimeBaseFlags(tb)
	TimeBase	tb


=item SetTimeBaseFlags TB, TIMEBASEFLAGS 

=cut
void
SetTimeBaseFlags(tb, timeBaseFlags)
	TimeBase	tb
	long	timeBaseFlags


=item SetTimeBaseMasterTimeBase SLAVE, MASTER, SLAVEZERO 

=cut
void
SetTimeBaseMasterTimeBase(slave, master, slaveZero)
	TimeBase	slave
	TimeBase	master
	TimeRecord &slaveZero


=item GetTimeBaseMasterTimeBase TB 

=cut
TimeBase
GetTimeBaseMasterTimeBase(tb)
	TimeBase	tb


=item SetTimeBaseMasterClock SLAVE, CLOCKMEISTER, SLAVEZERO 

=cut
void
SetTimeBaseMasterClock(slave, clockMeister, slaveZero)
	TimeBase	slave
	Component	clockMeister
	TimeRecord &slaveZero


=item GetTimeBaseMasterClock TB 

=cut
ComponentInstance
GetTimeBaseMasterClock(tb)
	TimeBase	tb


=item ConvertTime INOUT, NEWBASE 

=cut
TimeRecord
ConvertTime(inout, newBase)
	TimeRecord &inout
	TimeBase	newBase
	CODE:
	ConvertTime(&inout, newBase);
	RETVAL = inout;
	OUTPUT:
	RETVAL


=item ConvertTimeScale INOUT, NEWSCALE 

=cut
TimeRecord
ConvertTimeScale(inout, newScale)
	TimeRecord &inout
	long	newScale
	CODE:
	ConvertTimeScale(&inout, newScale);
	RETVAL = inout;
	OUTPUT:
	RETVAL


=item AddTime DST, SRC 

=cut
TimeRecord
AddTime(dst, src)
	TimeRecord &dst
	TimeRecord &src
	CODE:
	AddTime(&dst, &src);
	RETVAL = dst;
	OUTPUT:
	RETVAL


=item SubtractTime DST, SRC 

=cut
TimeRecord
SubtractTime(dst, src)
	TimeRecord &dst
	TimeRecord &src
	CODE:
	SubtractTime(&dst, &src);
	RETVAL = dst;
	OUTPUT:
	RETVAL


=item GetTimeBaseStatus TB 

=cut
void
GetTimeBaseStatus(tb)
	TimeBase	tb
	PPCODE:
	{
		long		ret;
		TimeRecord	unpinnedTime;
		
		ret = GetTimeBaseStatus(tb, &unpinnedTime);
		EXTEND(sp, 2);
		XS_PUSH(long, ret);
		XS_PUSH(TimeRecord, unpinnedTime);		
	}


=item SetTimeBaseZero TB, ZERO 

=cut
void
SetTimeBaseZero(tb, zero)
	TimeBase	tb
	TimeRecord &zero


=item GetTimeBaseEffectiveRate TB 

=cut
Fixed
GetTimeBaseEffectiveRate(tb)
	TimeBase	tb

=begin ignore
QTCallBack
NewCallBack(tb, cbType)
	TimeBase	tb
	short	cbType

void
DisposeCallBack(cb)
	QTCallBack	cb

short
GetCallBackType(cb)
	QTCallBack	cb

TimeBase
GetCallBackTimeBase(cb)
	QTCallBack	cb

MacOSRet
CallMeWhen(cb, callBackProc, refCon, param1, param2, param3)
	QTCallBack	cb
	QTCallBackUPP	callBackProc
	long	refCon
	long	param1
	long	param2
	long	param3

void
CancelCallBack(cb)
	QTCallBack	cb

MacOSRet
AddCallBackToTimeBase(cb)
	QTCallBack	cb

MacOSRet
RemoveCallBackFromTimeBase(cb)
	QTCallBack	cb

QTCallBack
GetFirstCallBack(tb)
	TimeBase	tb

QTCallBack
GetNextCallBack(cb)
	QTCallBack	cb

void
ExecuteCallBack(cb)
	QTCallBack	cb

MacOSRet
QueueSyncTask(task)
	QTSyncTaskPtr	task

MacOSRet
DequeueSyncTask(qElem)
	QTSyncTaskPtr	qElem

=end ignore

=cut


=item MCSetMovie MC, THEMOVIE, MOVIEWINDOW, WHERE 

=cut
ComponentResult
MCSetMovie(mc, theMovie, movieWindow, where)
	ComponentInstance	mc
	Movie	theMovie
	GrafPtr	movieWindow
	Point	where


=item MCGetIndMovie MC [, INDEX ]

=cut
Movie
MCGetIndMovie(mc, index=0)
	ComponentInstance	mc
	short	index

=begin ignore

ComponentResult
MCRemoveAllMovies(mc)
	ComponentInstance	mc

ComponentResult
MCRemoveAMovie(mc, m)
	ComponentInstance	mc
	Movie	m

=end ignore

=cut


=item MCRemoveMovie MC 

=cut
ComponentResult
MCRemoveMovie(mc)
	ComponentInstance	mc


=item MCIsPlayerEvent MC, E 

=cut
ComponentResult
MCIsPlayerEvent(mc, e)
	ComponentInstance	mc
	ToolboxEvent		e


=item MCDoAction MC, ACTION, ... 

=cut
void
MCDoAction(mc, action, ...)
	ComponentInstance	mc
	short	action
	PPCODE:
	{
		void *  	param = 0;
		TimeRecord 	tm;
		Fix16   	fix;
		Boolean		flag;
		Rect 		r;
		long		l;
		Fixed 		rate;
		
		switch (action) {
		default:
		case mcActionIdle:
		case mcActionActivate:
		case mcActionDeactivate:
		case mcActionSuspend:
		case mcActionResume:
			break;			/* No parameters */
		case mcActionDraw:
			XS_INPUT(GrafPtr, *(GrafPtr *)&param, ST(2));	/* WindowPtr */
			break;
		case mcActionMouseDown:
		case mcActionKey:
		case mcActionMovieClick:
			XS_INPUT(ToolboxEvent, *(ToolboxEvent *)&param, ST(2));	/* EventRecord * */
			break;
		case mcActionPlay:
			XS_INPUT(Fixed, *(Fixed *)&param, ST(2));	/* Fixed */
			break;
		case mcActionGoToTime:
		case mcActionSetSelectionBegin:
		case mcActionSetSelectionDuration:
			XS_INPUT(TimeRecord, tm, ST(2));	/* TimeRecord */
			param = &tm;
			break;
		case mcActionSetVolume:
			XS_INPUT(Fix16, fix, ST(2));	/* 16 bit fixed point value */
		case mcActionGetVolume:
			param = &fix;
			break;
		case mcActionStep:
		case mcActionSetLooping:
		case mcActionSetLoopIsPalindrome:
		case mcActionSetKeysEnabled:
		case mcActionSetPlaySelection:
		case mcActionSetUseBadge:
		case mcActionSetFlags:
		case mcActionSetPlayEveryFrame:
		case mcActionSetCursorSettingEnabled:
			XS_INPUT(long, *(long *)&param, ST(2));	/* long */
			break;
		case mcActionBadgeClick:
			XS_INPUT(Boolean, flag, ST(2));	/* Boolean, passed as pointer */
		case mcActionGetLooping:
		case mcActionGetLoopIsPalindrome:
		case mcActionGetKeysEnabled:
		case mcActionGetPlaySelection:
		case mcActionGetUseBadge:
		case mcActionGetPlayEveryFrame:
		case mcActionGetCursorSettingEnabled:
			param = &flag;
			break;
		case mcActionSetGrowBoxBounds:
			XS_INPUT(Rect, r, ST(2));	/* Rect */
			param = &r;
			break;
		case mcActionGetFlags:
			param = &l;
			break;
		case mcActionGetPlayRate:
			param = &rate;
			break;
		}
		if (gMacPerl_OSErr = (OSErr)MCDoAction(mc, action, param)) {
			XSRETURN_EMPTY;
		}
		switch (action) {
		default:
			XS_PUSH(int, 1);					/* No result */
			break;
		case mcActionGetVolume:
			XS_PUSH(Fix16, fix);				/* 16 bit fixed */
			break;		
		case mcActionGetLooping:
		case mcActionGetLoopIsPalindrome:
		case mcActionGetKeysEnabled:
		case mcActionGetPlaySelection:
		case mcActionGetUseBadge:
		case mcActionGetPlayEveryFrame:
			XS_PUSH(Boolean, flag);				/* Boolean */
			break;
		case mcActionGetFlags:
			XS_PUSH(long, l);					/* long */
			break;
		case mcActionGetPlayRate:
			XS_PUSH(Fixed, rate);				/* Fixed */
			break;
		}
	}


=item MCSetControllerAttached MC, ATTACH 

=cut
ComponentResult
MCSetControllerAttached(mc, attach)
	ComponentInstance	mc
	Boolean				attach


=item MCIsControllerAttached MC 

=cut
ComponentResult
MCIsControllerAttached(mc)
	ComponentInstance	mc


=item MCSetControllerPort MC, GP 

=cut
ComponentResult
MCSetControllerPort(mc, gp)
	ComponentInstance	mc
	GrafPtr				gp
	CODE:
	RETVAL = MCSetControllerPort(mc, (CGrafPtr)gp);
	OUTPUT:
	RETVAL


=item MCGetControllerPort MC 

=cut
GrafPtr
MCGetControllerPort(mc)
	ComponentInstance	mc
	CODE:
	RETVAL = (GrafPtr)MCGetControllerPort(mc);
	OUTPUT:
	RETVAL


=item MCSetVisible MC, VISIBLE 

=cut
ComponentResult
MCSetVisible(mc, visible)
	ComponentInstance	mc
	Boolean				visible


=item MCGetVisible MC 

=cut
ComponentResult
MCGetVisible(mc)
	ComponentInstance	mc


=item MCGetControllerBoundsRect MC 

=cut
Rect
MCGetControllerBoundsRect(mc)
	ComponentInstance	mc
	CODE:
	if (gMacPerl_OSErr = (OSErr)MCGetControllerBoundsRect(mc, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item MCSetControllerBoundsRect MC, BOUNDS 

=cut
ComponentResult
MCSetControllerBoundsRect(mc, bounds)
	ComponentInstance	mc
	Rect 			   &bounds


=item MCGetControllerBoundsRgn MC 

=cut
RgnHandle
MCGetControllerBoundsRgn(mc)
	ComponentInstance	mc


=item MCGetWindowRgn MC, W 

=cut
RgnHandle
MCGetWindowRgn(mc, w)
	ComponentInstance	mc
	GrafPtr				w


=item MCMovieChanged MC, M 

=cut
ComponentResult
MCMovieChanged(mc, m)
	ComponentInstance	mc
	Movie				m


=item MCSetDuration MC, DURATION 

=cut
ComponentResult
MCSetDuration(mc, duration)
	ComponentInstance	mc
	long				duration


=item MCGetCurrentTime MC 

=cut
void
MCGetCurrentTime(mc)
	ComponentInstance	mc
	PPCODE:
	{
		TimeValue	tm;
		TimeScale 	scale;
		
		tm = MCGetCurrentTime(mc, &scale);
		
		XS_PUSH(long, tm);
		XS_PUSH(long, scale);
	}


=item MCNewAttachedController MC, THEMOVIE, W, WHERE 

=cut
ComponentResult
MCNewAttachedController(mc, theMovie, w, where)
	ComponentInstance	mc
	Movie	theMovie
	GrafPtr	w
	Point	where


=item MCDraw MC, W 

=cut
ComponentResult
MCDraw(mc, w)
	ComponentInstance	mc
	GrafPtr	w


=item MCActivate MC, W, ACTIVATE 

=cut
ComponentResult
MCActivate(mc, w, activate)
	ComponentInstance	mc
	GrafPtr	w
	Boolean	activate


=item MCIdle MC 

=cut
ComponentResult
MCIdle(mc)
	ComponentInstance	mc


=item MCKey MC, KEY, MODIFIERS 

=cut
ComponentResult
MCKey(mc, key, modifiers)
	ComponentInstance	mc
	I8		key
	long	modifiers


=item MCClick MC, W, WHERE, WHEN, MODIFIERS 

=cut
ComponentResult
MCClick(mc, w, where, when, modifiers)
	ComponentInstance	mc
	GrafPtr	w
	Point	where
	long	when
	long	modifiers


=item MCEnableEditing MC, ENABLED 

=cut
ComponentResult
MCEnableEditing(mc, enabled)
	ComponentInstance	mc
	Boolean	enabled


=item MCIsEditingEnabled MC 

=cut
long
MCIsEditingEnabled(mc)
	ComponentInstance	mc


=item MCCopy MC 

=cut
Movie
MCCopy(mc)
	ComponentInstance	mc


=item MCCut MC 

=cut
Movie
MCCut(mc)
	ComponentInstance	mc


=item MCPaste MC, SRCMOVIE 

=cut
ComponentResult
MCPaste(mc, srcMovie)
	ComponentInstance	mc
	Movie	srcMovie


=item MCClear MC 

=cut
ComponentResult
MCClear(mc)
	ComponentInstance	mc


=item MCUndo MC 

=cut
ComponentResult
MCUndo(mc)
	ComponentInstance	mc


=item MCPositionController MC, MOVIERECT, CONTROLLERRECT, SOMEFLAGS 

=cut
ComponentResult
MCPositionController(mc, movieRect, controllerRect, someFlags)
	ComponentInstance	mc
	Rect 			   &movieRect
	Rect 			   &controllerRect
	long				someFlags


=item MCGetControllerInfo MC 

=cut
long
MCGetControllerInfo(mc)
	ComponentInstance	mc
	CODE:
	if (gMacPerl_OSErr = (OSErr)MCGetControllerInfo(mc, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item MCSetClip MC, THECLIP, MOVIECLIP 

=cut
ComponentResult
MCSetClip(mc, theClip, movieClip)
	ComponentInstance	mc
	RgnHandle	theClip
	RgnHandle	movieClip


=item MCGetClip MC 

=cut
void
MCGetClip(mc)
	ComponentInstance	mc
	PPCODE:
	{
		RgnHandle	theClip;
		RgnHandle 	movieClip;
		
		if (gMacPerl_OSErr = (OSErr)MCGetClip(mc, &theClip, &movieClip)) {
			XSRETURN_EMPTY;
		}
		XS_PUSH(RgnHandle, theClip);
		if (GIMME == G_ARRAY) {
			XS_PUSH(RgnHandle, movieClip);
		}
	}


=item MCDrawBadge MC, MOVIERGN 

=cut
RgnHandle
MCDrawBadge(mc, movieRgn)
	ComponentInstance	mc
	RgnHandle	movieRgn
	CODE:
	if (gMacPerl_OSErr = (OSErr)MCDrawBadge(mc, movieRgn, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item MCSetUpEditMenu MC, MODIFIERS, MH 

=cut
ComponentResult
MCSetUpEditMenu(mc, modifiers, mh)
	ComponentInstance	mc
	long	modifiers
	MenuHandle	mh


=item MCGetMenuString MC, MODIFIERS, ITEM, ASTRING 

=cut
ComponentResult
MCGetMenuString(mc, modifiers, item, aString)
	ComponentInstance	mc
	long	modifiers
	short	item
	Str255	aString

void
_MCSetActionFilter(mc, install)
	ComponentInstance	mc
	Boolean				install
	CODE:
	if (install) {
		MCSetActionFilter(mc, &uActionFilter);
	} else {
		MCSetActionFilter(mc, 0);
	}

=begin ignore

# item MCPtInController MC, PT

# cut
Boolean
MCPtInController(mc, thePt)
	ComponentInstance	mc
	Point	thePt
	CODE:
	if (gMacPerl_OSErr = (OSErr)MCPtInController(mc, thePt, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

# item MCInvalidate MC, WIN, RGN 

# cut
ComponentResult
MCInvalidate(mc, w, invalidRgn)
	ComponentInstance	mc
	GrafPtr	w
	RgnHandle	invalidRgn

=end ignore

=back

=cut
