/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.1 1997/04/07 20:49:35 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <StandardFile.h>
#include <GUSIFileSpec.h>

typedef struct {
	SV *	fileFilter;
	SV *	dlgHook;
	SV *	modalFilter;
	SV * 	activate;
} SFProcs;

typedef EventRecord * ToolboxEvent;
typedef CInfoPBPtr 	CatInfo;

static SFProcs * sCurSFProcs;

static pascal Boolean CallFileFilter(CatInfo pb, SFProcs * procs)
{
	Boolean	res;
	
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(CatInfo, pb);
	PUTBACK;
	
	perl_call_sv(procs->fileFilter, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(Boolean, res);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

static pascal Boolean CallSimpleFileFilter(CatInfo pb)
{
	return CallFileFilter(pb, sCurSFProcs);
}

pascal short CallDlgHook(short item, DialogPtr theDialog, SFProcs * procs)
{
	short	res;
	
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(short, item);
	XS_XPUSH(GrafPtr, theDialog);
	PUTBACK;
	
	perl_call_sv(procs->dlgHook, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(short, res);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

pascal Boolean CallModalFilter(DialogPtr theDialog, EventRecord *theEvent, short *itemHit, SFProcs * procs)
{
	Boolean	res;
	int		count;
	
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(GrafPtr, theDialog);
	XS_XPUSH(ToolboxEvent, theEvent);
	XS_XPUSH(short, *itemHit);
	PUTBACK;
	
	count = perl_call_sv(procs->modalFilter, G_ARRAY);
	
	SPAGAIN;
	
	while (count-- > 1)
		XS_POP(short, *itemHit);
	if (count < 0)
		res = false;
	else
		XS_POP(Boolean, res);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

pascal void CallActivate(DialogPtr theDialog, short itemNo, Boolean activating, SFProcs * procs)
{
	dSP;
	
	PUSHMARK(sp);
	XS_XPUSH(GrafPtr, theDialog);
	XS_XPUSH(short, itemNo);
	XS_XPUSH(Boolean, activating);
	PUTBACK;
	
	perl_call_sv(procs->activate, G_DISCARD);
}

#if GENERATINGCFM
RoutineDescriptor sCallFileFilter = 
	BUILD_ROUTINE_DESCRIPTOR(uppFileFilterYDProcInfo, CallFileFilter);
RoutineDescriptor sCallSimpleFileFilter = 
	BUILD_ROUTINE_DESCRIPTOR(uppFileFilterProcInfo, CallSimpleFileFilter);
RoutineDescriptor sCallDlgHook = 
	BUILD_ROUTINE_DESCRIPTOR(uppDlgHookYDProcInfo, CallDlgHook);
RoutineDescriptor sCallModalFilter = 
	BUILD_ROUTINE_DESCRIPTOR(uppModalFilterYDProcInfo, CallModalFilter);
RoutineDescriptor sCallActivate = 
	BUILD_ROUTINE_DESCRIPTOR(uppActivateYDProcInfo, CallActivate);
#else
#define sCallFileFilter			*NewFileFilterYDProc(CallFileFilter)
#define sCallSimpleFileFilter	*NewFileFilterProc(CallSimpleFileFilter)
#define sCallDlgHook			*NewDlgHookYDProc(CallDlgHook)
#define sCallModalFilter		*NewModalFilterYDProc(CallModalFilter)
#define sCallActivate			*NewActivateYDProc(CallActivate)
#endif

MODULE = Mac::StandardFile	PACKAGE = Mac::StandardFile

=head2 Functions

=over 4

=item StandardFileReply

A structure holding the result of a standard file dialog. Fields are:

	Boolean							sfGood;
	Boolean							sfReplacing;
	OSType							sfType;
	FSSpec							sfFile;
	ScriptCode						sfScript;
	short							sfFlags;
	Boolean							sfIsFolder;
	Boolean							sfIsVolume;

=cut
STRUCT StandardFileReply
	Boolean							sfGood;
	Boolean							sfReplacing;
	OSType							sfType;
	FSSpec							sfFile;
	I8								sfScript;
	short							sfFlags;
	Boolean							sfIsFolder;
	Boolean							sfIsVolume;


=item StandardPutFile PROMPT, DEFAULTNAME 

Display a dialog prompting for a new file.

=cut
StandardFileReply
StandardPutFile(prompt, defaultName)
	Str255	prompt
	Str255	defaultName
	CODE:
	StandardPutFile(prompt, defaultName, &RETVAL);
	OUTPUT:
	RETVAL


=item StandardGetFile FILEFILTER, TYPELIST 

Display a dialog prompting for an existing file.

=cut
StandardFileReply
StandardGetFile(fileFilter, typeList)
	SV *	fileFilter
	SV *	typeList
	CODE:
	{
		short	numTypes;
		STRLEN  len;
		char *  types;
		char *  typeBuf;
		SFProcs	procs;
		
		typeBuf  = 0;
		if (!SvOK(typeList)) {
			numTypes = -1;
			types    = 0;
		} else {
			types = SvPV(typeList, len);
			if (len & 3 && looks_like_number(typeList)) {
				XS_INPUT(short, numTypes, typeList);
			} else {
				numTypes = len >> 2;
				if (numTypes && (long)types & 1) {			/* Ensure alignment */
					typeBuf = (char *)malloc(numTypes << 2);
					memcpy(typeBuf, types, numTypes << 2);
					types = typeBuf;
				} 
			}
		}
		if (SvTRUE(fileFilter)) {
			sCurSFProcs = &procs;
			procs.fileFilter = fileFilter;
			StandardGetFile(&sCallSimpleFileFilter, numTypes, (OSType*)types, &RETVAL);
		} else
			StandardGetFile(nil, numTypes, (OSType*)types, &RETVAL);
		if (typeBuf)
			free(typeBuf);
	}
	OUTPUT:
	RETVAL


=item CustomPutFile PROMPT, DEFAULTNAME, DLGID, WHERE [, DLGHOOK [, FILTERPROC [, ACTIVATE, ... ]]]

Display a more sophisticated dialog for a new file.

=cut
StandardFileReply
CustomPutFile(prompt, defaultName, dlgID, where, dlgHook=&PL_sv_undef, filterProc=&PL_sv_undef, activate=&PL_sv_undef, ...)
	Str255	prompt
	Str255	defaultName
	short	dlgID
	Point	where
	SV *	dlgHook
	SV *	filterProc
	SV *	activate
	CODE:
	{
		SFProcs procs;
		short *	activationOrder = nil;
		
		procs.modalFilter = filterProc;
		procs.dlgHook     = dlgHook;
		procs.activate    = activate;
		
		if (items > 7) {
			activationOrder = (short *)malloc(2*(items-6));
			activationOrder[0] = items-7;
			while (items-- > 7) {
				XS_INPUT(short, activationOrder[items-6], ST(items));
			}
		}
		
		CustomPutFile(
			prompt,
			defaultName,
			&RETVAL,
			dlgID,
			where,
			SvTRUE(dlgHook) ? &sCallDlgHook : nil,
			SvTRUE(filterProc) ? &sCallModalFilter : nil,
			activationOrder,
			SvTRUE(activate) ? &sCallActivate : nil,
			&procs);
		
		if (activationOrder)
			free(activationOrder);
	}
	OUTPUT:
	RETVAL


=item CustomGetFile FILEFILTER, TYPELIST, DLGID, WHERE [, DLGHOOK [, FILTERPROC [, ACTIVATE, ... ]]]

Display a more sophisticated dialog for an existing file.

=cut
StandardFileReply
CustomGetFile(fileFilter, typeList, dlgID, where, dlgHook=&PL_sv_undef, filterProc=&PL_sv_undef, activate=&PL_sv_undef, ...)
	SV *	fileFilter
	SV *	typeList
	short	dlgID
	Point	where
	SV *	dlgHook
	SV *	filterProc
	SV *	activate
	CODE:
	{
		SFProcs procs;
		short	numTypes;
		STRLEN  len;
		char *  types;
		char *  typeBuf;
		short *	activationOrder = nil;
		
		procs.fileFilter  = fileFilter;
		procs.modalFilter = filterProc;
		procs.dlgHook     = dlgHook;
		procs.activate    = activate;
		
		typeBuf  = 0;
		if (!SvOK(typeList)) {
			numTypes = -1;
			types    = 0;
		} else {
			types = SvPV(typeList, len);
			if (len & 3 && looks_like_number(typeList)) {
				XS_INPUT(short, numTypes, typeList);
			} else {
				numTypes = len >> 2;
				if (numTypes && (long)types & 1) {			/* Ensure alignment */
					typeBuf = (char *)malloc(numTypes << 2);
					memcpy(typeBuf, types, numTypes << 2);
					types = typeBuf;
				} 
			}
		}
		if (items > 7) {
			activationOrder = (short *)malloc(2*(items-6));
			activationOrder[0] = items-7;
			while (items-- > 7) {
				XS_INPUT(short, activationOrder[items-6], ST(items));
			}
		}
		
		CustomGetFile(
			SvTRUE(fileFilter) ? &sCallFileFilter : nil,
			numTypes,
			(OSType *)types,
			&RETVAL,
			dlgID,
			where,
			SvTRUE(dlgHook) ? &sCallDlgHook : nil,
			SvTRUE(filterProc) ? &sCallModalFilter : nil,
			activationOrder,
			SvTRUE(activate) ? &sCallActivate : nil,
			&procs);
		
		if (activationOrder)
			free(activationOrder);
		if (typeBuf)
			free(typeBuf);
	}
	OUTPUT:
	RETVAL

=back 

=cut