/* $Header: /cvsroot/macperl/perl/macos/ext/MacPerl/OSA.xs,v 1.2 2001/04/16 04:45:15 neeri Exp $
 *
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: OSA.xs,v $
 * Revision 1.2  2001/04/16 04:45:15  neeri
 * Switch from atexit() to Perl_call_atexit (MacPerl bug #232158)
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.1  2000/05/14 21:45:04  neeri
 * First build released to public
 *
 * Revision 1.1  1997/04/07 20:51:08  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Components.h>
#include <AppleEvents.h>
#include <AppleScript.h>
#include <OSA.h>
#include <Gestalt.h>

ComponentInstance gScriptingComponent;

void ShutDownAppleScript(pTHX_ void * p)
{
	CloseComponent(gScriptingComponent);
	
	gScriptingComponent = nil;
}

OSErr InitAppleScript(void)
{
	OSErr                myErr;
	ComponentDescription descr;
	ComponentDescription capabilities;
	Component            myComponent;
	short                retryCount;
	long						res;
			
	retryCount = 0;
	
	if (Gestalt(gestaltAppleEventsAttr, &res))
		return -1;
	else if (!(res & (1<<gestaltAppleEventsPresent)))
		return -1;
	else if (Gestalt(gestaltComponentMgr, &res))
		return -1;
		
	descr.componentType         = kOSAComponentType;
	descr.componentSubType      = kAppleScriptSubtype;
	descr.componentManufacturer = (OSType) 0;
	descr.componentFlags        = kOSASupportsCompiling + 
											kOSASupportsGetSource + 
											kOSASupportsAESending;
	descr.componentFlagsMask    = descr.componentFlags;
	
	myComponent = FindNextComponent(nil, &descr);
	
	if (myComponent==nil)
	  	return -1;
	else {
		myErr = GetComponentInfo(myComponent, &capabilities, nil, nil, nil);
		gScriptingComponent = OpenComponent(myComponent);
		if (!gScriptingComponent)
			return(-1);
		else
			Perl_call_atexit(aTHX_ ShutDownAppleScript, NULL);
	}
		
	return myErr;
}

MODULE = OSA	PACKAGE = MacPerl	PREFIX = MP_

void
MP_Reply(reply)
	char *	reply
	CODE:
	{
		if (gMacPerl_Reply)
			DisposeHandle(gMacPerl_Reply);
	/**/		
		PtrToHand(reply, &gMacPerl_Reply, strlen(reply));
	}

void
MP_DoAppleScript(script)
	SV *	script
	CODE:
	{
		AEDesc	source;
		AEDesc	result;
		char *	scriptText;
		STRLEN	len;
	/**/		
		if (!gScriptingComponent && InitAppleScript())
			croak("MacPerl::DoAppleScript couldn't initialize AppleScript");
	/**/		
		scriptText = (char*) SvPV(ST(0), len);
		AECreateDesc(typeChar, scriptText, len, &source);
	/**/		
		if (!OSADoScript(
				gScriptingComponent, 
				&source, 
				kOSANullScript, 
				typeChar, 
				kOSAModeCanInteract,
				&result))
		{
			AEDisposeDesc(&source);
	/**/		
			if (!AECoerceDesc(&result, typeChar, &source)) {
				HLock(source.dataHandle);
				ST(0) = sv_2mortal(newSVpv(*source.dataHandle,GetHandleSize(source.dataHandle)));
				AEDisposeDesc(&source);
			} else
				ST(0) = &PL_sv_undef;
	/**/		
			AEDisposeDesc(&result);
		} else {
			AEDisposeDesc(&source);
	/**/		
			ST(0) = &PL_sv_undef;
		}
	}
