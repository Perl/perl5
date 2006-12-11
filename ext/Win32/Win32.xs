#include <windows.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SE_SHUTDOWN_NAMEA   "SeShutdownPrivilege"

typedef BOOL (WINAPI *PFNSHGetSpecialFolderPath)(HWND, char*, int, BOOL);
typedef HRESULT (WINAPI *PFNSHGetFolderPath)(HWND, int, HANDLE, DWORD, LPTSTR);
typedef int (__stdcall *PFNDllRegisterServer)(void);
typedef int (__stdcall *PFNDllUnregisterServer)(void);
#ifndef CSIDL_FLAG_CREATE
#   define CSIDL_FLAG_CREATE               0x8000
#endif

static OSVERSIONINFO g_osver = {0, 0, 0, 0, 0, ""};

#define ONE_K_BUFSIZE	1024

int
IsWin95(void)
{
    return (g_osver.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS);
}

int
IsWinNT(void)
{
    return (g_osver.dwPlatformId == VER_PLATFORM_WIN32_NT);
}

#ifdef __CYGWIN__

#define isSLASH(c) ((c) == '/' || (c) == '\\')
#define SKIP_SLASHES(s) \
    STMT_START {				\
	while (*(s) && isSLASH(*(s)))		\
	    ++(s);				\
    } STMT_END
#define COPY_NONSLASHES(d,s) \
    STMT_START {				\
	while (*(s) && !isSLASH(*(s)))		\
	    *(d)++ = *(s)++;			\
    } STMT_END

/* Find the longname of a given path.  path is destructively modified.
 * It should have space for at least MAX_PATH characters. */
char *
win32_longpath(char *path)
{
    WIN32_FIND_DATA fdata;
    HANDLE fhand;
    char tmpbuf[MAX_PATH+1];
    char *tmpstart = tmpbuf;
    char *start = path;
    char sep;
    if (!path)
	return Nullch;

    /* drive prefix */
    if (isALPHA(path[0]) && path[1] == ':') {
	start = path + 2;
	*tmpstart++ = path[0];
	*tmpstart++ = ':';
    }
    /* UNC prefix */
    else if (isSLASH(path[0]) && isSLASH(path[1])) {
	start = path + 2;
	*tmpstart++ = path[0];
	*tmpstart++ = path[1];
	SKIP_SLASHES(start);
	COPY_NONSLASHES(tmpstart,start);	/* copy machine name */
	if (*start) {
	    *tmpstart++ = *start++;
	    SKIP_SLASHES(start);
	    COPY_NONSLASHES(tmpstart,start);	/* copy share name */
	}
    }
    *tmpstart = '\0';
    while (*start) {
	/* copy initial slash, if any */
	if (isSLASH(*start)) {
	    *tmpstart++ = *start++;
	    *tmpstart = '\0';
	    SKIP_SLASHES(start);
	}

	/* FindFirstFile() expands "." and "..", so we need to pass
	 * those through unmolested */
	if (*start == '.'
	    && (!start[1] || isSLASH(start[1])
		|| (start[1] == '.' && (!start[2] || isSLASH(start[2])))))
	{
	    COPY_NONSLASHES(tmpstart,start);	/* copy "." or ".." */
	    *tmpstart = '\0';
	    continue;
	}

	/* if this is the end, bust outta here */
	if (!*start)
	    break;

	/* now we're at a non-slash; walk up to next slash */
	while (*start && !isSLASH(*start))
	    ++start;

	/* stop and find full name of component */
	sep = *start;
	*start = '\0';
	fhand = FindFirstFile(path,&fdata);
	*start = sep;
	if (fhand != INVALID_HANDLE_VALUE) {
	    STRLEN len = strlen(fdata.cFileName);
	    if ((STRLEN)(tmpbuf + sizeof(tmpbuf) - tmpstart) > len) {
		strcpy(tmpstart, fdata.cFileName);
		tmpstart += len;
		FindClose(fhand);
	    }
	    else {
		FindClose(fhand);
		errno = ERANGE;
		return Nullch;
	    }
	}
	else {
	    /* failed a step, just return without side effects */
	    /*PerlIO_printf(Perl_debug_log, "Failed to find %s\n", path);*/
	    errno = EINVAL;
	    return Nullch;
	}
    }
    strcpy(path,tmpbuf);
    return path;
}

char*
get_childdir(void)
{
    dTHX;
    char* ptr;
    char szfilename[MAX_PATH+1];

    GetCurrentDirectoryA(MAX_PATH+1, szfilename);
    New(0, ptr, strlen(szfilename)+1, char);
    strcpy(ptr, szfilename);
    return ptr;
}

void
free_childdir(char* d)
{
    dTHX;
    Safefree(d);
}

void*
get_childenv(void)
{
    return NULL;
}

void
free_childenv(void* d)
{
}

#  define PerlDir_mapA(dir) (dir)

#endif

XS(w32_ExpandEnvironmentStrings)
{
    dXSARGS;
    BYTE buffer[4096];

    if (items != 1)
	croak("usage: Win32::ExpandEnvironmentStrings($String);\n");

    ExpandEnvironmentStringsA(SvPV_nolen(ST(0)), (char*)buffer, sizeof(buffer));
    XSRETURN_PV((char*)buffer);
}

XS(w32_IsAdminUser)
{
    dXSARGS;
    HINSTANCE                   hAdvApi32;
    BOOL (__stdcall *pfnOpenThreadToken)(HANDLE hThr, DWORD dwDesiredAccess,
                                BOOL bOpenAsSelf, PHANDLE phTok);
    BOOL (__stdcall *pfnOpenProcessToken)(HANDLE hProc, DWORD dwDesiredAccess,
                                PHANDLE phTok);
    BOOL (__stdcall *pfnGetTokenInformation)(HANDLE hTok,
                                TOKEN_INFORMATION_CLASS TokenInformationClass,
                                LPVOID lpTokInfo, DWORD dwTokInfoLen,
                                PDWORD pdwRetLen);
    BOOL (__stdcall *pfnAllocateAndInitializeSid)(
                                PSID_IDENTIFIER_AUTHORITY pIdAuth,
                                BYTE nSubAuthCount, DWORD dwSubAuth0,
                                DWORD dwSubAuth1, DWORD dwSubAuth2,
                                DWORD dwSubAuth3, DWORD dwSubAuth4,
                                DWORD dwSubAuth5, DWORD dwSubAuth6,
                                DWORD dwSubAuth7, PSID pSid);
    BOOL (__stdcall *pfnEqualSid)(PSID pSid1, PSID pSid2);
    PVOID (__stdcall *pfnFreeSid)(PSID pSid);
    HANDLE                      hTok;
    DWORD                       dwTokInfoLen;
    TOKEN_GROUPS                *lpTokInfo;
    SID_IDENTIFIER_AUTHORITY    NtAuth = SECURITY_NT_AUTHORITY;
    PSID                        pAdminSid;
    int                         iRetVal;
    unsigned int                i;
    OSVERSIONINFO               osver;

    if (items)
        croak("usage: Win32::IsAdminUser()");

    /* There is no concept of "Administrator" user accounts on Win9x systems,
       so just return true. */
    memset(&osver, 0, sizeof(OSVERSIONINFO));
    osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
    GetVersionEx(&osver);
    if (osver.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS)
        XSRETURN_YES;

    hAdvApi32 = LoadLibrary("advapi32.dll");
    if (!hAdvApi32) {
        warn("Cannot load advapi32.dll library");
        XSRETURN_UNDEF;
    }

    pfnOpenThreadToken = (BOOL (__stdcall *)(HANDLE, DWORD, BOOL, PHANDLE))
        GetProcAddress(hAdvApi32, "OpenThreadToken");
    pfnOpenProcessToken = (BOOL (__stdcall *)(HANDLE, DWORD, PHANDLE))
        GetProcAddress(hAdvApi32, "OpenProcessToken");
    pfnGetTokenInformation = (BOOL (__stdcall *)(HANDLE,
        TOKEN_INFORMATION_CLASS, LPVOID, DWORD, PDWORD))
        GetProcAddress(hAdvApi32, "GetTokenInformation");
    pfnAllocateAndInitializeSid = (BOOL (__stdcall *)(
        PSID_IDENTIFIER_AUTHORITY, BYTE, DWORD, DWORD, DWORD, DWORD, DWORD,
        DWORD, DWORD, DWORD, PSID))
        GetProcAddress(hAdvApi32, "AllocateAndInitializeSid");
    pfnEqualSid = (BOOL (__stdcall *)(PSID, PSID))
        GetProcAddress(hAdvApi32, "EqualSid");
    pfnFreeSid = (PVOID (__stdcall *)(PSID))
        GetProcAddress(hAdvApi32, "FreeSid");

    if (!(pfnOpenThreadToken && pfnOpenProcessToken &&
          pfnGetTokenInformation && pfnAllocateAndInitializeSid &&
          pfnEqualSid && pfnFreeSid))
    {
        warn("Cannot load functions from advapi32.dll library");
        FreeLibrary(hAdvApi32);
        XSRETURN_UNDEF;
    }

    if (!pfnOpenThreadToken(GetCurrentThread(), TOKEN_QUERY, FALSE, &hTok)) {
        if (!pfnOpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hTok)) {
            warn("Cannot open thread token or process token");
            FreeLibrary(hAdvApi32);
            XSRETURN_UNDEF;
        }
    }

    pfnGetTokenInformation(hTok, TokenGroups, NULL, 0, &dwTokInfoLen);
    if (!New(1, lpTokInfo, dwTokInfoLen, TOKEN_GROUPS)) {
        warn("Cannot allocate token information structure");
        CloseHandle(hTok);
        FreeLibrary(hAdvApi32);
        XSRETURN_UNDEF;
    }

    if (!pfnGetTokenInformation(hTok, TokenGroups, lpTokInfo, dwTokInfoLen,
            &dwTokInfoLen))
    {
        warn("Cannot get token information");
        Safefree(lpTokInfo);
        CloseHandle(hTok);
        FreeLibrary(hAdvApi32);
        XSRETURN_UNDEF;
    }

    if (!pfnAllocateAndInitializeSid(&NtAuth, 2, SECURITY_BUILTIN_DOMAIN_RID,
            DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &pAdminSid))
    {
        warn("Cannot allocate administrators' SID");
        Safefree(lpTokInfo);
        CloseHandle(hTok);
        FreeLibrary(hAdvApi32);
        XSRETURN_UNDEF;
    }

    iRetVal = 0;
    for (i = 0; i < lpTokInfo->GroupCount; ++i) {
        if (pfnEqualSid(lpTokInfo->Groups[i].Sid, pAdminSid)) {
            iRetVal = 1;
            break;
        }
    }

    pfnFreeSid(pAdminSid);
    Safefree(lpTokInfo);
    CloseHandle(hTok);
    FreeLibrary(hAdvApi32);

    EXTEND(SP, 1);
    ST(0) = sv_2mortal(newSViv(iRetVal));
    XSRETURN(1);
}

XS(w32_LookupAccountName)
{
    dXSARGS;
    char SID[400];
    DWORD SIDLen;
    SID_NAME_USE snu;
    char Domain[256];
    DWORD DomLen;
    BOOL bResult;

    if (items != 5)
	croak("usage: Win32::LookupAccountName($system, $account, $domain, "
	      "$sid, $sidtype);\n");

    SIDLen = sizeof(SID);
    DomLen = sizeof(Domain);

    bResult = LookupAccountNameA(SvPV_nolen(ST(0)),	/* System */
                                 SvPV_nolen(ST(1)),	/* Account name */
                                 &SID,			/* SID structure */
                                 &SIDLen,		/* Size of SID buffer */
                                 Domain,		/* Domain buffer */
                                 &DomLen,		/* Domain buffer size */
                                 &snu);			/* SID name type */
    if (bResult) {
	sv_setpv(ST(2), Domain);
	sv_setpvn(ST(3), SID, SIDLen);
	sv_setiv(ST(4), snu);
	XSRETURN_YES;
    }
    XSRETURN_NO;
}


XS(w32_LookupAccountSID)
{
    dXSARGS;
    PSID sid;
    char Account[256];
    DWORD AcctLen = sizeof(Account);
    char Domain[256];
    DWORD DomLen = sizeof(Domain);
    SID_NAME_USE snu;
    BOOL bResult;

    if (items != 5)
	croak("usage: Win32::LookupAccountSID($system, $sid, $account, $domain, $sidtype);\n");

    sid = SvPV_nolen(ST(1));
    if (IsValidSid(sid)) {
        bResult = LookupAccountSidA(SvPV_nolen(ST(0)),	/* System */
                                    sid,		/* SID structure */
                                    Account,		/* Account name buffer */
                                    &AcctLen,		/* name buffer length */
                                    Domain,		/* Domain buffer */
                                    &DomLen,		/* Domain buffer length */
                                    &snu);		/* SID name type */
	if (bResult) {
	    sv_setpv(ST(2), Account);
	    sv_setpv(ST(3), Domain);
	    sv_setiv(ST(4), (IV)snu);
	    XSRETURN_YES;
	}
    }
    XSRETURN_NO;
}

XS(w32_InitiateSystemShutdown)
{
    dXSARGS;
    HANDLE hToken;              /* handle to process token   */
    TOKEN_PRIVILEGES tkp;       /* pointer to token structure  */
    BOOL bRet;
    char *machineName, *message;

    if (items != 5)
	croak("usage: Win32::InitiateSystemShutdown($machineName, $message, "
	      "$timeOut, $forceClose, $reboot);\n");

    machineName = SvPV_nolen(ST(0));

    if (OpenProcessToken(GetCurrentProcess(),
			 TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
			 &hToken))
    {
        LookupPrivilegeValueA(machineName,
                              SE_SHUTDOWN_NAMEA,
                              &tkp.Privileges[0].Luid);

	tkp.PrivilegeCount = 1; /* only setting one */
	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

	/* Get shutdown privilege for this process. */
	AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,
			      (PTOKEN_PRIVILEGES)NULL, 0);
    }

    message = SvPV_nolen(ST(1));
    bRet = InitiateSystemShutdownA(machineName, message,
                                   SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)));

    /* Disable shutdown privilege. */
    tkp.Privileges[0].Attributes = 0; 
    AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,
			  (PTOKEN_PRIVILEGES)NULL, 0); 
    CloseHandle(hToken);
    XSRETURN_IV(bRet);
}

XS(w32_AbortSystemShutdown)
{
    dXSARGS;
    HANDLE hToken;              /* handle to process token   */
    TOKEN_PRIVILEGES tkp;       /* pointer to token structure  */
    BOOL bRet;
    char *machineName;

    if (items != 1)
	croak("usage: Win32::AbortSystemShutdown($machineName);\n");

    machineName = SvPV_nolen(ST(0));

    if (OpenProcessToken(GetCurrentProcess(),
			 TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
			 &hToken))
    {
        LookupPrivilegeValueA(machineName,
                              SE_SHUTDOWN_NAMEA,
                              &tkp.Privileges[0].Luid);

	tkp.PrivilegeCount = 1; /* only setting one */
	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

	/* Get shutdown privilege for this process. */
	AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,
			      (PTOKEN_PRIVILEGES)NULL, 0);
    }

    bRet = AbortSystemShutdownA(machineName);

    /* Disable shutdown privilege. */
    tkp.Privileges[0].Attributes = 0;
    AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,
			  (PTOKEN_PRIVILEGES)NULL, 0);
    CloseHandle(hToken);
    XSRETURN_IV(bRet);
}


XS(w32_MsgBox)
{
    dXSARGS;
    char *msg;
    char *title = "Perl";
    DWORD flags = MB_ICONEXCLAMATION;
    I32 result;

    if (items < 1 || items > 3)
	croak("usage: Win32::MsgBox($message [, $flags [, $title]]);\n");

    msg = SvPV_nolen(ST(0));
    if (items > 1) {
	flags = SvIV(ST(1));
	if (items > 2)
	    title = SvPV_nolen(ST(2));
    }
    result = MessageBoxA(GetActiveWindow(), msg, title, flags);
    XSRETURN_IV(result);
}

XS(w32_LoadLibrary)
{
    dXSARGS;
    HANDLE hHandle;

    if (items != 1)
	croak("usage: Win32::LoadLibrary($libname)\n");
    hHandle = LoadLibraryA(SvPV_nolen(ST(0)));
    XSRETURN_IV((long)hHandle);
}

XS(w32_FreeLibrary)
{
    dXSARGS;

    if (items != 1)
	croak("usage: Win32::FreeLibrary($handle)\n");
    if (FreeLibrary(INT2PTR(HINSTANCE, SvIV(ST(0))))) {
	XSRETURN_YES;
    }
    XSRETURN_NO;
}

XS(w32_GetProcAddress)
{
    dXSARGS;

    if (items != 2)
	croak("usage: Win32::GetProcAddress($hinstance, $procname)\n");
    XSRETURN_IV(PTR2IV(GetProcAddress(INT2PTR(HINSTANCE, SvIV(ST(0))), SvPV_nolen(ST(1)))));
}

XS(w32_RegisterServer)
{
    dXSARGS;
    BOOL result = FALSE;
    HINSTANCE hnd;

    if (items != 1)
	croak("usage: Win32::RegisterServer($libname)\n");

    hnd = LoadLibraryA(SvPV_nolen(ST(0)));
    if (hnd) {
	PFNDllRegisterServer func;
	func = (PFNDllRegisterServer)GetProcAddress(hnd, "DllRegisterServer");
	if (func && func() == 0)
	    result = TRUE;
	FreeLibrary(hnd);
    }
    ST(0) = boolSV(result);
    XSRETURN(1);
}

XS(w32_UnregisterServer)
{
    dXSARGS;
    BOOL result = FALSE;
    HINSTANCE hnd;

    if (items != 1)
	croak("usage: Win32::UnregisterServer($libname)\n");

    hnd = LoadLibraryA(SvPV_nolen(ST(0)));
    if (hnd) {
	PFNDllUnregisterServer func;
	func = (PFNDllUnregisterServer)GetProcAddress(hnd, "DllUnregisterServer");
	if (func && func() == 0)
	    result = TRUE;
	FreeLibrary(hnd);
    }
    ST(0) = boolSV(result);
    XSRETURN(1);
}

/* XXX rather bogus */
XS(w32_GetArchName)
{
    dXSARGS;
    XSRETURN_PV(getenv("PROCESSOR_ARCHITECTURE"));
}

XS(w32_GetChipName)
{
    dXSARGS;
    SYSTEM_INFO sysinfo;

    Zero(&sysinfo,1,SYSTEM_INFO);
    GetSystemInfo(&sysinfo);
    /* XXX docs say dwProcessorType is deprecated on NT */
    XSRETURN_IV(sysinfo.dwProcessorType);
}

XS(w32_GuidGen)
{
    dXSARGS;
    GUID guid;
    char szGUID[50] = {'\0'};
    HRESULT  hr     = CoCreateGuid(&guid);

    if (SUCCEEDED(hr)) {
	LPOLESTR pStr = NULL;
	if (SUCCEEDED(StringFromCLSID(&guid, &pStr))) {
            WideCharToMultiByte(CP_ACP, 0, pStr, wcslen(pStr), szGUID,
                                sizeof(szGUID), NULL, NULL);
            CoTaskMemFree(pStr);
            XSRETURN_PV(szGUID);
        }
    }
    XSRETURN_UNDEF;
}

XS(w32_GetFolderPath)
{
    dXSARGS;
    char path[MAX_PATH+1];
    int folder;
    int create = 0;
    HMODULE module;

    if (items != 1 && items != 2)
	croak("usage: Win32::GetFolderPath($csidl [, $create])\n");

    folder = SvIV(ST(0));
    if (items == 2)
        create = SvTRUE(ST(1)) ? CSIDL_FLAG_CREATE : 0;

    module = LoadLibrary("shfolder.dll");
    if (module) {
        PFNSHGetFolderPath pfn;
        pfn = (PFNSHGetFolderPath)GetProcAddress(module, "SHGetFolderPathA");
        if (pfn && SUCCEEDED(pfn(NULL, folder|create, NULL, 0, path))) {
            FreeLibrary(module);
            XSRETURN_PV(path);
        }
        FreeLibrary(module);
    }

    module = LoadLibrary("shell32.dll");
    if (module) {
        PFNSHGetSpecialFolderPath pfn;
        pfn = (PFNSHGetSpecialFolderPath)
            GetProcAddress(module, "SHGetSpecialFolderPathA");
        if (pfn && pfn(NULL, path, folder, !!create)) {
            FreeLibrary(module);
            XSRETURN_PV(path);
        }
        FreeLibrary(module);
    }
    XSRETURN_UNDEF;
}

XS(w32_GetFileVersion)
{
    dXSARGS;
    DWORD size;
    DWORD handle;
    char *filename;
    char *data;

    if (items != 1)
	croak("usage: Win32::GetFileVersion($filename)\n");

    filename = SvPV_nolen(ST(0));
    size = GetFileVersionInfoSize(filename, &handle);
    if (!size)
        XSRETURN_UNDEF;

    New(0, data, size, char);
    if (!data)
        XSRETURN_UNDEF;

    if (GetFileVersionInfo(filename, handle, size, data)) {
        VS_FIXEDFILEINFO *info;
        UINT len;
        if (VerQueryValue(data, "\\", (void**)&info, &len)) {
            int dwValueMS1 = (info->dwFileVersionMS>>16);
            int dwValueMS2 = (info->dwFileVersionMS&0xffff);
            int dwValueLS1 = (info->dwFileVersionLS>>16);
            int dwValueLS2 = (info->dwFileVersionLS&0xffff);

            if (GIMME_V == G_ARRAY) {
                EXTEND(SP, 4);
                XST_mIV(0, dwValueMS1);
                XST_mIV(1, dwValueMS2);
                XST_mIV(2, dwValueLS1);
                XST_mIV(3, dwValueLS2);
                items = 4;
            }
            else {
                char version[50];
                sprintf(version, "%d.%d.%d.%d", dwValueMS1, dwValueMS2, dwValueLS1, dwValueLS2);
                XST_mPV(0, version);
            }
        }
    }
    else
        items = 0;

    Safefree(data);
    XSRETURN(items);
}

#ifdef __CYGWIN__
XS(w32_SetChildShowWindow)
{
    /* This function doesn't do anything useful for cygwin.  In the
     * MSWin32 case it modifies w32_showwindow, which is used by
     * win32_spawnvp().  Since w32_showwindow is an internal variable
     * inside the thread_intern structure, the MSWin32 implementation
     * lives in win32/win32.c in the core Perl distribution.
     */
    dXSARGS;
    XSRETURN_UNDEF;
}
#endif

XS(w32_GetCwd)
{
    dXSARGS;
    /* Make the host for current directory */
    char* ptr = PerlEnv_get_childdir();
    /*
     * If ptr != Nullch
     *   then it worked, set PV valid,
     *   else return 'undef'
     */
    if (ptr) {
	SV *sv = sv_newmortal();
	sv_setpv(sv, ptr);
	PerlEnv_free_childdir(ptr);

#ifndef INCOMPLETE_TAINTS
	SvTAINTED_on(sv);
#endif

	EXTEND(SP,1);
	SvPOK_on(sv);
	ST(0) = sv;
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

XS(w32_SetCwd)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::SetCurrentDirectory($cwd)");
    if (!PerlDir_chdir(SvPV_nolen(ST(0))))
	XSRETURN_YES;

    XSRETURN_NO;
}

XS(w32_GetNextAvailDrive)
{
    dXSARGS;
    char ix = 'C';
    char root[] = "_:\\";

    EXTEND(SP,1);
    while (ix <= 'Z') {
	root[0] = ix++;
	if (GetDriveType(root) == 1) {
	    root[2] = '\0';
	    XSRETURN_PV(root);
	}
    }
    XSRETURN_UNDEF;
}

XS(w32_GetLastError)
{
    dXSARGS;
    EXTEND(SP,1);
    XSRETURN_IV(GetLastError());
}

XS(w32_SetLastError)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::SetLastError($error)");
    SetLastError(SvIV(ST(0)));
    XSRETURN_EMPTY;
}

XS(w32_LoginName)
{
    dXSARGS;
    char name[128];
    DWORD size = sizeof(name);
    EXTEND(SP,1);
    if (GetUserName(name,&size)) {
	/* size includes NULL */
	ST(0) = sv_2mortal(newSVpvn(name,size-1));
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

XS(w32_NodeName)
{
    dXSARGS;
    char name[MAX_COMPUTERNAME_LENGTH+1];
    DWORD size = sizeof(name);
    EXTEND(SP,1);
    if (GetComputerName(name,&size)) {
	/* size does NOT include NULL :-( */
	ST(0) = sv_2mortal(newSVpvn(name,size));
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}


XS(w32_DomainName)
{
    dXSARGS;
    HINSTANCE hNetApi32 = LoadLibrary("netapi32.dll");
    DWORD (__stdcall *pfnNetApiBufferFree)(LPVOID Buffer);
    DWORD (__stdcall *pfnNetWkstaGetInfo)(LPWSTR servername, DWORD level,
					  void *bufptr);

    if (hNetApi32) {
	pfnNetApiBufferFree = (DWORD (__stdcall *)(void *))
	    GetProcAddress(hNetApi32, "NetApiBufferFree");
	pfnNetWkstaGetInfo = (DWORD (__stdcall *)(LPWSTR, DWORD, void *))
	    GetProcAddress(hNetApi32, "NetWkstaGetInfo");
    }
    EXTEND(SP,1);
    if (hNetApi32 && pfnNetWkstaGetInfo && pfnNetApiBufferFree) {
	/* this way is more reliable, in case user has a local account. */
	char dname[256];
	DWORD dnamelen = sizeof(dname);
	struct {
	    DWORD   wki100_platform_id;
	    LPWSTR  wki100_computername;
	    LPWSTR  wki100_langroup;
	    DWORD   wki100_ver_major;
	    DWORD   wki100_ver_minor;
	} *pwi;
	/* NERR_Success *is* 0*/
	if (0 == pfnNetWkstaGetInfo(NULL, 100, &pwi)) {
	    if (pwi->wki100_langroup && *(pwi->wki100_langroup)) {
		WideCharToMultiByte(CP_ACP, 0, pwi->wki100_langroup,
				    -1, (LPSTR)dname, dnamelen, NULL, NULL);
	    }
	    else {
		WideCharToMultiByte(CP_ACP, 0, pwi->wki100_computername,
				    -1, (LPSTR)dname, dnamelen, NULL, NULL);
	    }
	    pfnNetApiBufferFree(pwi);
	    FreeLibrary(hNetApi32);
	    XSRETURN_PV(dname);
	}
	FreeLibrary(hNetApi32);
    }
    else {
	/* Win95 doesn't have NetWksta*(), so do it the old way */
	char name[256];
	DWORD size = sizeof(name);
	if (hNetApi32)
	    FreeLibrary(hNetApi32);
	if (GetUserName(name,&size)) {
	    char sid[ONE_K_BUFSIZE];
	    DWORD sidlen = sizeof(sid);
	    char dname[256];
	    DWORD dnamelen = sizeof(dname);
	    SID_NAME_USE snu;
	    if (LookupAccountName(NULL, name, (PSID)&sid, &sidlen,
				  dname, &dnamelen, &snu)) {
		XSRETURN_PV(dname);		/* all that for this */
	    }
	}
    }
    XSRETURN_UNDEF;
}

XS(w32_FsType)
{
    dXSARGS;
    char fsname[256];
    DWORD flags, filecomplen;
    if (GetVolumeInformation(NULL, NULL, 0, NULL, &filecomplen,
			 &flags, fsname, sizeof(fsname))) {
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSVpvn(fsname,strlen(fsname))));
	    XPUSHs(sv_2mortal(newSViv(flags)));
	    XPUSHs(sv_2mortal(newSViv(filecomplen)));
	    PUTBACK;
	    return;
	}
	EXTEND(SP,1);
	XSRETURN_PV(fsname);
    }
    XSRETURN_EMPTY;
}

XS(w32_GetOSVersion)
{
    dXSARGS;
    /* Use explicit struct definition because wSuiteMask and
     * wProductType are not defined in the VC++ 6.0 headers.
     * WORD type has been replaced by unsigned short because
     * WORD is already used by Perl itself.
     */
    struct {
        DWORD dwOSVersionInfoSize;
        DWORD dwMajorVersion;
        DWORD dwMinorVersion;
        DWORD dwBuildNumber;
        DWORD dwPlatformId;
        CHAR  szCSDVersion[128];
        unsigned short wServicePackMajor;
        unsigned short wServicePackMinor;
        unsigned short wSuiteMask;
        BYTE  wProductType;
        BYTE  wReserved;
    }   osver;
    BOOL bEx = TRUE;

    osver.dwOSVersionInfoSize = sizeof(osver);
    if (!GetVersionExA((OSVERSIONINFOA*)&osver)) {
        bEx = FALSE;
        osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFOA);
        if (!GetVersionExA((OSVERSIONINFOA*)&osver)) {
            XSRETURN_EMPTY;
        }
    }
    if (GIMME_V == G_SCALAR) {
        XSRETURN_IV(osver.dwPlatformId);
    }
    XPUSHs(newSVpvn(osver.szCSDVersion, strlen(osver.szCSDVersion)));

    XPUSHs(newSViv(osver.dwMajorVersion));
    XPUSHs(newSViv(osver.dwMinorVersion));
    XPUSHs(newSViv(osver.dwBuildNumber));
    XPUSHs(newSViv(osver.dwPlatformId));
    if (bEx) {
        XPUSHs(newSViv(osver.wServicePackMajor));
        XPUSHs(newSViv(osver.wServicePackMinor));
        XPUSHs(newSViv(osver.wSuiteMask));
        XPUSHs(newSViv(osver.wProductType));
    }
    PUTBACK;
}

XS(w32_IsWinNT)
{
    dXSARGS;
    EXTEND(SP,1);
    XSRETURN_IV(IsWinNT());
}

XS(w32_IsWin95)
{
    dXSARGS;
    EXTEND(SP,1);
    XSRETURN_IV(IsWin95());
}

XS(w32_FormatMessage)
{
    dXSARGS;
    DWORD source = 0;
    char msgbuf[ONE_K_BUFSIZE];

    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::FormatMessage($errno)");

    if (FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM,
                       &source, SvIV(ST(0)), 0,
                       msgbuf, sizeof(msgbuf)-1, NULL))
    {
        XSRETURN_PV(msgbuf);
    }

    XSRETURN_UNDEF;
}

XS(w32_Spawn)
{
    dXSARGS;
    char *cmd, *args;
    void *env;
    char *dir;
    PROCESS_INFORMATION stProcInfo;
    STARTUPINFO stStartInfo;
    BOOL bSuccess = FALSE;

    if (items != 3)
	Perl_croak(aTHX_ "usage: Win32::Spawn($cmdName, $args, $PID)");

    cmd = SvPV_nolen(ST(0));
    args = SvPV_nolen(ST(1));

    env = PerlEnv_get_childenv();
    dir = PerlEnv_get_childdir();

    memset(&stStartInfo, 0, sizeof(stStartInfo));   /* Clear the block */
    stStartInfo.cb = sizeof(stStartInfo);	    /* Set the structure size */
    stStartInfo.dwFlags = STARTF_USESHOWWINDOW;	    /* Enable wShowWindow control */
    stStartInfo.wShowWindow = SW_SHOWMINNOACTIVE;   /* Start min (normal) */

    if (CreateProcess(
		cmd,			/* Image path */
		args,	 		/* Arguments for command line */
		NULL,			/* Default process security */
		NULL,			/* Default thread security */
		FALSE,			/* Must be TRUE to use std handles */
		NORMAL_PRIORITY_CLASS,	/* No special scheduling */
		env,			/* Inherit our environment block */
		dir,			/* Inherit our currrent directory */
		&stStartInfo,		/* -> Startup info */
		&stProcInfo))		/* <- Process info (if OK) */
    {
	int pid = (int)stProcInfo.dwProcessId;
	if (IsWin95() && pid < 0)
	    pid = -pid;
	sv_setiv(ST(2), pid);
	CloseHandle(stProcInfo.hThread);/* library source code does this. */
	bSuccess = TRUE;
    }
    PerlEnv_free_childenv(env);
    PerlEnv_free_childdir(dir);
    XSRETURN_IV(bSuccess);
}

XS(w32_GetTickCount)
{
    dXSARGS;
    DWORD msec = GetTickCount();
    EXTEND(SP,1);
    if ((IV)msec > 0)
	XSRETURN_IV(msec);
    XSRETURN_NV(msec);
}

XS(w32_GetShortPathName)
{
    dXSARGS;
    SV *shortpath;
    DWORD len;

    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::GetShortPathName($longPathName)");

    shortpath = sv_mortalcopy(ST(0));
    SvUPGRADE(shortpath, SVt_PV);
    if (!SvPVX(shortpath) || !SvLEN(shortpath))
        XSRETURN_UNDEF;

    /* src == target is allowed */
    do {
	len = GetShortPathName(SvPVX(shortpath),
			       SvPVX(shortpath),
			       SvLEN(shortpath));
    } while (len >= SvLEN(shortpath) && sv_grow(shortpath,len+1));
    if (len) {
	SvCUR_set(shortpath,len);
	*SvEND(shortpath) = '\0';
	ST(0) = shortpath;
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

XS(w32_GetFullPathName)
{
    dXSARGS;
    SV *filename;
    SV *fullpath;
    char *filepart;
    DWORD len;
    STRLEN filename_len;
    char *filename_p;

    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::GetFullPathName($filename)");

    filename = ST(0);
    filename_p = SvPV(filename, filename_len);
    fullpath = sv_2mortal(newSVpvn(filename_p, filename_len));
    if (!SvPVX(fullpath) || !SvLEN(fullpath))
        XSRETURN_UNDEF;

    do {
	len = GetFullPathName(SvPVX(filename),
			      SvLEN(fullpath),
			      SvPVX(fullpath),
			      &filepart);
    } while (len >= SvLEN(fullpath) && sv_grow(fullpath,len+1));
    if (len) {
	if (GIMME_V == G_ARRAY) {
	    EXTEND(SP,1);
	    if (filepart) {
		XST_mPV(1,filepart);
		len = filepart - SvPVX(fullpath);
	    }
	    else {
		XST_mPVN(1,"",0);
	    }
	    items = 2;
	}
	SvCUR_set(fullpath,len);
	*SvEND(fullpath) = '\0';
	ST(0) = fullpath;
	XSRETURN(items);
    }
    XSRETURN_EMPTY;
}

XS(w32_GetLongPathName)
{
    dXSARGS;
    SV *path;
    char tmpbuf[MAX_PATH+1];
    char *pathstr;
    STRLEN len;

    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::GetLongPathName($pathname)");

    path = ST(0);
    pathstr = SvPV(path,len);
    strcpy(tmpbuf, pathstr);
    pathstr = win32_longpath(tmpbuf);
    if (pathstr) {
	ST(0) = sv_2mortal(newSVpvn(pathstr, strlen(pathstr)));
	XSRETURN(1);
    }
    XSRETURN_EMPTY;
}

XS(w32_Sleep)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "usage: Win32::Sleep($milliseconds)");
    Sleep(SvIV(ST(0)));
    XSRETURN_YES;
}

XS(w32_CopyFile)
{
    dXSARGS;
    BOOL bResult;
    char szSourceFile[MAX_PATH+1];

    if (items != 3)
	Perl_croak(aTHX_ "usage: Win32::CopyFile($from, $to, $overwrite)");
    strcpy(szSourceFile, PerlDir_mapA(SvPV_nolen(ST(0))));
    bResult = CopyFileA(szSourceFile, PerlDir_mapA(SvPV_nolen(ST(1))), !SvTRUE(ST(2)));
    if (bResult)
	XSRETURN_YES;
    XSRETURN_NO;
}

XS(boot_Win32)
{
    dXSARGS;
    char *file = __FILE__;

    if (g_osver.dwOSVersionInfoSize == 0) {
        g_osver.dwOSVersionInfoSize = sizeof(g_osver);
        GetVersionEx(&g_osver);
    }

    newXS("Win32::LookupAccountName", w32_LookupAccountName, file);
    newXS("Win32::LookupAccountSID", w32_LookupAccountSID, file);
    newXS("Win32::InitiateSystemShutdown", w32_InitiateSystemShutdown, file);
    newXS("Win32::AbortSystemShutdown", w32_AbortSystemShutdown, file);
    newXS("Win32::ExpandEnvironmentStrings", w32_ExpandEnvironmentStrings, file);
    newXS("Win32::MsgBox", w32_MsgBox, file);
    newXS("Win32::LoadLibrary", w32_LoadLibrary, file);
    newXS("Win32::FreeLibrary", w32_FreeLibrary, file);
    newXS("Win32::GetProcAddress", w32_GetProcAddress, file);
    newXS("Win32::RegisterServer", w32_RegisterServer, file);
    newXS("Win32::UnregisterServer", w32_UnregisterServer, file);
    newXS("Win32::GetArchName", w32_GetArchName, file);
    newXS("Win32::GetChipName", w32_GetChipName, file);
    newXS("Win32::GuidGen", w32_GuidGen, file);
    newXS("Win32::GetFolderPath", w32_GetFolderPath, file);
    newXS("Win32::IsAdminUser", w32_IsAdminUser, file);
    newXS("Win32::GetFileVersion", w32_GetFileVersion, file);

    newXS("Win32::GetCwd", w32_GetCwd, file);
    newXS("Win32::SetCwd", w32_SetCwd, file);
    newXS("Win32::GetNextAvailDrive", w32_GetNextAvailDrive, file);
    newXS("Win32::GetLastError", w32_GetLastError, file);
    newXS("Win32::SetLastError", w32_SetLastError, file);
    newXS("Win32::LoginName", w32_LoginName, file);
    newXS("Win32::NodeName", w32_NodeName, file);
    newXS("Win32::DomainName", w32_DomainName, file);
    newXS("Win32::FsType", w32_FsType, file);
    newXS("Win32::GetOSVersion", w32_GetOSVersion, file);
    newXS("Win32::IsWinNT", w32_IsWinNT, file);
    newXS("Win32::IsWin95", w32_IsWin95, file);
    newXS("Win32::FormatMessage", w32_FormatMessage, file);
    newXS("Win32::Spawn", w32_Spawn, file);
    newXS("Win32::GetTickCount", w32_GetTickCount, file);
    newXS("Win32::GetShortPathName", w32_GetShortPathName, file);
    newXS("Win32::GetFullPathName", w32_GetFullPathName, file);
    newXS("Win32::GetLongPathName", w32_GetLongPathName, file);
    newXS("Win32::CopyFile", w32_CopyFile, file);
    newXS("Win32::Sleep", w32_Sleep, file);
#ifdef __CYGWIN__
    newXS("Win32::SetChildShowWindow", w32_SetChildShowWindow, file);
#endif

    XSRETURN_YES;
}
