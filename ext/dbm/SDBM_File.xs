#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ext/dbm/sdbm/sdbm.h"

typedef DBM* SDBM_File;
#define sdbm_new(dbtype,filename,flags,mode) sdbm_open(filename,flags,mode)

MODULE = SDBM_File	PACKAGE = SDBM_File	PREFIX = sdbm_

SDBM_File
sdbm_new(dbtype, filename, flags, mode)
	char *		dbtype
	char *		filename
	int		flags
	int		mode

void
sdbm_DESTROY(db)
	SDBM_File	db
	CODE:
	sdbm_close(db);

datum
sdbm_fetch(db, key)
	SDBM_File	db
	datum		key

int
sdbm_store(db, key, value, flags = DBM_REPLACE)
	SDBM_File	db
	datum		key
	datum		value
	int		flags

int
sdbm_delete(db, key)
	SDBM_File	db
	datum		key

datum
sdbm_firstkey(db)
	SDBM_File	db

datum
sdbm_nextkey(db, key)
	SDBM_File	db
	datum		key

int
sdbm_error(db)
	SDBM_File	db

int
sdbm_clearerr(db)
	SDBM_File	db

