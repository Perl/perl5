#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ndbm.h>

typedef DBM* NDBM_File;
#define dbm_new(dbtype,filename,flags,mode) dbm_open(filename,flags,mode)
#define nextkey(db,key) dbm_nextkey(db)

MODULE = NDBM_File	PACKAGE = NDBM_File	PREFIX = dbm_

NDBM_File
dbm_new(dbtype, filename, flags, mode)
	char *		dbtype
	char *		filename
	int		flags
	int		mode

void
dbm_DESTROY(db)
	NDBM_File	db
	CODE:
	dbm_close(db);

datum
dbm_fetch(db, key)
	NDBM_File	db
	datum		key

int
dbm_store(db, key, value, flags = DBM_REPLACE)
	NDBM_File	db
	datum		key
	datum		value
	int		flags

int
dbm_delete(db, key)
	NDBM_File	db
	datum		key

datum
dbm_firstkey(db)
	NDBM_File	db

datum
nextkey(db, key)
	NDBM_File	db
	datum		key

int
dbm_error(db)
	NDBM_File	db

int
dbm_clearerr(db)
	NDBM_File	db

