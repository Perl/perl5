/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 * MacPerl 5.1.5
 * 
 * Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Sound.h>

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

#define UnsignedFixedMulDiv(x,y,z)		not_here("UnsignedFixedMulDiv")
#define GetCompressionInfo(x,y,z,a,b)	not_here("GetCompressionInfo")
#define SetSoundPreference(x,y,z)		not_here("SetSoundPreference")
#define GetSoundPreference(x,y,z)		not_here("GetSoundPreference")
#define GetCompressionName(x,y)			not_here("GetCompressionName")
#endif

#define SndChannel	SndChannelPtr

static int
not_here(s)
char *s;
{
    croak("Mac::Sound::%s not implemented in CFM68K (Apple's fault)", s);
    return -1;
}

MODULE = Mac::Sound	PACKAGE = Mac::Sound

=head2 Structures

=over 4

=cut

STRUCT SndCommand
	U16 			cmd;
	short 			param1;
	long 			param2;

STRUCT SCStatus
	UnsignedFixed 	scStartTime;
	UnsignedFixed 	scEndTime;
	UnsignedFixed 	scCurrentTime;
	Boolean 		scChannelBusy;
	Boolean 		scChannelDisposed;
	Boolean 		scChannelPaused;
	Boolean 		scUnused;
	U32			 	scChannelAttributes;
	long 			scCPULoad;

STRUCT SMStatus
	short 			smMaxCPULoad;
	short 			smNumChannels;
	short 			smCurCPULoad;

STRUCT CompressionInfo
	long 			recordSize;
	OSType 			format;
	short 			compressionID;
	U16				samplesPerPacket;
	U16				bytesPerPacket;
	U16				bytesPerFrame;
	U16				bytesPerSample;

STRUCT SPB
	long 			inRefNum;					/*reference number of sound input device*/
	unsigned long 	count;						/*number of bytes to record*/
	unsigned long 	milliseconds;				/*number of milliseconds to record*/
	unsigned long 	bufferLength;				/*length of buffer in bytes*/
	Ptr 			bufferPtr;					/*buffer to store sound data in*/
	OSErr 			error;						/*error*/

=back

=head2 Functions

=over 4

=cut

void
SysBeep(duration)
	short	duration

MacOSRet
SndDoCommand(chan, cmd, noWait)
	SndChannel	chan
	SndCommand &cmd
	Boolean		noWait

MacOSRet
SndDoImmediate(chan, cmd)
	SndChannel	chan
	SndCommand &cmd

SndChannel
SndNewChannel(synth, init, callback=0)
	short	synth
	long	init
	SV *	callback
	CODE:
	RETVAL = nil;
	if (gMacPerl_OSErr = SndNewChannel(&RETVAL, synth, init, nil)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SndDisposeChannel(chan, quietNow=false)
	SndChannel	chan
	Boolean	quietNow

MacOSRet
_SndPlay(chan, sndHandle, async=false)
	SndChannel	chan
	Handle	sndHandle
	Boolean	async
	CODE:
	RETVAL = SndPlay(chan, (SndListHandle)sndHandle, async);
	OUTPUT:
	RETVAL

SndCommand
SndControl(id, cmd)
	short	id
	SndCommand &cmd
	CODE:
	RETVAL = cmd;
	if (gMacPerl_OSErr = SndControl(id, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

NumVersion
SndSoundManagerVersion()

MacOSRet
SndStartFilePlay(chan, fRefNum, resNum, bufferSize, theSelection, theCompletion=0, async=false)
	SndChannel	chan
	short	fRefNum
	short	resNum
	long	bufferSize
	AudioSelection	&theSelection
	SV *	theCompletion
	Boolean	async
	CODE:
	RETVAL =
		SndStartFilePlay(
			chan, fRefNum, resNum, bufferSize, nil, &theSelection, nil, async);
	OUTPUT:
	RETVAL

MacOSRet
SndPauseFilePlay(chan)
	SndChannel	chan

MacOSRet
SndStopFilePlay(chan, quietNow)
	SndChannel	chan
	Boolean	quietNow

SCStatus
SndChannelStatus(chan)
	SndChannel	chan
	CODE:
	if (gMacPerl_OSErr = SndChannelStatus(chan, sizeof(RETVAL), &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

SMStatus
SndManagerStatus()
	CODE:
	if (gMacPerl_OSErr = SndManagerStatus(sizeof(RETVAL), &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

short
SndGetSysBeepState()
	CODE:
	SndGetSysBeepState(&RETVAL);
	OUTPUT:
	RETVAL

MacOSRet
SndSetSysBeepState(sysBeepState)
	short	sysBeepState

=begin ignore

MacOSRet
SndPlayDoubleBuffer(chan, theParams)
	SndChannel	chan
	SndDoubleBufferHeaderPtr	theParams

=end ignore

=cut

NumVersion
MACEVersion()

void
Comp3to1(inBuffer, inState=NO_INIT, numChannels=1, whichChannel=1)
	SV *			inBuffer
	StateBlock		inState
	unsigned long	numChannels
	unsigned long	whichChannel
	PPCODE:
	{
		unsigned long 	cnt = SvCUR(inBuffer);
		SV *			outBuffer = newSVpv("", cnt / 3);
		StateBlock		outState;
		Comp3to1(
			SvPV_nolen(inBuffer), SvPV_nolen(outBuffer), cnt, 
			(items > 1) ? &inState : nil, &outState, numChannels, whichChannel);
		PUSHs(sv_2mortal(outBuffer));
		if (GIMME == G_ARRAY) {
			XS_PUSH(StateBlock, outState);
		}
	}

void
Exp1to3(inBuffer, inState=NO_INIT, numChannels=1, whichChannel=1)
	SV *			inBuffer
	StateBlock		inState
	unsigned long	numChannels
	unsigned long	whichChannel
	PPCODE:
	{
		unsigned long 	cnt = SvCUR(inBuffer) / 2;
		SV *			outBuffer = newSVpv("", cnt*6);
		StateBlock		outState;
		Exp1to3(
			SvPV_nolen(inBuffer), SvPV_nolen(outBuffer), cnt, 
			(items > 1) ? &inState : nil, &outState, numChannels, whichChannel);
		PUSHs(sv_2mortal(outBuffer));
		if (GIMME == G_ARRAY) {
			XS_PUSH(StateBlock, outState);
		}
	}

void
Comp6to1(inBuffer, inState=NO_INIT, numChannels=1, whichChannel=1)
	SV *			inBuffer
	StateBlock		inState
	unsigned long	numChannels
	unsigned long	whichChannel
	PPCODE:
	{
		unsigned long 	cnt = SvCUR(inBuffer);
		SV *			outBuffer = newSVpv("", cnt / 6);
		StateBlock		outState;
		Comp6to1(
			SvPV_nolen(inBuffer), SvPV_nolen(outBuffer), cnt, 
			(items > 1) ? &inState : nil, &outState, numChannels, whichChannel);
		PUSHs(sv_2mortal(outBuffer));
		if (GIMME == G_ARRAY) {
			XS_PUSH(StateBlock, outState);
		}
	}

void
Exp1to6(inBuffer, inState=NO_INIT, numChannels=1, whichChannel=1)
	SV *			inBuffer
	StateBlock		inState
	unsigned long	numChannels
	unsigned long	whichChannel
	PPCODE:
	{
		unsigned long 	cnt = SvCUR(inBuffer);
		SV *			outBuffer = newSVpv("", cnt * 6);
		StateBlock		outState;
		Exp1to6(
			SvPV_nolen(inBuffer), SvPV_nolen(outBuffer), cnt, 
			(items > 1) ? &inState : nil, &outState, numChannels, whichChannel);
		PUSHs(sv_2mortal(outBuffer));
		if (GIMME == G_ARRAY) {
			XS_PUSH(StateBlock, outState);
		}
	}

long
GetSysBeepVolume()
	CODE:
	if (gMacPerl_OSErr = GetSysBeepVolume(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SetSysBeepVolume(level)
	long	level

long
GetDefaultOutputVolume()
	CODE:
	if (gMacPerl_OSErr = GetDefaultOutputVolume(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SetDefaultOutputVolume(level)
	long	level

long
GetSoundHeaderOffset(sndHandle)
	Handle	sndHandle
	CODE:
	if (gMacPerl_OSErr = GetSoundHeaderOffset((SndListHandle)sndHandle, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

UnsignedFixed
UnsignedFixedMulDiv(value, multiplier, divisor)
	UnsignedFixed	value
	UnsignedFixed	multiplier
	UnsignedFixed	divisor

CompressionInfo
GetCompressionInfo(compressionID, format, numChannels, sampleSize)
	short	compressionID
	OSType	format
	short	numChannels
	short	sampleSize
	CODE:
	if (gMacPerl_OSErr = 
		GetCompressionInfo(
			compressionID, format, numChannels, sampleSize, &RETVAL)
	) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SetSoundPreference(theType, name, settings)
	OSType	theType
	Str255	name
	Handle	settings

MacOSRet
_GetSoundPreference(theType, name, settings)
	OSType	theType
	Str255	name
	Handle	settings
	CODE:
	RETVAL = GetSoundPreference(theType, name, settings);
	OUTPUT:
	RETVAL

=begin ignore

MacOSRet
OpenMixerSoundComponent(outputDescription, outputFlags, mixerComponent)
	SoundComponentDataPtr	outputDescription
	long	outputFlags
	ComponentInstance *	mixerComponent

MacOSRet
CloseMixerSoundComponent(ci)
	ComponentInstance	ci

MacOSRet
SndGetInfo(chan, selector, infoPtr)
	SndChannel	chan
	OSType	selector
	void *	infoPtr

MacOSRet
SndSetInfo(chan, selector, infoPtr)
	SndChannel	chan
	OSType	selector
	const void *	infoPtr

MacOSRet
GetSoundOutputInfo(outputDevice, selector, infoPtr)
	Component	outputDevice
	OSType	selector
	void *	infoPtr

MacOSRet
SetSoundOutputInfo(outputDevice, selector, infoPtr)
	Component	outputDevice
	OSType	selector
	const void *	infoPtr

=end ignore

=cut

Str255
GetCompressionName(compressionType)
	OSType	compressionType
	CODE:
	if (gMacPerl_OSErr = GetCompressionName(compressionType, RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=begin ignore

MacOSRet
SoundConverterOpen(inputFormat, outputFormat, sc)
	const SoundComponentData *	inputFormat
	const SoundComponentData *	outputFormat
	SoundConverter *	sc

MacOSRet
SoundConverterClose(sc)
	SoundConverter	sc

MacOSRet
SoundConverterGetBufferSizes(sc, inputBytesTarget, inputFrames, inputBytes, outputBytes)
	SoundConverter	sc
	unsigned long	inputBytesTarget
	unsigned long *	inputFrames
	unsigned long *	inputBytes
	unsigned long *	outputBytes

MacOSRet
SoundConverterBeginConversion(sc)
	SoundConverter	sc

MacOSRet
SoundConverterConvertBuffer(sc, inputPtr, inputFrames, outputPtr, outputFrames, outputBytes)
	SoundConverter	sc
	const void *	inputPtr
	unsigned long	inputFrames
	void *	outputPtr
	unsigned long *	outputFrames
	unsigned long *	outputBytes

MacOSRet
SoundConverterEndConversion(sc, outputPtr, outputFrames, outputBytes)
	SoundConverter	sc
	void *	outputPtr
	unsigned long *	outputFrames
	unsigned long *	outputBytes

=end ignore

=cut

NumVersion
SPBVersion()
		

Handle
SndRecord(filterProc, corner, quality)
	SV *	filterProc
	Point	corner
	OSType	quality
	CODE:
	{
		RETVAL = nil;
		if (gMacPerl_OSErr = 
			SndRecord(nil, corner, quality, (SndListHandle *)&RETVAL)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

MacOSRet
SndRecordToFile(filterProc, corner, quality, fRefNum)
	SV *	filterProc
	Point	corner
	OSType	quality
	short	fRefNum
	CODE:
	RETVAL = SndRecordToFile(nil, corner, quality, fRefNum);
	OUTPUT:
	RETVAL

MacOSRet
SPBSignInDevice(deviceRefNum, deviceName)
	short	deviceRefNum
	Str255	deviceName

MacOSRet
SPBSignOutDevice(deviceRefNum)
	short	deviceRefNum

void
SPBGetIndexedDevice(count)
	short	count
	PPCODE:
	{
		Str255	name;
		Handle 	icon;
		
		if (gMacPerl_OSErr = SPBGetIndexedDevice(count, name, &icon)) {
			XSRETURN_UNDEF;
		}
		XS_PUSH(Str255, name);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(Handle, icon);
		} else {
			DisposeHandle(icon);
		}
	}

long
SPBOpenDevice(deviceName, permission)
	Str255	deviceName
	short	permission
	CODE:
	if (gMacPerl_OSErr = SPBOpenDevice(deviceName, permission, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SPBCloseDevice(inRefNum)
	long	inRefNum

MacOSRet
SPBRecord(inParamPtr, asynchFlag=false)
	SPB	   &inParamPtr
	Boolean	asynchFlag

MacOSRet
SPBRecordToFile(fRefNum, inParamPtr, asynchFlag=false)
	short	fRefNum
	SPB	   &inParamPtr
	Boolean	asynchFlag

MacOSRet
SPBPauseRecording(inRefNum)
	long	inRefNum

MacOSRet
SPBResumeRecording(inRefNum)
	long	inRefNum

MacOSRet
SPBStopRecording(inRefNum)
	long	inRefNum

void
SPBGetRecordingStatus(inRefNum)
	long	inRefNum
	PPCODE:
	{
		short recordingStatus;
		short meterLevel;
		unsigned long totalSamplesToRecord;
		unsigned long numberOfSamplesRecorded;
		unsigned long totalMsecsToRecord;
		unsigned long numberOfMsecsRecorded;
		
		if (gMacPerl_OSErr = 
			SPBGetRecordingStatus(
				inRefNum, &recordingStatus, &meterLevel,
				&totalSamplesToRecord, &numberOfSamplesRecorded,
				&totalMsecsToRecord, &numberOfMsecsRecorded)
		) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(short, recordingStatus);
		XS_XPUSH(short, meterLevel);
		XS_XPUSH(U32, totalSamplesToRecord);
		XS_XPUSH(U32, numberOfSamplesRecorded);
		XS_XPUSH(U32, totalMsecsToRecord);
		XS_XPUSH(U32, numberOfMsecsRecorded);
	}

=begin ignore

MacOSRet
SPBGetDeviceInfo(inRefNum, infoType, infoData)
	long	inRefNum
	OSType	infoType
	void *	infoData

MacOSRet
SPBSetDeviceInfo(inRefNum, infoType, infoData)
	long	inRefNum
	OSType	infoType
	void *	infoData

=end ignore

long
SPBMillisecondsToBytes(inRefNum)
	long	inRefNum
	CODE:
	if (gMacPerl_OSErr = SPBMillisecondsToBytes(inRefNum, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
long
SPBBytesToMilliseconds(inRefNum)
	long	inRefNum
	CODE:
	if (gMacPerl_OSErr = SPBBytesToMilliseconds(inRefNum, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

short
SetupSndHeader(sndHandle, numChannels, sampleRate, sampleSize, compressionType, baseNote, numBytes)
	Handle	sndHandle
	short	numChannels
	UnsignedFixed	sampleRate
	short	sampleSize
	OSType	compressionType
	short	baseNote
	unsigned long	numBytes
	CODE:
	if (gMacPerl_OSErr = 
		SetupSndHeader(
			(SndListHandle)sndHandle, numChannels, sampleRate, sampleSize, 
			compressionType, baseNote, numBytes, &RETVAL)
	) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

MacOSRet
SetupAIFFHeader(fRefNum, numChannels, sampleRate, sampleSize, compressionType, numBytes, numFrames)
	short	fRefNum
	short	numChannels
	UnsignedFixed	sampleRate
	short	sampleSize
	OSType	compressionType
	unsigned long	numBytes
	unsigned long	numFrames

=begin ignore

MacOSRet
ParseAIFFHeader(fRefNum, sndInfo, numFrames, dataOffset)
	short	fRefNum
	SoundComponentData *	sndInfo
	unsigned long *	numFrames
	unsigned long *	dataOffset

MacOSRet
ParseSndHeader(sndHandle, sndInfo, numFrames, dataOffset)
	SndListHandle	sndHandle
	SoundComponentData *	sndInfo
	unsigned long *	numFrames
	unsigned long *	dataOffset

=end ignore

=back

=cut
