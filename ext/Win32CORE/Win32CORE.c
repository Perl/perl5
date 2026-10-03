/*    Win32CORE.c
 *
 *    Copyright (C) 2007 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#if defined(__CYGWIN__) && !defined(USEIMPORTLIB)
  #undef WIN32
#endif

#define PERL_NO_GET_CONTEXT
#define PERL_IN_WIN32CORE_C
/* newXS_len_flags() isn't exported, but this XS module is never a .dll file */
#define PERL_CORE

#include "EXTERN.h"
#if defined(__CYGWIN__) && !defined(USEIMPORTLIB)
  #define EXTCONST extern const
#endif
#include "perl.h"
#include "XSUB.h"


/* this struct is currently around 0x169 bytes long */
static const struct {
    char Win32__GetCwd [sizeof("Win32::GetCwd")];
    char Win32__SetCwd [sizeof("Win32::SetCwd")];
    char Win32__GetNextAvailDrive [sizeof("Win32::GetNextAvailDrive")];
    char Win32__GetLastError [sizeof("Win32::GetLastError")];
    char Win32__SetLastError [sizeof("Win32::SetLastError")];
    char Win32__LoginName [sizeof("Win32::LoginName")];
    char Win32__NodeName [sizeof("Win32::NodeName")];
    char Win32__DomainName [sizeof("Win32::DomainName")];
    char Win32__FsType [sizeof("Win32::FsType")];
    char Win32__GetOSVersion [sizeof("Win32::GetOSVersion")];
    char Win32__IsWinNT [sizeof("Win32::IsWinNT")];
    char Win32__IsWin95 [sizeof("Win32::IsWin95")];
    char Win32__FormatMessage [sizeof("Win32::FormatMessage")];
    char Win32__Spawn [sizeof("Win32::Spawn")];
    char Win32__GetTickCount [sizeof("Win32::GetTickCount")];
    char Win32__GetShortPathName [sizeof("Win32::GetShortPathName")];
    char Win32__GetFullPathName [sizeof("Win32::GetFullPathName")];
    char Win32__GetLongPathName [sizeof("Win32::GetLongPathName")];
    char Win32__CopyFile [sizeof("Win32::CopyFile")];
    char Win32__Sleep [sizeof("Win32::Sleep")];
} fnname_table = {
    "Win32::GetCwd",
    "Win32::SetCwd",
    "Win32::GetNextAvailDrive",
    "Win32::GetLastError",
    "Win32::SetLastError",
    "Win32::LoginName",
    "Win32::NodeName",
    "Win32::DomainName",
    "Win32::FsType",
    "Win32::GetOSVersion",
    "Win32::IsWinNT",
    "Win32::IsWin95",
    "Win32::FormatMessage",
    "Win32::Spawn",
    "Win32::GetTickCount",
    "Win32::GetShortPathName",
    "Win32::GetFullPathName",
    "Win32::GetLongPathName",
    "Win32::CopyFile",
    "Win32::Sleep"
};

static const unsigned char fnname_lens [] = {
    sizeof("Win32::GetCwd"),
    sizeof("Win32::SetCwd"),
    sizeof("Win32::GetNextAvailDrive"),
    sizeof("Win32::GetLastError"),
    sizeof("Win32::SetLastError"),
    sizeof("Win32::LoginName"),
    sizeof("Win32::NodeName"),
    sizeof("Win32::DomainName"),
    sizeof("Win32::FsType"),
    sizeof("Win32::GetOSVersion"),
    sizeof("Win32::IsWinNT"),
    sizeof("Win32::IsWin95"),
    sizeof("Win32::FormatMessage"),
    sizeof("Win32::Spawn"),
    sizeof("Win32::GetTickCount"),
    sizeof("Win32::GetShortPathName"),
    sizeof("Win32::GetFullPathName"),
    sizeof("Win32::GetLongPathName"),
    sizeof("Win32::CopyFile"),
    sizeof("Win32::Sleep")
};

/* w32_CORE_all()'s XS_ANY member has a packed U32.
   Low U16 is ptr offset to a U8 length, U8 length includes '\0'.
   High U16 is ptr offset to 1st char of the null terminated string. */

XS(w32_CORE_all){
    /* capture the XSANY value before Perl_load_module, the CV's any member will
     * be overwritten by Perl_load_module and subsequent newXSes or pure perl
     * subs
     */
    U32 pack = XSANY.any_u32; /* CV* cv is never used again after here */
    /* I'd use dSAVE_ERRNO() here, but it doesn't save the Win32 error code
     * under cygwin, if that changes this code should change to use that.
     */
    int saved_errno = errno;
    DWORD err = GetLastError();
    Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs_share("Win32"), newSVnv(0.27));
    Size_t lenp = PTR2nat(&fnname_lens) + PTR2nat((U16)pack);
    const unsigned char * len = NUM2PTR(const unsigned char *, lenp);
    unsigned char function_len = (*len)-1; /* remove '\0' */
    Size_t pvp = PTR2nat(&fnname_table) + PTR2nat((U16)((U32)(pack >> 16)));
    const char *function = NUM2PTR(const char *, pvp);
    /* Prior code here called call_pv() which has GV_ADD, so just keep it. */
    CV* new_cv = get_cvn_flags(function, function_len, GV_ADD);
    SetLastError(err);
    errno = saved_errno;
    /* mark and SP from caller are passed through unchanged */
    call_sv(MUTABLE_SV(new_cv), GIMME_V);
}

#ifdef __cplusplus
extern "C"
#endif
XS_EXTERNAL(boot_Win32CORE)
{
    /* This function only exists because writemain.SH, lib/ExtUtils/Embed.pm
     * and win32/buildext.pl will all generate references to it.  The function
     * should never be called though, as Win32CORE.pm doesn't use DynaLoader.
     */
    PERL_UNUSED_ARG(cv);
}

/* init_Win32CORE() has been exported from perl5xx.dll for many years,
   for reasons not fully understood. Possibly because in very old WinPerls,
   perl5xx.dll did not export Perl_init_os_extras(), because it is assumed all
   embedders of libperl will create and pass their own func ptr to their
   implementation of Perl_init_os_extras(). Another reason could be at
   CC .c->.obj time, it is unknown if win32/win32.c will be part of
   a full sized full static perl.exe without an export table, and without
   a DynaLoader.xs, and [bizzare end user] without a Win32.pm/Win32.xs from CPAN
   or will be part of perl5xx.dll. */

EXTERN_C
#if !defined(__CYGWIN__) || defined(USEIMPORTLIB)
__declspec(dllexport)
#endif
void
init_Win32CORE(pTHX)
{
    /* This function is called from init_os_extras().  The Perl interpreter
     * is not yet fully initialized, so don't do anything fancy in here.
     */
    const unsigned char * len = (const unsigned char *)&fnname_lens;
    const char * function = (char *)&fnname_table;
    while (function < (char *)&fnname_table + sizeof(fnname_table)) {
        const char * const file = __FILE__;
        unsigned char name_len = *len;
        name_len -= 1;
        /* XXX TODO Win32CORE should really use RV2CV optimization for stubs
           https://github.com/Perl/perl5/issues/23131  XXX */
        /* skip a strlen(), newXS_len_flags() isn't exported from perl5xx.dll */
        CV* cv = newXS_len_flags(function, name_len, w32_CORE_all, file, NULL, 0, 0);
        U16 len_off = PTR2nat(len) - PTR2nat(&fnname_lens);
        U16 fn_off = PTR2nat(function) - PTR2nat(&fnname_table);
        U32 pack = (fn_off << 16) | len_off;
        XSANY.any_u32 = pack;
        function += *len++;
    }

    /* Don't forward Win32::SetChildShowWindow().  It accesses the internal variable
     * w32_showwindow in thread_intern and is therefore not implemented in Win32.xs.
     */
    /* newXS("Win32::SetChildShowWindow", w32_SetChildShowWindow, file); */
}
