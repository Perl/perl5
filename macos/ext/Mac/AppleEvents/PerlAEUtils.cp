/*********************************************************************
Project	:	MacPerl
File		:	PerlAEUtils.cp		-	Stuff for Perl AppleEvent handling
Author	:	Matthias Neeracher
Language	:	Metrowerks C++

$Log: PerlAEUtils.cp,v $
Revision 1.2  2000/09/09 22:18:25  neeri
Dynamic libraries compile under 5.6

Revision 1.1  2000/08/14 01:48:18  neeri
Checked into Sourceforge

Revision 1.1  1997/04/07 20:49:09  neeri
Synchronized with MacPerl 5.1.4a1

*********************************************************************/

#define MAC_CONTEXT

#define EOF 	-1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "PerlAEUtils.h"

OSACreateAppleEventUPP	gPAECreate			= nil;
OSASendUPP					gPAESend				= nil;
AEEventHandlerUPP			gPAEResume			= nil;
OSAActiveUPP				gPAEActive			= nil;
long							gPAECreateRefCon	= 0;
long							gPAESendRefCon		= 0;
long							gPAEResumeRefCon	= 0;
long							gPAEActiveRefCon	= 0;
Boolean						gPAEInstall = true;

int PAENextParam(char ** format)
{
	Boolean paren = false;
	Boolean space = true;
	OSType  type  = 0;
	
	for (;;) 
		switch (**format) {
		case 0:
			return 0;
		case '\'':
			for (;;) {
				switch (*++*format) {
				case 0:
					return 0;
				case '\'':
					break;
				default:
					type = (type << 8) | (**format & 0xFF);
					continue;
				}
				space = true;
				break;
			} 
			++*format;
			break;
		case 'Ò':
			do {
				++*format;
				if (!**format)
					return 0;
			} while (**format != 'Ó');
			++*format;
			space = true;
			break;
		case 'Ç':
			do {
				++*format;
				if (!**format)
					return 0;
			} while (**format != 'È');
			++*format;
			space = true;
			break;
		case '(':
			paren = true;
			space = true;
			++*format;
			break;
		case ')':
			paren = false;
			space = true;
			++*format;
			break;
		case '@':
			++*format;
			if (**format == '@') {		// @@: Handle
				++*format;

				return 3;
			} else if (paren)				// @, coerced
				if (type == 'TEXT') 
					return 4;				// To TEXT, use zero terminated
				else
					return 2;				// Not to TEXT, use pointer/length
			else
				return 1;
		case ' ':
		case '\t':
		case ':':
		case ',':
		case '[':
		case ']':
		case '{':
		case '}':
			space = true;
			++*format;
			break;
		default:
			if (space) {
				type = 0;
				space = false;
			}
			type = (type << 8) | (**format & 0xFF);
			++*format;
			break;
		}
}

Ptr				gPAEArgs;
static Handle	gArgHdl	= 0;

static void vPushArgs(int length, ...)
{
	va_list	list;
	
	va_start(list, length);
	if (!gArgHdl)
		PtrToHand((Ptr) list, &gArgHdl, length);
	else {
		HUnlock(gArgHdl);
		PtrAndHand((Ptr) list, gArgHdl, length);
	}
	HLock(gArgHdl);
	gPAEArgs = *gArgHdl;
}

Boolean PAEDoNextParam(char ** formscan, SV * sv)
{
	char *	ptr;
	STRLEN	length;
	
	switch (PAENextParam(formscan)) {
	case 0:
		return false;
	case 1:
		vPushArgs(4, (AEDesc *)SvPV_nolen((SV*)SvRV(sv)));
		break;
	case 2:
		ptr = SvPV(sv, length);
		vPushArgs(8, length, ptr);
		break;
	case 4:
		ptr = SvPV(sv, length);
		vPushArgs(4, ptr);
		break;
	case 3:
		vPushArgs(4, (Handle)SvIV((SV*)SvRV(sv)));
		break;
	}
	
	return true;
}

void PAEClearArgs()
{
	if (gArgHdl)
		SetHandleSize(gArgHdl, 0);
	gPAEArgs = nil;
}

class PerlEventHandler {
	OSType					aeClass;
	OSType					aeID;
	SV *						handler;
	SV	*						refCon;
	AEEventHandlerUPP		resumeHandler;
	long						resumeRefCon;
	PerlEventHandler *	prev;
	PerlEventHandler *	next;
	Boolean					sysHandler;
	
	static AEEventHandlerUPP	upp;
	static PerlEventHandler	*	handlers;
public:	
	PerlEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler);
	~PerlEventHandler();
	
	void	Get(SV * theHandler, SV * theRefCon);
	void	Change(SV * newHandler, SV * newRefCon);
	OSErr	Call(const AppleEvent * event, AppleEvent * reply);

	static PerlEventHandler * Find(OSType aeClass, OSType aeID, Boolean sysHandler);
	static void					  NukeHandlers();
};

pascal OSErr HandlePerlEvent(const AppleEvent * ev, AppleEvent * re, long ref)
{
	return ((PerlEventHandler *)ref)->Call(ev, re);
}

AEEventHandlerUPP		PerlEventHandler::upp		=	nil;
PerlEventHandler	*	PerlEventHandler::handlers	=	nil;

PerlEventHandler::PerlEventHandler(
	OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler)
	: 	aeClass(aeClass), aeID(aeID), 
		handler(newSVsv(handler)), refCon(newSVsv(refCon)), sysHandler(sysHandler)
{
	if (!gPAEInstall || AEGetEventHandler(aeClass, aeID, &resumeHandler, &resumeRefCon, sysHandler))
		resumeHandler	=	nil;
	next		=	handlers;
	prev		=	nil;
	handlers	= 	this;
	if (!upp) {
		upp = NewAEEventHandlerProc(HandlePerlEvent);
		atexit(PAENuke);
	}
	if (gPAEInstall)
		AEInstallEventHandler(aeClass, aeID, upp, (long) this, sysHandler);
}

PerlEventHandler::~PerlEventHandler()
{
	if (gPAEInstall)
		if (resumeHandler)
			AEInstallEventHandler(aeClass, aeID, resumeHandler, resumeRefCon, sysHandler);
		else
			AERemoveEventHandler(aeClass, aeID, upp, sysHandler);
	if (!prev)
		handlers = next;
	else
		prev->next = next;
	if (next)
		next->prev = prev;
	SvREFCNT_dec(handler);
	SvREFCNT_dec(refCon);
}	

void PerlEventHandler::Get(SV * theHandler, SV * theRefCon)
{
	SvSetSV(theHandler, handler);
	SvSetSV(theRefCon, refCon);
}

void PerlEventHandler::Change(SV * newHandler, SV * newRefCon)
{
	SvSetSV(handler, newHandler);
	SvSetSV(refCon, newRefCon);
}

static SV * newMortalAEDesc(const AEDesc * desc)
{
	SV *	sv =	sv_newmortal();
	sv_setref_pvn(sv, "AEDesc", (char*)desc, sizeof(AEDesc));
	
	return sv;
}

OSErr	PerlEventHandler::Call(const AppleEvent * event, AppleEvent * reply)
{
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs(newMortalAEDesc(event));
	XPUSHs(newMortalAEDesc(reply));
	XPUSHs(sv_mortalcopy(refCon));
	PUTBACK;
	
	perl_call_sv(handler, G_SCALAR);
	
	SPAGAIN;
	
	OSErr	res = (OSErr) POPi;
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

PerlEventHandler * PerlEventHandler::Find(OSType aeClass, OSType aeID, Boolean sysHandler)
{
	AEEventHandlerUPP		hproc;
	PerlEventHandler *	handler;
	
	if (gPAEInstall) {
 		if (AEGetEventHandler(aeClass, aeID, &hproc, (long *)&handler, sysHandler))
			return nil;
		if (hproc != upp)
			return nil;
		
		return handler;
	} else {
		for (handler = handlers; handler; handler = handler->next)
			if (handler->aeClass 	== aeClass 
			 && handler->aeID 		== aeID 
			 && handler->sysHandler	== sysHandler)
				return handler;
		
		return nil;
	}
}

void PerlEventHandler::NukeHandlers()
{
	while (handlers)
		delete handlers;
}

OSErr PAEInstallEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler)
{
	PerlEventHandler * ev = PerlEventHandler::Find(aeClass, aeID, sysHandler);
	
	if (ev)
		ev->Change(handler, refCon);
	else
		new PerlEventHandler(aeClass, aeID, handler, refCon, sysHandler);
	
	return noErr;
}

OSErr PAEGetEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler)
{
	PerlEventHandler * ev = PerlEventHandler::Find(aeClass, aeID, sysHandler);
	
	if (ev)
		ev->Get(handler, refCon);
	
	return ev != nil ? noErr : errAEEventNotHandled;
}

OSErr PAERemoveEventHandler(OSType aeClass, OSType aeID, Boolean sysHandler)
{
	PerlEventHandler * ev = PerlEventHandler::Find(aeClass, aeID, sysHandler);
	
	if (ev)
		delete ev;
	
	return ev != nil ? noErr : errAEHandlerNotFound;
}

OSErr	PAEDoAppleEvent(const AppleEvent * event, AppleEvent * reply)
{
	OSType	aeClass;
	OSType	aeID;
	DescType	realType;
	Size		realSize;
	OSErr		err = errAEEventNotHandled;
	
	AEGetAttributePtr(
		event, keyEventClassAttr, typeWildCard, &realType, &aeClass, 4, &realSize);
	AEGetAttributePtr(
		event, keyEventIDAttr, typeWildCard, &realType, &aeID, 4, &realSize);
	
	PerlEventHandler * ev = PerlEventHandler::Find(aeClass, aeID, false);
	if (!ev)
		ev = PerlEventHandler::Find(typeWildCard, aeID, false);
	if (!ev)
		ev = PerlEventHandler::Find(aeClass, typeWildCard, false);
	if (!ev)
		ev = PerlEventHandler::Find(typeWildCard, typeWildCard, false);
	
	if (ev)
		err = ev->Call(event, reply);
	
	if (err == errAEEventNotHandled) {
		ev = PerlEventHandler::Find(aeClass, aeID, true);
		if (!ev)
			ev = PerlEventHandler::Find(typeWildCard, aeID, true);
		if (!ev)
			ev = PerlEventHandler::Find(aeClass, typeWildCard, true);
		if (!ev)
			ev = PerlEventHandler::Find(typeWildCard, typeWildCard, true);
		
		if (ev)
			err = ev->Call(event, reply);
	}
	
	return err;
}

Boolean PAEHasOpenHandler()
{
	const OSType	aeClass = 'aevt';
	const OSType	aeID 	  = 'odoc';
	
	return	PerlEventHandler::Find(aeClass, aeID, false)
		||		PerlEventHandler::Find(typeWildCard, aeID, false)
		||		PerlEventHandler::Find(aeClass, typeWildCard, false)
		||		PerlEventHandler::Find(typeWildCard, typeWildCard, false)
		||		PerlEventHandler::Find(aeClass, aeID, true)
		||		PerlEventHandler::Find(typeWildCard, aeID, true)
		||		PerlEventHandler::Find(aeClass, typeWildCard, true)
		||		PerlEventHandler::Find(typeWildCard, typeWildCard, true);
}

void PAENuke()
{
	PerlEventHandler::NukeHandlers();
}
