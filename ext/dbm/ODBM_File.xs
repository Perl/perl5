#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef NULL
#undef NULL
#endif
#include <dbm.h>

#include <fcntl.h>

typedef void* ODBM_File;

#define odbm_fetch(db,key)			fetch(key)
#define odbm_store(db,key,value,flags)		store(key,value)
#define odbm_delete(db,key)			delete(key)
#define odbm_firstkey(db)			firstkey()
#define odbm_nextkey(db,key)			nextkey(key)

static int dbmrefcnt;

#ifndef DBM_REPLACE
#define DBM_REPLACE 0
#endif

MODULE = ODBM_File	PACKAGE = ODBM_File	PREFIX = odbm_

ODBM_File
odbm_new(dbtype, filename, flags, mode)
	char *		dbtype
	char *		filename
	int		flags
	int		mode
	CODE:
	{
	    char tmpbuf[1025];
	    if (dbmrefcnt++)
		croak("Old dbm can only open one database");
	    sprintf(tmpbuf,"%s.dir",filename);
	    if (stat(tmpbuf, &statbuf) < 0) {
		if (flags & O_CREAT) {
		    if (mode < 0 || close(creat(tmpbuf,mode)) < 0)
			croak("ODBM_File: Can't create %s", filename);
		    sprintf(tmpbuf,"%s.pag",filename);
		    if (close(creat(tmpbuf,mode)) < 0)
			croak("ODBM_File: Can't create %s", filename);
		}
		else
		    croak("ODBM_FILE: Can't open %s", filename);
	    }
	    RETVAL = (void*)(dbminit(filename) >= 0 ? &dbmrefcnt : 0);
	    ST(0) = sv_mortalcopy(&sv_undef);
	    sv_setptrobj(ST(0), RETVAL, "ODBM_File");
	}

void
DESTROY(db)
	ODBM_File	db
	CODE:
	dbmrefcnt--;
	dbmclose();

datum
odbm_fetch(db, key)
	ODBM_File	db
	datum		key

int
odbm_store(db, key, value, flags = DBM_REPLACE)
	ODBM_File	db
	datum		key
	datum		value
	int		flags

int
odbm_delete(db, key)
	ODBM_File	db
	datum		key

datum
odbm_firstkey(db)
	ODBM_File	db

datum
odbm_nextkey(db, key)
	ODBM_File	db
	datum		key

