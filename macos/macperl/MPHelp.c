/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPHelp.c			-	Various helpful functions
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPHelp.c,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.4  1998/04/07 01:46:39  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:53  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:01  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:49  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:01:10  neeri
Initial revision

Revision 0.2  1993/09/08  00:00:00  neeri
Corrected some misunderstandings of dbm

Revision 0.1  1993/08/17  00:00:00  neeri
Use Application directory

*********************************************************************/

#include "MPHelp.h"
#include "MPConsole.h"
#include "MPUtils.h"
#include "MPEditor.h"

#include <Menus.h>
#include <Balloons.h>
#include <ToolUtils.h>
#include <GUSIFileSpec.h>
#include <ndbm.h>
#include <ctype.h>
#include <PLStringFuncs.h>
#include <Folders.h>
#include <fcntl.h>
#include <ioctl.h>
#include <stdio.h>
#include <string.h>

static void MetaHelp(StringPtr msg, StringPtr m1, StringPtr m2, StringPtr m3) 
{
	SetCursor(&qd.arrow);
	ParamText(msg, m1, m2, m3);
 	AppAlert(ErrorAlert);
}

static MenuHandle	gHelpMenus[20];
static Handle		gHelpURLs[20];
static DBM * 		gHelpIndex = nil;
static Boolean		gHasHelp	=	true;

void InitHelpIndex()
{
	int			depth   	= 	0;
	int			curIndex	=	0;
	int			nextIndex= 	0;
	MenuHandle	curMenu;
	char *		menu;
	char *		scan;
	char * 		next;
	datum 		key;
	datum 		data;
	Str255		contrib;
	int			menuStack[10];

	AppendMenu(myMenus[helpM], "\p-(");

	if (!gHelpIndex)
		goto whyNoHelp;
		
	key.dptr 	= " MENU";
	key.dsize	= 5;
	data 			= dbm_fetch(gHelpIndex, key);
	
	if (!data.dptr)
		goto whyNoHelp;
	
	curMenu 				=	gHelpMenus[curIndex = nextIndex++] = myMenus[helpM];
	menuStack[depth] 	= 	curIndex;
	PtrToHand("\n\n\n\n\n\n\n\n\n\n", &gHelpURLs[curIndex], CountMItems(curMenu));
	for (menu = data.dptr; depth>=0; menu = next+1) {
		next = strchr(menu, '\n');
		if (menu == next) 
			if (!depth--)
				break;
			else	{
				curIndex = 	menuStack[depth];
				curMenu	=	gHelpMenus[curIndex];
				continue;
			}
		scan 			= 	strchr(menu, '\t');
		contrib[0]	=	scan - menu;
		memcpy(contrib+1, menu, contrib[0]);
		AppendMenu(curMenu, "\pxxx");
		SetMenuItemText(curMenu, CountMItems(curMenu), contrib);
		PtrAndHand(scan+1, gHelpURLs[curIndex], next - scan);
		if (*++scan == '!') {
			curIndex =  nextIndex++;
			gHelpMenus[curIndex] = NewMenu(kHierHelpMenu+curIndex, "\p");
			SetItemCmd(curMenu, CountMItems(curMenu), 0x1B);
			SetItemMark(curMenu, CountMItems(curMenu), kHierHelpMenu+curIndex);
			curMenu = gHelpMenus[curIndex];
			InsertMenu(curMenu, -1);
			gHelpURLs[curIndex]	=	NewHandle(0);
			menuStack[++depth] 	= 	curIndex;
		}
	}
	return;
whyNoHelp:
	gHasHelp = false;
	AppendMenu(myMenus[helpM], "\pEnabling online Help...");	
}

void InitHelp()
{
	CInfoPBRec	info;
	FSSpec BalloonPath;
	
	if (gHelpIndex || !gHasHelp)
		return;
		
	BalloonPath.vRefNum 	= gAppVol;
	BalloonPath.parID		= gAppDir;
	PLstrcpy(BalloonPath.name, (StringPtr) "\pMacPerl Help");

	if (!GUSIFSpGetCatInfo(&BalloonPath, &info)) 
		if (gHelpIndex = dbm_open(GUSIFSp2FullPath(&BalloonPath), DBM_RDONLY, 0))
			return;
			
	if (!FindFolder(
			kOnSystemDisk, 
			kPreferencesFolderType, 
			false, 
			&BalloonPath.vRefNum,
			&BalloonPath.parID)
		&& !GUSIFSpGetCatInfo(&BalloonPath, &info) 
	) 	
		gHelpIndex = dbm_open(GUSIFSp2FullPath(&BalloonPath), DBM_RDONLY, 0);
}

void EndHelp()
{
	if (gHelpIndex) {
		dbm_close(gHelpIndex);
		
		gHelpIndex = nil;
	}
}

#define isperlident(x) (isalnum(x) || (x) == '_' || (x) == ':')

void Explain(DPtr doc)
{
	TEHandle		te;
	datum 		key;
	datum 		data;
	char *		text;
	short			pos;
	short			start;
	short			restore = -1;
	
	InitHelp();
	
	if (!gHelpIndex) {
		MetaHelp(
			"\pTo enable online help, put the file \"MacPerl Help\" "
			"in the same folder as the MacPerl application and "
			"restart MacPerl.", (StringPtr) "\p", (StringPtr) "\p", (StringPtr) "\p");
		return;
	}

	if (doc) {
		te = doc->theText;
			
		pos = (*te)->selEnd - (*te)->selStart;
		HLock((*te)->hText);
		text = *(*te)->hText;
		start= (*te)->selStart;
		if (pos) {
			/* Trim spaces */
			while (pos && isspace(text[start]))
				++start, --pos;
			while (pos && isspace(text[start+pos-1]))
				--pos;
			if (text[start] == '$') 
				switch (text[start+pos]) {
				case '[':
					text[restore=start] = '@';
					break;
				case '{':
					text[restore=start] = '%';
					break;
				}
		} else {
			/* Intuit topic */
			if (start && !isspace(text[start-1]) && !strchr("()[]{}", text[start-1]))
				--start;
			pos = start;
			if (isperlident(text[start])) {
				/* Identifier, scan to start && end */
				do {
					--start;
				} while (start && isperlident(text[start]));
				do {
					++pos;
				} while (pos<te[0]->teLength && isperlident(text[pos]));
				switch (text[start]) {
				case '$':
					if (pos < te[0]->teLength)
						switch (text[pos]) {
						case '[':
							text[restore=start] = '@';
							break;
						case '{':
							text[restore=start] = '%';
							break;
						}
					/* Fall through */
				case '%':
				case '@':
					/* variable */
					break;
				case '^':
					if (start && text[start-1] == '$') {
						--start;
						break;
					}
					/* Fall through */
				default:
					/* procedure */
					if (!isperlident(text[start]))
						++start;
				}
			} else {
				if (start)
					switch (text[start-1]) {
					case '$':
					case '@':
					case '%':
						--start;
						goto symbolic_variable;
					}
				switch (text[start]) {
				case '%':
					if (!isalnum(text[start+1]))
						break; /* Operator, not variable reference */
					/* Fall through */
				case '$':
				case '@':
symbolic_variable:
					if (text[start+1] == '^')
						pos = start+3;
					else
						pos = start+2;
					break;
				default:
					pos = start+1;
					while (start) {
						switch (text[start-1]) {
						case '+':
						case '-':
						case '>':
						case '<':
						case '&':
						case '|':
						case '=':
						case '*':
						case '^':
							--start;
							continue;
						}
						break;
					}
					while (pos < te[0]->teLength) {
						switch (text[pos]) {
						case '+':
						case '-':
						case '>':
						case '<':
						case '&':
						case '|':
						case '=':
						case '*':
						case '^':
							++pos;
							continue;
						}
						break;
					}
				}
			}
			pos -= start;
		}
		if (!pos)
			HUnlock((*te)->hText);
	} else 
		pos = 0;
		
	if (!pos) {
		MetaHelp("\pYou didn't select any text to look up.",
					(StringPtr) "\p", (StringPtr) "\p", (StringPtr) "\p");

		EndHelp();
		
		return;
	}
	
	key.dptr = text+start;
	key.dsize = pos;
	data = dbm_fetch(gHelpIndex, key);
	if (restore > -1)
		text[restore] = '$';
	HUnlock((*te)->hText);
	EndHelp();
	
	if (!data.dptr) {
		Str255	keyStr;
		
		keyStr[0] = key.dsize;
		memcpy(keyStr+1, key.dptr, key.dsize);
		
		MetaHelp("\pUnfortunately, I can't give you any help for \"",
					keyStr, (StringPtr) "\p\"", (StringPtr) "\p");
	} else {
		TESetSelect(start, start+pos, te);
		LaunchHelpURL(data.dptr, data.dsize);
	}
}	

void LaunchHelpURL(char * urlPtr, int urlLen)
{
	int		len;
	char		urlBuf[300];
	char *	url = urlBuf+8;
	char *	end;

	strcpy(urlBuf+1, "Helper•");
	if (*urlPtr == '!')
		return; 	/* False positive */
	if ((!strncmp(urlPtr, "file:", 5) && urlPtr[5] != '/')
	 || (!strncmp(urlPtr, "pod:", 4) && urlPtr[4] != '/')	
	) {
		char * 	path;
		char *	urlPath;
		FSSpec 	here;
		
		here.vRefNum 	= gAppVol;
		here.parID		= gAppDir;
		
		GUSIFSpUp(&here);
		*strchr(urlPtr, ':') = 0;
		strcpy(url, urlPtr);
		strcat(url, ":///");
		urlLen -= strlen(urlPtr)+1;
		urlPtr += strlen(urlPtr)+1;
		urlPtr[-1] = ':';
		urlPath	= url+strlen(url);
		for (path = GUSIFSp2FullPath(&here); *path; path++)
			switch (*path) {
			case ':':	/* Translate directory separators */
				*urlPath++ = '/';
				break;
			case '<':	/* Encode dangerous characters */
			case '>':	
			case '+':
			case '\"':
			case '*':
			case '%':
			case '&':
			case '/':
			case '(':
			case ')':
			case '=':
			case '?':
			case '\'':
			case '`':
			case '^':
			case '$':
			case '#':
			case ' ':
				sprintf(urlPath, "%%%02X", *path);
				urlPath += 3;
				break;
			default:
				*urlPath++ = *path;
				break;
			}
		if (urlPath[-1] != '/')
			*urlPath++ = '/';
		memcpy(urlPath, urlPtr, urlLen);
		len = urlPath - url + urlLen;
	} else {
		memcpy(url, urlPtr, urlLen);
		len = urlLen;
	}
	
	if (end = (char *) memchr(url, ':', len)) {
		urlBuf[0] = end-urlBuf-1;
		FindHelper((StringPtr) urlBuf, nil, true);
	}
		
	if (gICInstance) {
		long 		selStart 	= 0;
		long 		selEnd 	= len;
		
		if (!ICLaunchURL(gICInstance, "\p", url, len, &selStart, &selEnd)) 
			return;
		else {
			ICAttr	attr;
			long		size			=	0;

			if (end) {
			
				if(ICGetPref(gICInstance, (StringPtr) urlBuf, &attr, nil, &size) == icPrefNotFoundErr) {
					SetCursor(&qd.arrow);
					url[-1] = urlBuf[0]-7;
					ParamText((StringPtr)(url-1), (StringPtr)"\p", (StringPtr)"\p", (StringPtr)"\p");
 					if (AppAlert(HelperAlert) == 1) {
						url[-1] = '•';
						ICEditPreferences(gICInstance, (StringPtr) urlBuf);
					}
					return;
				}
			}
		}
	}
	MetaHelp("\pFailed to launch help viewer. "
				"Please make sure that you have Internet Config 1.3 or later "
				"installed, set a web browser as the helper for “http”, "
				"and set up “Shuck” as the helper for “pod”.",
				(StringPtr) "\p", (StringPtr) "\p", (StringPtr) "\p");
}

void DoHelp(short menu, short item) 
{
	if (gHasHelp) {
		Handle	urls = gHelpURLs[menu];
		char *	url;
		char *	urlEnd;
	
		if (!urls)		/* False alarm from MenuChoice */
			return;

		HLock(urls);
		for (url = *urls; --item && url; url = strchr(url, '\n')+1);
		if (url && (urlEnd = strchr(url, '\n')))
			LaunchHelpURL(url, urlEnd - url);
		HUnlock(urls);
	} else
		MetaHelp(
			"\pTo enable online help, put the file \"MacPerl Help\" "
			"in the same folder as the MacPerl application and "
			"restart MacPerl.", (StringPtr) "\p", (StringPtr) "\p", (StringPtr) "\p");
}

