#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ndbm.h>

typedef DBM* NDBM_File;
#define dbm_new(dbtype,filename,flags,mode) dbm_open(filename,flags,mode)
#define nextkey(db,key) dbm_nextkey(db)

static int
XS_NDBM_File_dbm_new(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 4) {
	croak("Usage: NDBM_File::new(dbtype, filename, flags, mode)");
    }
    {
	char *	dbtype = SvPV(ST(1),na);
	char *	filename = SvPV(ST(2),na);
	int	flags = (int)SvIV(ST(3));
	int	mode = (int)SvIV(ST(4));
	NDBM_File	RETVAL;

	RETVAL = dbm_new(dbtype, filename, flags, mode);
	ST(0) = sv_newmortal();
	sv_setptrobj(ST(0), RETVAL, "NDBM_File");
    }
    return ax;
}

static int
XS_NDBM_File_dbm_DESTROY(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: NDBM_File::DESTROY(db)");
    }
    {
	NDBM_File	db;

	if (SvROK(ST(1))) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not a reference");
	dbm_close(db);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_fetch(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: NDBM_File::fetch(db, key)");
    }
    {
	NDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = dbm_fetch(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_store(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 3 || items > 4) {
	croak("Usage: NDBM_File::store(db, key, value, flags = DBM_REPLACE)");
    }
    {
	NDBM_File	db;
	datum	key;
	datum	value;
	int	flags;
	int	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	value.dptr = SvPV(ST(3), na);
	value.dsize = (int)na;;

	if (items < 4)
	    flags = DBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = dbm_store(db, key, value, flags);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_delete(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: NDBM_File::delete(db, key)");
    }
    {
	NDBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = dbm_delete(db, key);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_firstkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: NDBM_File::firstkey(db)");
    }
    {
	NDBM_File	db;
	datum	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	RETVAL = dbm_firstkey(db);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_NDBM_File_nextkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: NDBM_File::nextkey(db, key)");
    }
    {
	NDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = nextkey(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_error(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: NDBM_File::error(db)");
    }
    {
	NDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	RETVAL = dbm_error(db);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_NDBM_File_dbm_clearerr(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: NDBM_File::clearerr(db)");
    }
    {
	NDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "NDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (NDBM_File) tmp;
	}
	else
	    croak("db is not of type NDBM_File");

	RETVAL = dbm_clearerr(db);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

int boot_NDBM_File(ix,ax,items)
int ix;
int ax;
int items;
{
    char* file = __FILE__;

    newXSUB("NDBM_File::new", 0, XS_NDBM_File_dbm_new, file);
    newXSUB("NDBM_File::DESTROY", 0, XS_NDBM_File_dbm_DESTROY, file);
    newXSUB("NDBM_File::fetch", 0, XS_NDBM_File_dbm_fetch, file);
    newXSUB("NDBM_File::store", 0, XS_NDBM_File_dbm_store, file);
    newXSUB("NDBM_File::delete", 0, XS_NDBM_File_dbm_delete, file);
    newXSUB("NDBM_File::firstkey", 0, XS_NDBM_File_dbm_firstkey, file);
    newXSUB("NDBM_File::nextkey", 0, XS_NDBM_File_nextkey, file);
    newXSUB("NDBM_File::error", 0, XS_NDBM_File_dbm_error, file);
    newXSUB("NDBM_File::clearerr", 0, XS_NDBM_File_dbm_clearerr, file);
}
