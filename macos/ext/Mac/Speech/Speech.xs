/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Speech/Speech.xs,v 1.2 2000/09/09 22:18:28 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Speech.xs,v $
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:33  neeri
 * Checked into Sourceforge
 *
 * Revision 1.4  1998/04/07 01:03:15  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.3  1997/11/18 00:53:21  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.2  1997/08/08 16:39:30  neeri
 * MacPerl 5.1.4b1 + time() fix
 *
 * Revision 1.1  1997/04/07 20:50:45  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Speech.h>

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

#ifdef __CFM68K__

#undef FOURWORDINLINE
#define FOURWORDINLINE(w1,w2,w3,w4)  = {w1,w2,w3,w4}

extern pascal NumVersion SpeechManagerVersion(void)
 FOURWORDINLINE(0x203C, 0x0000, 0x000C, 0xA800);

extern pascal OSErr MakeVoiceSpec(OSType creator, OSType id, VoiceSpec *voice)
 FOURWORDINLINE(0x203C, 0x0604, 0x000C, 0xA800);

extern pascal OSErr CountVoices(short *numVoices)
 FOURWORDINLINE(0x203C, 0x0108, 0x000C, 0xA800);

extern pascal OSErr GetIndVoice(short index, VoiceSpec *voice)
 FOURWORDINLINE(0x203C, 0x030C, 0x000C, 0xA800);

extern pascal OSErr GetVoiceDescription(const VoiceSpec *voice, VoiceDescription *info, long infoLength)
 FOURWORDINLINE(0x203C, 0x0610, 0x000C, 0xA800);

extern pascal OSErr GetVoiceInfo(const VoiceSpec *voice, OSType selector, void *voiceInfo)
 FOURWORDINLINE(0x203C, 0x0614, 0x000C, 0xA800);

extern pascal OSErr NewSpeechChannel(VoiceSpec *voice, SpeechChannel *chan)
 FOURWORDINLINE(0x203C, 0x0418, 0x000C, 0xA800);

extern pascal OSErr DisposeSpeechChannel(SpeechChannel chan)
 FOURWORDINLINE(0x203C, 0x021C, 0x000C, 0xA800);

extern pascal OSErr SpeakString(ConstStr255Param s)
 FOURWORDINLINE(0x203C, 0x0220, 0x000C, 0xA800);

extern pascal OSErr SpeakText(SpeechChannel chan, const void * textBuf, unsigned long textBytes)
 FOURWORDINLINE(0x203C, 0x0624, 0x000C, 0xA800);

extern pascal OSErr SpeakBuffer(SpeechChannel chan, const void * textBuf, unsigned long textBytes, long controlFlags)
 FOURWORDINLINE(0x203C, 0x0828, 0x000C, 0xA800);

extern pascal OSErr StopSpeech(SpeechChannel chan)
 FOURWORDINLINE(0x203C, 0x022C, 0x000C, 0xA800);

extern pascal OSErr StopSpeechAt(SpeechChannel chan, long whereToStop)
 FOURWORDINLINE(0x203C, 0x0430, 0x000C, 0xA800);

extern pascal OSErr PauseSpeechAt(SpeechChannel chan, long whereToPause)
 FOURWORDINLINE(0x203C, 0x0434, 0x000C, 0xA800);

extern pascal OSErr ContinueSpeech(SpeechChannel chan)
 FOURWORDINLINE(0x203C, 0x0238, 0x000C, 0xA800);

extern pascal short SpeechBusy(void)
 FOURWORDINLINE(0x203C, 0x003C, 0x000C, 0xA800);

extern pascal short SpeechBusySystemWide(void)
 FOURWORDINLINE(0x203C, 0x0040, 0x000C, 0xA800);

extern pascal OSErr SetSpeechRate(SpeechChannel chan, Fixed rate)
 FOURWORDINLINE(0x203C, 0x0444, 0x000C, 0xA800);

extern pascal OSErr GetSpeechRate(SpeechChannel chan, Fixed *rate)
 FOURWORDINLINE(0x203C, 0x0448, 0x000C, 0xA800);

extern pascal OSErr SetSpeechPitch(SpeechChannel chan, Fixed pitch)
 FOURWORDINLINE(0x203C, 0x044C, 0x000C, 0xA800);

extern pascal OSErr GetSpeechPitch(SpeechChannel chan, Fixed *pitch)
 FOURWORDINLINE(0x203C, 0x0450, 0x000C, 0xA800);

extern pascal OSErr SetSpeechInfo(SpeechChannel chan, OSType selector, const void *speechInfo)
 FOURWORDINLINE(0x203C, 0x0654, 0x000C, 0xA800);

extern pascal OSErr GetSpeechInfo(SpeechChannel chan, OSType selector, void *speechInfo)
 FOURWORDINLINE(0x203C, 0x0658, 0x000C, 0xA800);

extern pascal OSErr TextToPhonemes(SpeechChannel chan, const void * textBuf, unsigned long textBytes, Handle phonemeBuf, long *phonemeBytes)
 FOURWORDINLINE(0x203C, 0x0A5C, 0x000C, 0xA800);

extern pascal OSErr UseDictionary(SpeechChannel chan, Handle dictionary)
 FOURWORDINLINE(0x203C, 0x0460, 0x000C, 0xA800);

#endif

#define SpeechFail(error)	if (gMacPerl_OSErr = (error)) { XSRETURN_UNDEF; } else 0

MODULE = Mac::Speech	PACKAGE = Mac::Speech

=head2 Functions

=over 4

=item SpeechManagerVersion 

=cut
NumVersion 
SpeechManagerVersion()


=item CountVoices 

=cut
short
CountVoices()
	CODE:
	SpeechFail(CountVoices(&RETVAL));
	OUTPUT:
	RETVAL


=item GetIndVoice INDEX 

=cut
VoiceSpec
GetIndVoice(index)
	short index
	CODE:
	SpeechFail(GetIndVoice(index, &RETVAL));
	OUTPUT:
	RETVAL
	

=item GetVoiceDescription VOICE 

=cut
VoiceDescription
GetVoiceDescription(voice)
	VoiceSpec &voice
	CODE:
	SpeechFail(GetVoiceDescription(&voice, &RETVAL, sizeof(RETVAL)));
	OUTPUT:
	RETVAL


=item NewSpeechChannel VOICE 

=cut
SpeechChannel
NewSpeechChannel(voice)
	VoiceSpec &voice
	CODE:
	SpeechFail(NewSpeechChannel(&voice, &RETVAL));
	OUTPUT:
	RETVAL


=item DisposeSpeechChannel CHAN 

=cut
MacOSRet
DisposeSpeechChannel(chan)
	SpeechChannel chan


=item SpeakString S 

=cut
MacOSRet
SpeakString(s)
	Str255 s;


=item SpeakText CHAN, TEXT 

=cut
MacOSRet
SpeakText(chan, text)
	SpeechChannel 	chan
	SV *			text
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		RETVAL	= 	SpeakText(chan, textPtr, textSize);
	}
	OUTPUT:
	RETVAL


=item SpeakBuffer CHAN, TEXT, CONTROLFLAGS 

=cut
MacOSRet
SpeakBuffer(chan, text, controlFlags)
	SpeechChannel 	chan
	SV *			text
	long			controlFlags
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		RETVAL	= 	SpeakBuffer(chan, textPtr, textSize, controlFlags);
	}
	OUTPUT:
	RETVAL


=item StopSpeech CHAN 

=cut
MacOSRet
StopSpeech(chan)
	SpeechChannel chan


=item StopSpeechAt CHAN, WHERETOSTOP 

=cut
MacOSRet
StopSpeechAt(chan, whereToStop)
	SpeechChannel 	chan
	long		  	whereToStop


=item PauseSpeechAt CHAN, WHERETOPAUSE 

=cut
MacOSRet
PauseSpeechAt(chan, whereToPause)
	SpeechChannel 	chan
	long		  	whereToPause


=item ContinueSpeech CHAN 

=cut
MacOSRet
ContinueSpeech(chan)
	SpeechChannel chan


=item SpeechBusy 

=cut
int
SpeechBusy()


=item SpeechBusySystemWide 

=cut
int
SpeechBusySystemWide()


=item SetSpeechRate CHAN, RATE 

=cut
MacOSRet
SetSpeechRate(chan, rate)
	SpeechChannel 	chan
	Fixed 			rate


=item GetSpeechRate CHAN 

=cut
Fixed
GetSpeechRate(chan)
	SpeechChannel	chan
	CODE:
	SpeechFail(GetSpeechRate(chan, &RETVAL));
	OUTPUT:
	RETVAL


=item SetSpeechPitch CHAN, PITCH 

=cut
MacOSRet
SetSpeechPitch(chan, pitch)
	SpeechChannel 	chan
	Fixed 			pitch


=item GetSpeechPitch CHAN 

=cut
Fixed
GetSpeechPitch(chan)
	SpeechChannel	chan
	CODE:
	SpeechFail(GetSpeechPitch(chan, &RETVAL));
	OUTPUT:
	RETVAL

=item TextToPhonemes CHAN, TEXT

=cut
SV *
TextToPhonemes(chan, text)
	SpeechChannel 	chan
	SV *			text
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		long	phonSize;
		Handle	h;
		
		textPtr = 	SvPV(text, textSize);
		h = NewHandle(textSize*3+1024);
		SpeechFail(TextToPhonemes(chan, textPtr, textSize, h, &phonSize));
		HLock(h);
		RETVAL	= 	newSVpv(*h, phonSize);
		DisposeHandle(h);
	}
	OUTPUT:
	RETVAL

=back

=cut
