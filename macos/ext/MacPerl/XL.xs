/* $Header: /cvsroot/macperl/perl/macos/ext/MacPerl/XL.xs,v 1.2 2001/04/16 04:45:15 neeri Exp $
 *
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: XL.xs,v $
 * Revision 1.2  2001/04/16 04:45:15  neeri
 * Switch from atexit() to Perl_call_atexit (MacPerl bug #232158)
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.1  2000/05/14 21:45:05  neeri
 * First build released to public
 *
 * Revision 1.3  1998/04/07 01:47:31  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.2  1997/06/04 22:08:52  neeri
 * Compiles fine.
 *
 * Revision 1.1  1997/04/07 20:51:09  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#undef modff
#include <HyperXCmd.h>
#include <Resources.h>
#include <TextUtils.h>
#include <XL.h>
#include <strings.h>

XLGlue 	XLPerlGlue;

static void PerlXLGetGlobal(XCmdPtr params)
{
  	dTHX;

	StringPtr 	var	=	(StringPtr) params->inArgs[0];
	char			ch 	= 	0;
	SV *			sv;
	char *		str;
	STRLEN		len;
	
	if (sv = get_sv(p2cstr(var), FALSE)) {
		str = (char *)SvPV(sv,len);
		PtrToHand(str, (Handle *) &params->outArgs[0], len+1);
	} else
		PtrToHand(&ch, (Handle *) &params->outArgs[0], 1);
		
	c2pstr((char *) var);
	
	params->result = xresSucc;	
}

static void PerlXLSetGlobal(XCmdPtr params)
{
  	dTHX;

	StringPtr 	var	=	(StringPtr) params->inArgs[0];
	Handle		val	= 	(Handle) params->inArgs[1];
	char			ch 	= 	0;
	SV *			sv;
	
	HLock(val);
	if (sv = get_sv(p2cstr(var), TRUE))
		sv_setpv(sv, *val);
	c2pstr((char *) var);
	HUnlock(val);
	
	params->result = sv ? xresSucc : xresFail;	
}

static void InitPerlXL()
{
	XLCopyGlue(XLPerlGlue, XLDefaultGlue);
	
	XLPerlGlue[xl_GetGlobal]	=	PerlXLGetGlobal;
	XLPerlGlue[xl_SetGlobal]	=	PerlXLSetGlobal;
}

typedef struct {
	short		refNum;
	FSSpec	file;
} ResourceFile;

typedef struct {
	short				count;
	ResourceFile	file[1];
} ** ResourceFiles;

typedef struct {
	short		refNum;
	ResType	type;
	short		id;
} Xternal, ** XternalHdl;

static ResourceFiles ResFiles;
static XternalHdl		Xternals;
static int				XternalIndex = 0;
static Boolean			CloseInstalled = false;

static void XLCloseResFiles(pTHX_ void * p)
{
	if (ResFiles) {
		while ((*ResFiles)->count--)
			CloseResFile((*ResFiles)->file[(*ResFiles)->count].refNum);
		
		DisposeHandle((Handle) ResFiles);
		
		ResFiles = nil;
	}
	
	if (Xternals) {
		DisposeHandle((Handle) Xternals);
		
		Xternals = nil;
	}
	
	XternalIndex 	= 	0;
	CloseInstalled	=	false;
}

static ResType SearchTypes[] = {'XCMD', 'XFCN', 0};

void XS_MacPerl__CallXL(pTHX_ CV *);

static void XLLoadResFile(short refNum) 
{
  	dTHX;

	Handle			xcmd;
	ResType *		type;
	short				count;
	short				id;
	ResType			rtyp;
	short				oldRes = CurResFile();
	Xternal			x;
	CV *				cv;
	char *			file = __FILE__;
	char				name[256];
	
	if (!CloseInstalled) {
		Perl_call_atexit(aTHX_ XLCloseResFiles, NULL);
		CloseInstalled = true;
	}
		
	if (!Xternals)
		Xternals = (XternalHdl) NewHandle(0);
	
	UseResFile(refNum);
	
	for (type = SearchTypes; *type; ++type)
		for (count = Count1Resources(*type); count; --count)
			if (xcmd = Get1IndResource(*type, count)) {
				getresinfo(xcmd, &id, &rtyp, name);
				
				x.refNum = refNum;
				x.type	= rtyp;
				x.id		= id;
				
				PtrAndHand((Ptr) &x, (Handle) Xternals, sizeof(Xternal));
				
    			cv = newXS(name, XS_MacPerl__CallXL, file);
				XSANY.any_i32 = XternalIndex++;
			}
			
	UseResFile(oldRes);
}

static OSErr XLTryResLoad(FSSpec * spec)
{
	short				i;
	short				refNum;
	ResourceFile	file;
	
	if (!ResFiles) {
		i = 0;
		
		PtrToHand((Ptr) &i, (Handle *) &ResFiles, sizeof(short));
	}
	
	for (i = (*ResFiles)->count; i--; ) {
		ResourceFile * file = (*ResFiles)->file + i;
		
		if (file->file.vRefNum != spec->vRefNum)
			continue;
		if (file->file.parID != spec->parID)
			continue;
			
		if (EqualString(file->file.name, spec->name, false, true))
			return 0;
	}
	
	refNum = HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdPerm);
	
	if (refNum == -1)
		return ResError();
	
	file.refNum = refNum;
	file.file 	= *spec;
	
	PtrAndHand((Ptr) &file, (Handle) ResFiles, sizeof(ResourceFile));
	++(*ResFiles)->count;
	
	XLLoadResFile(refNum);
	
	return 0;
}

MODULE = XL	PACKAGE = MacPerl	PREFIX = MP_

void
MP_LoadExternals(path)
	char *	path
	CODE:
	{
		OSErr		err;
		FSSpec	spec;
		
		if (strchr(path, ':')) {
			if (!GUSIPath2FSp(path, &spec))
				err = XLTryResLoad(&spec);
			else
				err = fnfErr;
			
			goto done;
		}
		{
			AV *ar = GvAVn(PL_incgv);
			I32 i;
			char * tryname;
			STRLEN n_a;
	    	SV * namesv = NEWSV(806, 0);
	    	for (i = 0; i <= AvFILL(ar); i++) {
				SV *dirsv = *av_fetch(ar, i, TRUE);

				if (!SvROK(dirsv)) {
		    		char *dir = SvPVx(dirsv, n_a);
		    		/* We have ensured in incpush that library ends with ':' */
		    		Perl_sv_setpvf(aTHX_ namesv, "%s%s", dir, path+(path[0] == ':'));
		    		TAINT_PROPER("require");
		    		tryname = SvPVX(namesv);
		   		{
		    			/* Convert slashes in the name part, but not the directory part, to colons */
		    			char * colon;
		    			for (colon = tryname+strlen(dir); colon = strchr(colon, '/'); )
			    			*colon++ = ':';
		    		}
					if (!GUSIPath2FSp(tryname, &spec) && !XLTryResLoad(&spec)) {
						err = 0;
				
						goto done;
					}
				}
			}
		}		
		err = fnfErr;
	done:
		switch (err) {
		case noErr:
			break;
		case fnfErr:
			croak("MacPerl::LoadExternals(\"%s\"): File not found.", path);
		default:
			croak("MacPerl::LoadExternals(\"%s\"): OS Error (%d).", err);
		}
	}

void
MP__CallXL(...)
	CODE:
	{
		dXSI32;
		int 					i;
		short					resFile;
		struct XCmdBlock	xcmd;
		Xternal				xt;
		Handle				xh;

		xcmd.paramCount = items;
		for (i = 0; i < items; ++i) {
			STRLEN	len;
			char * 	arg = (char *) SvPV(ST(i), len);
		
			PtrToHand(arg, xcmd.params+i, len+1);
		}
	
		for (i = items; i < 16; ++i)
			xcmd.params[i] = nil;
	
		xcmd.returnValue = nil;
		xcmd.passFlag	  = 0;

		xt = (*Xternals)[ix];
		resFile = CurResFile();
		UseResFile(xt.refNum);
		
		xh = Get1Resource(xt.type, xt.id);
		
		if (!xh)
			croak("XCMD disappeared. Film at 11!");
			
		XLCall(xh, XLPerlGlue, &xcmd);
	
		UseResFile(resFile);
	
		for (i=0; i<16; ++i)
			if (xcmd.params[i])
				DisposeHandle(xcmd.params[i]);
		
		if (xcmd.returnValue) {
			HLock(xcmd.returnValue);
			ST(0) = sv_2mortal(newSVpv(*xcmd.returnValue, 0));		
			DisposeHandle(xcmd.returnValue);
		} else
			ST(0) = &PL_sv_undef;
	}

BOOT:
		InitPerlXL();
