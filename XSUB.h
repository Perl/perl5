#define ST(off) PL_stack_base[ax + (off)]

#ifdef CAN_PROTOTYPE
#  ifdef PERL_OBJECT
#    define XS(name) void name(CV* cv, CPerlObj* pPerl)
#  else
#    define XS(name) void name(CV* cv)
#  endif
#else
#  define XS(name) void name(cv) CV* cv;
#endif

#define dXSARGS				\
	dSP; dMARK;			\
	I32 ax = mark - PL_stack_base + 1;	\
	I32 items = sp - mark

#define XSANY CvXSUBANY(cv)

#define dXSI32 I32 ix = XSANY.any_i32

#ifdef __cplusplus
#  define XSINTERFACE_CVT(ret,name) ret (*name)(...)
#else
#  define XSINTERFACE_CVT(ret,name) ret (*name)()
#endif
#define dXSFUNCTION(ret)		XSINTERFACE_CVT(ret,XSFUNCTION)
#define XSINTERFACE_FUNC(ret,cv,f)	((XSINTERFACE_CVT(ret,))(f))
#define XSINTERFACE_FUNC_SET(cv,f)	\
		CvXSUBANY(cv).any_dptr = (void (*) _((void*)))(f)

#define XSRETURN(off)					\
    STMT_START {					\
	PL_stack_sp = PL_stack_base + ax + ((off) - 1);	\
	return;						\
    } STMT_END

/* Simple macros to put new mortal values onto the stack.   */
/* Typically used to return values from XS functions.       */
#define XST_mIV(i,v)  (ST(i) = sv_2mortal(newSViv(v))  )
#define XST_mNV(i,v)  (ST(i) = sv_2mortal(newSVnv(v))  )
#define XST_mPV(i,v)  (ST(i) = sv_2mortal(newSVpv(v,0)))
#define XST_mNO(i)    (ST(i) = &PL_sv_no   )
#define XST_mYES(i)   (ST(i) = &PL_sv_yes  )
#define XST_mUNDEF(i) (ST(i) = &PL_sv_undef)
 
#define XSRETURN_IV(v) STMT_START { XST_mIV(0,v);  XSRETURN(1); } STMT_END
#define XSRETURN_NV(v) STMT_START { XST_mNV(0,v);  XSRETURN(1); } STMT_END
#define XSRETURN_PV(v) STMT_START { XST_mPV(0,v);  XSRETURN(1); } STMT_END
#define XSRETURN_NO    STMT_START { XST_mNO(0);    XSRETURN(1); } STMT_END
#define XSRETURN_YES   STMT_START { XST_mYES(0);   XSRETURN(1); } STMT_END
#define XSRETURN_UNDEF STMT_START { XST_mUNDEF(0); XSRETURN(1); } STMT_END
#define XSRETURN_EMPTY STMT_START {                XSRETURN(0); } STMT_END

#define newXSproto(a,b,c,d)	sv_setpv((SV*)newXS(a,b,c), d)

#ifdef XS_VERSION
#  define XS_VERSION_BOOTCHECK \
    STMT_START {							\
	SV *tmpsv; STRLEN n_a;						\
	char *vn = Nullch, *module = SvPV(ST(0),n_a);			\
	if (items >= 2)	 /* version supplied as bootstrap arg */	\
	    tmpsv = ST(1);						\
	else {								\
	    /* XXX GV_ADDWARN */					\
	    tmpsv = perl_get_sv(form("%s::%s", module,			\
				  vn = "XS_VERSION"), FALSE);		\
	    if (!tmpsv || !SvOK(tmpsv))					\
		tmpsv = perl_get_sv(form("%s::%s", module,		\
				      vn = "VERSION"), FALSE);		\
	}								\
	if (tmpsv && (!SvOK(tmpsv) || strNE(XS_VERSION, SvPV(tmpsv, n_a))))	\
	    croak("%s object version %s does not match %s%s%s%s %_",	\
		  module, XS_VERSION,					\
		  vn ? "$" : "", vn ? module : "", vn ? "::" : "",	\
		  vn ? vn : "bootstrap parameter", tmpsv);		\
    } STMT_END
#else
#  define XS_VERSION_BOOTCHECK
#endif

#ifdef PERL_CAPI
#  define VTBL_sv		get_vtbl(want_vtbl_sv)
#  define VTBL_env		get_vtbl(want_vtbl_env)
#  define VTBL_envelem		get_vtbl(want_vtbl_envelem)
#  define VTBL_sig		get_vtbl(want_vtbl_sig)
#  define VTBL_sigelem		get_vtbl(want_vtbl_sigelem)
#  define VTBL_pack		get_vtbl(want_vtbl_pack)
#  define VTBL_packelem		get_vtbl(want_vtbl_packelem)
#  define VTBL_dbline		get_vtbl(want_vtbl_dbline)
#  define VTBL_isa		get_vtbl(want_vtbl_isa)
#  define VTBL_isaelem		get_vtbl(want_vtbl_isaelem)
#  define VTBL_arylen		get_vtbl(want_vtbl_arylen)
#  define VTBL_glob		get_vtbl(want_vtbl_glob)
#  define VTBL_mglob		get_vtbl(want_vtbl_mglob)
#  define VTBL_nkeys		get_vtbl(want_vtbl_nkeys)
#  define VTBL_taint		get_vtbl(want_vtbl_taint)
#  define VTBL_substr		get_vtbl(want_vtbl_substr)
#  define VTBL_vec		get_vtbl(want_vtbl_vec)
#  define VTBL_pos		get_vtbl(want_vtbl_pos)
#  define VTBL_bm		get_vtbl(want_vtbl_bm)
#  define VTBL_fm		get_vtbl(want_vtbl_fm)
#  define VTBL_uvar		get_vtbl(want_vtbl_uvar)
#  define VTBL_defelem		get_vtbl(want_vtbl_defelem)
#  define VTBL_regexp		get_vtbl(want_vtbl_regexp)
#  define VTBL_regdata		get_vtbl(want_vtbl_regdata)
#  define VTBL_regdatum		get_vtbl(want_vtbl_regdatum)
#  ifdef USE_LOCALE_COLLATE
#    define VTBL_collxfrm	get_vtbl(want_vtbl_collxfrm)
#  endif
#  define VTBL_amagic		get_vtbl(want_vtbl_amagic)
#  define VTBL_amagicelem	get_vtbl(want_vtbl_amagicelem)
#else
#  define VTBL_sv		&PL_vtbl_sv
#  define VTBL_env		&PL_vtbl_env
#  define VTBL_envelem		&PL_vtbl_envelem
#  define VTBL_sig		&PL_vtbl_sig
#  define VTBL_sigelem		&PL_vtbl_sigelem
#  define VTBL_pack		&PL_vtbl_pack
#  define VTBL_packelem		&PL_vtbl_packelem
#  define VTBL_dbline		&PL_vtbl_dbline
#  define VTBL_isa		&PL_vtbl_isa
#  define VTBL_isaelem		&PL_vtbl_isaelem
#  define VTBL_arylen		&PL_vtbl_arylen
#  define VTBL_glob		&PL_vtbl_glob
#  define VTBL_mglob		&PL_vtbl_mglob
#  define VTBL_nkeys		&PL_vtbl_nkeys
#  define VTBL_taint		&PL_vtbl_taint
#  define VTBL_substr		&PL_vtbl_substr
#  define VTBL_vec		&PL_vtbl_vec
#  define VTBL_pos		&PL_vtbl_pos
#  define VTBL_bm		&PL_vtbl_bm
#  define VTBL_fm		&PL_vtbl_fm
#  define VTBL_uvar		&PL_vtbl_uvar
#  define VTBL_defelem		&PL_vtbl_defelem
#  define VTBL_regexp		&PL_vtbl_regexp
#  define VTBL_regdata		&PL_vtbl_regdata
#  define VTBL_regdatum		&PL_vtbl_regdatum
#  ifdef USE_LOCALE_COLLATE
#    define VTBL_collxfrm	&PL_vtbl_collxfrm
#  endif
#  define VTBL_amagic		&PL_vtbl_amagic
#  define VTBL_amagicelem	&PL_vtbl_amagicelem
#endif

#ifdef PERL_OBJECT
#  include "objXSUB.h"

#  undef  PERL_OBJECT_THIS
#  define PERL_OBJECT_THIS pPerl
#  undef  PERL_OBJECT_THIS_
#  define PERL_OBJECT_THIS_ pPerl,

#  undef  SAVEDESTRUCTOR
#  define SAVEDESTRUCTOR(f,p) \
	pPerl->Perl_save_destructor((FUNC_NAME_TO_PTR(f)),(p))

#  ifdef WIN32
#    ifndef WIN32IO_IS_STDIO
#      undef	errno
#      define	errno			ErrorNo()
#    endif
#    undef  ErrorNo
#    define ErrorNo			pPerl->ErrorNo
#    undef  NtCrypt
#    define NtCrypt			pPerl->NtCrypt
#    undef  NtGetLib
#    define NtGetLib			pPerl->NtGetLib
#    undef  NtGetArchLib
#    define NtGetArchLib		pPerl->NtGetArchLib
#    undef  NtGetSiteLib
#    define NtGetSiteLib		pPerl->NtGetSiteLib
#    undef  NtGetBin
#    define NtGetBin			pPerl->NtGetBin
#    undef  NtGetDebugScriptStr
#    define NtGetDebugScriptStr		pPerl->NtGetDebugScriptStr
#  endif /* WIN32 */

#  ifndef NO_XSLOCKS
#    undef closedir
#    undef opendir
#    undef stdin
#    undef stdout
#    undef stderr
#    undef feof
#    undef ferror
#    undef fgetpos
#    undef ioctl
#    undef getlogin
#    undef setjmp
#    undef getc
#    undef ungetc
#    undef fileno

#    define mkdir		PerlDir_mkdir
#    define chdir		PerlDir_chdir
#    define rmdir		PerlDir_rmdir
#    define closedir		PerlDir_close
#    define opendir		PerlDir_open
#    define readdir		PerlDir_read
#    define rewinddir		PerlDir_rewind
#    define seekdir		PerlDir_seek
#    define telldir		PerlDir_tell
#    define putenv		PerlEnv_putenv
#    define getenv		PerlEnv_getenv
#    define stdin		PerlIO_stdin()
#    define stdout		PerlIO_stdout()
#    define stderr		PerlIO_stderr()
#    define fopen		PerlIO_open
#    define fclose		PerlIO_close
#    define feof		PerlIO_eof
#    define ferror		PerlIO_error
#    define fclearerr		PerlIO_clearerr
#    define getc		PerlIO_getc
#    define fputc(c, f)		PerlIO_putc(f,c)
#    define fputs(s, f)		PerlIO_puts(f,s)
#    define fflush		PerlIO_flush
#    define ungetc(c, f)	PerlIO_ungetc((f),(c))
#    define fileno		PerlIO_fileno
#    define fdopen		PerlIO_fdopen
#    define freopen		PerlIO_reopen
#    define fread(b,s,c,f)	PerlIO_read((f),(b),(s*c))
#    define fwrite(b,s,c,f)	PerlIO_write((f),(b),(s*c))
#    define setbuf		PerlIO_setbuf
#    define setvbuf		PerlIO_setvbuf
#    define setlinebuf		PerlIO_setlinebuf
#    define stdoutf		PerlIO_stdoutf
#    define vfprintf		PerlIO_vprintf
#    define ftell		PerlIO_tell
#    define fseek		PerlIO_seek
#    define fgetpos		PerlIO_getpos
#    define fsetpos		PerlIO_setpos
#    define frewind		PerlIO_rewind
#    define tmpfile		PerlIO_tmpfile
#    define access		PerlLIO_access
#    define chmod		PerlLIO_chmod
#    define chsize		PerlLIO_chsize
#    define close		PerlLIO_close
#    define dup			PerlLIO_dup
#    define dup2		PerlLIO_dup2
#    define flock		PerlLIO_flock
#    define fstat		PerlLIO_fstat
#    define ioctl		PerlLIO_ioctl
#    define isatty		PerlLIO_isatty
#    define lseek		PerlLIO_lseek
#    define lstat		PerlLIO_lstat
#    define mktemp		PerlLIO_mktemp
#    define open		PerlLIO_open
#    define read		PerlLIO_read
#    define rename		PerlLIO_rename
#    define setmode		PerlLIO_setmode
#    define stat		PerlLIO_stat
#    define tmpnam		PerlLIO_tmpnam
#    define umask		PerlLIO_umask
#    define unlink		PerlLIO_unlink
#    define utime		PerlLIO_utime
#    define write		PerlLIO_write
#    define malloc		PerlMem_malloc
#    define realloc		PerlMem_realloc
#    define free		PerlMem_free
#    define abort		PerlProc_abort
#    define exit		PerlProc_exit
#    define _exit		PerlProc__exit
#    define execl		PerlProc_execl
#    define execv		PerlProc_execv
#    define execvp		PerlProc_execvp
#    define getuid		PerlProc_getuid
#    define geteuid		PerlProc_geteuid
#    define getgid		PerlProc_getgid
#    define getegid		PerlProc_getegid
#    define getlogin		PerlProc_getlogin
#    define kill		PerlProc_kill
#    define killpg		PerlProc_killpg
#    define pause		PerlProc_pause
#    define popen		PerlProc_popen
#    define pclose		PerlProc_pclose
#    define pipe		PerlProc_pipe
#    define setuid		PerlProc_setuid
#    define setgid		PerlProc_setgid
#    define sleep		PerlProc_sleep
#    define times		PerlProc_times
#    define wait		PerlProc_wait
#    define setjmp		PerlProc_setjmp
#    define longjmp		PerlProc_longjmp
#    define signal		PerlProc_signal
#    define htonl		PerlSock_htonl
#    define htons		PerlSock_htons
#    define ntohl		PerlSock_ntohl
#    define ntohs		PerlSock_ntohs
#    define accept		PerlSock_accept
#    define bind		PerlSock_bind
#    define connect		PerlSock_connect
#    define endhostent		PerlSock_endhostent
#    define endnetent		PerlSock_endnetent
#    define endprotoent		PerlSock_endprotoent
#    define endservent		PerlSock_endservent
#    define gethostbyaddr	PerlSock_gethostbyaddr
#    define gethostbyname	PerlSock_gethostbyname
#    define gethostent		PerlSock_gethostent
#    define gethostname		PerlSock_gethostname
#    define getnetbyaddr	PerlSock_getnetbyaddr
#    define getnetbyname	PerlSock_getnetbyname
#    define getnetent		PerlSock_getnetent
#    define getpeername		PerlSock_getpeername
#    define getprotobyname	PerlSock_getprotobyname
#    define getprotobynumber	PerlSock_getprotobynumber
#    define getprotoent		PerlSock_getprotoent
#    define getservbyname	PerlSock_getservbyname
#    define getservbyport	PerlSock_getservbyport
#    define getservent		PerlSock_getservent
#    define getsockname		PerlSock_getsockname
#    define getsockopt		PerlSock_getsockopt
#    define inet_addr		PerlSock_inet_addr
#    define inet_ntoa		PerlSock_inet_ntoa
#    define listen		PerlSock_listen
#    define recv		PerlSock_recv
#    define recvfrom		PerlSock_recvfrom
#    define select		PerlSock_select
#    define send		PerlSock_send
#    define sendto		PerlSock_sendto
#    define sethostent		PerlSock_sethostent
#    define setnetent		PerlSock_setnetent
#    define setprotoent		PerlSock_setprotoent
#    define setservent		PerlSock_setservent
#    define setsockopt		PerlSock_setsockopt
#    define shutdown		PerlSock_shutdown
#    define socket		PerlSock_socket
#    define socketpair		PerlSock_socketpair

#    ifdef WIN32
#      include "XSlock.h"
#    endif  /* WIN32 */
#  endif  /* NO_XSLOCKS */
#else
#  ifdef PERL_CAPI
#    include "perlCAPI.h"
#  endif
#endif	/* PERL_OBJECT */
