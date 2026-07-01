MODULE = XS::APItest            PACKAGE = XS::APItest::Backrefs

void
apitest_weaken(SV *sv)
    PROTOTYPE: $
    CODE:
        sv_rvweaken(sv);

SV *
has_backrefs(SV *sv)
    CODE:
        if (SvROK(sv) && sv_get_backrefs(SvRV(sv)))
            RETVAL = &PL_sv_yes;
        else
            RETVAL = &PL_sv_no;
    OUTPUT:
        RETVAL

#ifdef WIN32
#ifdef PERL_IMPLICIT_SYS

const char *
PerlDir_mapA(const char *path)

const WCHAR *
PerlDir_mapW(const WCHAR *wpath)

#endif

void
Comctl32Version()
    PREINIT:
        HMODULE dll;
        VS_FIXEDFILEINFO *info;
        UINT len;
        HRSRC hrsc;
        HGLOBAL ver;
        void * vercopy;
    PPCODE:
        dll = GetModuleHandle("comctl32.dll"); /* must already be in proc */
        if(!dll)
            croak("Comctl32Version: comctl32.dll not in process???");
        hrsc = FindResource(dll,    MAKEINTRESOURCE(VS_VERSION_INFO),
                                    MAKEINTRESOURCE((Size_t)VS_FILE_INFO));
        if(!hrsc)
            croak("Comctl32Version: comctl32.dll no version???");
        ver = LoadResource(dll, hrsc);
        len = SizeofResource(dll, hrsc);
        vercopy = (void *)sv_grow(sv_newmortal(),len);
        memcpy(vercopy, ver, len);
        if (VerQueryValue(vercopy, "\\", (void**)&info, &len)) {
            int dwValueMS1 = (info->dwFileVersionMS>>16);
            int dwValueMS2 = (info->dwFileVersionMS&0xffff);
            int dwValueLS1 = (info->dwFileVersionLS>>16);
            int dwValueLS2 = (info->dwFileVersionLS&0xffff);
            EXTEND(SP, 4);
            mPUSHi(dwValueMS1);
            mPUSHi(dwValueMS2);
            mPUSHi(dwValueLS1);
            mPUSHi(dwValueLS2);
        }

#endif
