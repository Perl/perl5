/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/SpeechRecognition/SpeechRecognition.xs,v 1.2 2000/09/09 22:18:28 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: SpeechRecognition.xs,v $
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:33  neeri
 * Checked into Sourceforge
 *
 * Revision 1.3  1997/11/18 00:53:23  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.2  1997/08/08 16:39:31  neeri
 * MacPerl 5.1.4b1 + time() fix
 *
 * Revision 1.1  1997/04/07 20:50:51  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <GUSIFileSpec.h>
#include <SpeechRecognition.h>

#ifdef __CFM68K__

#undef THREEWORDINLINE
#define THREEWORDINLINE(w1,w2,w3)  = {w1,w2,w3}

extern pascal OSErr SROpenRecognitionSystem(SRRecognitionSystem *system, OSType systemID)
 THREEWORDINLINE(0x303C, 0x0400, 0xAA56);

extern pascal OSErr SRCloseRecognitionSystem(SRRecognitionSystem system)
 THREEWORDINLINE(0x303C, 0x0201, 0xAA56);

extern pascal OSErr SRSetProperty(SRSpeechObject srObject, OSType selector, const void *property, Size propertyLen)
 THREEWORDINLINE(0x303C, 0x0802, 0xAA56);

extern pascal OSErr SRGetProperty(SRSpeechObject srObject, OSType selector, void *property, Size *propertyLen)
 THREEWORDINLINE(0x303C, 0x0803, 0xAA56);

extern pascal OSErr SRReleaseObject(SRSpeechObject srObject)
 THREEWORDINLINE(0x303C, 0x0204, 0xAA56);

extern pascal OSErr SRGetReference(SRSpeechObject srObject, SRSpeechObject *newObjectRef)
 THREEWORDINLINE(0x303C, 0x0425, 0xAA56);

extern pascal OSErr SRNewRecognizer(SRRecognitionSystem system, SRRecognizer *recognizer, OSType sourceID)
 THREEWORDINLINE(0x303C, 0x060A, 0xAA56);

extern pascal OSErr SRStartListening(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x020C, 0xAA56);

extern pascal OSErr SRStopListening(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x020D, 0xAA56);

extern pascal OSErr SRSetLanguageModel(SRRecognizer recognizer, SRLanguageModel languageModel)
 THREEWORDINLINE(0x303C, 0x040E, 0xAA56);

extern pascal OSErr SRGetLanguageModel(SRRecognizer recognizer, SRLanguageModel *languageModel)
 THREEWORDINLINE(0x303C, 0x040F, 0xAA56);

extern pascal OSErr SRContinueRecognition(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x0210, 0xAA56);

extern pascal OSErr SRCancelRecognition(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x0211, 0xAA56);

extern pascal OSErr SRIdle(void )
 THREEWORDINLINE(0x303C, 0x0028, 0xAA56);

extern pascal OSErr SRNewLanguageModel(SRRecognitionSystem system, SRLanguageModel *model, const void *name, Size nameLength)
 THREEWORDINLINE(0x303C, 0x0812, 0xAA56);

extern pascal OSErr SRNewPath(SRRecognitionSystem system, SRPath *path)
 THREEWORDINLINE(0x303C, 0x0413, 0xAA56);

extern pascal OSErr SRNewPhrase(SRRecognitionSystem system, SRPhrase *phrase, const void *text, Size textLength)
 THREEWORDINLINE(0x303C, 0x0814, 0xAA56);

extern pascal OSErr SRNewWord(SRRecognitionSystem system, SRWord *word, const void *text, Size textLength)
 THREEWORDINLINE(0x303C, 0x0815, 0xAA56);

extern pascal OSErr SRPutLanguageObjectIntoHandle(SRLanguageObject languageObject, Handle lobjHandle)
 THREEWORDINLINE(0x303C, 0x0416, 0xAA56);

extern pascal OSErr SRPutLanguageObjectIntoDataFile(SRLanguageObject languageObject, short fRefNum)
 THREEWORDINLINE(0x303C, 0x0328, 0xAA56);

extern pascal OSErr SRNewLanguageObjectFromHandle(SRRecognitionSystem system, SRLanguageObject *languageObject, Handle lObjHandle)
 THREEWORDINLINE(0x303C, 0x0417, 0xAA56);

extern pascal OSErr SRNewLanguageObjectFromDataFile(SRRecognitionSystem system, SRLanguageObject *languageObject, short fRefNum)
 THREEWORDINLINE(0x303C, 0x0427, 0xAA56);

extern pascal OSErr SREmptyLanguageObject(SRLanguageObject languageObject)
 THREEWORDINLINE(0x303C, 0x0218, 0xAA56);

extern pascal OSErr SRChangeLanguageObject(SRLanguageObject languageObject, const void *text, Size textLength)
 THREEWORDINLINE(0x303C, 0x0619, 0xAA56);

extern pascal OSErr SRAddLanguageObject(SRLanguageObject base, SRLanguageObject addon)
 THREEWORDINLINE(0x303C, 0x041A, 0xAA56);

extern pascal OSErr SRAddText(SRLanguageObject base, const void *text, Size textLength, long refCon)
 THREEWORDINLINE(0x303C, 0x081B, 0xAA56);

extern pascal OSErr SRRemoveLanguageObject(SRLanguageObject base, SRLanguageObject toRemove)
 THREEWORDINLINE(0x303C, 0x041C, 0xAA56);

extern pascal OSErr SRCountItems(SRSpeechObject container, long *count)
 THREEWORDINLINE(0x303C, 0x0405, 0xAA56);

extern pascal OSErr SRGetIndexedItem(SRSpeechObject container, SRSpeechObject *item, long index)
 THREEWORDINLINE(0x303C, 0x0606, 0xAA56);

extern pascal OSErr SRSetIndexedItem(SRSpeechObject container, SRSpeechObject item, long index)
 THREEWORDINLINE(0x303C, 0x0607, 0xAA56);

extern pascal OSErr SRRemoveIndexedItem(SRSpeechObject container, long index)
 THREEWORDINLINE(0x303C, 0x0408, 0xAA56);

extern pascal OSErr SRDrawText(SRRecognizer recognizer, const void *dispText, Size dispLength)
 THREEWORDINLINE(0x303C, 0x0621, 0xAA56);

extern pascal OSErr SRDrawRecognizedText(SRRecognizer recognizer, const void *dispText, Size dispLength)
 THREEWORDINLINE(0x303C, 0x0622, 0xAA56);

extern pascal OSErr SRSpeakText(SRRecognizer recognizer, const void *speakText, Size speakLength)
 THREEWORDINLINE(0x303C, 0x0620, 0xAA56);

extern pascal OSErr SRSpeakAndDrawText(SRRecognizer recognizer, const void *text, Size textLength)
 THREEWORDINLINE(0x303C, 0x061F, 0xAA56);

extern pascal OSErr SRStopSpeech(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x0223, 0xAA56);

extern pascal Boolean SRSpeechBusy(SRRecognizer recognizer)
 THREEWORDINLINE(0x303C, 0x0224, 0xAA56);

extern pascal OSErr SRProcessBegin(SRRecognizer recognizer, Boolean failed)
 THREEWORDINLINE(0x303C, 0x031D, 0xAA56);

extern pascal OSErr SRProcessEnd(SRRecognizer recognizer, Boolean failed)
 THREEWORDINLINE(0x303C, 0x031E, 0xAA56);
#endif

#define SpeechFail(error)	if (gMacPerl_OSErr = (error)) { XSRETURN_UNDEF; } else 0

MODULE = Mac::SpeechRecognition	PACKAGE = Mac::SpeechRecognition

=head2 Functions

=over 4

=item SRMakeSpeechObject OBJ 

=cut
SRSpeechObject
SRMakeSpeechObject(obj)
	OSType	obj
	CODE:
	RETVAL = (SRSpeechObject) obj;
	OUTPUT:
	RETVAL


=item SROpenRecognitionSystem [ SYSTEMID ]

=cut
SRSpeechObject
SROpenRecognitionSystem(systemID=0)
	OSType 	systemID
	CODE:
	SpeechFail(SROpenRecognitionSystem(&RETVAL, systemID));
	OUTPUT:
	RETVAL


=item SRCloseRecognitionSystem SYSTEM 

=cut
MacOSRet
SRCloseRecognitionSystem(system)
	SRSpeechObject 	system


=item SRSetProperty SROBJECT, SELECTOR, PROPERTY 

=cut
MacOSRet
SRSetProperty(srObject, selector, property)
	SRSpeechObject 	srObject
	OSType 			selector
	SV *			property
	CODE:
	{
		STRLEN	propSize;
		char 	buf[256];
		void *	propPtr	= buf;
		switch (selector) {
		case kSRForegroundOnly:
		case kSRBlockBackground:
		case kSRBlockModally:
		case kSRWantsResultTextDrawn:
		case kSRWantsAutoFBGestures:
		case kSRCancelOnSoundOut:
		case kSROptional:
		case kSREnabled:
		case kSRRepeatable:
		case kSRRejectable:
			*(Boolean *)buf	= (Boolean) SvIV(property);
			propSize 	= 1;
			break;
		case kSRFeedbackAndListeningModes:
		case kSRSoundInVolume:
		case kSRListenKeyMode:
		case kSRListenKeyCombo:
		case kSRRejectionLevel:
			*(u_short *)buf	= (u_short) SvIV(property);
			propSize 	= 2;
			break;
		case kSRNotificationParam:
		case kSRSearchStatusParam:
		case kSRRefCon:
			*(u_long *)buf	= (u_long) SvIV(property);
			propSize 	= 4;
			break;
		case kSRLMObjType:
			memcpy(buf, SvPV_nolen(property), propSize = 4);
			break;
		case kSRRejectedWord:
		case kSRLanguageModelFormat:
		case kSRPathFormat:
		case kSRPhraseFormat:
			if (sv_isa(property, "SRSpeechObject"))
	    		*(SRSpeechObject *)buf = (SRSpeechObject)SvIV((SV*)SvRV(property));
			else
	    		croak("property is not of type SRSpeechObject");
			propSize 	= 4;
			break;
		case kSRReadAudioFSSpec:
			GUSIPath2FSp((char *) SvPV_nolen(property), (FSSpec *)buf);
			propSize = sizeof(FSSpec);
			break;
		case kSRListenKeyName:
		case kSRKeyWord:
			MacPerl_CopyC2P(SvPV_nolen(property), (StringPtr) buf);
			propSize = *buf+1;
			break;
		case kSRTEXTFormat:
		case kSRSpelling:
			propPtr = SvPV(property, propSize);
			break;
		}
		RETVAL = SRSetProperty(srObject, selector, propPtr, propSize);
	}
	OUTPUT:
	RETVAL


=item SRGetProperty SROBJECT, SELECTOR 

=cut
void
SRGetProperty(srObject, selector)
	SRSpeechObject 	srObject
	OSType 			selector
	CODE:
	{
		STRLEN	propSize;
		char 	buf[256];
		void *	propPtr	= buf;
		*(long *)buf = 0;
		switch (selector) {
		case kSRForegroundOnly:
		case kSRBlockBackground:
		case kSRBlockModally:
		case kSRWantsResultTextDrawn:
		case kSRWantsAutoFBGestures:
		case kSRCancelOnSoundOut:
		case kSROptional:
		case kSREnabled:
		case kSRRepeatable:
		case kSRRejectable:
			propPtr = buf+3;
			propSize= 1;
			break;
		case kSRFeedbackAndListeningModes:
		case kSRSoundInVolume:
		case kSRListenKeyMode:
		case kSRListenKeyCombo:
		case kSRRejectionLevel:
			propPtr = buf+2;
			propSize= 2;
			break;
		case kSRNotificationParam:
		case kSRSearchStatusParam:
		case kSRRefCon:
		case kSRLMObjType:
		case kSRRejectedWord:
		case kSRLanguageModelFormat:
		case kSRPathFormat:
		case kSRPhraseFormat:
			propPtr = buf;
			propSize= 4;
			break;
		case kSRReadAudioFSSpec:
			propPtr = buf;
			propSize= sizeof(FSSpec);
			break;
		case kSRListenKeyName:
		case kSRKeyWord:
		case kSRTEXTFormat:
		case kSRSpelling:
			propPtr = buf;
			propSize= 256;
			break;
		}
		SpeechFail(SRGetProperty(srObject, selector, propPtr, (long *)&propSize));
		/* Should handle buffer too small, but we won't */
		ST(0) = sv_newmortal();
		switch (selector) {
		case kSRForegroundOnly:
		case kSRBlockBackground:
		case kSRBlockModally:
		case kSRWantsResultTextDrawn:
		case kSRWantsAutoFBGestures:
		case kSRCancelOnSoundOut:
		case kSROptional:
		case kSREnabled:
		case kSRRepeatable:
		case kSRRejectable:
		case kSRFeedbackAndListeningModes:
		case kSRSoundInVolume:
		case kSRListenKeyMode:
		case kSRListenKeyCombo:
		case kSRRejectionLevel:
		case kSRNotificationParam:
		case kSRSearchStatusParam:
		case kSRRefCon:
			if (*buf & 0x80)
				sv_setnv(ST(0), (double)*(u_long *)buf);
			else
				sv_setiv(ST(0), *(IV *)buf);
			break;
		case kSRLMObjType:
			sv_setpvn(ST(0), buf, 4);
			break;
		case kSRRejectedWord:
		case kSRLanguageModelFormat:
		case kSRPathFormat:
		case kSRPhraseFormat:
			sv_setref_pv(ST(0), "SRSpeechObject", (void*)*(SRSpeechObject *)buf);
			break;
		case kSRReadAudioFSSpec:
			sv_setpv(ST(0), GUSIFSp2FullPath((FSSpec *)buf));
			break;
		case kSRListenKeyName:
		case kSRKeyWord:
			sv_setpvn(ST(0), buf+1, *buf);
			break;
		case kSRTEXTFormat:
		case kSRSpelling:
			sv_setpvn(ST(0), buf, propSize);
			break;
		}
	}


=item SRReleaseObject SROBJECT 

=cut
MacOSRet
SRReleaseObject(srObject)
	SRSpeechObject 	srObject


=item SRGetReference SROBJECT 

=cut
SRSpeechObject
SRGetReference(srObject)
	SRSpeechObject 	srObject
	CODE:
	SpeechFail(SRGetReference(srObject, &RETVAL));
	OUTPUT:
	RETVAL


=item SRNewRecognizer SYSTEM [, SOURCEID ]

=cut
SRSpeechObject
SRNewRecognizer(system, sourceID = 0)
	SRSpeechObject 	system
	OSType 			sourceID
	CODE:
	SpeechFail(SRNewRecognizer(system, &RETVAL, sourceID));
	OUTPUT:
	RETVAL


=item SRStartListening RECOGNIZER 

=cut
MacOSRet
SRStartListening(recognizer)
	SRSpeechObject 	recognizer


=item SRStopListening RECOGNIZER 

=cut
MacOSRet
SRStopListening(recognizer)
	SRSpeechObject 	recognizer


=item SRSetLanguageModel RECOGNIZER, LANGUAGEMODEL 

=cut
MacOSRet
SRSetLanguageModel(recognizer, languageModel)
	SRSpeechObject 	recognizer
	SRSpeechObject 	languageModel


=item SRGetLanguageModel RECOGNIZER 

=cut
SRSpeechObject
SRGetLanguageModel(recognizer)
	SRSpeechObject 	recognizer
	CODE:
	SpeechFail(SRGetLanguageModel(recognizer, &RETVAL));
	OUTPUT:
	RETVAL


=item SRContinueRecognition RECOGNIZER 

=cut
MacOSRet
SRContinueRecognition(recognizer)
	SRSpeechObject 	recognizer


=item SRCancelRecognition RECOGNIZER 

=cut
MacOSRet
SRCancelRecognition(recognizer)
	SRSpeechObject 	recognizer


=item SRIdle 

=cut
MacOSRet
SRIdle()


=item SRNewLanguageModel SYSTEM, NAME 

=cut
SRSpeechObject
SRNewLanguageModel(system, name)
	SRSpeechObject 	system
	SV *			name
	CODE:
	{
		STRLEN	nameLength;
		void *	namePtr = SvPV(name, nameLength);
		SpeechFail(SRNewLanguageModel(system, &RETVAL, namePtr, nameLength));
	}
	OUTPUT:
	RETVAL


=item SRNewPath SYSTEM 

=cut
SRSpeechObject
SRNewPath(system)
	SRSpeechObject 	system
	CODE:
	SpeechFail(SRNewPath(system, &RETVAL));
	OUTPUT:
	RETVAL


=item SRNewPhrase SYSTEM, TEXT 

=cut
SRSpeechObject
SRNewPhrase(system, text)
	SRSpeechObject 	system
	SV *			text
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(text, textLength);
		SpeechFail(SRNewPhrase(system, &RETVAL, textPtr, textLength));
	}
	OUTPUT:
	RETVAL


=item SRNewWord SYSTEM, TEXT 

=cut
SRSpeechObject
SRNewWord(system, text)
	SRSpeechObject 	system
	SV *			text
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(text, textLength);
		SpeechFail(SRNewWord(system, &RETVAL, textPtr, textLength));
	}
	OUTPUT:
	RETVAL


=item SRPutLanguageObjectIntoHandle LANGUAGEOBJECT, LOBJHANDLE 

=cut
MacOSRet
SRPutLanguageObjectIntoHandle(languageObject, lobjHandle)
	SRSpeechObject 	languageObject
	Handle 			lobjHandle


=item SRPutLanguageObjectIntoDataFile LANGUAGEOBJECT, FREFNUM 

=cut
MacOSRet
SRPutLanguageObjectIntoDataFile(languageObject, fRefNum)
	SRSpeechObject 	languageObject
	short 			fRefNum


=item SRNewLanguageObjectFromHandle SYSTEM, LOBJHANDLE 

=cut
SRSpeechObject
SRNewLanguageObjectFromHandle(system, lObjHandle)
	SRSpeechObject 	system
	Handle 			lObjHandle
	CODE:
	SpeechFail(SRNewLanguageObjectFromHandle(system, &RETVAL, lObjHandle));
	OUTPUT:
	RETVAL


=item SRNewLanguageObjectFromDataFile SYSTEM, FREFNUM 

=cut
SRSpeechObject
SRNewLanguageObjectFromDataFile(system, fRefNum)
	SRSpeechObject 	system
	short 			fRefNum
	CODE:
	SpeechFail(SRNewLanguageObjectFromDataFile(system, &RETVAL, fRefNum));
	OUTPUT:
	RETVAL


=item SREmptyLanguageObject LANGUAGEOBJECT 

=cut
MacOSRet
SREmptyLanguageObject(languageObject)
	SRSpeechObject 	languageObject


=item SRChangeLanguageObject LANGUAGEOBJECT, TEXT 

=cut
MacOSRet
SRChangeLanguageObject(languageObject, text)
	SRSpeechObject 	languageObject
	SV *			text
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(text, textLength);
		RETVAL = SRChangeLanguageObject(languageObject, textPtr, textLength);
	}
	OUTPUT:
	RETVAL


=item SRAddLanguageObject BASE, ADDON 

=cut
MacOSRet
SRAddLanguageObject(base, addon)
	SRSpeechObject 	base
	SRSpeechObject 	addon


=item SRAddText BASE, TEXT [, REFCON ]

=cut
MacOSRet
SRAddText(base, text, refCon=0)
	SRSpeechObject 	base
	SV *			text
	long 			refCon
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(text, textLength);
		RETVAL = SRAddText(base, textPtr, textLength, refCon);
	}
	OUTPUT:
	RETVAL


=item SRRemoveLanguageObject BASE, TOREMOVE 

=cut
MacOSRet
SRRemoveLanguageObject(base, toRemove)
	SRSpeechObject 	base
	SRSpeechObject 	toRemove


=item SRCountItems CONTAINER 

=cut
long
SRCountItems(container)
	SRSpeechObject 	container
	CODE:
	SpeechFail(SRCountItems(container, &RETVAL));
	OUTPUT:
	RETVAL


=item SRGetIndexedItem CONTAINER, INDEX 

=cut
SRSpeechObject
SRGetIndexedItem(container, index)
	SRSpeechObject 	container
	long 			index
	CODE:
	SpeechFail(SRGetIndexedItem(container, &RETVAL, index));
	OUTPUT:
	RETVAL
	


=item SRSetIndexedItem CONTAINER, ITEM, INDEX 

=cut
MacOSRet
SRSetIndexedItem(container, item, index)
	SRSpeechObject 	container
	SRSpeechObject 	item
	long 			index


=item SRRemoveIndexedItem CONTAINER, INDEX 

=cut
MacOSRet
SRRemoveIndexedItem(container, index)
	SRSpeechObject 	container
	long 			index


=item SRDrawText RECOGNIZER, DISPTEXT 

=cut
MacOSRet
SRDrawText(recognizer, dispText)
	SRSpeechObject 	recognizer
	SV *			dispText
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(dispText, textLength);
		RETVAL = SRDrawText(recognizer, textPtr, textLength);
	}
	OUTPUT:
	RETVAL


=item SRDrawRecognizedText RECOGNIZER, DISPTEXT 

=cut
MacOSRet
SRDrawRecognizedText(recognizer, dispText)
	SRSpeechObject 	recognizer
	SV *			dispText
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(dispText, textLength);
		RETVAL = SRDrawRecognizedText(recognizer, textPtr, textLength);
	}
	OUTPUT:
	RETVAL


=item SRSpeakText RECOGNIZER, SPEAKTEXT 

=cut
MacOSRet
SRSpeakText(recognizer, speakText)
	SRSpeechObject 	recognizer
	SV *			speakText
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(speakText, textLength);
		RETVAL = SRSpeakText(recognizer, textPtr, textLength);
	}
	OUTPUT:
	RETVAL


=item SRSpeakAndDrawText RECOGNIZER, TEXT 

=cut
MacOSRet
SRSpeakAndDrawText(recognizer, text)
	SRSpeechObject 	recognizer
	SV *			text
	CODE:
	{
		STRLEN	textLength;
		void *	textPtr = SvPV(text, textLength);
		RETVAL = SRSpeakAndDrawText(recognizer, textPtr, textLength);
	}
	OUTPUT:
	RETVAL


=item SRStopSpeech RECOGNIZER 

=cut
MacOSRet
SRStopSpeech(recognizer)
	SRSpeechObject 	recognizer


=item SRSpeechBusy RECOGNIZER 

=cut
Boolean
SRSpeechBusy(recognizer)
	SRSpeechObject 	recognizer


=item SRProcessBegin RECOGNIZER, FAILED 

=cut
MacOSRet
SRProcessBegin(recognizer, failed)
	SRSpeechObject 	recognizer
	Boolean 		failed


=item SRProcessEnd RECOGNIZER, FAILED 

=cut
MacOSRet
SRProcessEnd(recognizer, failed)
	SRSpeechObject 	recognizer
	Boolean 		failed

=back

=cut
