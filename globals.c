#include "INTERN.h"
#define PERL_IN_GLOBALS_C
#include "perl.h"

int
Perl_fprintf_nocontext(PerlIO *stream, const char *format, ...)
{
    dTHXs;
    va_list(arglist);
    va_start(arglist, format);
    return PerlIO_vprintf(stream, format, arglist);
}

int
Perl_printf_nocontext(const char *format, ...)
{
    dTHXs;
    va_list(arglist);
    va_start(arglist, format);
    return PerlIO_vprintf(PerlIO_stdout(), format, arglist);
}

#include "perlapi.h"		/* bring in PL_force_link_funcs */
