#include <process.h>
#define INCL_DOS
#define INCL_DOSERRORS
#define INCL_DOSNLS
#define INCL_WINSWITCHLIST
#define INCL_WINWINDOWMGR
#define INCL_WININPUT
#define INCL_VIO
#define INCL_KBD
#include <os2.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static unsigned long
constant(char *name, int arg)
{
    errno = 0;
    if (name[0] == 'P' && name[1] == '_') {
	if (strEQ(name, "P_BACKGROUND"))
#ifdef P_BACKGROUND
	    return P_BACKGROUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_DEBUG"))
#ifdef P_DEBUG
	    return P_DEBUG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_DEFAULT"))
#ifdef P_DEFAULT
	    return P_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_DETACH"))
#ifdef P_DETACH
	    return P_DETACH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_FOREGROUND"))
#ifdef P_FOREGROUND
	    return P_FOREGROUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_FULLSCREEN"))
#ifdef P_FULLSCREEN
	    return P_FULLSCREEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_MAXIMIZE"))
#ifdef P_MAXIMIZE
	    return P_MAXIMIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_MINIMIZE"))
#ifdef P_MINIMIZE
	    return P_MINIMIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_NOCLOSE"))
#ifdef P_NOCLOSE
	    return P_NOCLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_NOSESSION"))
#ifdef P_NOSESSION
	    return P_NOSESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_NOWAIT"))
#ifdef P_NOWAIT
	    return P_NOWAIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_OVERLAY"))
#ifdef P_OVERLAY
	    return P_OVERLAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_PM"))
#ifdef P_PM
	    return P_PM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_QUOTE"))
#ifdef P_QUOTE
	    return P_QUOTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_SESSION"))
#ifdef P_SESSION
	    return P_SESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_TILDE"))
#ifdef P_TILDE
	    return P_TILDE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_UNRELATED"))
#ifdef P_UNRELATED
	    return P_UNRELATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_WAIT"))
#ifdef P_WAIT
	    return P_WAIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "P_WINDOWED"))
#ifdef P_WINDOWED
	    return P_WINDOWED;
#else
	    goto not_there;
#endif
    } else if (name[0] == 'T' && name[1] == '_') {
	if (strEQ(name, "FAPPTYP_NOTSPEC"))
#ifdef FAPPTYP_NOTSPEC
	    return FAPPTYP_NOTSPEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_NOTWINDOWCOMPAT"))
#ifdef FAPPTYP_NOTWINDOWCOMPAT
	    return FAPPTYP_NOTWINDOWCOMPAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_WINDOWCOMPAT"))
#ifdef FAPPTYP_WINDOWCOMPAT
	    return FAPPTYP_WINDOWCOMPAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_WINDOWAPI"))
#ifdef FAPPTYP_WINDOWAPI
	    return FAPPTYP_WINDOWAPI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_BOUND"))
#ifdef FAPPTYP_BOUND
	    return FAPPTYP_BOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DLL"))
#ifdef FAPPTYP_DLL
	    return FAPPTYP_DLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DOS"))
#ifdef FAPPTYP_DOS
	    return FAPPTYP_DOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_PHYSDRV"))
#ifdef FAPPTYP_PHYSDRV
	    return FAPPTYP_PHYSDRV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_VIRTDRV"))
#ifdef FAPPTYP_VIRTDRV
	    return FAPPTYP_VIRTDRV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_PROTDLL"))
#ifdef FAPPTYP_PROTDLL
	    return FAPPTYP_PROTDLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_32BIT"))
#ifdef FAPPTYP_32BIT
	    return FAPPTYP_32BIT;
#else
	    goto not_there;
#endif
    }

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

const char* const ptypes[] = { "FS", "DOS", "VIO", "PM", "DETACH" };

static char *
my_type()
{
    int rc;
    TIB *tib;
    PIB *pib;
    
    if (!(_emx_env & 0x200)) return (char*)ptypes[1]; /* not OS/2. */
    if (CheckOSError(DosGetInfoBlocks(&tib, &pib))) 
	return NULL; 
    
    return (pib->pib_ultype <= 4 ? (char*)ptypes[pib->pib_ultype] : "UNKNOWN");
}

static ULONG
file_type(char *path)
{
    int rc;
    ULONG apptype;
    
    if (!(_emx_env & 0x200)) 
	croak("file_type not implemented on DOS"); /* not OS/2. */
    if (CheckOSError(DosQueryAppType(path, &apptype))) {
	if (rc == ERROR_INVALID_EXE_SIGNATURE) 
	    croak("Invalid EXE signature"); 
	else if (rc == ERROR_EXE_MARKED_INVALID) {
	    croak("EXE marked invalid"); 
	}
	croak("DosQueryAppType err %ld", rc); 
    }
    
    return apptype;
}

DeclFuncByORD(HSWITCH, myWinQuerySwitchHandle,  ORD_WinQuerySwitchHandle,
		  (HWND hwnd, PID pid), (hwnd, pid))
DeclFuncByORD(ULONG, myWinQuerySwitchEntry,  ORD_WinQuerySwitchEntry,
		  (HSWITCH hsw, PSWCNTRL pswctl), (hsw, pswctl))
DeclFuncByORD(ULONG, myWinSetWindowText,  ORD_WinSetWindowText,
		  (HWND hwnd, char* text), (hwnd, text))
DeclFuncByORD(BOOL, myWinQueryWindowProcess,  ORD_WinQueryWindowProcess,
		  (HWND hwnd, PPID ppid, PTID ptid), (hwnd, ppid, ptid))

DeclFuncByORD(ULONG, XmyWinSwitchToProgram,  ORD_WinSwitchToProgram,
		  (HSWITCH hsw), (hsw))
#define myWinSwitchToProgram(hsw) (!CheckOSError(XmyWinSwitchToProgram(hsw)))

DeclFuncByORD(HWND, myWinQueryActiveWindow,  ORD_WinQueryActiveWindow,
		  (HWND hwnd), (hwnd))


ULONG (*pWinQuerySwitchList) (HAB hab, PSWBLOCK pswblk, ULONG usDataLength);
ULONG (*pWinChangeSwitchEntry) (HSWITCH hsw, __const__ SWCNTRL *pswctl);

HWND (*pWinQueryWindow) (HWND hwnd, LONG cmd);
BOOL (*pWinQueryWindowPos) (HWND hwnd, PSWP pswp);
LONG (*pWinQueryWindowText) (HWND hwnd, LONG cchBufferMax, PCH pchBuffer);
LONG (*pWinQueryWindowTextLength) (HWND hwnd);
LONG (*pWinQueryClassName) (HWND hwnd, LONG cchMax, PCH pch);
HWND (*pWinQueryFocus) (HWND hwndDesktop);
BOOL (*pWinSetFocus) (HWND hwndDesktop, HWND hwndFocus);
BOOL (*pWinShowWindow) (HWND hwnd, BOOL fShow);
BOOL (*pWinPostMsg) (HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
BOOL (*pWinSetWindowPos) (HWND hwnd, HWND hwndInsertBehind, LONG x, LONG y,
    LONG cx, LONG cy, ULONG fl);
HENUM (*pWinBeginEnumWindows) (HWND hwnd);
BOOL (*pWinEndEnumWindows) (HENUM henum);
HWND (*pWinGetNextWindow) (HENUM henum);
BOOL (*pWinIsWindow) (HAB hab, HWND hwnd);
HWND (*pWinQueryWindow) (HWND hwnd, LONG cmd);

DeclWinFuncByORD(HWND, IsChild,  ORD_WinIsChild,
		 (HWND hwnd, HWND hwndParent), (hwnd, hwndParent))
DeclWinFuncByORD(HWND, WindowFromId,  ORD_WinWindowFromId,
		 (HWND hwnd, ULONG id), (hwnd, id))

HWND (*pWinWindowFromPoint)(HWND hwnd, __const__ POINTL *pptl, BOOL fChildren);

DeclWinFuncByORD(HWND, EnumDlgItem, ORD_WinEnumDlgItem,
		 (HWND hwndDlg, HWND hwnd, ULONG code), (hwndDlg, hwnd, code));

int
WindowText_set(HWND hwnd, char* text)
{
   return !CheckWinError(myWinSetWindowText(hwnd, text));
}

LONG
QueryWindowTextLength(HWND hwnd)
{
    LONG ret;

    if (!pWinQueryWindowTextLength)
	AssignFuncPByORD(pWinQueryWindowTextLength, ORD_WinQueryWindowTextLength);
    ret = pWinQueryWindowTextLength(hwnd);
    CheckWinError(ret);			/* May put false positive */
    return ret;
}

SV *
QueryWindowText(HWND hwnd)
{
    LONG l = QueryWindowTextLength(hwnd);
    SV *sv = newSVpvn("", 0);
    STRLEN n_a;

    if (l == 0)
	return sv;
    SvGROW(sv, l + 1);
    if (!pWinQueryWindowText)
	AssignFuncPByORD(pWinQueryWindowText, ORD_WinQueryWindowText);
    CheckWinError(l = pWinQueryWindowText(hwnd, l + 1, SvPV_force(sv, n_a)));
    SvCUR_set(sv, l);
    return sv;
}

SWP
QueryWindowSWP_(HWND hwnd)
{
    SWP swp;

    if (!pWinQueryWindowPos)
	AssignFuncPByORD(pWinQueryWindowPos, ORD_WinQueryWindowPos);
    if (CheckWinError(pWinQueryWindowPos(hwnd, &swp)))
	croak("WinQueryWindowPos() error");
    return swp;
}

SV *
QueryWindowSWP(HWND hwnd)
{
    SWP swp = QueryWindowSWP_(hwnd);

    return newSVpvn((char*)&swp, sizeof(swp));
}

SV *
QueryClassName(HWND hwnd)
{
    SV *sv = newSVpvn("",0);
    STRLEN l = 46, len = 0, n_a;

    if (!pWinQueryClassName)
	AssignFuncPByORD(pWinQueryClassName, ORD_WinQueryClassName);
    while (l + 1 >= len) {
	if (len)
	    len = 2*len + 10;		/* Grow quick */
	else
	    len = l + 2;
	SvGROW(sv, len);
	l = pWinQueryClassName(hwnd, len, SvPV_force(sv, n_a));
	CheckWinError(l);
	SvCUR_set(sv, l);
    }
    return sv;
}

HWND
QueryFocusWindow(HWND hwndDesktop)
{
    HWND ret;

    if (!pWinQueryFocus)
	AssignFuncPByORD(pWinQueryFocus, ORD_WinQueryFocus);
    ret = pWinQueryFocus(hwndDesktop);
    CheckWinError(ret);
    return ret;
}

BOOL
FocusWindow_set(HWND hwndFocus, HWND hwndDesktop)
{
    if (!pWinSetFocus)
	AssignFuncPByORD(pWinSetFocus, ORD_WinSetFocus);
    return !CheckWinError(pWinSetFocus(hwndDesktop, hwndFocus));
}

BOOL
ShowWindow(HWND hwnd, BOOL fShow)
{
    if (!pWinShowWindow)
	AssignFuncPByORD(pWinShowWindow, ORD_WinShowWindow);
    return !CheckWinError(pWinShowWindow(hwnd, fShow));
}

BOOL
PostMsg(HWND hwnd, ULONG msg, ULONG mp1, ULONG mp2)
{
    if (!pWinPostMsg)
	AssignFuncPByORD(pWinPostMsg, ORD_WinPostMsg);
    return !CheckWinError(pWinPostMsg(hwnd, msg, (MPARAM)mp1, (MPARAM)mp2));
}

BOOL
WindowPos_set(HWND hwnd, LONG x, LONG y, ULONG fl, LONG cx, LONG cy, 
	      HWND hwndInsertBehind)
{
    if (!pWinSetWindowPos)
	AssignFuncPByORD(pWinSetWindowPos, ORD_WinSetWindowPos);
    return !CheckWinError(pWinSetWindowPos(hwnd, hwndInsertBehind, x, y, cx, cy, fl));
}

HENUM
BeginEnumWindows(HWND hwnd)
{
    if (!pWinBeginEnumWindows)
	AssignFuncPByORD(pWinBeginEnumWindows, ORD_WinBeginEnumWindows);
    return SaveWinError(pWinBeginEnumWindows(hwnd));
}

BOOL
EndEnumWindows(HENUM henum)
{
    if (!pWinEndEnumWindows)
	AssignFuncPByORD(pWinEndEnumWindows, ORD_WinEndEnumWindows);
    return !CheckWinError(pWinEndEnumWindows(henum));
}

HWND
GetNextWindow(HENUM henum)
{
    if (!pWinGetNextWindow)
	AssignFuncPByORD(pWinGetNextWindow, ORD_WinGetNextWindow);
    return SaveWinError(pWinGetNextWindow(henum));
}

BOOL
IsWindow(HWND hwnd, HAB hab)
{
    if (!pWinIsWindow)
	AssignFuncPByORD(pWinIsWindow, ORD_WinIsWindow);
    return !CheckWinError(pWinIsWindow(hab, hwnd));
}

HWND
QueryWindow(HWND hwnd, LONG cmd)
{
    if (!pWinQueryWindow)
	AssignFuncPByORD(pWinQueryWindow, ORD_WinQueryWindow);
    return !CheckWinError(pWinQueryWindow(hwnd, cmd));
}

HWND
WindowFromPoint(long x, long y, HWND hwnd, BOOL fChildren)
{
    POINTL ppl;

    ppl.x = x; ppl.y = y;
    if (!pWinWindowFromPoint)
	AssignFuncPByORD(pWinWindowFromPoint, ORD_WinWindowFromPoint);
    return SaveWinError(pWinWindowFromPoint(hwnd, &ppl, fChildren));
}

static void
fill_swentry(SWENTRY *swentryp, HWND hwnd, PID pid)
{
	 int rc;
	 HSWITCH hSwitch;    

	 if (!(_emx_env & 0x200)) 
	     croak("switch_entry not implemented on DOS"); /* not OS/2. */
	 if (CheckWinError(hSwitch = 
			   myWinQuerySwitchHandle(hwnd, pid)))
	     croak("WinQuerySwitchHandle err %ld", Perl_rc);
	 swentryp->hswitch = hSwitch;
	 if (CheckOSError(myWinQuerySwitchEntry(hSwitch, &swentryp->swctl)))
	     croak("WinQuerySwitchEntry err %ld", rc);
}

static void
fill_swentry_default(SWENTRY *swentryp)
{
	fill_swentry(swentryp, NULLHANDLE, getpid());
}

/* static ULONG (* APIENTRY16 pDosSmSetTitle)(ULONG, PSZ); */
ULONG _THUNK_FUNCTION(DosSmSetTitle)(ULONG, PSZ);

#if 0			/*  Does not work.  */
static ULONG (*pDosSmSetTitle)(ULONG, PSZ);

static void
sesmgr_title_set(char *s)
{
    SWENTRY swentry;
    static HMODULE hdosc = 0;
    BYTE buf[20];
    long rc;

    fill_swentry_default(&swentry);
    if (!pDosSmSetTitle || !hdosc) {
	if (CheckOSError(DosLoadModule(buf, sizeof buf, "sesmgr", &hdosc)))
	    croak("Cannot load SESMGR: no `%s'", buf);
	if (CheckOSError(DosQueryProcAddr(hdosc, 0, "DOSSMSETTITLE",
					  (PFN*)&pDosSmSetTitle)))
	    croak("Cannot load SESMGR.DOSSMSETTITLE, err=%ld", rc);
    }
/*     (pDosSmSetTitle)(swcntrl.idSession,s); */
    rc = ((USHORT)
          (_THUNK_PROLOG (2+4);
           _THUNK_SHORT (swcntrl.idSession);
           _THUNK_FLAT (s);
           _THUNK_CALLI (*pDosSmSetTitle)));
    if (CheckOSError(rc))
	warn("*DOSSMSETTITLE: err=%ld, ses=%ld, addr=%x, *paddr=%x", 
	     rc, swcntrl.idSession, &_THUNK_FUNCTION(DosSmSetTitle),
	     pDosSmSetTitle);
}

#else /* !0 */

static bool
sesmgr_title_set(char *s)
{
    SWENTRY swentry;
    long rc;

    fill_swentry_default(&swentry);
    rc = ((USHORT)
          (_THUNK_PROLOG (2+4);
           _THUNK_SHORT (swentry.swctl.idSession);
           _THUNK_FLAT (s);
           _THUNK_CALL (DosSmSetTitle)));
#if 0
    if (CheckOSError(rc))
	warn("DOSSMSETTITLE: err=%ld, ses=%ld, addr=%x", 
	     rc, swcntrl.idSession, _THUNK_FUNCTION(DosSmSetTitle));
#endif
    return !CheckOSError(rc);
}
#endif /* !0 */

#if 0			/*  Does not work.  */
USHORT _THUNK_FUNCTION(Win16SetTitle) ();

static void
set_title2(char *s)
{
    long rc;

    rc = ((USHORT)
          (_THUNK_PROLOG (4);
           _THUNK_FLAT (s);
           _THUNK_CALL (Win16SetTitle)));
    if (CheckWinError(rc))
	warn("Win16SetTitle: err=%ld", rc);
}
#endif

SV *
process_swentry(unsigned long pid, unsigned long hwnd)
{
    SWENTRY swentry;

    if (!(_emx_env & 0x200)) 
	     croak("process_swentry not implemented on DOS"); /* not OS/2. */
    fill_swentry(&swentry, hwnd, pid);
    return newSVpvn((char*)&swentry, sizeof(swentry));
}

SV *
swentries_list()
{
    int num, n = 0;
    STRLEN n_a;
    PSWBLOCK pswblk;
    SV *sv = newSVpvn("",0);

    if (!(_emx_env & 0x200)) 
	     croak("swentries_list not implemented on DOS"); /* not OS/2. */
    if (!pWinQuerySwitchList)
	AssignFuncPByORD(pWinQuerySwitchList, ORD_WinQuerySwitchList);
    num = pWinQuerySwitchList(0, NULL, 0);	/* HAB is not required */
    if (!num)
	croak("(Unknown) error during WinQuerySwitchList()");
    /* Allow one extra entry to allow overflow detection (may happen
	if the list has been changed). */
    while (num > n) {
	if (n == 0)
	    n = num + 1;
	else
	    n = 2*num + 10;			/* Enlarge quickly */
	SvGROW(sv, sizeof(ULONG) + sizeof(SWENTRY) * n + 1);
	pswblk = (PSWBLOCK) SvPV_force(sv, n_a);
	num = pWinQuerySwitchList(0, pswblk, SvLEN(sv));
    }
    SvCUR_set(sv, sizeof(ULONG) + sizeof(SWENTRY) * num);
    *SvEND(sv) = 0;
    return sv;
}

SWENTRY
swentry( char *title, HWND sw_hwnd, HWND icon_hwnd, HPROGRAM owner_phandle,
	 PID owner_pid, ULONG owner_sid, ULONG visible, ULONG nonswitchable,
	 ULONG jumpable, ULONG ptype, HSWITCH sw_entry)
{
  SWENTRY e;

  strncpy(e.swctl.szSwtitle, title, MAXNAMEL);
  e.swctl.szSwtitle[60] = 0;
  e.swctl.hwnd = sw_hwnd;
  e.swctl.hwndIcon = icon_hwnd;
  e.swctl.hprog = owner_phandle;
  e.swctl.idProcess = owner_pid;
  e.swctl.idSession = owner_sid;
  e.swctl.uchVisibility = ((visible ? SWL_VISIBLE : SWL_INVISIBLE)
			   | (nonswitchable ? SWL_GRAYED : 0));
  e.swctl.fbJump = (jumpable ? SWL_JUMPABLE : 0);
  e.swctl.bProgType = ptype;
  e.hswitch = sw_entry;
  return e;
}

SV *
create_swentry( char *title, HWND owner_hwnd, HWND icon_hwnd, HPROGRAM owner_phandle,
	 PID owner_pid, ULONG owner_sid, ULONG visible, ULONG nonswitchable,
	 ULONG jumpable, ULONG ptype, HSWITCH sw_entry)
{
    SWENTRY e = swentry(title, owner_hwnd, icon_hwnd, owner_phandle, owner_pid,
			owner_sid, visible, nonswitchable, jumpable, ptype,
			sw_entry);

    return newSVpvn((char*)&e, sizeof(e));
}

int
change_swentrysw(SWENTRY *sw)
{
    ULONG rc;			/* For CheckOSError */

    if (!(_emx_env & 0x200)) 
	     croak("change_entry() not implemented on DOS"); /* not OS/2. */
    if (!pWinChangeSwitchEntry)
	AssignFuncPByORD(pWinChangeSwitchEntry, ORD_WinChangeSwitchEntry);
    return !CheckOSError(pWinChangeSwitchEntry(sw->hswitch, &sw->swctl));
}

int
change_swentry(SV *sv)
{
    STRLEN l;
    PSWENTRY pswentry = (PSWENTRY)SvPV(sv, l);

    if (l != sizeof(SWENTRY))
	croak("Wrong structure size %ld!=%ld in change_swentry()", (long)l, (long)sizeof(SWENTRY));
    return change_swentrysw(pswentry);
}


#define swentry_size()		(sizeof(SWENTRY))

void
getscrsize(int *wp, int *hp)
{
    int i[2];

    _scrsize(i);
    *wp = i[0];
    *hp = i[1];
}

/* Force vio to not cross 64K-boundary: */
#define VIO_FROM_VIOB			\
    vio = viob;				\
    if (!_THUNK_PTR_STRUCT_OK(vio))	\
	vio++

bool
scrsize_set(int w, int h)
{
    VIOMODEINFO viob[2], *vio;
    ULONG rc;

    VIO_FROM_VIOB;

    if (h == -9999)
	h = w, w = 0;
    vio->cb = sizeof(*vio);
    if (CheckOSError(VioGetMode( vio, 0 )))
	return 0;

    if( w > 0 )
      vio->col = (USHORT)w;

    if( h > 0 )
      vio->row = (USHORT)h;

    vio->cb = 8;
    if (CheckOSError(VioSetMode( vio, 0 )))
	return 0;
    return 1;
}

void
cursor(int *sp, int *ep, int *wp, int *ap)
{
    VIOCURSORINFO viob[2], *vio;
    ULONG rc;

    VIO_FROM_VIOB;

    if (CheckOSError(VioGetCurType( vio, 0 )))
	croak("VioGetCurType() error");

    *sp = vio->yStart;
    *ep = vio->cEnd;
    *wp = vio->cx;
    *ep = vio->attr;
}

bool
cursor__(int is_a)
{
    int s,e,w,a;

    cursor(&s, &e, &w, &a);
    if (is_a)
	return a;
    else
	return w;
}

bool
cursor_set(int s, int e, int w, int a)
{
    VIOCURSORINFO viob[2], *vio;
    ULONG rc;

    VIO_FROM_VIOB;

    vio->yStart = s;
    vio->cEnd = e;
    vio->cx = w;
    vio->attr = a;
    return !CheckOSError(VioSetCurType( vio, 0 ));
}

static int
bufsize(void)
{
#if 1
    VIOMODEINFO viob[2], *vio;
    ULONG rc;

    VIO_FROM_VIOB;

    vio->cb = sizeof(*vio);
    if (CheckOSError(VioGetMode( vio, 0 )))
	croak("Can't get size of buffer for screen");
#if 0	/* buf=323552247, full=1118455, partial=0 */
    croak("Lengths: buf=%d, full=%d, partial=%d",vio->buf_length,vio->full_length,vio->partial_length);
    return newSVpvn((char*)vio->buf_addr, vio->full_length);
#endif
    return vio->col * vio->row * 2;	/* How to get bytes/cell?  2 or 4? */
#else	/* 0 */
    int i[2];

    _scrsize(i);
    return i[0]*i[1]*2;
#endif	/* 0 */
}
    
SV *
screen(void)
{
    ULONG rc;
    USHORT bufl = bufsize();
    char b[(1<<16) * 3]; /* This/3 is enough for 16-bit calls, we need
			    2x overhead due to 2 vs 4 issue, and extra
			    64K due to alignment logic */
    char *buf = b;
    
    if (((ULONG)buf) & 0xFFFF)
	buf += 0x10000 - (((ULONG)buf) & 0xFFFF);
    if ((sizeof(b) - (buf - b)) < 2*bufl)
	croak("panic: VIO buffer allocation");
    if (CheckOSError(VioReadCellStr( buf, &bufl, 0, 0, 0 )))
	return &PL_sv_undef;
    return newSVpvn(buf,bufl);
}

bool
screen_set(SV *sv)
{
    ULONG rc;
    STRLEN l = SvCUR(sv), bufl = bufsize();
    char b[(1<<16) * 2]; /* This/2 is enough for 16-bit calls, we need
			    extra 64K due to alignment logic */
    char *buf = b;
    
    if (((ULONG)buf) & 0xFFFF)
	buf += 0x10000 - (((ULONG)buf) & 0xFFFF);
    if (!SvPOK(sv) || ((l != bufl) && (l != 2*bufl)))
	croak("Wrong size %d of saved screen data", SvCUR(sv));
    if ((sizeof(b) - (buf - b)) < l)
	croak("panic: VIO buffer allocation");
    Copy(SvPV(sv,l), buf, bufl, char);
    if (CheckOSError(VioWrtCellStr( buf, bufl, 0, 0, 0 )))
	return 0;
    return 1;
}

int
process_codepages()
{
    ULONG cps[4], cp, rc;

    if (CheckOSError(DosQueryCp( sizeof(cps), cps, &cp )))
	croak("DosQueryCp() error");
    return cp;
}

int
out_codepage()
{
    USHORT cp, rc;

    if (CheckOSError(VioGetCp( 0, &cp, 0 )))
	croak("VioGetCp() error");
    return cp;
}

bool
out_codepage_set(int cp)
{
    USHORT rc;

    return !(CheckOSError(VioSetCp( 0, cp, 0 )));
}

int
in_codepage()
{
    USHORT cp, rc;

    if (CheckOSError(KbdGetCp( 0, &cp, 0 )))
	croak("KbdGetCp() error");
    return cp;
}

bool
in_codepage_set(int cp)
{
    USHORT rc;

    return !(CheckOSError(KbdSetCp( 0, cp, 0 )));
}

bool
process_codepage_set(int cp)
{
    USHORT rc;

    return !(CheckOSError(DosSetProcessCp( cp )));
}

int
ppidOf(int pid)
{
  PQTOPLEVEL psi;
  int ppid;

  if (!pid)
      return -1;
  psi = get_sysinfo(pid, QSS_PROCESS);
  if (!psi)
      return -1;
  ppid = psi->procdata->ppid;
  Safefree(psi);
  return ppid;
}

int
sidOf(int pid)
{
  PQTOPLEVEL psi;
  int sid;

  if (!pid)
      return -1;
  psi = get_sysinfo(pid, QSS_PROCESS);
  if (!psi)
      return -1;
  sid = psi->procdata->sessid;
  Safefree(psi);
  return sid;
}

MODULE = OS2::Process		PACKAGE = OS2::Process


unsigned long
constant(name,arg)
	char *		name
	int		arg

char *
my_type()

U32
file_type(path)
    char *path

SV *
swentry_expand( SV *sv )
    PPCODE:
     {
	 STRLEN l;
	 PSWENTRY pswentry = (PSWENTRY)SvPV(sv, l);

	 if (l != sizeof(SWENTRY))
		croak("Wrong structure size %ld!=%ld in swentry_expand()", (long)l, (long)sizeof(SWENTRY));
	 EXTEND(sp,11);
	 PUSHs(sv_2mortal(newSVpv(pswentry->swctl.szSwtitle, 0)));
	 PUSHs(sv_2mortal(newSVnv(pswentry->swctl.hwnd)));
	 PUSHs(sv_2mortal(newSVnv(pswentry->swctl.hwndIcon)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.hprog)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.idProcess)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.idSession)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.uchVisibility & SWL_VISIBLE)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.uchVisibility & SWL_GRAYED)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.fbJump == SWL_JUMPABLE)));
	 PUSHs(sv_2mortal(newSViv(pswentry->swctl.bProgType)));
	 PUSHs(sv_2mortal(newSViv(pswentry->hswitch)));
     }

SV *
create_swentry( char *title, unsigned long sw_hwnd, unsigned long icon_hwnd, unsigned long owner_phandle, unsigned long owner_pid, unsigned long owner_sid, unsigned long visible, unsigned long switchable,	 unsigned long jumpable, unsigned long ptype, unsigned long sw_entry)

int
change_swentry( SV *sv )

bool
sesmgr_title_set(s)
    char *s

SV *
process_swentry(unsigned long pid = getpid(), unsigned long hwnd = NULLHANDLE);

int
swentry_size()

SV *
swentries_list()

int
WindowText_set(unsigned long hwndFrame, char *title)

bool
FocusWindow_set(unsigned long hwndFocus, unsigned long hwndDesktop = HWND_DESKTOP)

bool
ShowWindow(unsigned long hwnd, bool fShow = TRUE)

bool
PostMsg(unsigned long hwnd, unsigned long msg, unsigned long mp1 = 0, unsigned long mp2 = 0)

bool
WindowPos_set(unsigned long hwnd, long x, long y, unsigned long fl = SWP_MOVE, long cx = 0, long cy = 0, unsigned long hwndInsertBehind = HWND_TOP)

unsigned long
BeginEnumWindows(unsigned long hwnd)

bool
EndEnumWindows(unsigned long henum)

unsigned long
GetNextWindow(unsigned long henum)

bool
IsWindow(unsigned long hwnd, unsigned long hab = Acquire_hab())

unsigned long
QueryWindow(unsigned long hwnd, long cmd)

unsigned long
IsChild(unsigned long hwnd, unsigned long hwndParent)

unsigned long
WindowFromId(unsigned long hwndParent, unsigned long id)

unsigned long
WindowFromPoint(long x, long y, unsigned long hwnd, bool fChildren = 0)

unsigned long
EnumDlgItem(unsigned long hwndDlg, unsigned long code, unsigned long hwnd = NULLHANDLE)
   C_ARGS: hwndDlg, hwnd, code

int
out_codepage()

bool
out_codepage_set(int cp)

int
in_codepage()

bool
in_codepage_set(int cp)

SV *
screen()

bool
screen_set(SV *sv)

SV *
process_codepages()
  PPCODE:
  {
    ULONG cps[4], c, i = 0, rc;

    if (CheckOSError(DosQueryCp( sizeof(cps), cps, &c )))
	c = 0;
    c /= sizeof(ULONG);
    if (c >= 3)
    EXTEND(sp, c);
    while (i < c)
	PUSHs(sv_2mortal(newSViv(cps[i++])));
  }

bool
process_codepage_set(int cp)

MODULE = OS2::Process		PACKAGE = OS2::Process	PREFIX = Query

unsigned long
QueryFocusWindow(unsigned long hwndDesktop = HWND_DESKTOP)

long
QueryWindowTextLength(unsigned long hwnd)

SV *
QueryWindowText(unsigned long hwnd)

SV *
QueryWindowSWP(unsigned long hwnd)

SV *
QueryClassName(unsigned long hwnd)

MODULE = OS2::Process		PACKAGE = OS2::Process	PREFIX = myWin

NO_OUTPUT BOOL
myWinQueryWindowProcess(unsigned long hwnd, OUTLIST unsigned long pid, OUTLIST unsigned long tid)
   POSTCALL:
	if (CheckWinError(RETVAL))
	    croak("QueryWindowProcess() error");

void
cursor(OUTLIST int stp, OUTLIST int ep, OUTLIST int wp, OUTLIST int ap)

bool
cursor_set(int s, int e, int w = cursor__(0), int a = cursor__(1))

int
myWinSwitchToProgram(unsigned long hsw)
    PREINIT:
	ULONG rc;

unsigned long
myWinQueryActiveWindow(unsigned long hwnd = HWND_DESKTOP)

MODULE = OS2::Process		PACKAGE = OS2::Process	PREFIX = get

int
getppid()

int
ppidOf(int pid = getpid())

int
sidOf(int pid = getpid())

void
getscrsize(OUTLIST int wp, OUTLIST int hp)

bool
scrsize_set(int w_or_h, int h = -9999)
