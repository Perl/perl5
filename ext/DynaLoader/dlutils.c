/* dlutils.c - handy functions and definitions for dl_*.xs files
 *
 * Currently this file is simply #included into dl_*.xs/.c files.
 * It should really be split into a dlutils.h and dlutils.c
 *
 * Modified:
 * 29th Feburary 2000 - Alan Burlison: Added functionality to close dlopen'd
 *                      files when the interpreter exits
 */

#define MY_CXT_KEY "DynaLoader_guts"

typedef struct {
    char *	x_dl_last_error;	/* pointer to allocated memory for
					   last error message */
    int		x_dl_nonlazy;		/* flag for immediate rather than lazy
					   linking (spots unresolved symbol) */
#ifdef DL_LOADONCEONLY
    HV *	x_dl_loaded_files;	/* only needed on a few systems */
#endif
#ifdef DL_CXT_EXTRA
    my_cxtx_t	x_dl_cxtx;		/* extra platform-specific data */
#endif
#ifdef DEBUGGING
    int		x_dl_debug;	/* value copied from $DynaLoader::dl_debug */
#endif
} my_cxt_t;

/* XXX most of this is boilerplate code that should abstracted further into
 * macros and exposed via XSUB.h */

#if defined(USE_ITHREADS)

#define dMY_CXT_SV \
	SV *my_cxt_sv = *hv_fetch(PL_modglobal, MY_CXT_KEY,		\
				  sizeof(MY_CXT_KEY)-1, TRUE)

/* we allocate my_cxt in a Perl SV so that it will be released when
 * the interpreter goes away */
#define dMY_CXT_INIT \
	dMY_CXT_SV;							\
	/* newSV() allocates one more than needed */			\
	my_cxt_t *my_cxt = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1));	\
	Zero(my_cxt, 1, my_cxt_t);					\
	sv_setuv(my_cxt_sv, (UV)my_cxt);

#define dMY_CXT	\
	dMY_CXT_SV;							\
	my_cxt_t *my_cxt = (my_cxt_t*)SvUV(my_cxt_sv)

#define dl_last_error	(my_cxt->x_dl_last_error)
#define dl_nonlazy	(my_cxt->x_dl_nonlazy)
#ifdef DL_LOADONCEONLY
#define dl_loaded_files	(my_cxt->x_dl_loaded_files)
#endif
#ifdef DL_CXT_EXTRA
#define dl_cxtx		(my_cxt->x_dl_cxtx)
#endif
#ifdef DEBUGGING
#define dl_debug	(my_cxt->x_dl_debug)
#endif

#else /* USE_ITHREADS */

static my_cxt_t my_cxt;

#define dMY_CXT_SV	dNOOP
#define dMY_CXT_INIT	dNOOP
#define dMY_CXT		dNOOP

#define dl_last_error	(my_cxt.x_dl_last_error)
#define dl_nonlazy	(my_cxt.x_dl_nonlazy)
#ifdef DL_LOADONCEONLY
#define dl_loaded_files	(my_cxt.x_dl_loaded_files)
#endif
#ifdef DL_CXT_EXTRA
#define dl_cxtx		(my_cxt.x_dl_cxtx)
#endif
#ifdef DEBUGGING
#define dl_debug	(my_cxt.x_dl_debug)
#endif

#endif /* !defined(USE_ITHREADS) */


#ifdef DEBUGGING
#define DLDEBUG(level,code) \
    STMT_START {					\
	dMY_CXT;					\
	if (dl_debug>=level) { code; }			\
    } STMT_END
#else
#define DLDEBUG(level,code)	NOOP
#endif

#ifdef DL_UNLOAD_ALL_AT_EXIT
/* Close all dlopen'd files */
static void
dl_unload_all_files(pTHX_ void *unused)
{
    CV *sub;
    AV *dl_librefs;
    SV *dl_libref;

    if ((sub = get_cv("DynaLoader::dl_unload_file", FALSE)) != NULL) {
        dl_librefs = get_av("DynaLoader::dl_librefs", FALSE);
        while ((dl_libref = av_pop(dl_librefs)) != &PL_sv_undef) {
           dSP;
           ENTER;
           SAVETMPS;
           PUSHMARK(SP);
           XPUSHs(sv_2mortal(dl_libref));
           PUTBACK;
           call_sv((SV*)sub, G_DISCARD | G_NODEBUG);
           FREETMPS;
           LEAVE;
        }
    }
}
#endif

static void
dl_generic_private_init(pTHX)	/* called by dl_*.xs dl_private_init() */
{
    char *perl_dl_nonlazy;
    dMY_CXT_INIT;

    dl_last_error = NULL;
    dl_nonlazy = 0;
#ifdef DL_LOADONCEONLY
    dl_loaded_files = Nullhv;
#endif
#ifdef DEBUGGING
    {
	SV *sv = get_sv("DynaLoader::dl_debug", 0);
	dl_debug = sv ? SvIV(sv) : 0;
    }
#endif
    if ( (perl_dl_nonlazy = getenv("PERL_DL_NONLAZY")) != NULL )
	dl_nonlazy = atoi(perl_dl_nonlazy);
    if (dl_nonlazy)
	DLDEBUG(1,PerlIO_printf(Perl_debug_log, "DynaLoader bind mode is 'non-lazy'\n"));
#ifdef DL_LOADONCEONLY
    if (!dl_loaded_files)
	dl_loaded_files = newHV(); /* provide cache for dl_*.xs if needed */
#endif
#ifdef DL_UNLOAD_ALL_AT_EXIT
    call_atexit(&dl_unload_all_files, (void*)0);
#endif
}


/* SaveError() takes printf style args and saves the result in dl_last_error */
static void
SaveError(pTHX_ char* pat, ...)
{
    dMY_CXT;
    va_list args;
    SV *msv;
    char *message;
    STRLEN len;

    /* This code is based on croak/warn, see mess() in util.c */

    va_start(args, pat);
    msv = vmess(pat, &args);
    va_end(args);

    message = SvPV(msv,len);
    len++;		/* include terminating null char */

    /* Allocate some memory for the error message */
    if (dl_last_error)
        dl_last_error = (char*)saferealloc(dl_last_error, len);
    else
        dl_last_error = (char*)safemalloc(len);

    /* Copy message into dl_last_error (including terminating null char) */
    strncpy(dl_last_error, message, len) ;
    DLDEBUG(2,PerlIO_printf(Perl_debug_log, "DynaLoader: stored error msg '%s'\n",dl_last_error));
}

