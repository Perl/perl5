/* dl_dyld.xs
 *
 * Platform:	Darwin (Mac OS)
 * Author:	Wilfredo Sanchez <wsanchez@apple.com>
 * Based on:	dl_next.xs by Paul Marquess
 * Based on:	dl_dlopen.xs by Anno Siegel
 * Created:	Aug 15th, 1994
 *
 */

/*
 *  And Gandalf said: 'Many folk like to know beforehand what is to
 *  be set on the table; but those who have laboured to prepare the
 *  feast like to keep their secret; for wonder makes the words of
 *  praise louder.'
 *
 *     [p.970 of _The Lord of the Rings_, VI/v: "The Steward and the King"]
 */

/* Porting notes:

dl_dyld.xs is based on dl_next.xs by Anno Siegel.

dl_next.xs is in turn a port from dl_dlopen.xs by Paul Marquess.  It
should not be used as a base for further ports though it may be used
as an example for how dl_dlopen.xs can be ported to other platforms.

The method used here is just to supply the sun style dlopen etc.
functions in terms of NeXT's/Apple's dyld.  The xs code proper is
unchanged from Paul's original.

The port could use some streamlining.  For one, error handling could
be simplified.

This should be useable as a replacement for dl_next.xs, but it has not
been tested on NeXT platforms.

  Wilfredo Sanchez

*/

#define PERL_EXT
#include "EXTERN.h"
#define PERL_IN_DL_DYLD_XS
#include "perl.h"
#include "XSUB.h"

#include "dlutils.c"	/* for SaveError() etc */

#undef environ
#undef bool
#import <mach-o/dyld.h>

static char *dlerror()
{
    dTHX;
    dMY_CXT;
    return dl_last_error;
}

static int dlclose(void *handle) /* stub only */
{
    return 0;
}

enum dyldErrorSource
{
    OFImage,
};

static void TranslateError
    (const char *path, enum dyldErrorSource type, int number)
{
    dTHX;
    dMY_CXT;
    char *error;
    unsigned int index;
    static char *OFIErrorStrings[] =
    {
	"%s(%d): Object Image Load Failure\n",
	"%s(%d): Object Image Load Success\n",
	"%s(%d): Not a recognisable object file\n",
	"%s(%d): No valid architecture\n",
	"%s(%d): Object image has an invalid format\n",
	"%s(%d): Invalid access (permissions?)\n",
	"%s(%d): Unknown error code from NSCreateObjectFileImageFromFile\n",
    };
#define NUM_OFI_ERRORS (sizeof(OFIErrorStrings) / sizeof(OFIErrorStrings[0]))

    switch (type)
    {
    case OFImage:
	index = number;
	if (index > NUM_OFI_ERRORS - 1)
	    index = NUM_OFI_ERRORS - 1;
	error = Perl_form_nocontext(OFIErrorStrings[index], path, number);
	break;

    default:
	error = Perl_form_nocontext("%s(%d): Totally unknown error type %d\n",
		     path, number, type);
	break;
    }
    sv_setpv(MY_CXT.x_dl_last_error, error);
}

static char *dlopen(char *path)
{
    int dyld_result;
    NSObjectFileImage ofile;
    NSModule handle = NULL;

    dyld_result = NSCreateObjectFileImageFromFile(path, &ofile);
    if (dyld_result != NSObjectFileImageSuccess)
	TranslateError(path, OFImage, dyld_result);
    else
    {
    	// NSLinkModule will cause the run to abort on any link errors
	// not very friendly but the error recovery functionality is limited.
	handle = NSLinkModule(ofile, path, TRUE);
	NSDestroyObjectFileImage(ofile);
    }

    return handle;
}

static void *
dlsym(void *handle, char *symbol)
{
    void *addr;

    if (NSIsSymbolNameDefined(symbol))
	addr = NSAddressOfSymbol(NSLookupAndBindSymbol(symbol));
    else
    	addr = NULL;

    return addr;
}



/* ----- code from dl_dlopen.xs below here ----- */


static void
dl_private_init(pTHX)
{
    (void)dl_generic_private_init(aTHX);
}

MODULE = DynaLoader     PACKAGE = DynaLoader

BOOT:
    (void)dl_private_init(aTHX);



void *
dl_load_file(filename, flags=0)
    char *	filename
    int		flags
    CODE:
    DLDEBUG(1,PerlIO_printf(Perl_debug_log, "dl_load_file(%s,%x):\n", filename,flags));
    if (flags & 0x01)
	Perl_warn(aTHX_ "Can't make loaded symbols global on this platform while loading %s",filename);
    RETVAL = dlopen(filename);
    DLDEBUG(2,PerlIO_printf(Perl_debug_log, " libref=%x\n", RETVAL));
    ST(0) = sv_newmortal() ;
    if (RETVAL == NULL)
	SaveError(aTHX_ "%s",dlerror()) ;
    else
	sv_setiv( ST(0), PTR2IV(RETVAL) );


void *
dl_find_symbol(libhandle, symbolname, ign_err=0)
    void *		libhandle
    char *		symbolname
    int	        	ign_err
    CODE:
    symbolname = Perl_form_nocontext("_%s", symbolname);
    DLDEBUG(2, PerlIO_printf(Perl_debug_log,
			     "dl_find_symbol(handle=%lx, symbol=%s)\n",
			     (unsigned long) libhandle, symbolname));
    RETVAL = dlsym(libhandle, symbolname);
    DLDEBUG(2, PerlIO_printf(Perl_debug_log,
			     "  symbolref = %lx\n", (unsigned long) RETVAL));
    ST(0) = sv_newmortal() ;
    if (RETVAL == NULL) {
        if (!ign_err)
	    SaveError(aTHX_ "%s",dlerror()) ;
    } else
	sv_setiv( ST(0), PTR2IV(RETVAL) );


void
dl_undef_symbols()
    PPCODE:



# These functions should not need changing on any platform:

void
dl_install_xsub(perl_name, symref, filename="$Package")
    char *	perl_name
    void *	symref
    const char *	filename
    CODE:
    DLDEBUG(2,PerlIO_printf(Perl_debug_log, "dl_install_xsub(name=%s, symref=%x)\n",
	    perl_name, symref));
    ST(0) = sv_2mortal(newRV((SV*)newXS_flags(perl_name,
					      (void(*)(pTHX_ CV *))symref,
					      filename, NULL,
					      XS_DYNAMIC_FILENAME)));


SV *
dl_error()
    CODE:
    dMY_CXT;
    RETVAL = newSVsv(MY_CXT.x_dl_last_error);
    OUTPUT:
    RETVAL

#if defined(USE_ITHREADS)

void
CLONE(...)
    CODE:
    MY_CXT_CLONE;

    PERL_UNUSED_VAR(items);

    /* MY_CXT_CLONE just does a memcpy on the whole structure, so to avoid
     * using Perl variables that belong to another thread, we create our 
     * own for this thread.
     */
    MY_CXT.x_dl_last_error = newSVpvs("");

#endif

# end.
