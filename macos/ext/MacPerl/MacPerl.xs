/* $Header: /cvsroot/macperl/perl/macos/ext/MacPerl/MacPerl.xs,v 1.2 2001/04/17 03:53:44 pudge Exp $
 *
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MacPerl.xs,v $
 * Revision 1.2  2001/04/17 03:53:44  pudge
 * Minor version/config changes, plus sync with maint-5.6/perl
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.1  2000/05/14 21:45:04  neeri
 * First build released to public
 *
 * Revision 1.3  1998/04/07 01:47:30  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.2  1997/11/18 00:53:29  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:51:05  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <QuickDraw.h>
#include <Dialogs.h>
#include <Lists.h>
#include <GUSIFileSpec.h>
#include <PLStringFuncs.h>
#include <Files.h>
#include <Fonts.h>
#include <Resources.h>
#include <LowMem.h>


/* Shamelessly borrowed from Apple's includes. Sorry */

/*
 * faccess() commands; for general use
 */
 					/* 'd' => "directory" ops */
#define F_DELETE		(('d'<<8)|0x01)
#define F_RENAME		(('d'<<8)|0x02)

/*
 * more faccess() commands; for use only by MPW tools
 */
 
#define F_OPEN 			(('d'<<8)|0x00)		/* reserved for operating system use */
					/* 'e' => "editor" ops */
#define F_GTABINFO 		(('e'<<8)|0x00)		/* get tab offset for file */	
#define F_STABINFO 		(('e'<<8)|0x01)		/* set 	"	"		"	"  */
#define F_GFONTINFO		(('e'<<8)|0x02)		/* get font number and size for file */
#define F_SFONTINFO		(('e'<<8)|0x03)		/* set 	"		"	"	"	"	" 	 */
#define F_GPRINTREC		(('e'<<8)|0x04)		/* get print record for file */
#define F_SPRINTREC		(('e'<<8)|0x05)		/* set 	"		"	"	" 	 */
#define F_GSELINFO 		(('e'<<8)|0x06)		/* get selection information for file */
#define F_SSELINFO 		(('e'<<8)|0x07)		/* set		"		"		"		" */
#define F_GWININFO 		(('e'<<8)|0x08)		/* get current window position */
#define F_SWININFO 		(('e'<<8)|0x09)		/* set	"		"		" 	   */
#define F_GSCROLLINFO	(('e'<<8)|0x0A)		/* get scroll information */
#define F_SSCROLLINFO	(('e'<<8)|0x0B)		/* set    "   		"  	  */
#define F_GMARKER		(('e'<<8)|0x0D)		/* Get Marker */
#define F_SMARKER		(('e'<<8)|0x0C)		/* Set   " 	  */
#define F_GSAVEONCLOSE	(('e'<<8)|0x0F)		/* Get Save on close */
#define F_SSAVEONCLOSE	(('e'<<8)|0x0E)		/* Set   "	 "	 " 	 */

/*
 *	argument structure for use with F_SMARKER command
 */
#ifdef powerc
#pragma options align=mac68k
#endif
struct MarkElement {
	int				start;			/* start position of mark */
	int				end;			/* end position */
	unsigned char	charCount;		/* number of chars in mark name */
	char			name[64];		/* marker name */
};									/* note: marker may be up to 64 chars long */

#ifdef powerc
#pragma options align=reset
#endif

#ifndef __cplusplus
typedef struct MarkElement MarkElement;
#endif

#ifdef powerc
#pragma options align=mac68k
#endif
struct SelectionRecord {
	long	startingPos;
	long	endingPos;
	long	displayTop;
};
#ifdef powerc
#pragma options align=reset
#endif
#ifndef __cplusplus
typedef struct SelectionRecord SelectionRecord;
#endif

static char gMacPerlScratch[256];
#define gMacPerlScratchString ((StringPtr) gMacPerlScratch)

static ControlHandle GetDlgCtrl(DialogPtr dlg, short item)
{
	short 	kind;
	Handle	hdl;
	Rect	box;
	
	GetDialogItem(dlg, item, &kind, &hdl, &box);
	return (ControlHandle) hdl;
}

static void GetDlgText(DialogPtr dlg, short item, StringPtr text)
{
	GetDialogItemText((Handle) GetDlgCtrl(dlg, item), text);
}

static void SetDlgText(DialogPtr dlg, short item, char * text)
{
	setdialogitemtext((Handle) GetDlgCtrl(dlg, item), text);
}

static void GetDlgRect(DialogPtr dlg, short item, Rect * r)
{
	short 	kind;
	Handle	hdl;
	
	GetDialogItem(dlg, item, &kind, &hdl, r);
}

static void FrameDlgRect(DialogPtr dlg, short item)
{
	Rect	r;
	
	GetDlgRect(dlg, item, &r);
	InsetRect(&r, -4, -4);
	PenSize(3, 3);
	FrameRoundRect(&r, 16, 16);
	PenSize(1,1);
}

ListHandle 	gPickList 	= NULL;
Boolean		gPickScalar = false;

#define SetCell(cell, row, column)	{ (cell).h = column; (cell).v = row; }
#define ROW(cell) 					(cell).v

pascal void
MacListUpdate(myDialog, myItem)
DialogPtr		myDialog;
short			myItem;
{
	Rect	myrect;

	LUpdate(myDialog->visRgn, gPickList);
	myrect = (**(gPickList)).rView;
	InsetRect(&myrect, -1, -1);
	FrameRect(&myrect);
}

static void HandleArrowInList(
				ListHandle list, Boolean down, Boolean extend, Boolean extreme)
{
	Cell	cell;
	Cell	cur;

	if (!list)	/* How did we get here, anyway? */
		return;
	if (list[0]->selFlags & lOnlyOne)
		extend = false;
	SetPt(&cell, 0, 0);
	if (!LGetSelect(true, &cell, list))
		SetPt(&cur, 0, down ? -1 : 0);
	else if (down) {
		do {
			if (!extend)
				LSetSelect(false, cell, list);
			cur = cell;
			++cell.v;
		} while (LGetSelect(true, &cell, list));
	} else {
		cur = cell;
		if (!extend) 
			do {
				LSetSelect(false, cell, list);
				++cell.v;
			} while (LGetSelect(true, &cell, list));
	}
	if (down) {
		if (++cur.v >= list[0]->dataBounds.bottom)
			cur.v = 0;
	} else {
		if (--cur.v < 0)
			cur.v = list[0]->dataBounds.bottom-1;
	}
	if (extend && extreme) 
		if (down) 
			do {
				LSetSelect(true, cur, list);
			} while (++cur.v < list[0]->dataBounds.bottom);
		else
			do {
				LSetSelect(true, cur, list);
			} while (--cur.v >= 0);
	else {
		if (extreme)
			cur.v = down ? list[0]->dataBounds.bottom-1 : 0;
		LSetSelect(true, cur, list);
	}
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uMacListUpdate = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, MacListUpdate);
#else
#define uMacListUpdate MacListUpdate
#endif

pascal Boolean
MacListFilter(myDialog, myEvent, myItem)
DialogPtr		myDialog;
EventRecord		*myEvent;
short			*myItem;
{
	Rect	listrect;
	short	myascii;
	Handle	myhandle;
	Point	mypoint;
	short	mytype;
	int		activate;

	SetPort(myDialog);
	if (myEvent->what == keyDown)
		switch (myascii = myEvent->message & 0x0FF) {
		case 015:
		case 003:	/* This is return or enter... */
			*myItem = 1;
			return true;
		case '.':
			if (!(myEvent->modifiers & cmdKey))
				break;
			/* Fall through */
		case 033:	/* Cancel */
			*myItem = 2;
			return true;
		case 036:	/* UpArrow */
		case 037:	/* DownArrow */
			HandleArrowInList(
				gPickList, myascii==037, 
				(myEvent->modifiers & shiftKey) != 0,
				(myEvent->modifiers & cmdKey)   != 0);
			myEvent->what = nullEvent;
		}
	else if (myEvent->what == mouseDown) {
		mypoint = myEvent->where;
		GlobalToLocal(&mypoint);
		GetDialogItem(myDialog, 4, &mytype, &myhandle, &listrect);
		if (PtInRect(mypoint, &listrect) && gPickList != NULL) {
			if (!gPickScalar && myEvent->when - gPickList[0]->clikTime < LMGetDoubleTime()) {
				LRect(&listrect, gPickList[0]->lastClick, gPickList);
				if (PtInRect(mypoint, &listrect))
					LSetSelect(true, gPickList[0]->lastClick, gPickList);
			}
			if (LClick(mypoint, (short)myEvent->modifiers, gPickList)) {
				/* User double-clicked in cell... */
				LSetSelect(true, gPickList[0]->lastClick, gPickList);
				*myItem = 1;
				return true;
			}
		}
	} else if (myEvent->what == activateEvt && gPickList != NULL) {
		activate = (myEvent->modifiers & 0x01) != 0;
		LActivate((Boolean) activate, gPickList);
	}
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uMacListFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, MacListFilter);
#else
#define uMacListFilter MacListFilter
#endif

static OSErr GetVolInfo(short volume, Boolean indexed, FSSpec * spec)
{
	OSErr				err;
	HParamBlockRec	pb;
	
	pb.volumeParam.ioNamePtr	=	spec->name;
	pb.volumeParam.ioVRefNum	=	indexed ? 0 : volume;
	pb.volumeParam.ioVolIndex	=	indexed ? volume : 0;
	
	if (err = PBHGetVInfoSync(&pb))
		return err;
	
	spec->vRefNum	=	pb.volumeParam.ioVRefNum;
	spec->parID		=	1;
	
	return noErr;
}

int choose() 
{
	croak("choose not implemented at the moment");
	
	return -1;
}

MODULE = MacPerl	PACKAGE = MacPerl	PREFIX = MP_

void
MP_SetFileInfo(creator, type, path, ...)
	OSType	creator
	OSType	type
	char *	path
	CODE:
	{
		int i;
		for (i=2; i<items; i++)
			fsetfileinfo((char *) SvPV_nolen(ST(i)), creator, type);
	}

void
MP_GetFileInfo(path)
	char *	path
	PPCODE:
	{
		unsigned long	creator;
		unsigned long	type;
		
		errno = 0;
		
		fgetfileinfo(path, &creator, &type);
			
		if (errno) {
			if (GIMME != G_ARRAY)
				XPUSHs(&PL_sv_undef);
			/* Else return empty list */
		} else if (GIMME != G_ARRAY) {
			XPUSHs(sv_2mortal(newSVpv((char *) &type, 4)));
		} else {
			XPUSHs(sv_2mortal(newSVpv((char *) &creator, 4)));
			XPUSHs(sv_2mortal(newSVpv((char *) &type, 4)));
		}
	}

void
MP_Ask(prompt, ...)
	char *	prompt
	CODE:
	{
		short			item;
		DialogPtr	dlg;
		
		dlg = GetNewDialog(2010, NULL, (WindowPtr)-1);
		InitCursor();
		SetDlgText(dlg, 3, prompt);
		
		if (items > 1)
			SetDlgText(dlg, 4, (char *) SvPV_nolen(ST(1)));
		SelectDialogItemText(dlg, 4, 0, 1024);
		
		ShowWindow(dlg);
		SetPort(dlg);
		FrameDlgRect(dlg, ok);
		ModalDialog((ModalFilterUPP)0, &item);
		switch (item) {
		case ok:
			GetDlgText(dlg, 4, gMacPerlScratchString);
			ST(0) = sv_2mortal(newSVpv(gMacPerlScratch+!!*gMacPerlScratch, gMacPerlScratch[0]));
			break;
		case cancel:
			ST(0) = &PL_sv_undef;
			break;
		}
		DisposeDialog(dlg);
	}

int
MP_Answer(prompt, ...)
	char *	prompt
	CODE:
	{
		short			item;
		DialogPtr	dlg;
		
		if (items > 4)
			items = 4;
			
		dlg = GetNewDialog((items>1) ? 1999+items : 2001, NULL, (WindowPtr)-1);
		InitCursor();
		SetDlgText(dlg, 5, prompt);
		
		if (items > 1)
			for (item = 1; item < items; item++) {
				strcpy(gMacPerlScratch+1, (char *) SvPV_nolen(ST(item)));
				*gMacPerlScratchString = strlen(gMacPerlScratch+1);
				SetControlTitle(GetDlgCtrl(dlg, item), gMacPerlScratchString);
			}
		else
			SetControlTitle(GetDlgCtrl(dlg, 1), "\pOK");
			
		ShowWindow(dlg);
		SetPort(dlg);
		FrameDlgRect(dlg, ok);
		ModalDialog((ModalFilterUPP)0, &item);
		DisposeDialog(dlg);
		
		RETVAL = (items > 1) ? items - item - 1 : 0;
	}
	OUTPUT:
	RETVAL

void
MP_Choose(domain, type, prompt, ...)
	int		domain
	int		type
	char *	prompt
	CODE:
	{
		int 	 	flags;
		STRLEN	len;
		char * 	constraint;
		char * 	def_addr;
		
		constraint = (items>=4) ? ((char *) SvPV(ST(3), len)) : nil;
		constraint = constraint && len ? constraint : nil;
		flags = (items>=5) ? ((int) SvIV(ST(4))) : 0;
		def_addr = (items>=6) ? ((char *) SvPV(ST(5), len)) : nil;
		def_addr = def_addr && len ? def_addr : nil;
		
		gMacPerlScratch[0] = 0;
		
		if (def_addr) {
			memcpy(gMacPerlScratch, def_addr, len);
			gMacPerlScratch[len] = 0;	/* Some types require this */
		} 
		len = 256;							/* Len is output only! */
		
		if (choose(domain, type, prompt, constraint, flags, gMacPerlScratch, &len) < 0 || !len)
			ST(0) = &PL_sv_undef;
		else
			ST(0) = sv_2mortal(newSVpv(gMacPerlScratch, len));
	}

void
MP_Pick(prompt, ...)
	char *	prompt
	PPCODE:
	{	
		short			itemHit;
		STRLEN		len;
		Boolean		done;
		DialogPtr	dlg;
		Cell			mycell;
		short			mytype;
		Handle		myhandle;
		Point			cellsize;
		Rect			listrect, dbounds;
		char	*		item;
			
		InitCursor();
		dlg = GetNewDialog(2020, NULL, (WindowPtr)-1);
		
		SetDlgText(dlg, 3, prompt);
		GetDialogItem(dlg, 4, &mytype, &myhandle, &listrect);
		SetDialogItem(dlg, 4, mytype, (Handle)&uMacListUpdate, &listrect);
		
		SetPort(dlg);
		InsetRect(&listrect, 1, 1);
		SetRect(&dbounds, 0, 0, 1, items-1);
		cellsize.h = (listrect.right - listrect.left);
		cellsize.v = 17;
	
		listrect.right -= 15;
	
		gPickList = LNew(&listrect, &dbounds, cellsize, 0,
								dlg, true, false, false, true);
	
		gPickScalar = GIMME != G_ARRAY;
		gPickList[0]->selFlags = !gPickScalar ? lExtendDrag+lUseSense : lOnlyOne;
		LSetDrawingMode(false, gPickList);
		
		SetCell(mycell, 0, 0);
		for (; mycell.v<items-1; ++mycell.v)	{
			item = (char *) SvPV(ST(mycell.v+1), len);
			LSetCell(item, len, mycell, gPickList);
		}
	
		LSetDrawingMode(true, gPickList);
		ShowWindow(dlg);
		
		for (done=false; !done; ) {
			SetPort(dlg);
			FrameDlgRect(dlg, ok);
			ModalDialog((ModalFilterUPP) &uMacListFilter, &itemHit);
			switch (itemHit) {
			case ok:
				SetCell(mycell, 0, 0);
				done = true;
				while (LGetSelect(true, &mycell, gPickList)) {
					XPUSHs(sv_mortalcopy(ST(mycell.v+1)));
					++mycell.v;
				}
				break;
			case cancel:
				done = true;
				break;
			}
		}	/* Modal Loop */
		SetPort(dlg);
		LDispose(gPickList);
		gPickList = nil;
		DisposeDialog(dlg);
	}

void
MP_Quit(condition)
	int	condition
	CODE:
	gMacPerl_Quit = condition;

void
MP_FAccess(file, cmd, ...)
	char *	file
	unsigned	cmd
	PPCODE:
	{
		unsigned				uarg;
		Rect					rarg;
		SelectionRecord	sarg;
		char * 				name;
		
		switch (cmd) {
		case F_GFONTINFO:
			if (faccess(file, cmd, (long *)&uarg) < 0)
				XPUSHs(&PL_sv_undef);
			else if (GIMME != G_ARRAY)
				XPUSHs(sv_2mortal(newSViv(uarg >> 16)));
			else {
				GetFontName(uarg >> 16, gMacPerlScratchString);
				XPUSHs(sv_2mortal(newSVpv(gMacPerlScratch+!!*gMacPerlScratch, *gMacPerlScratch)));
				XPUSHs(sv_2mortal(newSViv(uarg & 0xFFFF)));
			}
			break;
		case F_GSELINFO:
			if (faccess(file, cmd, (long *)&sarg) < 0)
				XPUSHs(&PL_sv_undef);
			else if (GIMME != G_ARRAY)
				XPUSHs(sv_2mortal(newSViv(sarg.startingPos)));
			else {
				XPUSHs(sv_2mortal(newSViv(sarg.startingPos)));
				XPUSHs(sv_2mortal(newSViv(sarg.endingPos)));
				XPUSHs(sv_2mortal(newSViv(sarg.displayTop)));
			}
			break;
		case F_GTABINFO:
			if (faccess(file, cmd, (long *)&uarg) < 0) 
				XPUSHs(&PL_sv_undef);
			else
				XPUSHs(sv_2mortal(newSViv(uarg)));
			break;
		case F_GWININFO:
			if (faccess(file, cmd, (long *)&rarg) < 0)
				XPUSHs(&PL_sv_undef);
			else if (GIMME != G_ARRAY)
				XPUSHs(sv_2mortal(newSViv(rarg.top)));
			else {
				XPUSHs(sv_2mortal(newSViv(rarg.left)));
				XPUSHs(sv_2mortal(newSViv(rarg.top)));
				XPUSHs(sv_2mortal(newSViv(rarg.right)));
				XPUSHs(sv_2mortal(newSViv(rarg.bottom)));
			}
			break;
		case F_SFONTINFO:
			if (items < 3)
				croak("Usage: MacPerl::FAccess(file, F_SFONTINFO, font [, size])");
			
			name = SvPV_nolen(ST(2));
			
			if (items == 3) {
				if (faccess(file, F_GFONTINFO, (long *)&uarg) < 0)
					uarg = 9;
			} else
				uarg = (unsigned) SvIV(ST(3));
			
			if (isalpha(*name)) {
				short	family;
				
				getfnum(name, &family);
				
				uarg = (uarg & 0xFFFF) | ((unsigned) family) << 16;
			} else 
				uarg = (uarg & 0xFFFF) | ((unsigned) SvIV(ST(2))) << 16;
			
			if (faccess(file, cmd, (long *)uarg) < 0)
				XPUSHs(&PL_sv_undef);
			else
				XPUSHs(sv_2mortal(newSViv(1)));
			break;
		case F_SSELINFO:
			if (items < 4)
				croak("Usage: MacPerl::FAccess(file, F_SSELINFO, start, end [, top])");
			
			if (items == 4) {
				if (faccess(file, F_GSELINFO, (long *) &sarg) < 0) 
					sarg.displayTop = SvIV(ST(2));
			} else 
				sarg.displayTop = SvIV(ST(4));
				
			sarg.startingPos = SvIV(ST(2));
			sarg.endingPos = SvIV(ST(3));
			
			if (faccess(file, cmd, (long *)&sarg) < 0)
				XPUSHs(&PL_sv_undef);
			else
				XPUSHs(sv_2mortal(newSViv(1)));
			break;
		case F_STABINFO:
			if (items < 3)
				croak("Usage: MacPerl::FAccess(file, F_STABINFO, tab)");
			
			uarg = SvIV(ST(2));
			
			if (faccess(file, cmd, (long *)uarg) < 0) 
				XPUSHs(&PL_sv_undef);
			else
				XPUSHs(sv_2mortal(newSViv(1)));
			break;
		case F_SWININFO:
			if (items < 4 )
				croak("Usage: MacPerl::FAccess(file, F_SWININFO, left, top [, right [, bottom]])");
			
			if (items < 6) {
				if (faccess(file, F_GWININFO, (long *)&rarg) < 0)
					rarg.bottom = rarg.right = 400;
				else {
					rarg.bottom = rarg.bottom - rarg.top + (short) SvIV(ST(3));
					if (items == 4)
						rarg.right = rarg.right - rarg.left + (short) SvIV(ST(2));
				}
			} else {
				rarg.right = (short) SvIV(ST(4));
				rarg.bottom = (short) SvIV(ST(5));
			}
				
			rarg.left = (short) SvIV(ST(2));
			rarg.top = (short) SvIV(ST(3));
			
			if (faccess(file, cmd, (long *)&rarg) < 0)
				XPUSHs(&PL_sv_undef);
			else
				XPUSHs(sv_2mortal(newSViv(1)));
			break;
		default:
			croak("MacPerl::FAccess() can't handle this command");
		}
	}

void
MP_MakeFSSpec(path)
	char *	path
	CODE:
	{
		FSSpec	spec;
		
		if (GUSIPath2FSp(path, &spec))
	 		ST(0) = &PL_sv_undef;
		else
			ST(0) = sv_2mortal(newSVpv(GUSIFSp2Encoding(&spec), 0));
	}

void
MP_MakePath(path)
	char *	path
	CODE:	
	{
		FSSpec	spec;
		
		if (GUSIPath2FSp(path, &spec))
	 		ST(0) = &PL_sv_undef;
		else
			ST(0) = sv_2mortal(newSVpv(GUSIFSp2FullPath(&spec), 0));
	}

void
MP_Volumes()
	PPCODE:
	{
		FSSpec spec;
		
		if (GIMME != G_ARRAY) {
			GUSISpecial2FSp('macs', kOnSystemDisk, &spec);
			GetVolInfo(spec.vRefNum, false, &spec);
			
			XPUSHs(sv_2mortal(newSVpv(GUSIFSp2Encoding(&spec), 0)));
		} else {
			short	index;
			
			for (index = 0; !GetVolInfo(index+1, true, &spec); ++index)
				XPUSHs(sv_2mortal(newSVpv(GUSIFSp2Encoding(&spec), 0)));
		}
	}

BOOT:
	{
		extern int	StandAlone;
		VersRecHndl	vers 	= (VersRecHndl) GetResource('vers', 1);
		int 		versLen	= *(*vers)->shortVersion;
		SV *		version	= get_sv("MacPerl::Version", TRUE | GV_ADDMULTI);
		SV *		arch	= get_sv("MacPerl::Architecture", TRUE | GV_ADDMULTI);
		SV *		cc	= get_sv("MacPerl::Compiler", TRUE | GV_ADDMULTI);

		HLock((Handle) vers);
		memcpy(gMacPerlScratch, (char *)(*vers)->shortVersion+1, versLen);
		if (StandAlone) 
			strcpy(gMacPerlScratch+versLen, " Application");
		else
			strcpy(gMacPerlScratch+versLen, " MPW");
		
		sv_setpv(version, gMacPerlScratch);
		SvREADONLY_on(version);
		
		sv_setpv(arch, ARCHNAME);
		SvREADONLY_on(arch);

		sv_setpv(cc, CC);
		SvREADONLY_on(cc);
	}
