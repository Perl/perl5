/***********************************************************************************
**
**       Developer's Programming Interface for Mercutio Menu Definition Function
**               © 1992-1996 Ramon M. Felciano, All Rights Reserved
**                         Latest C port -- Monday, April 22, 1996 
**
************************************************************************************/

/*
**	09Aug94 : Tom Emerson
**	Modified by Tom Emerson (tree@bedford.symantec.com) to work correctly with
**	the universal headers, and hence when calling from PowerPC native code.
**	This has been conditionalized so that it will compile with and without the
**  universal interfaces.
**	
*/

/*
**  03Sep96 : Bryan Pietrzak (U S WEST Marketing Resources Group)
**  Support STRICT_MENUS:
**		Added PrivateMenuInfo because MenuInfo does not exist with STRICT_MENUS
**		Added GetMenuProc because can’t get at the menu proc by dereferencing with STRICT_MENUS
**		Changed MenuHandle to MenuRef
**
**  11Jul96 : Uwe Hees
**	Added Events.h to compile seperately.
**  Removed obsolete defintion of MDEFProc.
**  Changed interface to MDEF_SetCallbackProc for use with UPPs.
**
**  22Apr96 : RMF Updated to 1.3
**	19Dec94 : RMF
**	Updated to full Mercutio 1.2 spec by Ramon Felciano.
**	
**	27Dec94 : RMF
**	MDEF_CalcItemSize now correctly returns a result.
**	MDEF_StripCustomData declares Point at top of function (bug?).
*/

#include "MercutioAPI.h"
 
#ifndef __EVENTS__
#include <Events.h>
#endif

// 960903•ZAK in case Apple defines this in the future, define it conditionally
#ifndef GetMenuProc
#define GetMenuProc(menu)	(*((Handle *) ((*((Ptr *) (menu))) + 0x06)))
#endif

#define 	_Point2Long(pt)		(* (long *) &pt)		// these would have pbs with register vars
#define 	_Long2Point(long)	(* (Point *) &long)
#define		_TopLeft(aRect)		(* (Point *) &(aRect).top)

/***********************************************************************************
**
**   MDEF_GetVersion returns the MDEF version in long form. This can be typecast
**	 to a normal version record if needed.
**
************************************************************************************/
pascal	long	MDEF_GetVersion (MenuRef menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;
	
	proc = GetMenuProc(menu);  // 960903•ZAK
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, getVersionMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);
	
	HSetState(proc, state);
	
	/* the result, a long, is returned in dummyRect.topLeft */
	return _Point2Long(_TopLeft(dummyRect));
}

/***********************************************************************************
**
**   MDEF_GetCopyright returns a stringHandle to the copyright message for the MDEF.
**
**   IMPORTANT: THE CALLER IS RESPONSIBLE FOR DISPOSING OF THIS HANDLE WHEN DONE
**              WITH IT.
**
************************************************************************************/
pascal	StringHandle	MDEF_GetCopyright (MenuRef menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;
	Point	topleft;
	long	pointAsLong;
	
	proc = GetMenuProc(menu);  // 960903•ZAK
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, getCopyrightMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
	
	/* the result, a stringHandle, is returned in dummyRect.topLeft */
	topleft = _TopLeft(dummyRect);
	pointAsLong = _Point2Long(topleft);
	return (StringHandle)(pointAsLong);
}

/***********************************************************************************
**
**   IsCustomMenu returns true if hMenu is controlled by a custom MDEF. This relies on my}
**   convention of returning the customDefProcSig constant in the rect parameter: this obtuse}
**   convention should be unique enough that only my custom MDEFs behave this way.}
**
************************************************************************************/
pascal	Boolean MDEF_IsCustomMenu (MenuRef menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;
	
	proc = GetMenuProc(menu);  // 960903•ZAK
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, areYouCustomMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
	
	/* the result, a long, is returned in dummyRect.topLeft */
	return (_Point2Long(_TopLeft(dummyRect)) == (long) (customDefProcSig));
}


/***********************************************************************************
**
**   MDEF_MenuKey is a replacement for the standard toolbox call MenuKey for use with the}
**   Mercutio. Given the keypress message and modifiers parameters from a standard event, it }
**   checks to see if the keypress is a key-equivalent for a particular menuitem. If you are currently}
**   using custom menus (i.e. menus using Mercutio), pass the handle to one of these menus in}
**   hMenu. If you are not using custom menus, pass in NIL or another menu, and MDEF_MenuKey will use the}
**   standard MenuKey function to interpret the keypress.}
**
**   As with MenuKey, MDEF_MenuKey returns the menu ID in high word of the result, and the menu}
**   item in the low word.}
**
************************************************************************************/

pascal	long MDEF_MenuKey (long theMessage, short theModifiers, MenuRef menu)
{
	
	if ((menu == NULL) || (!MDEF_IsCustomMenu(menu))) {
		return(MenuKey((char)(theMessage & charCodeMask)));
	} else {
		Handle proc = GetMenuProc(menu);  // 960903•ZAK
		char state = HGetState(proc);
		Rect dummyRect;
		Point pt = _Long2Point(theMessage);
		MenuDefUPP	menuProcUPP;
		
		HLock(proc);
		dummyRect.top = dummyRect.left = 0;
		
		menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
		CallMenuDefProc(menuProcUPP, mMenuKeyMsg, menu, &dummyRect, pt, &theModifiers);	
		DisposeRoutineDescriptor(menuProcUPP);

		HSetState(proc, state);
		return( _Point2Long(_TopLeft(dummyRect)));
	}
}















pascal void	MDEF_SetCallbackProc(MenuRef hMenu, MercutioCallbackUPP mercutioCallback)
//pascal void MDEF_SetCallbackProc (MenuRef hMenu, ProcPtr mercutioCallback)
{
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(hMenu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);
	
	pt.h = (short) (0x0000FFFF & (long) mercutioCallback);
	pt.v = (short) ((long) mercutioCallback >> 16);
	
	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, setCallbackMsg, hMenu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}




pascal void MDEF_SetMenuPrefs (MenuRef menu, MenuPrefsRec *thePrefs)
{
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	pt.h = (short) (0x0000FFFF & (long) thePrefs);
	pt.v = (short) ((long) thePrefs >> 16);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, setPrefsMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
	CalcMenuSize(menu);
}



pascal void MDEF_SetKeyGraphicsPreference (MenuRef menu, Boolean preferGraphics)
{
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	pt.h = (short) preferGraphics;
	pt.v = 0;

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, setKeyGraphicsMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}

pascal void MDEF_SetSmallIconID (MenuRef menu, short iconsSmallAboveID)
{
	Rect	dummyRect;
	Point 	pt;
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	pt.h = 0;
	pt.v = 0;

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, setSmallIconIDMsg, menu, &dummyRect, pt, &iconsSmallAboveID);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}




pascal void MDEF_StripCustomData (MenuRef menu)
{
	Point 	pt = {0,0};
	Rect	dummyRect;
	short	dummyInt;
	MenuDefUPP	menuProcUPP;

	Handle proc;
	char state;
	
	proc = GetMenuProc(menu);  // 960903•ZAK
	state = HGetState(proc);
	HLock(proc);


	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, stripCustomDataMsg, menu, &dummyRect, pt, &dummyInt);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}




pascal void MDEF_DrawItem (MenuRef menu, short item, Rect destRect)
{
	Point 	pt = {0,0};
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, mDrawItemMsg, menu, &destRect, pt, &item);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}


pascal void MDEF_DrawItemState (MenuRef menu, short item, Rect destRect, Boolean isHilited, Boolean isEnabled)
{
	Point	pt;
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	pt.h = (short) isHilited;
	pt.v = (short) isEnabled;

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, mDrawItemStateMsg, menu, &destRect, pt, &item);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}


pascal void MDEF_CalcItemSize (MenuRef menu, short item, Rect *destRect)
{
	Point 	pt = {0,0};
	MenuDefUPP	menuProcUPP;

	Handle proc = GetMenuProc(menu);  // 960903•ZAK
	char state = HGetState(proc);
	HLock(proc);

	menuProcUPP = (MenuDefUPP)NewRoutineDescriptor((ProcPtr)*proc, uppMenuDefProcInfo, kM68kISA);
	CallMenuDefProc(menuProcUPP, mCalcItemMsg, menu, destRect, pt, &item);	
	DisposeRoutineDescriptor(menuProcUPP);

	HSetState(proc, state);
}


