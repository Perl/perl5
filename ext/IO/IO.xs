#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef I_UNISTD
#  include <unistd.h>
#endif

typedef int SysRet;
typedef FILE * InputStream;
typedef FILE * OutputStream;

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
	if (strEQ(name, "SEEK_EOF"))
#ifdef SEEK_EOF
	    { *pval = SEEK_EOF; return TRUE; }
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
#ifdef HAS_FGETPOS
	if (handle) {
	    Fpos_t pos;
	    fgetpos(handle, &pos);
	    ST(0) = sv_2mortal(newSVpv((char*)&pos, sizeof(Fpos_t)));
	}
	else {
	    ST(0) = &sv_undef;
	    errno = EINVAL;
	}
#else
	ST(0) = (SV *) not_here("IO::Seekable::fgetpos");
#endif

SysRet
fsetpos(handle, pos)
	InputStream	handle
	SV *		pos
    CODE:
#ifdef HAS_FSETPOS
	if (handle)
	    RETVAL = fsetpos(handle, (Fpos_t*)SvPVX(pos));
	else {
	    RETVAL = -1;
	    errno = EINVAL;
	}
#else
	    RETVAL = (SysRet) not_here("IO::Seekable::fsetpos");
#endif
    OUTPUT:
	RETVAL

MODULE = IO	PACKAGE = IO::File	PREFIX = f

OutputStream
new_tmpfile(packname = "IO::File")
    char *		packname
    CODE:
	RETVAL = tmpfile();
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
	    RETVAL = ungetc(c, handle);
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
	    RETVAL = ferror(handle);
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
	    RETVAL = Fflush(handle);
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
	    setbuf(handle, buf);



SysRet
setvbuf(handle, buf, type, size)
	OutputStream	handle
	char *		buf = SvPOK(ST(1)) ? sv_grow(ST(1), SvIV(ST(3))) : 0;
	int		type
	int		size
    CODE:
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
    OUTPUT:
	RETVAL


