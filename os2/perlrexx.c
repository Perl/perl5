#define INCL_DOSPROCESS
#define INCL_DOSSEMAPHORES
#define INCL_DOSMODULEMGR
#define INCL_DOSMISC
#define INCL_DOSEXCEPTIONS
#define INCL_DOSERRORS
#define INCL_REXXSAA
#include <os2.h>

/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef OEMVS
#ifdef MYMALLOC
/* sbrk is limited to first heap segement so make it big */
#pragma runopts(HEAP(8M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#else
#pragma runopts(HEAP(2M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#endif
#endif


#include "EXTERN.h"
#include "perl.h"

static void xs_init (pTHX);
static PerlInterpreter *my_perl;

#if defined (__MINT__) || defined (atarist)
/* The Atari operating system doesn't have a dynamic stack.  The
   stack size is determined from this value.  */
long _stksize = 64 * 1024;
#endif

/* Register any extra external extensions */

/* Do not delete this line--writemain depends on it */
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void
xs_init(pTHX)
{
    char *file = __FILE__;
    dXSUB_SYS;
        newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

int perlos2_is_inited;

static void
init_perlos2(void)
{
/*    static char *env[1] = {NULL};	*/

    Perl_OS2_init3(0, 0, 0);
}

static int
init_perl(int doparse)
{
    int exitstatus;
    char *argv[3] = {"perl_in_REXX", "-e", ""};

    if (!perlos2_is_inited) {
	perlos2_is_inited = 1;
	init_perlos2();
    }
    if (my_perl)
	return 1;
    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    return 0;
	perl_construct(my_perl);
	PL_perl_destruct_level = 1;
    }
    if (!doparse)
        return 1;
    exitstatus = perl_parse(my_perl, xs_init, 3, argv, (char **)NULL);
    return !exitstatus;
}

/* The REXX-callable entrypoints ... */

ULONG PERL (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    int exitstatus;
    char buf[256];
    char *argv[3] = {"perl_from_REXX", "-e", buf};
    ULONG ret;

    if (rargc != 1) {
	sprintf(retstr->strptr, "one argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (rargv[0].strlength >= sizeof(buf)) {
	sprintf(retstr->strptr,
		"length of the argument %ld exceeds the maximum %ld",
		rargv[0].strlength, (long)sizeof(buf) - 1);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }

    if (!init_perl(0))
	return 1;

    memcpy(buf, rargv[0].strptr, rargv[0].strlength);
    buf[rargv[0].strlength] = 0;
    
    exitstatus = perl_parse(my_perl, xs_init, 3, argv, (char **)NULL);
    if (!exitstatus) {
	exitstatus = perl_run(my_perl);
    }

    perl_destruct(my_perl);
    perl_free(my_perl);
    my_perl = 0;

    if (exitstatus)
	ret = 1;
    else {
	ret = 0;
	sprintf(retstr->strptr, "%s", "ok");
	retstr->strlength = strlen (retstr->strptr);
    }
    PERL_SYS_TERM1(0);
    return ret;
}

ULONG PERLEXIT (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no arguments expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    PERL_SYS_TERM1(0);
    return 0;
}

ULONG PERLTERM (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no arguments expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (!my_perl) {
	sprintf(retstr->strptr, "no perl interpreter present");
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    perl_destruct(my_perl);
    perl_free(my_perl);
    my_perl = 0;

    sprintf(retstr->strptr, "%s", "ok");
    retstr->strlength = strlen (retstr->strptr);
    return 0;
}


ULONG PERLINIT (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (!init_perl(1))
	return 1;

    sprintf(retstr->strptr, "%s", "ok");
    retstr->strlength = strlen (retstr->strptr);
    return 0;
}

ULONG PERLEVAL (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    SV *res, *in;
    STRLEN len;
    char *str;

    if (rargc != 1) {
	sprintf(retstr->strptr, "one argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }

    if (!init_perl(1))
	return 1;

  {
    dSP;
    int ret;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    in = sv_2mortal(newSVpvn(rargv[0].strptr, rargv[0].strlength));
    eval_sv(in, G_SCALAR);
    SPAGAIN;
    res = POPs;
    PUTBACK;

    ret = 0;
    if (SvTRUE(ERRSV) || !SvOK(res))
	ret = 1;
    str = SvPV(res, len);
    if (len <= 256			/* Default buffer is 256-char long */
	|| !DosAllocMem((PPVOID)&retstr->strptr, len,
			PAG_READ|PAG_WRITE|PAG_COMMIT)) {
	    memcpy(retstr->strptr, str, len);
	    retstr->strlength = len;
    } else
	ret = 1;

    FREETMPS;
    LEAVE;

    return ret;
  }
}
#define INCL_DOSPROCESS
#define INCL_DOSSEMAPHORES
#define INCL_DOSMODULEMGR
#define INCL_DOSMISC
#define INCL_DOSEXCEPTIONS
#define INCL_DOSERRORS
#define INCL_REXXSAA
#include <os2.h>

/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef OEMVS
#ifdef MYMALLOC
/* sbrk is limited to first heap segement so make it big */
#pragma runopts(HEAP(8M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#else
#pragma runopts(HEAP(2M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#endif
#endif


#include "EXTERN.h"
#include "perl.h"

static void xs_init (pTHX);
static PerlInterpreter *my_perl;

#if defined (__MINT__) || defined (atarist)
/* The Atari operating system doesn't have a dynamic stack.  The
   stack size is determined from this value.  */
long _stksize = 64 * 1024;
#endif

/* Register any extra external extensions */

/* Do not delete this line--writemain depends on it */
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void
xs_init(pTHX)
{
    char *file = __FILE__;
    dXSUB_SYS;
        newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

int perlos2_is_inited;

static void
init_perlos2(void)
{
/*    static char *env[1] = {NULL};	*/

    Perl_OS2_init3(0, 0, 0);
}

static int
init_perl(int doparse)
{
    int exitstatus;
    char *argv[3] = {"perl_in_REXX", "-e", ""};

    if (!perlos2_is_inited) {
	perlos2_is_inited = 1;
	init_perlos2();
    }
    if (my_perl)
	return 1;
    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    return 0;
	perl_construct(my_perl);
	PL_perl_destruct_level = 1;
    }
    if (!doparse)
        return 1;
    exitstatus = perl_parse(my_perl, xs_init, 3, argv, (char **)NULL);
    return !exitstatus;
}

/* The REXX-callable entrypoints ... */

ULONG PERL (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    int exitstatus;
    char buf[256];
    char *argv[3] = {"perl_from_REXX", "-e", buf};
    ULONG ret;

    if (rargc != 1) {
	sprintf(retstr->strptr, "one argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (rargv[0].strlength >= sizeof(buf)) {
	sprintf(retstr->strptr,
		"length of the argument %ld exceeds the maximum %ld",
		rargv[0].strlength, (long)sizeof(buf) - 1);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }

    if (!init_perl(0))
	return 1;

    memcpy(buf, rargv[0].strptr, rargv[0].strlength);
    buf[rargv[0].strlength] = 0;
    
    exitstatus = perl_parse(my_perl, xs_init, 3, argv, (char **)NULL);
    if (!exitstatus) {
	exitstatus = perl_run(my_perl);
    }

    perl_destruct(my_perl);
    perl_free(my_perl);
    my_perl = 0;

    if (exitstatus)
	ret = 1;
    else {
	ret = 0;
	sprintf(retstr->strptr, "%s", "ok");
	retstr->strlength = strlen (retstr->strptr);
    }
    PERL_SYS_TERM1(0);
    return ret;
}

ULONG PERLEXIT (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no arguments expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    PERL_SYS_TERM1(0);
    return 0;
}

ULONG PERLTERM (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no arguments expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (!my_perl) {
	sprintf(retstr->strptr, "no perl interpreter present");
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    perl_destruct(my_perl);
    perl_free(my_perl);
    my_perl = 0;

    sprintf(retstr->strptr, "%s", "ok");
    retstr->strlength = strlen (retstr->strptr);
    return 0;
}


ULONG PERLINIT (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    if (rargc != 0) {
	sprintf(retstr->strptr, "no argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }
    if (!init_perl(1))
	return 1;

    sprintf(retstr->strptr, "%s", "ok");
    retstr->strlength = strlen (retstr->strptr);
    return 0;
}

ULONG PERLEVAL (PCSZ name, LONG rargc, const RXSTRING *rargv,
                    PCSZ queuename, PRXSTRING retstr)
{
    SV *res, *in;
    STRLEN len;
    char *str;

    if (rargc != 1) {
	sprintf(retstr->strptr, "one argument expected, got %ld", rargc);
	retstr->strlength = strlen (retstr->strptr);
	return 1;
    }

    if (!init_perl(1))
	return 1;

  {
    dSP;
    int ret;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    in = sv_2mortal(newSVpvn(rargv[0].strptr, rargv[0].strlength));
    eval_sv(in, G_SCALAR);
    SPAGAIN;
    res = POPs;
    PUTBACK;

    ret = 0;
    if (SvTRUE(ERRSV) || !SvOK(res))
	ret = 1;
    str = SvPV(res, len);
    if (len <= 256			/* Default buffer is 256-char long */
	|| !DosAllocMem((PPVOID)&retstr->strptr, len,
			PAG_READ|PAG_WRITE|PAG_COMMIT)) {
	    memcpy(retstr->strptr, str, len);
	    retstr->strlength = len;
    } else
	ret = 1;

    FREETMPS;
    LEAVE;

    return ret;
  }
}
