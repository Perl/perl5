/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Menus/Menus.xs,v 1.3 2001/04/16 04:45:15 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Menus.xs,v $
 * Revision 1.3  2001/04/16 04:45:15  neeri
 * Switch from atexit() to Perl_call_atexit (MacPerl bug #232158)
 *
 * Revision 1.2  2000/09/09 22:18:27  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:31  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:52:37  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:59  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Menus.h>


static void WipeFilter(pTHX_ void * p)
{
	gMacPerl_FilterMenu	= nil;
}

static Boolean PrepareMenus()
{
	dSP ;
	
	PUSHMARK(sp) ;
	
	perl_call_pv("Mac::Menus::_PrepareMenus", G_DISCARD|G_NOARGS);

	return true;
}

static Boolean FilterMenu(long menuSelection)
{
	HV *  	menus;
	SV ** 	handler;
	char 	code[10];
	
	if (menuSelection == -1)
		return PrepareMenus();
		
	PerlIO_sprintf(code, 10, "%08X", menuSelection);
	menus 	= perl_get_hv("Mac::Menus::Menu", 2);
	(handler = hv_fetch(menus, code, 4, 0))
		|| (handler	= hv_fetch(menus, code, 8, 0));
		
	if (handler) {
        int res ;
		SV * result;
      	dSP ;

        ENTER ;
        SAVETMPS;

        PUSHMARK(sp) ;
        XPUSHs(sv_2mortal(newSViv((menuSelection >> 16) & 0x0FFFF)));
        XPUSHs(sv_2mortal(newSViv(menuSelection 		& 0x0FFFF)));
        PUTBACK ;

        res = perl_call_pv("Mac::Menus::_HandleMenu", G_SCALAR);

        SPAGAIN ;

		result	= POPs;
        res		= SvTRUE(result);

        PUTBACK ;
        FREETMPS ;
        LEAVE ;
		
		return res != 0;
	}
	return false;
}

static pascal void CallMDEF(
	short message, MenuHandle menu, Rect * menuRect, Point hitPt, short * item)
{
	dXSARGS ;

	ENTER ;
	SAVETMPS;

	PUSHMARK(sp) ;
	XS_XPUSH(short, message);
	XS_XPUSH(MenuHandle, menu);
	switch (message) {
	case mDrawMsg:
		XS_XPUSH(Rect, *menuRect);
		break;
	case mChooseMsg:
		XS_XPUSH(Rect, *menuRect);
		XS_XPUSH(Point, hitPt);
		XS_XPUSH(short, *item);
		break;
	case mSizeMsg:
		break;
	case mPopUpMsg:
		XS_XPUSH(Point, hitPt);
		break;		
	}
	PUTBACK ;

	perl_call_pv("Mac::Menus::_MenuDefProc", G_SCALAR);

	SPAGAIN ;

	switch (message) {
	case mDrawMsg:
	case mSizeMsg:
		break;
	case mChooseMsg:
		XS_POP(short, *item);
		break;
	case mPopUpMsg:
		XS_POP(Rect, *menuRect);
		break;		
	}

	PUTBACK ;
	FREETMPS ;
	LEAVE ;
}

#if GENERATINGCFM
RoutineDescriptor sCallMDEF = 
	BUILD_ROUTINE_DESCRIPTOR(uppMenuDefProcInfo, CallMDEF);
#else
struct {
	short	jmp;
	void *	addr;
} sCallMDEF = {0x4EF9, CallMDEF};
#endif
static Handle	sMDEF;
static int		sMDEFRefCount;

MODULE = Mac::Menus	PACKAGE = Mac::Menus

BOOT:
gMacPerl_FilterMenu	= FilterMenu;
Perl_call_atexit(aTHX_ WipeFilter, NULL);

STRUCT ** MenuHandle
	short		menuID;
	short		menuWidth;
	short		menuHeight;
	long		enableFlags;
	Str255		menuData;

=head2 Functions

=over 4

=item HEIGHT = GetMBarHeight()

=cut
short
GetMBarHeight()

=item MENU = NewMenu ID, TITLE

=cut
MenuHandle
NewMenu(menuID, menuTitle)
	short 	menuID
	Str255 	menuTitle

=item MENU = GetMenu ID

=cut
MenuHandle
GetMenu(resourceID)
	short 	resourceID

=item DisposeMenu MENU

=cut
void
_DisposeMenu(theMenu)
	MenuHandle 	theMenu
	CODE:
	if (sMDEFRefCount && theMenu[0]->menuProc == sMDEF)
		if (!--sMDEFRefCount)
			DisposeHandle(sMDEF);
	DisposeMenu(theMenu);

=item AppendMenu MENU, DATA

=cut
void
AppendMenu(menu, data)
	MenuHandle 	menu
	Str255	 	data

=item AppendResMenu MENU, TYPE

=cut
void
AppendResMenu(theMenu, theType)
	MenuHandle 	theMenu
	OSType 		theType

=item InsertResMenu MENU, TYPE, AFTERITEM

=cut
void
InsertResMenu(theMenu, theType, afterItem)
	MenuHandle 	theMenu
	OSType 	theType
	short 	afterItem

=item InsertMenu MENU [, BEFOREID]

=cut
void
InsertMenu(theMenu, beforeID=0)
	MenuHandle 	theMenu
	short 		beforeID

=item DrawMenuBar()

=cut
void
DrawMenuBar()

=item InvalMenuBar()

=cut
void
InvalMenuBar()

=item DeleteMenu ID

=cut
void
DeleteMenu(menuID)
	short 	menuID

=item ClearMenuBar()

=cut
void
ClearMenuBar()

=item MENUBAR = GetNewMBar ID

=cut
Handle
GetNewMBar(menuBarID)
	short 	menuBarID

=item MENUBAR = GetMenuBar()

=cut
Handle
GetMenuBar()

=item SetMenuBar MENUBAR

=cut
void
SetMenuBar(menuList)
	Handle 	menuList

=item InsertMenuItem MENU, ITEMS, AFTERITEM

=cut
void
InsertMenuItem(theMenu, itemString, afterItem)
	MenuHandle 	theMenu
	Str255 		itemString
	short 		afterItem

=item DeleteMenuItem MENU, ITEM

=cut
void
DeleteMenuItem(theMenu, item)
	MenuHandle 	theMenu
	short 		item

=item HiliteMenu ID

=cut
void
HiliteMenu(menuID)
	short 	menuID

=item SetMenuItemText MENU, ITEM, TEXT

=cut
void
SetMenuItemText(theMenu, item, itemString)
	MenuHandle 	theMenu
	short 		item
	Str255	 	itemString

=item TEXT = GetMenuItemText MENU, ITEM

=cut
Str255
GetMenuItemText(theMenu, item)
	MenuHandle 	theMenu
	short 		item
	CODE:
	GetMenuItemText(theMenu, item, RETVAL);
	OUTPUT:
	RETVAL

=item DisableItem MENU [, ITEM]

=cut
void
DisableItem(theMenu, item=0)
	MenuHandle 	theMenu
	short 		item

=item EnableItem MENU [, ITEM]

=cut
void
EnableItem(theMenu, item=0)
	MenuHandle 	theMenu
	short 		item

=item CheckItem MENU, ITEM, CHECKED

=cut
void
CheckItem(theMenu, item, checked)
	MenuHandle 	theMenu
	short 		item
	Boolean 	checked

=item SetItemMark MENU, ITEM, MARK

=cut
void
SetItemMark(theMenu, item, markChar)
	MenuHandle 	theMenu
	short 		item
	char	 	markChar

=item MARK = GetItemMark MENU, ITEM

=cut
char
GetItemMark(theMenu, item)
	MenuHandle 	theMenu
	short 		item
	CODE:
	{
		short markChar;
		GetItemMark(theMenu, item, &markChar);
		RETVAL = (char) markChar;
	}
	OUTPUT:
	RETVAL

=item SetItemIcon MENU, ITEM, ICON

=cut
void
SetItemIcon(theMenu, item, iconIndex)
	MenuHandle 	theMenu
	short 		item
	short 		iconIndex

=item ICON = GetItemIcon MENU, ITEM

=cut
short
GetItemIcon(theMenu, item)
	MenuHandle 	theMenu
	short 	item
	CODE:
	GetItemIcon(theMenu, item, &RETVAL);
	OUTPUT:
	RETVAL

=item SetItemStyle MENU, ITEM, STYLE

=cut
void
SetItemStyle(theMenu, item, chStyle)
	MenuHandle 	theMenu
	short 		item
	short 		chStyle

=item STYLE = GetItemStyle MENU, ITEM

=cut
short
GetItemStyle(theMenu, item)
	MenuHandle 	theMenu
	short 	item
	CODE:
	{
		Style	chStyle;
		GetItemStyle(theMenu, item, &chStyle);
		RETVAL = chStyle;
	}
	OUTPUT:
	RETVAL

=item CalcMenuSize MENU

=cut
void
CalcMenuSize(theMenu)
	MenuHandle 	theMenu

=item COUNT = CountMItems MENU

=cut
short
CountMItems(theMenu)
	MenuHandle 	theMenu

=item MENU = GetMenuHandle ID

=cut
MenuHandle
GetMenuHandle(menuID)
	short 	menuID

=item FlashMenuBar ID

=cut
void
FlashMenuBar(menuID)
	short 	menuID

=item SetMenuFlash COUNT

=cut
void
SetMenuFlash(count)
	short 	count

=item CMD = GetItemCmd MENU, ITEM

=cut
char
GetItemCmd(theMenu, item)
	MenuHandle 	theMenu
	short 		item
	CODE:
	{
		short	cmdChar;
		GetItemCmd(theMenu, item, &cmdChar);
		RETVAL = (char) cmdChar;
	}
	OUTPUT:
	RETVAL

=item SetItemCmd MENU, ITEM, COMMAND

=cut
void
SetItemCmd(theMenu, item, cmdChar)
	MenuHandle 	theMenu
	short 		item
	char 		cmdChar

void
_PopUpMenuSelect(menu, top, left, popUpItem)
	MenuHandle 	menu
	short 	top
	short 	left
	short 	popUpItem
	PPCODE:
	{
		long res = PopUpMenuSelect(menu, top, left, popUpItem);
		if (!res) {
			XSRETURN_EMPTY;
		} else {
			EXTEND(sp,2);
			PUSHs(sv_2mortal(newSViv((res >> 16) & 0x0FFFF)));
			PUSHs(sv_2mortal(newSViv(res & 0x0FFFF)));
		}
	}

void
_MenuChoice()
	PPCODE:
	{
		long res = MenuChoice();
		if (!res) {
			XSRETURN_EMPTY;
		} else {
			EXTEND(sp,2);
			PUSHs(sv_2mortal(newSViv((res >> 16) & 0x0FFFF)));
			PUSHs(sv_2mortal(newSViv(res & 0x0FFFF)));
		}
	}

=item InsertFontResMenu MENU, AFTERITEM, SCRIPTFILTER

=cut
void
InsertFontResMenu(theMenu, afterItem, scriptFilter)
	MenuHandle 	theMenu
	short 		afterItem
	short 		scriptFilter

=item InsertIntlResMenu MENU, TYPE, AFTERITEM, SCRIPTFILTER

=cut
void
InsertIntlResMenu(theMenu, theType, afterItem, scriptFilter)
	MenuHandle 	theMenu
	OSType 		theType
	short 		afterItem
	short 		scriptFilter

void
_SetMDEFProc(theMenu)
	MenuHandle	theMenu
	CODE:
	if (theMenu[0]->menuProc != sMDEF) {
		if (!sMDEFRefCount++) {
			PtrToHand((Ptr)&sCallMDEF, &sMDEF, sizeof(sCallMDEF));
#if !GENERATINGCFM
			FlushInstructionCache();
			FlushDataCache();
#endif
		}
		theMenu[0]->menuProc = sMDEF;
	}
