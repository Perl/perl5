/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPScript.c		-	Handle scripts
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPScript.c,v $
Revision 1.4  2001/04/16 02:42:43  neeri
run_perl no longer longjmps (MacPerl bug #232703)

Revision 1.3  2001/01/24 09:51:30  neeri
Fix library paths (Bug 129817)

Revision 1.5  1999/01/24 05:07:00  neeri
Tweak alias handling

Revision 1.4  1998/04/07 01:46:44  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:57  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:07  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:00  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:54:19  neeri
Always keep the right resource file in front.

Revision 1.1  1994/02/27  23:01:56  neeri
Initial revision

Revision 0.2  1993/10/14  00:00:00  neeri
Run front window

Revision 0.1  1993/08/17  00:00:00  neeri
Set up correct default directory

*********************************************************************/

#define ORIGINAL_WRAPPER

#include "MPScript.h"
#include "MPWindow.h"
#include "MPAppleEvents.h"
#include "MPAEVTStream.h"
#include "MPFile.h"
#include "MPSave.h"
#include "MPMain.h"
#include "MPPreferences.h"
#include "icemalloc.h"

#include <AERegistry.h>
#include <String.h>
#include <GUSIFileSpec.h>
#include <sys/types.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>
#include <StandardFile.h>
#include <Resources.h>
#include <PLStringFuncs.h>
#include <TextUtils.h>
#include <LowMem.h>
#include <CodeFragments.h>
#include <AEBuild.h>
#include <AEStream.h>
#include <AESubDescs.h>
#include <OSA.h>

static FSSpec ** sStandardScripts;

pascal Boolean GetScriptFilter(CInfoPBPtr pb)
{
	switch (GetDocTypeFromInfo(pb)) {
	case kPreferenceDoc:
		/* We don't want preference files here. */
	case kUnknownDoc:
		return true;
	default:
		return false;
	}
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uGetScriptFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppFileFilterProcInfo, GetScriptFilter);
#endif

void PopupOffending(AEDesc * repl)
{
	OSErr						err;
	AEDesc					target;
	short						line;
	DescType					type;
	Size						size;
	FSSpec					file;
	
	if (AEGetParamPtr(repl, kOSAErrorOffendingObject, typeFSS, &type, &file, sizeof(FSSpec), &size))
		return;
	if (AEGetKeyDesc(repl, kOSAErrorRange, typeWildCard, &target))
		return;
	err = AEGetKeyPtr(&target, keyOSASourceStart, typeShortInteger, &type, &line, sizeof(short), &size);
	AEDisposeDesc(&target);
	if (err)
		return;
	IssueJumpCommand(&file, nil, line);
}

static void SendScriptEvent(
	DescType argType, 
	Ptr 		argPtr, 
	Handle	argHdl,
	Size 		argSize, 
	Boolean	syntax,
	FSSpec *	dir)
{
	OSErr					err;
	AppleEvent			cmd, repl;
	AEAddressDesc		addr;
	AEStream				aes;
	
	if (err = MakeSelfAddress(&addr))
		goto failedAddress;
		
	if (err = 
		AECreateAppleEvent(
			kAEMiscStandards, kAEDoScript, &addr, 
			kAutoGenerateReturnID, kAnyTransactionID, 
			&cmd)
	)
		goto failedAppleEvent;
	
	if (err = AEStream_OpenEvent(&aes, &cmd))
		goto failedStream;
	
	err = AEStream_WriteKey(&aes, keyDirectObject);
	
	if (!err)
		if (argHdl) {
			AEDesc	arg;
			
			arg.descriptorType	=	argType;
			arg.dataHandle			=	argHdl;
			
			err = AEStream_WriteAEDesc(&aes, &arg);
		} else
			err = AEStream_WriteDesc(&aes, argType, argPtr, argSize);
	
	if (!err)	
		if (syntax)
			err = AEStream_WriteKeyDesc(
						&aes, 'CHCK', typeBoolean, (Ptr) &syntax, sizeof(Boolean));
		else {
			if (gDebug)
				err =	AEStream_WriteKeyDesc(
							&aes, 'DEBG', typeBoolean, (Ptr) &gDebug, sizeof(Boolean));
			if (!err && gWarnings)
				err =	AEStream_WriteKeyDesc(
							&aes, 'WARN', typeBoolean, (Ptr) &gWarnings, sizeof(Boolean));
		}
	if (!err && dir)
		err =	AEStream_WriteKeyDesc(&aes, 'DIRE', typeFSS, (Ptr) dir, sizeof(FSSpec));	
					
	if (err)
		AEStream_Close(&aes, nil);
	else 
		err = AEStream_Close(&aes, &cmd);
	
	if (err)
		goto failedStream;
		
	if (AESend(&cmd, &repl,
			kAEWaitReply+kAEAlwaysInteract, kAENormalPriority, kAEDefaultTimeout,
			nil, nil)
	&& !gQuitting
	) 
		PopupOffending(&repl);

	AEDisposeDesc(&repl);
failedStream:
	AEDisposeDesc(&cmd);
failedAppleEvent:
	AEDisposeDesc(&addr);
failedAddress:
	;
}

pascal void DoScriptMenu(short theItem)
{
	StandardFileReply	reply;
	FSSpec				dir;

	BuildSEList();
	
	switch (theItem) {
	default:
		reply.sfFile = (*sStandardScripts)[theItem-pmStandard];
		dir = reply.sfFile;
		GUSIFSpUp(&dir);
		SendScriptEvent(
			typeFSS, (Ptr) &reply.sfFile, nil, sizeof(FSSpec), 
			false, &dir);
		break;
	case pmRun:
	case pmCheckSyntax:
		StandardGetFile(&uGetScriptFilter, MacPerlFileTypeCount, MacPerlFileTypes, &reply);
		if (reply.sfGood) {
			dir = reply.sfFile;
			GUSIFSpUp(&dir);
			SendScriptEvent(
				typeFSS, (Ptr) &reply.sfFile, nil, sizeof(FSSpec), 
				theItem == pmCheckSyntax, &dir);
		}
		break;
	case pmRunFront:
	case pmCheckFront:
		{
			WindowPtr	win;
			DPtr			doc;
			
			for (win = FrontWindow(); win; win = GetNextWindow(win)) {
				if (!IsWindowVisible(win) || !Ours(win))
					continue;
				if ((doc = DPtrFromWindowPtr(win)) && doc->kind == kDocumentWindow)
					break;
			}
			
			if (!win)
				break;
			
			if (doc->u.reg.everSaved) {
				dir = doc->theFSSpec;
			} else {	
				dir.vRefNum	= 	gAppVol;
				dir.parID	=	gAppDir;
			}
			GUSIFSpUp(&dir);
			
			if (doc->dirty || !doc->u.reg.everSaved) {
				if (doc->u.reg.everSaved)
					strcpy(gMacPerl_PseudoFileName, GUSIFSp2FullPath(&doc->theFSSpec));
				else
					getwtitle(win, gMacPerl_PseudoFileName);

				SendScriptEvent(
					typeChar, nil, (*doc->theText)->hText, 
					GetHandleSize((*doc->theText)->hText),
					theItem == pmCheckFront, &dir);
			} else {
				gMacPerl_PseudoFileName[0] = 0;
				SendScriptEvent(
					typeFSS, (Ptr) &doc->theFSSpec, nil, sizeof(FSSpec), 
					theItem == pmCheckFront, &dir);
			}
		}
		break;
	case pmWarnings:
		gWarnings = !gWarnings;
		CheckItem(myMenus[perlM], pmWarnings, gWarnings);
		break;
	case pmDebug:
		gDebug = !gDebug;
		CheckItem(myMenus[perlM], pmDebug, gDebug);
		break;
	case pmTaint:
		gTaint = !gTaint;
		CheckItem(myMenus[perlM], pmTaint, gTaint);
		break;
	}
}

typedef void (*atexitfn)();

void MP_Exit(int status)
{
	if (gRunningPerl)
		longjmp(gExitPerl, -status-1);
	else {
		ExitToShell();
	}
}

static atexitfn 	PerlExitFn[20];
static int			PerlExitCnt;

int MP_AtExit(atexitfn func)
{
	if (gRunningPerl)
		PerlExitFn[PerlExitCnt++] = func;
	else {
		return atexit(func);
	}
		
	return 0;
}

static char **		PerlArgs;
static int			PerlArgMax;
static char **		PerlEnviron;
static Handle		PerlEnvText;

char * MP_GetEnv(const char * var)
{
	char ** 	env;
	
	for (env = PerlEnviron; *env; ++env)
		if (equalstring(*env, var, false, true))
			return *env + strlen(*env) + 1;
		
	return nil;
}

pascal void InitPerlEnviron()
{
	/* gDebugLogName 	= "Dev:Console:Debug Log";
	gExit				= MP_Exit;
	gAtExit			= MP_AtExit;
	 */
	gMacPerl_AlwaysExtract	= true;
	gMacPerl_HandleEvent		= HandleEvent;
}

pascal Handle MakeLibraries()
{
	char		end = 0;
	int		libCount;
	int		envLen;
	short		resFile;
	char *	libpath;
	FSSpec	libspec;
	Handle	libs;
	Handle	env;
	Str255	lib;

	if (libs = gCachedLibraries)
		goto haveLibs;
	
	PtrToHand("MACPERL", &libs, 8);
	libspec.vRefNum		= 	gAppVol;
	libspec.parID			=	gAppDir;
	GUSIFSpUp(&libspec);
	libpath  				=	GUSIFSp2FullPath(&libspec);
	libCount					=	strlen(libpath);
	PtrAndHand(libpath, libs, libCount+1);
	
	PtrAndHand("PERL5LIB", libs, 9);
	
	resFile = CurResFile();
	OpenPreferences();
	if (gPrefsFile) {
		UseResFile(gPrefsFile);
		
		for (libCount = 1; ; ++libCount) {
			GetIndString(lib, LibraryPaths, libCount);
			
			if (!lib[0])
				break;
			
			if (lib[1] == ':') {
				char *	libpath;
				FSSpec	libspec;
			
				libspec.vRefNum	= 	gAppVol;
				libspec.parID		=	gAppDir;
				memcpy(libspec.name+1, lib+2, *libspec.name = *lib-1);
			
				libpath  = GUSIFSp2FullPath(&libspec);
				memcpy(lib+1, libpath, *lib = strlen(libpath));
			}
				
			if (libCount > 1)
				PtrAndHand(",", libs, 1);
			
			PtrAndHand(lib+1, libs, lib[0]);
		}
		PtrAndHand(&end, libs, 1);

		if (env = Get1Resource('STR#', EnvironmentVars)) {
			DetachResource(env);
			HLock(env);
			libpath = *env + 2;
			for (libCount = **(short **)env; libCount--; libpath += envLen+1)  {
				envLen 	= *libpath;
				*strchr(libpath, '=') = 0;
				*libpath = 0;
			}
			if (libpath > *env+2) {
				PtrAndHand(*env+3, libs, libpath-*env-3);
				PtrAndHand(*env+2, libs, 1);
			}
			DisposeHandle(env);
		}

		CloseResFile(gPrefsFile);
	}
	
	UseResFile(resFile);
	
	gCachedLibraries = libs;

haveLibs:
	HandToHand(&libs);
	
	return libs;
}

/* Build environment from AEDescriptor passed in 'ENVT' parameter */

void MakePerlEnviron(AEDesc * desc)
{
	Handle		envText  = MakeLibraries();
	int			index;
	int			libOffset;
	int			totalLength;
	int			envCount = 0;
	void * 		curName;
	void * 		curValue;
	long			curNameLen;
	long			curValueLen;
	char *		text;
	AEKeyword	key;
	AESubDesc	strings;
	AESubDesc	cur;	
	
	HLock(envText);
	libOffset =		strlen(*envText)+1;
	libOffset +=	strlen(*envText+libOffset)+1;
	libOffset +=	strlen(*envText+libOffset)+1;
	totalLength = GetHandleSize(envText);
	text = *envText;
	while (totalLength - (text - *envText) > 1) {
		text += strlen(text)+1;
		++envCount;
	}
	envCount >>= 1;
	HUnlock(envText);
	
	if (desc) {
		HLock(desc->dataHandle);
		AEDescToSubDesc(desc, &strings); 
		
		for (index = 0; !AEGetNthSubDesc(&strings, ++index, &key, &cur); ) {
			curName = AEGetSubDescData(&cur, &curNameLen);
			
			if (AEGetNthSubDesc(&strings, ++index, &key, &cur))
				curValue = nil;
			else
				curValue = AEGetSubDescData(&cur, &curValueLen);
			
			if (!memcmp(curName, "PERL5LIB", 9)) {
				if (curValue) {
					Munger(envText, libOffset, nil, 0, curValue, curValueLen+1);
					(*envText)[libOffset+curValueLen] = ',';
				}
			} else {
				++envCount;
				
				totalLength = GetHandleSize(envText);
				
				PtrAndHand(curName, envText, curNameLen+1);
				
				(*envText)[totalLength+curNameLen] = 0;
				
				if (curValue) {
					PtrAndHand(curValue, envText, curValueLen+1);
				
					(*envText)[totalLength+curNameLen+curValueLen+1] = 0;
				} else {
					PtrAndHand(curName, envText, 1);
				
					(*envText)[totalLength+curNameLen+1] = 0;
				}
			}
		}
	}
	if (PerlEnvText) {
		DisposePtr((Ptr) PerlEnviron);
		DisposeHandle(PerlEnvText);
	}

	MoveHHi(PerlEnvText = envText);
	HLock(envText);
		
	PerlEnviron 				= (char **) NewPtr((envCount+1) * sizeof(char *));
	PerlEnviron[envCount] 	= nil;
	text							= *envText;
	
	while (envCount--) {
		PerlEnviron[envCount]	= text;
		text 						  += strlen(text) + 1;
		text 						  += strlen(text) + 1;
	}
}

extern Sfio_t * gSfioStringTempFile;

extern void	GUSIStdioFlush();
extern void	GUSIStdioClose();	

void CleanupPerl()
{
	int i;
	extern FILE * _lastbuf;

	UseResFile(gAppFile);

	GUSIStdioFlush();
	GUSIStdioClose();	
	
	/* Fear and loathing in stdio: Unused streams don't 
	// get closed by the above
	*/
	fclose(stdin);
	fclose(stdout);
	fclose(stderr);
	gSfioStringTempFile = nil;

	/* Close all files */

	for (i = 0; i<FD_SETSIZE; ++i)
		close(i);

	while (PerlExitCnt)
		PerlExitFn[--PerlExitCnt]();

	UseResFile(gAppFile);

	/* free_pool_memory('PERL'); */

	freopen("Dev:Console", "r", stdin);
	freopen("Dev:Console", "w", stdout);
	freopen("Dev:Console", "w", stderr); 
	
	gExplicitWNE = false;
}

enum {
	extractDone			= -7,
	extractSyntax		= -6,
	extractTaint		= -5,
	extractWarn			= -4,
	extractDir			= -3,
	extractCpp			= -2,
	extractDebug 		= -1
};

typedef char * (*ArgExtractor)(void * data, int index);

pascal Boolean RunScript(ArgExtractor extractor, void * data)
{
	int		ArgC;
	char	*	res;
	int		i;
	int 		DynamicArgs;
	int		returnCode;
	Boolean	wasRuntime;
	
	wasRuntime	= gRuntimeScript != 0;
	ArgC			= 1;
	PerlArgMax	= 20;
	PerlArgs 	= malloc(PerlArgMax * sizeof(char *));
	PerlArgs[0]	= "MacPerl";
	
	{
		char		path[256];
	
		strcpy(path, extractor(data, extractDir));
		chdir(path);
	}
	
	if ((res = extractor(data, extractSyntax)) && *res == 'y')
		PerlArgs[ArgC++] = "-c";

	if (((res = extractor(data, extractWarn)) && *res == 'y') || gWarnings)
		PerlArgs[ArgC++] = "-w";

	if (((res = extractor(data, extractDebug)) && *res == 'y') || gDebug)
		PerlArgs[ArgC++] = "-d";

	if (((res = extractor(data, extractTaint)) && *res == 'y') || gTaint)
		PerlArgs[ArgC++] = "-T";

	if ((res = extractor(data, extractCpp)) && *res == 'y')
		PerlArgs[ArgC++] = "-P";

	DynamicArgs = ArgC;
	
	if (res = extractor(data, 1)) {
		if (gPerlPrefs.checkType && !gPseudoFile) 
			PerlArgs[ArgC++] = "-x";
		
		DynamicArgs 		= ArgC;
		
		PerlArgs[ArgC++] 	= res;
	
		for (i=2; PerlArgs[ArgC] = extractor(data, i); ++i)
			if (++ArgC == PerlArgMax) {
				PerlArgMax	+= 20;
				PerlArgs 	= realloc(PerlArgs, PerlArgMax * sizeof(char *));
			}
	}
	
	extractor(data, extractDone);
	
	UseResFile(gAppFile);
	
	PerlArgs[ArgC] =  nil;
	gRunningPerl 	=  true;
	gMacPerl_Quit	=	0;
	/* gFirstErrorLine= -1; */
	
	ShowWindowStatus();
	
	signal(SIGINT, exit);
	setvbuf(stdout, NULL, _IOLBF, BUFSIZ);
	setvbuf(stderr, NULL, _IOLBF, BUFSIZ);
	
	if (!(returnCode = setjmp(gExitPerl))) {
		returnCode = run_perl(ArgC, PerlArgs, PerlEnviron);
		if (!returnCode)	/* Emulate longjmp */
			returnCode = -1; 
	}	

	for (i=DynamicArgs; PerlArgs[i]; ++i)
		DisposePtr(PerlArgs[i]);

	free(PerlArgs);

	CleanupPerl();
	gRunningPerl = false;
	gAborting    = false;
	
	if (gScriptFile != gAppFile) {
		CloseResFile(gScriptFile);
		
		gScriptFile = gAppFile;
	}
	
	ShowWindowStatus();
	
	++gCompletedScripts;
	
	switch (gMacPerl_Quit) {
	case 1:
		/* 1: Quit if run in a standalone runtime */
		if (!wasRuntime)
			break;
	case 3:
		/* 3: Quit if this script was the cause of MacPerl being run */
		if (gCompletedScripts > 1)
			break;
	case 2:
		/* 2: Always quit */
		DoQuit(kAEAsk);
	case 0:
		/* 0: Never quit */
		;
	}
	
	return returnCode == -1;
}

char * MakePath(char * path)
{
	char * retarg = NewPtr(strlen(path)+1);
	
	if (retarg)		
		strcpy(retarg, path);
			
	return retarg;
}

char * AEExtractor(void * data, int index)
{
	static Boolean			hasParams = false;
	static AEDesc			params;
	static AESubDesc		paramList;
	static int				scriptIndex;
	
	AppleEvent * 	event;
	AESubDesc		sd;
	AEKeyword		noKey;
	AEDesc			desc;
	FSSpec			script;
	FSSpec			arg;
	Size				size;
	char *			retarg;
	DescType			type;
	Boolean			flag;
	
	event = (AppleEvent *) data;
	
	if (!hasParams) {
		AEGetParamDesc(event, keyDirectObject, typeAEList, &params);
		AEDescToSubDesc(&params, &paramList);
		hasParams = true;
		scriptIndex = 0; 
		
		if (gRuntimeScript)
			gPseudoFile = gRuntimeScript;
		else
			while (!AEGetNthSubDesc(&paramList, ++scriptIndex, &noKey, &sd)) {
				if (!AESubDescToDesc(&sd, typeFSS, &desc)) {
					script = **(FSSpec **) desc.dataHandle;
					
					AEDisposeDesc(&desc);
					
					break;
				} 
				if (AESubDescToDesc(&sd, typeChar, &desc))
					continue;
				if ((*desc.dataHandle)[0] == '-') {
					AEDisposeDesc(&desc);
					
					continue;
				} else {
					if (!gMacPerl_PseudoFileName[0])
						strcpy(gMacPerl_PseudoFileName, "<AppleEvent>");
					gPseudoFile = desc.dataHandle;
					
					break;
				}
			}
	}
	
	switch (index) {
	case extractDone:
		gRuntimeScript = nil;

		if (hasParams)
			AEDisposeDesc(&params);
			
		hasParams		= false;

		return nil;
	case extractDir:
		if (gPseudoFile) {
			script.vRefNum	=	gAppVol;
			script.parID	=	gAppDir;
		} else {
			short	res	= CurResFile();
			
			gScriptFile = HOpenResFile(script.vRefNum, script.parID, script.name, fsRdPerm);
			
			if (gPseudoFile	= 	Get1NamedResource('TEXT', (StringPtr) "\p!")) {
				strcpy(gMacPerl_PseudoFileName, GUSIFSp2FullPath(&script));
				
				DetachResource(gPseudoFile);
			}

			UseResFile(res);
		} 
		if (!AEGetParamPtr(
			event, 'DIRE', typeFSS, &type, (Ptr) &arg, sizeof(FSSpec), &size)
		) 
			script = arg;
		else
			GUSIFSpUp(&script);
		
		return GUSIFSp2FullPath(&script);
	case extractDebug:
		if (AEGetParamPtr(event, 'DEBG', typeBoolean, &type, (Ptr) &flag, 1, &size))
			return nil;
		else
			return flag ? "y" : "n";
	case extractTaint:
		if (AEGetParamPtr(event, 'TAIN', typeBoolean, &type, (Ptr) &flag, 1, &size))
			return nil;
		else
			return flag ? "y" : "n";
	case extractCpp:
		if (AEGetParamPtr(event, 'PREP', typeBoolean, &type, (Ptr) &flag, 1, &size))
			return nil;
		else
			return flag ? "y" : "n";
	case extractSyntax:
		if (AEGetParamPtr(event, 'CHCK', typeBoolean, &type, (Ptr) &flag, 1, &size))
			return nil;
		else
			return flag ? "y" : "n";
	case extractWarn:
		if (AEGetParamPtr(event, 'WARN', typeBoolean, &type, (Ptr) &flag, 1, &size))
			return nil;
		else
			return flag ? "y" : "n";
	default:
		/* A runtime script inserts itself at the beginning */
		if (gRuntimeScript)
			--index;
		
		if (index == scriptIndex && gPseudoFile)
			return MakePath("Dev:Pseudo");
		
		/* End of list ? */
		if (AEGetNthSubDesc(&paramList, index, &noKey, &sd))
			return nil;
	
		switch (AEGetSubDescType(&sd)) {
		case typeFSS:
		case typeAlias:
			if (!AESubDescToDesc(&sd, typeFSS, &desc)) {
				arg = **(FSSpec **) desc.dataHandle;
			
				AEDisposeDesc(&desc);
			
				/* A file, convert to a path name */
				retarg = GUSIFSp2FullPath(&arg);
			
				return MakePath(retarg);
			} 
			/* Fall through */
		default:
			if (!AESubDescToDesc(&sd, typeChar, &desc)) {
				size 	= GetHandleSize(desc.dataHandle);
				retarg 	= NewPtr(size+1);
				
				if (retarg) {
					retarg[size] = 0;
				
					memcpy(retarg, *desc.dataHandle, size);
				}
						
				AEDisposeDesc(&desc);
				
				return retarg;
			}
			break;
		}
		
		return nil;
	}			
}

char * StupidExtractor(void * data, int index)
{
	FSSpec	*		spec;
	FSSpec			dir;
	char *			retarg;
	char *			path;
	
	spec = (FSSpec *) data;
	
	switch (index) {
	case extractDone:
	case extractDebug:
	case extractCpp:
		return nil;
	case extractDir:
		dir = *spec;
		
		{
			short	res	= CurResFile();
			
			gScriptFile = HOpenResFile(dir.vRefNum, dir.parID, dir.name, fsRdPerm);
			
			if (gPseudoFile	= 	Get1NamedResource('TEXT', (StringPtr) "\p!")) {
				strcpy(gMacPerl_PseudoFileName, GUSIFSp2FullPath(spec));
				
				DetachResource(gPseudoFile);
			}
			
			UseResFile(res);
		} 
		
		GUSIFSpUp(&dir);
		
		return GUSIFSp2FullPath(&dir);
	default:
		if (index > 1)
			return nil;

		if (gPseudoFile)
			return "Dev:Pseudo";
			
		path = GUSIFSp2FullPath(spec);
		retarg = NewPtr(strlen(path)+1);
			
		strcpy(retarg, path);
			
		return retarg;
	}			
}

void AddErrorDescription(AppleEvent * reply)
{
#if 0
	OSErr			err;
	AliasHandle	file;
	AEStream		aes;
	AEDesc      newDesc;
	short			line;

	if (gFirstErrorLine == -1 || reply->descriptorType == typeNull) 
		return;
	
	line = (short) gFirstErrorLine;
	
	if (NewAlias(nil, &gFirstErrorFile, &file)) 
		return;
		
	HLock((Handle) file);
	err = AEPutParamPtr(
				reply, kOSAErrorOffendingObject, 
				typeAlias, (Ptr) *file, GetHandleSize((Handle) file));
	DisposeHandle((Handle) file);
		
	if (err)
		return;
		
	if (AEStream_Open(&aes))
		return;
		
	if (AEStream_OpenRecord(&aes, typeAERecord)
	||	 AEStream_WriteKeyDesc(&aes, keyOSASourceStart, typeShortInteger, (Ptr) &line, 2)
	||	 AEStream_WriteKeyDesc(&aes, keyOSASourceEnd, typeShortInteger, (Ptr) &line, 2)
	||	 AEStream_CloseRecord(&aes)
	||	 AEStream_Close(&aes, &newDesc)
	) {
		AEStream_Close(&aes, nil);
	} else {
		AEPutParamDesc(reply, kOSAErrorRange, &newDesc)	;
		AEDisposeDesc(&newDesc);
	}
#endif
}

pascal OSErr DoScript(const AppleEvent *event, AppleEvent *reply, long refCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (refCon)
#endif
	Boolean	ranOK;
	OSType	mode;
	DescType	typeCode;
	Size		size;
	AEDesc	env;
	
	if (gRunningPerl) {
		AppleEvent e[2];
		
		e[0] = *event;
		e[1] = *reply;
		
		PtrAndHand((Ptr) e, (Handle) gWaitingScripts, 16);
		
		return AESuspendTheCurrentEvent(event);
	}

	if (AEGetParamPtr(event, 'MODE', typeEnumerated, &typeCode, &mode, 4, &size))
		mode = 'LOCL';
	
	switch (mode) {
	case 'DPLX':
	case 'RCTL':				
		if (reply) {	/* Return immediately from initial request */
			AEDuplicateDesc(event, &gDelayedScript);
			
			return 0;
		}

		/* Fall through on delayed request */ 
	case 'BATC':
		freopen("Dev:AEVT", "r", stdin);
		freopen("Dev:AEVT", "w", stdout);
		freopen("Dev:AEVT:diag", "w", stderr); 
		
		Relay(event, nil, mode);
	}
	
	if (AEGetParamDesc(event, 'ENVT', typeAEList, &env))
		MakePerlEnviron(nil);
	else {
		MakePerlEnviron(&env);
		AEDisposeDesc(&env);
	}
		
	ranOK = RunScript(AEExtractor, (void *) event);
	
	switch (mode) {
	case 'DPLX':
	case 'RCTL':
		/* Provoke controller to send last data event */
		if (!gQuitting)
			FlushAEVTs(nil);
		break;
	case 'BATC':
	case 'LOCL':	
		/* Get output data into reply event */
		FlushAEVTs(reply);
		
		if (gMacPerl_Reply) {
			HLock(gMacPerl_Reply);
			AEPutParamPtr(
						reply, keyDirectObject,
						typeChar, *gMacPerl_Reply, GetHandleSize(gMacPerl_Reply));
			DisposeHandle(gMacPerl_Reply);
			gMacPerl_Reply = nil;
		}
		
		AddErrorDescription(reply);
	}
	
	return ranOK ? 0 : (gMacPerl_SyntaxError ? 1 : 2);
}

pascal Boolean DoRuntime()
{
#if 0
	FSSpec	spec;
	
	if (gRuntimeScript = Get1NamedResource('TEXT', (StringPtr) "\p!")) {
		spec.vRefNum 	= 	gAppVol;
		spec.parID		=	gAppDir;
		PLstrcpy(spec.name, LMGetCurApName());
		strcpy(gMacPerl_PseudoFileName, GUSIFSp2FullPath(&spec));
		
		DetachResource(gRuntimeScript);
	}
#endif

	return false;
}

pascal void AddStandardScripts()
{
	short			runs;
	short 		index;
	FSSpec		spec;

	if (sStandardScripts) {
		runs = GetHandleSize((Handle) sStandardScripts) / sizeof(FSSpec)+1;
		for (index = 0; index++ < runs; )
			DeleteMenuItem(myMenus[perlM], pmStandard-1);
	}
	
	spec.vRefNum	=	gAppVol;
	spec.parID		=	gAppDir;
	
	GUSIFSpUp(&spec);
	
	for (runs = 0; runs++ < 2; GUSISpecial2FSp(kExtensionFolderType, 0, &spec)) {
		if (GUSIFSpDown(&spec, (StringPtr) "\pMacPerl Scripts"))
			continue;
		if (GUSIFSpDown(&spec, (StringPtr) "\p"))
			continue;
		for (index = 1; !GUSIFSpIndex(&spec, index++); )
			switch (GetDocType(&spec)) {
			case kPreferenceDoc:
				/* We don't want preference files here. */
			case kUnknownDoc:
				continue;
			default:
				if (!sStandardScripts) {
					AppendMenu(myMenus[perlM], (StringPtr) "\p-(");
					PtrToHand((Ptr)&spec, (Handle *)&sStandardScripts, sizeof(FSSpec));
				} else
					PtrAndHand((Ptr)&spec, (Handle)sStandardScripts, sizeof(FSSpec));
				AppendMenu(myMenus[perlM], spec.name);
			}
	}
}
