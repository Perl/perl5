/***********************************************************************************
**
**       Developer's Programming Interface for Mercutio Menu Definition Function
**               © 1992 Ramon M. Felciano, All Rights Reserved
**                       C port -- December 5, 1992
**
************************************************************************************/

#include "Menus.h"
#include "Memory.h"
#include "Events.h"

#define		customDefProcSig  'CUST'
#define		areYouCustomMsg  128
#define		getVersionMsg  131
#define		getCopyrightMsg  132
#define		mMenuKeyMsg  262
#define 	_Point2Long(pt)	(* (long *) &pt)			// these would have pbs with register vars
#define 	_Long2Point(long)	(* (Point *) &long)

void InitMercutio(void);
long PowerMenuKey (long theMessage, short theModifiers, MenuHandle hMenu);
Boolean IsCustomMenu (MenuHandle menu);
long	GetMDEFVersion (MenuHandle menu);
StringHandle	GetMDEFCopyright (MenuHandle menu);

typedef pascal void (*MDEFProc)(short msg, MenuHandle theMenu, Rect* menuRect,
				Point hitPt, short *itemID);


/***********************************************************************************
**
**   GetMDEFVersion returns the MDEF version in long form. This can be typecast
**	 to a normal version record if needed.
**
************************************************************************************/
long	GetMDEFVersion (MenuHandle menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	
	proc = (*menu)->menuProc;	/* same as **menu.menuProc */
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);
	CallMenuDefProc((MenuDefProcPtr) *proc, getVersionMsg, menu, &dummyRect, pt, &dummyInt);
	HSetState(proc, state);
	
	/* the result, a long, is returned in dummyRect.topLeft */
	return _Point2Long(dummyRect);
}

/***********************************************************************************
**
**   GetMDEFCopyright returns a stringHandle to the copyright message for the MDEF.
**
**   IMPORTANT: THE CALLER IS RESPONSIBLE FOR DISPOSING OF THIS HANDLE WHEN DONE
**              WITH IT.
**
************************************************************************************/
StringHandle	GetMDEFCopyright (MenuHandle menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	
	proc = (*menu)->menuProc;	/* same as **menu.menuProc */
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);
	CallMenuDefProc((MenuDefProcPtr) *proc, getCopyrightMsg, menu, &dummyRect, pt, &dummyInt);
	HSetState(proc, state);
	
	/* the result, a stringHandle, is returned in dummyRect.topLeft */
	return *(StringHandle*)(&dummyRect);
}

/***********************************************************************************
**
**   IsCustomMenu returns true if hMenu is controlled by a custom MDEF. This relies on my}
**   convention of returning the customDefProcSig constant in the rect parameter: this obtuse}
**   convention should be unique enough that only my custom MDEFs behave this way.}
**
************************************************************************************/
Boolean IsCustomMenu (MenuHandle menu)
{
	SignedByte state;
	Handle	proc;
	Rect	dummyRect;
	short	dummyInt;
	Point 	pt;
	
	proc = (*menu)->menuProc;	/* same as **menu.menuProc */
	state = HGetState(proc);
	HLock(proc);
	dummyRect.top = dummyRect.left = dummyRect.bottom = dummyRect.right = 0;

	SetPt(&pt,0,0);
	CallMenuDefProc((MenuDefProcPtr) *proc, areYouCustomMsg, menu, &dummyRect, pt, &dummyInt);
	HSetState(proc, state);
	
	/* the result, a long, is returned in dummyRect.topLeft */
	return (_Point2Long(dummyRect) == (long) (customDefProcSig));
}


/***********************************************************************************
**
**   PowerMenuKey is a replacement for the standard toolbox call MenuKey for use with the}
**   Mercutio. Given the keypress message and modifiers parameters from a standard event, it }
**   checks to see if the keypress is a key-equivalent for a particular menuitem. If you are currently}
**   using custom menus (i.e. menus using Mercutio), pass the handle to one of these menus in}
**   hMenu. If you are not using custom menus, pass in NIL or another menu, and PowerMenuKey will use the}
**   standard MenuKey function to interpret the keypress.}
**
**   As with MenuKey, PowerMenuKey returns the menu ID in high word of the result, and the menu}
**   item in the low word.}
**
************************************************************************************/

long PowerMenuKey (long theMessage, short theModifiers, MenuHandle hMenu)
{
	if ((hMenu == NULL) || (!IsCustomMenu(hMenu)))
	{
		return(MenuKey((char)(theMessage & charCodeMask)));
	}
	else
	{
		Handle proc = (*hMenu)->menuProc;
		char state = HGetState(proc);
		Rect dummyRect;
		Point pt = _Long2Point(theMessage);
		
		HLock(proc);
		dummyRect.top = dummyRect.left = 0;
		CallMenuDefProc((MenuDefProcPtr) *proc, mMenuKeyMsg, hMenu, &dummyRect, pt, &theModifiers);
		HSetState(proc, state);
		return( _Point2Long(dummyRect));
	}
}


