/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPSave.c			-	Handle all the runtimes
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPSave.c,v $
Revision 1.2  2001/10/03 19:23:16  pudge
Sync with perforce maint-5.6/macperl

Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.3  1998/04/07 01:46:43  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/08/08 16:58:06  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:58  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:01:45  neeri
Initial revision

Revision 0.1  1993/10/03  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <Errors.h>
#include <Resources.h>
#include <PLStringFuncs.h>
#include <LowMem.h>
#include <Folders.h>
#include <Finder.h>
#include <GUSIFileSpec.h>

#include <string.h>

#include "MPSave.h"
#include "MPGlobals.h"
#include "MPFile.h"
#include "MPUtils.h"

#if defined(powerc) || defined (__powerc)
#pragma options align=mac68k
#endif

#define SERsrcBase	32700

typedef struct {
	OSType			version; 
	OSType			id;
	OSType			fType;
	OSType			fCreator;
	
	unsigned			wantsBundle 	: 1;
	unsigned			hasCustomIcon 	: 1;
} SEPackage, ** SEPackageHdl;

typedef struct {
	OSType	type;
	OSType	realType;
	short		id;
	short		realID;
} ShoppingList, ** ShoppingListHdl;

typedef struct {
	OSType	type;
	short		id;
} OwnerList;

#if defined(powerc) || defined (__powerc)
#pragma options align=reset
#endif

typedef struct {
	OSType			id;
	OSType			fType;
	OSType			fCreator;
	StringHandle	name;
	Boolean			wantsBundle;
	Boolean			hasCustomIcon;
	FSSpec			file;
} SaveExtension;

typedef struct {
	short				count;
	SaveExtension	ext[1];
} SERec, * SEPtr, ** SEHdl;

SEHdl			SaveExtensions	=	nil;
OSType **	FileTypeH = nil;
OSType * 	MacPerlFileTypes;
short			MacPerlFileTypeCount;

OwnerList noOwner[] = {
	0, 0
};

OwnerList ancientOwner[] = {
	'ALRT', 256,
	'ALRT', 257,
	'ALRT', 262,
	'ALRT', 266,
	'ALRT', 270,
	'ALRT', 274,
	'ALRT', 300,
	'ALRT', 302,
	'ALRT', 3850,
	'BNDL', 128,
	'CNTL', 192,
	'CODE', 0,
	'CODE', 1,
	'CODE', 2,
	'CODE', 3,
	'CODE', 4,
	'CODE', 5,
	'CODE', 6,
	'CODE', 7,
	'CODE', 8,
	'CODE', 9,
	'CODE', 10,
	'CODE', 11,
	'CODE', 12,
	'CODE', 13,
	'CODE', 14,
	'CODE', 15,
	'CODE', 16,
	'CODE', 17,
	'CODE', 18,
	'CODE', 19,
	'CODE', 20,
	'CODE', 21,
	'CODE', 22,
	'CODE', 23,
	'CODE', 24,
	'CODE', 25,
	'CODE', 26,
	'CODE', 27,
	'CODE', 28,
	'CODE', 29,
	'CODE', 30,
	'CODE', 31,
	'CODE', 32,
	'CODE', 33,
	'CODE', 34,
	'CODE', 35,
	'CODE', 36,
	'CODE', 37,
	'CODE', 38,
	'CODE', 39,
	'CODE', 40,
	'CODE', 41,
	'CODE', 42,
	'CODE', 43,
	'CODE', 44,
	'CODE', 45,
	'CODE', 46,
	'CODE', 47,
	'CODE', 48,
	'CODE', 49,
	'CODE', 50,
	'CODE', 51,
	'CURS', 128,
	'CURS', 129,
	'CURS', 130,
	'CURS', 131,
	'CURS', 132,
	'CURS', 144,
	'CURS', 145,
	'CURS', 146,
	'CURS', 147,
	'CURS', 148,
	'CURS', 160,
	'CURS', 161,
	'CURS', 162,
	'CURS', 163,
	'DITL', 192,
	'DITL', 256,
	'DITL', 257,
	'DITL', 258,
	'DITL', 262,
	'DITL', 266,
	'DITL', 270,
	'DITL', 274,
	'DITL', 300,
	'DITL', 302,
	'DITL', 320,
	'DITL', 384,
	'DITL', 385,
	'DITL', 386,
	'DITL', 387,
	'DITL', 512,
	'DITL', 1005,
	'DITL', 2001,
	'DITL', 2002,
	'DITL', 2003,
	'DITL', 2010,
	'DITL', 2020,
	'DITL', 3850,
	'DITL', 10240,
	'DLOG', 192,
	'DLOG', 258,
	'DLOG', 320,
	'DLOG', 384,
	'DLOG', 512,
	'DLOG', 1005,
	'DLOG', 2001,
	'DLOG', 2002,
	'DLOG', 2003,
	'DLOG', 2010,
	'DLOG', 2020,
	'DLOG', 10240,
	'FOND', 19999,
	'FOND', 32268,
	'FREF', 128,
	'FREF', 129,
	'FREF', 130,
	'FREF', 131,
	'FREF', 132,
	'FREF', 133,
	'FREF', 134,
	'GU·I', 10240,
	'ICN#', 10240,
	'ICN#', 128,
	'ICN#', 129,
	'ICN#', 130,
	'ICN#', 131,
	'ICN#', 385,
	'ICN#', 386,
	'ICN#', 387,
	'IRng', 128,
	'LDEF', 128,
	'MDEF', 1,
	'MENU', 128,
	'MENU', 129,
	'MENU', 130,
	'MENU', 131,
	'MENU', 132,
	'MENU', 192,
	'McPL', 0,
	'MrP#', 128,
	'MrP3', 128,
	'MrP7', 128,
	'MrP4', 128,
	'MrP8', 128,
	'MrPA', 4096,
	'MrPB', 128,
	'MrPC', 0,
	'MrPC', 1,
	'MrPC', 2,
	'MrPD', 4096,
	'MrPF', 132,
	'MrPF', 133,
	'MrPF', 134,
	'MrPI', 128,
	'MrPL', 0,
	'MrPS', -1,
	'NFNT', 2816,
	'NFNT', 2825,
	'NFNT', 2828,
	'NFNT', 32268,
	'PICT', 128,
	'SIZE', -1,
	'STR ', 133,
	'STR#', 129,
	'STR#', 130,
	'STR#', 132,
	'STR#', 256,
	'STR#', 32268,
	'STR#', 384,
	'TMPL', 10240,
	'WIND', 128,
	'WIND', 129,
	'WIND', 130,
	'acur', 0,
	'acur', 128,
	'acur', 129,
	'aete', 0,
	'dctb', 384,
	'hmnu', 129,
	'hmnu', 130,
	'hmnu', 132,
	'icl4', 128,
	'icl4', 129,
	'icl4', 130,
	'icl4', 131,
	'icl4', 385,
	'icl4', 386,
	'icl4', 387,
	'icl8', 128,
	'icl8', 129,
	'icl8', 130,
	'icl8', 131,
	'icl8', 385,
	'icl8', 386,
	'icl8', 387,
	'icm#', 256,
	'icm#', 257,
	'icm#', 264,
	'icm#', 265,
	'icm#', 266,
	'ics#', 128,
	'vers', 1,
	'vers', 2,
	0,      0
};

OwnerList * noOwnerPtr = noOwner;
OwnerList * ancientOwnerPtr = ancientOwner;

Boolean InOwnerList(OSType type, short id, OwnerList * list)
{
	while (list->type)
		if (list->type == type && list->id == id)
			return true;
		else
			++list;
	
	return false;
}

OSErr CopySomeResources(short origFile, short resFile)
{
	OSErr				err;
	Handle 			rsrc;
	Handle			nur;
	short				typeCnt;
	short				typeIdx;
	short				rsrcCnt;
	short				rsrcIdx;
	short				rsrcID;
	Boolean			wantItBadly;
	ResType			rsrcType;
	Str255			rsrcName;
	OwnerList **	include;
	OwnerList **	exclude;
	
	UseResFile(origFile);
	
	if (!(exclude = (OwnerList **) Get1Resource('McPo', 128)))
		exclude = &ancientOwnerPtr;

	if (!(include = (OwnerList **) Get1Resource('McPo', 129)))
		include = &noOwnerPtr;
	
	typeCnt = Count1Types();
	
	for (typeIdx = 0; typeIdx++ < typeCnt; ) {
		Get1IndType(&rsrcType, typeIdx);
		
		rsrcCnt = Count1Resources(rsrcType);
		
		for (rsrcIdx = 0; rsrcIdx++ < rsrcCnt; ) {
			rsrc = Get1IndResource(rsrcType, rsrcIdx);
			
			if (!rsrc) 
				return ResError();
			
			GetResInfo(rsrc, &rsrcID, &rsrcType, rsrcName);
			
			if (rsrcType == 'McPo' && rsrcID == 128)
				continue;
			if (rsrcType == 'TEXT' && !PLstrcmp(rsrcName, "\p!"))
				continue;
			if (rsrcType == 'McPo' && rsrcID == 129) {
				wantItBadly = true;
				HandToHand(&rsrc);
			} else {
				wantItBadly = InOwnerList(rsrcType, rsrcID, *include);
				DetachResource(rsrc);
			}
			
			if (wantItBadly || !InOwnerList(rsrcType, rsrcID, *exclude)) {
				UseResFile(resFile);
		
				if (nur = Get1Resource(rsrcType, rsrcID))
					if (wantItBadly) {
						RemoveResource(nur);
						
						nur = nil;
					}
				
				if (!nur) {	
					AddResource(rsrc, rsrcType, rsrcID, rsrcName);
				
					if (err = ResError()) {
						DisposeHandle(rsrc);
						return err;
					}
				} else 
					DisposeHandle(rsrc);
				
				UseResFile(origFile);
			} else
				DisposeHandle(rsrc);
		}
	}
	
	return noErr;
}

OSErr	CopyShoppingList(short from, short to, ShoppingList * list, StringPtr fileName)
{
	OSErr			err;
	
	for (; list->type; ++list) {
		Handle		rsrc;
		Handle		nur;
		Str255		name;
		char *		macro;
		char *      end;
		int			len;
				
		UseResFile(from);
		
		rsrc = Get1Resource(list->type, list->id);
		
		if (!rsrc)
			return ResError();
		
		UseResFile(to);
		
		GetResInfo(rsrc, &list->id, &list->type, name);
		name[name[0]+1] = 0;
		
		for (macro = strchr((char *)name+1, '%'); macro; )
			if (macro[1] == 'n') {
				if (end = (char *)memchr(fileName+1, '.', *name)) 
					len = end - (char *) fileName - 1;
				else
					len = *fileName;
				memmove(macro+len, macro+2, strlen(macro+2)+1);
				memcpy(macro, fileName+1, len);
				macro += len;
			} else
				macro = strchr(macro+1, '%');
			
		name[0] = strlen((char *)name+1);
		if (nur = Get1Resource(list->realType, list->realID))
			RemoveResource(nur);
			
		HandToHand(&rsrc);
		AddResource(rsrc, list->realType, list->realID, name);
		
		if (err = ResError())
			goto finish;
		
nextrsrc:
		;
	}
	
finish:
	UseResFile(from);
	
	return err;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

static OSType	WantsType;
static OSType	WantsCreator;
static Boolean	WantsBundle;
static Boolean	HasCustomIcon;

OSErr DoOpenResFile(FSSpec * spec, short * resFile)
{
	OSErr	err;
	FInfo info;
	
	*resFile = HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdWrPerm);
	if (*resFile == -1) {
		if (err = DoCreate(*spec))
			return err;

		*resFile =  HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdWrPerm);
		if (*resFile == -1) {
			FileError((StringPtr) "\perror opening file ", spec->name);
			
			return ResError();
		}
	}
	
	HGetFInfo(spec->vRefNum, spec->parID, spec->name, &info);
	
	info.fdType		=	WantsType;
	info.fdCreator	=	WantsCreator;
	
	if (WantsBundle)
		info.fdFlags 	|= kHasBundle;
	if (HasCustomIcon)
		info.fdFlags 	|= kHasCustomIcon;
		
	HSetFInfo(spec->vRefNum, spec->parID, spec->name, &info);
	
	return noErr;
}

OSErr CopyRsrc(FSSpec * from, FSSpec * to)
{
	OSErr		err;
	short 	res;
	short		fromRef;
	short		toRef;
	Handle	copy;
	Ptr		buffer;
	long		len;
	
	copy 		= NewHandle(4096);
	buffer 	= *copy;
	HLock(copy);
	
	if (err = DoOpenResFile(to, &res))
		goto disposeBuffer;
	
	CloseResFile(res);
	
	if (err = HOpenRF(from->vRefNum, from->parID, from->name, fsRdPerm, &fromRef))
		goto disposeBuffer;
	if (err = HOpenRF(to->vRefNum, to->parID, to->name, fsRdWrPerm, &toRef))
		goto closeFrom;

	do {
		len	=	4096;
		
		FSRead(fromRef, &len, buffer);
		FSWrite(toRef, &len, buffer);
	} while (len == 4096);
	
	FSClose(toRef);
	
closeFrom:
	FSClose(fromRef);
disposeBuffer:
	DisposeHandle(copy);
	
	return err;
}

OSErr CopyData(FSSpec * from, FSSpec * to)
{
	OSErr		err;
	short		fromRef;
	short		toRef;
	Handle	copy;
	Ptr		buffer;
	long		len;
	
	copy 		= NewHandle(4096);
	buffer 	= *copy;
	HLock(copy);
	
	if (err = HOpen(from->vRefNum, from->parID, from->name, fsRdPerm, &fromRef))
		goto disposeBuffer;
	if (err = HOpen(to->vRefNum, to->parID, to->name, fsRdWrPerm, &toRef))
		goto closeFrom;

	do {
		len	=	4096;
		
		FSRead(fromRef, &len, buffer);
		FSWrite(toRef, &len, buffer);
	} while (len == 4096);
	
	FSClose(toRef);
	
closeFrom:
	FSClose(fromRef);
disposeBuffer:
	DisposeHandle(copy);
	
	return err;
}

OSErr MakePackage(FSSpec * spec, short * resFile, DocType type, StringPtr name)
{
	OSErr					err;
	short					index;
	short					packFile;
	ShoppingListHdl	shopping;

	BuildSEList();
	
	for (index = 0; index < (*SaveExtensions)->count; ++index)
		if ((*SaveExtensions)->ext[index].id == type)
			break;
	
	if (index == (*SaveExtensions)->count)
		return errAEWrongDataType;

	WantsType 		= (*SaveExtensions)->ext[index].fType;
	WantsCreator	= (*SaveExtensions)->ext[index].fCreator;
	WantsBundle		= (*SaveExtensions)->ext[index].wantsBundle;
	HasCustomIcon	= (*SaveExtensions)->ext[index].hasCustomIcon;

	if (err = DoOpenResFile(spec, resFile))
		return err;
	
	{
		FSSpec *	spec = &(*SaveExtensions)->ext[index].file;
		
		packFile = HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdPerm);
	}
	
	if (packFile == -1) {
		err = fnfErr;
		goto done;
	}
	
	if (!(shopping = (ShoppingListHdl) Get1Resource('McPs', SERsrcBase))) {
		err = ResError();
		goto closePackage;
	}
	
	HLock((Handle) shopping);
	err = CopyShoppingList(packFile, *resFile, *shopping, name);

closePackage:
	CloseResFile(packFile);
done:	
	if (err)
		CloseResFile(*resFile);

	UseResFile(gAppFile);
		
	return err;
}

ShoppingList Runtime7Shopping[] =
{
	{ 'MrPB', 'BNDL', 128, 128 },
	{ 'MrPI', 'ICN#', 128, 128 },
	{ 'MrP4', 'icl4', 128, 128 },
	{ 'MrP8', 'icl8', 128, 128 },
	{ 'MrP#', 'ics#', 128, 128 },
	{ 'MrP3', 'ics4', 128, 128 },
	{ 'MrP7', 'ics8', 128, 128 },
	{ 		 0,    0,     0,	 0 }
};

OSErr Make7Runtime(FSSpec * spec, short * resFile, StringPtr name)
{
	OSErr		err;
	FSSpec	from;
	
	from.vRefNum	=	gAppVol;
	from.parID		=	gAppDir;
	PLstrcpy(from.name, LMGetCurApName());

	if (err = CopyRsrc(&from, spec))
		return err;
		
	if (err = CopyData(&from, spec))
		return err;
		
	if (err = DoOpenResFile(spec, resFile))
		return err;
		
	return CopyShoppingList(gAppFile, *resFile, Runtime7Shopping, name);
}

pascal OSErr DoSave(DPtr theDocument, FSSpec theFSSpec, StringPtr name)
{
	OSErr   			err;
	short				resFile;
	short				origFile;
	Handle			text	= 	(*theDocument->theText)->hText;
	Handle			thePHandle;
	HHandle			theHHandle;
	StringHandle	theAppName;

	HDelete(theFSSpec.vRefNum, theFSSpec.parID, theFSSpec.name);
	
	switch (theDocument->type) {
	case kPlainTextDoc:
		{
			short		refNum;
			long		length;
			
			WantsCreator	=	MPAppSig;
			WantsType		=	'TEXT';
			WantsBundle		=	false;
			HasCustomIcon	=	false;
			
			if (err = DoOpenResFile(&theFSSpec, &resFile))
				return err;
			
			if (err = 
				HOpenDF(
					theFSSpec.vRefNum, theFSSpec.parID, theFSSpec.name,
					fsRdWrPerm, &refNum)
			) {
				if (err = DoCreate(theFSSpec))
					goto closeResource;
				
				if (err =
					HOpenDF(
						theFSSpec.vRefNum, theFSSpec.parID, theFSSpec.name,
						fsRdWrPerm, &refNum)
				) {
					FileError((StringPtr) "\perror opening file ", theFSSpec.name);
					
					goto closeResource;
				}
			}
			
			length 	= GetHandleSize(text);
			
			HLock(text);
			
			err = FSWrite(refNum, &length, *text);
			
			HUnlock(text);
			FSClose(refNum);
			
			if (err)
				goto closeResource;
		}
		break;
	default:
		if (err = MakePackage(&theFSSpec, &resFile, theDocument->type, name))
			return err;
		
		goto writeScript;
	case kRuntime7Doc:
		WantsCreator	=	MPRtSig;
		WantsType		=	'APPL';
		WantsBundle		=	true;
		HasCustomIcon	=	false;

		if (err = Make7Runtime(&theFSSpec, &resFile, name))
			return err;
		
writeScript:			
		if (err = HandToHand(&text))
			goto closeResource;
		
		UseResFile(resFile);
		
		AddResource(text, 'TEXT', 128, (StringPtr) "\p!");
		if (err = ResError()) {
			DisposeHandle(text);
			
			goto closeResource;
		}
		
		if (err = PtrToHand(&theDocument->type, &text, 4))
			goto closeResource;
		
		AddResource(text, 'MrPL', 128, (StringPtr) "\p");
		if (err = ResError()) {
			DisposeHandle(text);
			
			goto closeResource;
		}
			
		break;
	}
	
	/* write out the printer info */
	if (theDocument->thePrintSetup) {
		thePHandle = (Handle)theDocument->thePrintSetup;
		HandToHand(&thePHandle);

		AddResource(thePHandle, 'TFSP', 255, (StringPtr) "\pPrinter Info");
		err = ResError();
		if (err = ResError()) {
			ShowError((StringPtr) "\pAddResource TFSP", err);
			goto closeResource;
		}
	}

	theHHandle = (HHandle)NewHandle(sizeof(HeaderRec));
 	HLock((Handle)theHHandle);

	(*theHHandle)->theRect     = theDocument->theWindow->portRect;
	OffsetRect(
		&(*theHHandle)->theRect,
		-theDocument->theWindow->portBits.bounds.left,
		-theDocument->theWindow->portBits.bounds.top);
		
	GetFontName((*(theDocument->theText))->txFont, (StringPtr) &(*theHHandle)->theFont);
	
	(*theHHandle)->theSize     = (*(theDocument->theText))->txSize;

	HUnlock((Handle)theHHandle);

	AddResource((Handle)theHHandle, 'TFSS', 255, (StringPtr) "\pHeader Info");
	if (err = ResError()) {
		ShowError((StringPtr) "\pAddResource- TFSS", err);
		goto closeResource;
	}

	if (theDocument->type == kPlainTextDoc) {
		/*Now put an AppName in for Finder in 7.0*/
	
		theAppName = (StringHandle)NewHandle(8);
		PLstrcpy(*theAppName,(StringPtr) "\pMacPerl");
	
		AddResource((Handle)theAppName, 'STR ', - 16396, (StringPtr) "\pFinder App Info");
		if (err = ResError()) {
			ShowError((StringPtr) "\pAppName", err);
			goto closeResource;
		}
	}

	if (theDocument->kind == kDocumentWindow && theDocument->u.reg.everLoaded) {
		/* Copy all resources that need copying */
		
		origFile = 
			HOpenResFile(
				theDocument->u.reg.origFSSpec.vRefNum,
				theDocument->u.reg.origFSSpec.parID,
				theDocument->u.reg.origFSSpec.name,
				fsRdPerm);
		if (origFile != -1) {
			err = CopySomeResources(origFile, resFile);
				
			CloseResFile(origFile);
		} 
		/* Otherwise, let's just assume the file had no resource fork */
	}

closeResource:
	CloseResFile(resFile);
	UseResFile(gAppFile);
	
	return err;
}

void ScanExtensions(OSType type, void (*found)(const FSSpec * spec, CInfoPBRec * info))
{
	short			runs;
	short 		index;
	FSSpec		spec;
	CInfoPBRec	info;
	
	spec.vRefNum	=	gAppVol;
	spec.parID		=	gAppDir;
	
	GUSIFSpUp(&spec);
	
	for (runs = 0; runs++ < 2; GUSISpecial2FSp(kExtensionFolderType, 0, &spec)) {
		if (GUSIFSpDown(&spec, (StringPtr) "\pMacPerl Extensions"))
			continue;
		if (GUSIFSpDown(&spec, (StringPtr) "\p"))
			continue;
		for (index = 1; !GUSIFSpIndex(&spec, index++); )
			if (!GUSIFSpGetCatInfo(&spec, &info) && info.hFileInfo.ioFlFndrInfo.fdType == type)
				found(&spec, &info);
	}
}

void AddSaveExtension(const FSSpec * spec, CInfoPBRec * info)
{
	short 				res;
	short					index;
	SEPackageHdl		pack;	
	StringHandle		name;
	SaveExtension *	ext;
	OSType				fType;
	
	res = HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdPerm);
	
	if (res == -1)
		return;
		
	if (!(pack = (SEPackageHdl) Get1Resource('McPp', SERsrcBase)))
		goto closeIt;
	
	for (index = 0; index<(*SaveExtensions)->count; ++index)
		if ((*pack)->id == (*SaveExtensions)->ext[index].id)
			goto closeIt;
	
	name	=	(StringHandle) Get1Resource('STR ', SERsrcBase);
	
	SetHandleSize(
		(Handle) SaveExtensions, GetHandleSize((Handle) SaveExtensions) + sizeof(SaveExtension));
	
	ext 						= (*SaveExtensions)->ext + (*SaveExtensions)->count++;
	ext->id					= (*pack)->id;
	ext->fType				= (*pack)->fType;
	ext->fCreator			= (*pack)->fCreator;
	ext->wantsBundle		= (*pack)->wantsBundle;
	ext->hasCustomIcon	= (*pack)->hasCustomIcon;
	ext->name		= name;
	ext->file 		= *spec;
	
	DetachResource((Handle) name);
	
	fType = ext->fType;
	
	for (index = 0; index<MacPerlFileTypeCount; ++index)
		if (fType == (*FileTypeH)[index])
			goto closeIt;
	
	PtrAndHand(&fType, (Handle) FileTypeH, sizeof(OSType));
	
	++MacPerlFileTypeCount;
closeIt:
	CloseResFile(res);
}

pascal void BuildSEList()
{
	if (SaveExtensions)
		return;
	
	SaveExtensions 				= (SEHdl) NewHandle(2);
	(*SaveExtensions)->count 	= 0;
	
	PtrToHand("APPLTEXT", (Handle *) &FileTypeH, 8);
	MacPerlFileTypeCount			= 2;
	
	ScanExtensions('McPp', AddSaveExtension);
	
	MoveHHi((Handle) FileTypeH);
	HLock((Handle) FileTypeH);
	
	MacPerlFileTypes				= *FileTypeH;
}

pascal Boolean CanSaveAs(DocType type)
{
	short	index;
	
	BuildSEList();
	
	switch (type) {
	case kPlainTextDoc:
	case kRuntime7Doc:
		return true;
	default:
		break;
	}
	
	for (index = 0; index<(*SaveExtensions)->count; ++index)
		if (type == (*SaveExtensions)->ext[index].id)
			return true;
			
	return false;
}


pascal void AddExtensionsToMenu(MenuHandle menu)
{
	short				index;
	StringHandle	name;
	
	BuildSEList();
	
	for (index = 0; index < (*SaveExtensions)->count; ++index) {
		name = (*SaveExtensions)->ext[index].name;
		
		HLock((Handle) name);
		AppendMenu(menu, (StringPtr) "\px");
		SetMenuItemText(menu, index+ssd_Predef+1, *name);
		HUnlock((Handle) name);
	}
}

pascal short Type2Menu(DocType type)
{
	short	index;

	BuildSEList();
	
	switch (type) {
	case kPlainTextDoc:
		return 1;
	case kRuntime7Doc:
		return 2;
	default:
		for (index = 0; index < (*SaveExtensions)->count; ++index)
			if ((*SaveExtensions)->ext[index].id == type)
				return index + ssd_Predef + 1;
	}
	
	/* Should never happen */
	
	return 0;
}

pascal DocType Menu2Type(short item)
{
	BuildSEList();
	
	switch (item) {
	case 1:
		return kPlainTextDoc;
	case 2:
		return kRuntime7Doc;
	default:
		item -= ssd_Predef + 1;
		
		if (item < 0 || item >= (*SaveExtensions)->count)
			return kUnknownDoc;
		
		return (*SaveExtensions)->ext[item].id;
	}
}
