#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <gdbm.h>

#include <fcntl.h>

typedef GDBM_FILE GDBM_File;

#define gdbm_new(dbtype, name, block_size, read_write, mode, fatal_func) \
	gdbm_open(name, block_size, read_write, mode, fatal_func)

typedef datum gdatum;

typedef void (*FATALFUNC)();

MODULE = GDBM_File	PACKAGE = GDBM_File	PREFIX = gdbm_

GDBM_File
gdbm_new(dbtype, name, block_size, read_write, mode, fatal_func = (FATALFUNC)croak)
	char *		dbtype
	char *		name
	int		block_size
	int		read_write
	int		mode
	FATALFUNC	fatal_func

GDBM_File
gdbm_open(name, block_size, read_write, mode, fatal_func = (FATALFUNC)croak)
	char *		name
	int		block_size
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

gdatum
gdbm_fetch(db, key)
	GDBM_File	db
	datum		key

int
gdbm_store(db, key, value, flags = GDBM_REPLACE)
	GDBM_File	db
	datum		key
	datum		value
	int		flags

int
gdbm_delete(db, key)
	GDBM_File	db
	datum		key

gdatum
gdbm_firstkey(db)
	GDBM_File	db

gdatum
gdbm_nextkey(db, key)
	GDBM_File	db
	datum		key

int
gdbm_reorganize(db)
	GDBM_File	db

