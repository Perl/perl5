#include "EXTERN.h"
#define PERLIO_NOT_STDIO 1
#include "perl.h"
#include "XSUB.h"

#ifdef I_UNISTD
#  include <unistd.h>
#endif
#ifdef I_FCNTL
#  include <fcntl.h>
#endif

#ifdef PerlIO
typedef int SysRet;
typedef PerlIO * InputStream;
typedef PerlIO * OutputStream;
#else
#define PERLIO_IS_STDIO 1
typedef int SysRet;
typedef FILE * InputStream;
typedef FILE * OutputStream;
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static bool
constant(name, pval)
char *name;
IV *pval;
{
    switch (*name) {
    case '_':
	if (strEQ(name, "_IOFBF"))
#ifdef _IOFBF
	    { *pval = _IOFBF; return TRUE; }
#else
	    return FALSE;
#endif
	if (strEQ(name, "_IOLBF"))
#ifdef _IOLBF
	    { *pval = _IOLBF; return TRUE; }
#else
	    return FALSE;
#endif
	if (strEQ(name, "_IONBF"))
#ifdef _IONBF
	    { *pval = _IONBF; return TRUE; }
#else
	    return FALSE;
#endif
	break;
    case 'S':
	if (strEQ(name, "SEEK_SET"))
#ifdef SEEK_SET
	    { *pval = SEEK_SET; return TRUE; }
#else
	    return FALSE;
#endif
	if (strEQ(name, "SEEK_CUR"))
#ifdef SEEK_CUR
	    { *pval = SEEK_CUR; return TRUE; }
#else
	    return FALSE;
#endif
	if (strEQ(name, "SEEK_END"))
#ifdef SEEK_END
	    { *pval = SEEK_END; return TRUE; }
#else
	    return FALSE;
#endif
	break;
    }

    return FALSE;
}


MODULE = IO	PACKAGE = IO::Seekable	PREFIX = f

SV *
fgetpos(handle)
	InputStream	handle
    CODE:
	if (handle) {
	    Fpos_t pos;
#ifdef PerlIO
	    PerlIO_getpos(handle, &pos);
#else
	    fgetpos(handle, &pos);
#endif
	    ST(0) = sv_2mortal(newSVpv((char*)&pos, sizeof(Fpos_t)));
	}
	else {
	    ST(0) = &sv_undef;
	    errno = EINVAL;
	}

SysRet
fsetpos(handle, pos)
	InputStream	handle
	SV *		pos
    CODE:
	if (handle)
#ifdef PerlIO
	    RETVAL = PerlIO_setpos(handle, (Fpos_t*)SvPVX(pos));
#else
	    RETVAL = fsetpos(handle, (Fpos_t*)SvPVX(pos));
#endif
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
    OUTPUT:
	RETVAL

MODULE = IO	PACKAGE = IO::File	PREFIX = f

OutputStream
new_tmpfile(packname = "IO::File")
    char *		packname
    CODE:
#ifdef PerlIO
	RETVAL = PerlIO_tmpfile();
#else
	RETVAL = tmpfile();
#endif
    OUTPUT:
	RETVAL

MODULE = IO	PACKAGE = IO::Handle	PREFIX = f

SV *
constant(name)
	char *		name
    CODE:
	IV i;
	if (constant(name, &i))
	    ST(0) = sv_2mortal(newSViv(i));
	else
	    ST(0) = &sv_undef;

int
ungetc(handle, c)
	InputStream	handle
	int		c
    CODE:
	if (handle)
#ifdef PerlIO
	    RETVAL = PerlIO_ungetc(handle, c);
#else
	    RETVAL = ungetc(c, handle);
#endif
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
    OUTPUT:
	RETVAL

int
ferror(handle)
	InputStream	handle
    CODE:
	if (handle)
#ifdef PerlIO
	    RETVAL = PerlIO_error(handle);
#else
	    RETVAL = ferror(handle);
#endif
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
    OUTPUT:
	RETVAL

int
clearerr(handle)
	InputStream	handle
    CODE:
	if (handle) {
#ifdef PerlIO
	    PerlIO_clearerr(handle);
#else
	    clearerr(handle);
#endif
	    RETVAL = 0;
	}
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
    OUTPUT:
	RETVAL

SysRet
fflush(handle)
	OutputStream	handle
    CODE:
	if (handle)
#ifdef PerlIO
	    RETVAL = PerlIO_flush(handle);
#else
	    RETVAL = Fflush(handle);
#endif
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
    OUTPUT:
	RETVAL

void
setbuf(handle, buf)
	OutputStream	handle
	char *		buf = SvPOK(ST(1)) ? sv_grow(ST(1), BUFSIZ) : 0;
    CODE:
	if (handle)
#ifdef PERLIO_IS_STDIO
	    setbuf(handle, buf);
#else
	    not_here("IO::Handle::setbuf");
#endif

SysRet
setvbuf(handle, buf, type, size)
	OutputStream	handle
	char *		buf = SvPOK(ST(1)) ? sv_grow(ST(1), SvIV(ST(3))) : 0;
	int		type
	int		size
    CODE:
#ifdef PERLIO_IS_STDIO
#ifdef _IOFBF   /* Should be HAS_SETVBUF once Configure tests for that */
	if (handle)
	    RETVAL = setvbuf(handle, buf, type, size);
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
#else
	    RETVAL = (SysRet) not_here("IO::Handle::setvbuf");
#endif /* _IOFBF */
#else
	    not_here("IO::Handle::setvbuf");
#endif
    OUTPUT:
	RETVAL


