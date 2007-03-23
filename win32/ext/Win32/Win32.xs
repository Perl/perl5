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

XS(boot_Win32)
{
    dXSARGS;
    char *file = __FILE__;

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

    XSRETURN_YES;
}
