/***********************************************************************************
**
**       Developer's Programming Interface for Mercutio Menu Definition Function
**               © 1992-1996 Ramon M. Felciano, All Rights Reserved
**                         C port -- January 17, 1994
**
************************************************************************************/

/*
**  03Sep96 : Bryan Pietrzak (U S WEST Marketing Resources Group)
**  Changed MenuHandle to MenuRef to support STRICT_MENUS
**
**  11Jul96 : Uwe Hees
**	Added Menus.h to compile seperately.
**  Added struct alignment support to force mac68k struct alignment.
**  Activated interface to MDEF_SetCallbackProc for use with UPPs.
*/

#ifndef __MercutioAPI__
#define __MercutioAPI__

#ifndef __MENUS__
#include <Menus.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if PRAGMA_ALIGN_SUPPORTED
#pragma options align=mac68k
#endif

#define		customDefProcSig	'CUST'
#define		areYouCustomMsg		(short) ('*' * 256 + '*')
#define		getVersionMsg		(short) ('*' * 256 + 'v')
#define		setCallbackMsg		(short) ('*' * 256 + 'c')
#define		stripCustomDataMsg	(short) ('*' * 256 + 'd')
#define		getCopyrightMsg		(short) ('C' * 256 + 'C')
#define		setPrefsMsg			(short) ('*' * 256 + 'p')
#define		setKeyGraphicsMsg	(short) ('*' * 256 + 'g')
#define		setSmallIconIDMsg	(short) ('*' * 256 + 'i')


#define		mMenuKeyMsg			(short) ('S' * 256 + 'K')
#define		mDrawItemStateMsg	(short) ('S' * 256 + 'D')
#define		mCountItemMsg		(short) ('S' * 256 + 'C')

#define		cbBasicDataOnlyMsg	1
#define		cbIconOnlyMsg		2
#define		cbGetLongestItemMsg 3

typedef struct {
		Style	s;
		SignedByte	filler;
	} FlexStyle;
	
typedef struct {
		FlexStyle	isDynamicFlag;
		FlexStyle	forceNewGroupFlag;
		FlexStyle	useCallbackFlag;
		FlexStyle	controlKeyFlag;
		FlexStyle	optionKeyFlag;
		FlexStyle	shiftKeyFlag;
		FlexStyle	cmdKeyFlag;
		FlexStyle	unusedFlag;
		short	requiredModifiers;
		UInt32	unused2;
		UInt32	unused3;
	} MenuPrefsRec, *MenuPrefsPtr;

typedef	struct	{	// PACKED RECORD
		char	iconID;
		char	keyEq;
		char	mark;
		Style	textStyle;
	} StdItemData, *StdItemDataPtr;



// ItemFlagsRec is a 2-byte sequence of 1-bit flags. It is defined
// as a short here; use these constants to set the flags.

// high byte
#define	kForceNewGroup	0x8000
#define	kIsDynamic		0x4000
#define	kUseCallback	0x2000
#define	kControlKey		0x1000
#define	kOptionKey		0x0800
#define	kLastItem		0x0400
#define kShiftKey		0x0200
#define	kCmdKey			0x0100
// low byte
#define	kIsHier			0x0080
#define	kChangedByCallback	0x0040
#define	kEnabled		0x0020
#define	kHilited		0x0010
#define	kIconIsSmall		0x0008
#define	kHasIcon		0x0004
#define	ksameAlternateAsLastTime		0x0002
#define	kdontDisposeIcon		0x0001

typedef	struct	{
		char	iconID;
		char	keyEq;
		char	mark;
		FlexStyle	textStyle;
		short	itemID;
		Rect	itemRect;
		short	flags;
		ResType	iconType;
		Handle	hIcon;
		StringPtr pString;
		Str255	itemStr;
		short	cbMsg;
	} RichItemData, *RichItemPtr;

	
// UPP Callback	
#if GENERATINGCFM
typedef UniversalProcPtr MercutioCallbackUPP;
#else
typedef ProcPtr MercutioCallbackUPP;
#endif

enum
{
	uppMercutioCallbackProcInfo = kPascalStackBased
		| STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(short)))
		| STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(short)))
		| STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(RichItemData*)))
};
// 3712 // $E80
#if GENERATINGCFM
#define NewMercutioCallback(userRoutine)	\
	(MercutioCallbackUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppMercutioCallbackProcInfo, GetCurrentArchitecture())
#define CallMercutioCallback(userRoutine, menuID, prevModifiers, richItemData)	\
	CallUniversalProc((UniversalProcPtr)(userRoutine), uppMercutioCallbackProcInfo, (menuID), (prevModifiers), (richItemData))
#else
#define NewMercutioCallback(userRoutine)	\
	((MercutioCallbackUPP)(userRoutine))
#define CallMercutioCallback(userRoutine, menuID, prevModifiers, richItemData)	\
	(*(userRoutine)) ((menuID), (prevModifiers), (richItemData))
#endif
// END UPP Callback

extern pascal long MDEF_GetVersion(MenuRef menu);
extern pascal StringHandle MDEF_GetCopyright(MenuRef menu);
extern pascal Boolean	MDEF_IsCustomMenu(MenuRef menu);

extern pascal long	MDEF_MenuKey(long theMessage, short theModifiers, MenuRef hMenu);
					
extern pascal void	MDEF_CalcItemSize(MenuRef hMenu, short item, Rect *destRect);
extern pascal void	MDEF_DrawItem(MenuRef hMenu, short item, Rect destRect);
extern pascal void	MDEF_DrawItemState(MenuRef hMenu, short item, Rect destRect, Boolean isHilited, Boolean isEnabled);

extern pascal void	MDEF_StripCustomData(MenuRef hMenu);

// Changed to do UPP
extern pascal void	MDEF_SetCallbackProc(MenuRef hMenu, MercutioCallbackUPP mercutioCallback);
//extern pascal void	MDEF_SetCallbackProc(MenuRef hMenu, ProcPtr theProc);
extern pascal void	MDEF_SetMenuPrefs(MenuRef hMenu, MenuPrefsRec *thePrefs);

extern pascal void MDEF_SetKeyGraphicsPreference (MenuRef menu, Boolean preferGraphics);
extern pascal void MDEF_SetSmallIconID (MenuRef menu, short iconsSmallAboveID);

#if PRAGMA_ALIGN_SUPPORTED
#pragma options align=reset
#endif

#ifdef __cplusplus
}
#endif

#endif