#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gdbm.h>
#include <fcntl.h>

typedef GDBM_FILE GDBM_File;

#define GDBM_BLOCKSIZE 0 /* gdbm defaults to stat blocksize */
#define gdbm_TIEHASH(dbtype, name, read_write, mode, fatal_func) \
	gdbm_open(name, GDBM_BLOCKSIZE, read_write, mode, fatal_func)

#define gdbm_FETCH(db,key)			gdbm_fetch(db,key)
#define gdbm_STORE(db,key,value,flags)		gdbm_store(db,key,value,flags)
#define gdbm_DELETE(db,key)			gdbm_delete(db,key)
#define gdbm_FIRSTKEY(db)			gdbm_firstkey(db)
#define gdbm_NEXTKEY(db,key)			gdbm_nextkey(db,key)
#define gdbm_EXISTS(db,key)			gdbm_exists(db,key)

typedef void (*FATALFUNC)();

static int
not_here(char *s)
{
    croak("GDBM_File::%s not implemented on this architecture", s);
    return -1;
}

/* GDBM allocates the datum with system malloc() and expects the user
 * to free() it.  So we either have to free() it immediately, or have
 * perl free() it when it deallocates the SV, depending on whether
 * perl uses malloc()/free() or not. */
static void
output_datum(SV *arg, char *str, int size)
{
#if !defined(MYMALLOC) || (defined(MYMALLOC) && defined(PERL_POLLUTE_MALLOC))
	sv_usepvn(arg, str, size);
#else
	sv_setpvn(arg, str, size);
	safesysfree(str);
#endif
}

/* Versions of gdbm prior to 1.7x might not have the gdbm_sync,
   gdbm_exists, and gdbm_setopt functions.  Apparently Slackware
   (Linux) 2.1 contains gdbm-1.5 (which dates back to 1991).
*/
#ifndef GDBM_FAST
#define gdbm_exists(db,key) not_here("gdbm_exists")
#define gdbm_sync(db) (void) not_here("gdbm_sync")
#define gdbm_setopt(db,optflag,optval,optlen) not_here("gdbm_setopt")
#endif

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	if (strEQ(name, "GDBM_CACHESIZE"))
#ifdef GDBM_CACHESIZE
	    return GDBM_CACHESIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_FAST"))
#ifdef GDBM_FAST
	    return GDBM_FAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_FASTMODE"))
#ifdef GDBM_FASTMODE
	    return GDBM_FASTMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_INSERT"))
#ifdef GDBM_INSERT
	    return GDBM_INSERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_NEWDB"))
#ifdef GDBM_NEWDB
	    return GDBM_NEWDB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_READER"))
#ifdef GDBM_READER
	    return GDBM_READER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_REPLACE"))
#ifdef GDBM_REPLACE
	    return GDBM_REPLACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_WRCREAT"))
#ifdef GDBM_WRCREAT
	    return GDBM_WRCREAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GDBM_WRITER"))
#ifdef GDBM_WRITER
	    return GDBM_WRITER;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = GDBM_File	PACKAGE = GDBM_File	PREFIX = gdbm_

double
constant(name,arg)
	char *		name
	int		arg


GDBM_File
gdbm_TIEHASH(dbtype, name, read_write, mode, fatal_func = (FATALFUNC)croak)
	char *		dbtype
	char *		name
	int		read_write
	int		mode
	FATALFUNC	fatal_func

void
gdbm_close(db)
	GDBM_File	db
	CLEANUP:

void
gdbm_DESTROY(db)
	GDBM_File	db
	CODE:
	gdbm_close(db);

datum
gdbm_FETCH(db, key)
	GDBM_File	db
	datum		key

int
gdbm_STORE(db, key, value, flags = GDBM_REPLACE)
	GDBM_File	db
	datum		key
	datum		value
	int		flags
    CLEANUP:
	if (RETVAL) {
	    if (RETVAL < 0 && errno == EPERM)
		croak("No write permission to gdbm file");
	    croak("gdbm store returned %d, errno %d, key \"%.*s\"",
			RETVAL,errno,key.dsize,key.dptr);
	    /* gdbm_clearerr(db); */
	}

int
gdbm_DELETE(db, key)
	GDBM_File	db
	datum		key

datum
gdbm_FIRSTKEY(db)
	GDBM_File	db

datum
gdbm_NEXTKEY(db, key)
	GDBM_File	db
	datum		key

int
gdbm_reorganize(db)
	GDBM_File	db


void
gdbm_sync(db)
	GDBM_File	db

int
gdbm_EXISTS(db, key)
	GDBM_File	db
	datum		key

int
gdbm_setopt (db, optflag, optval, optlen)
	GDBM_File	db
	int		optflag
	int		&optval
	int		optlen

