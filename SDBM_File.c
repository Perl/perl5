#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ext/dbm/sdbm/sdbm.h"

typedef DBM* SDBM_File;
#define sdbm_new(dbtype,filename,flags,mode) sdbm_open(filename,flags,mode)
#define nextkey(db,key) sdbm_nextkey(db)

static int
XS_SDBM_File_sdbm_new(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 4) {
	croak("Usage: SDBM_File::new(dbtype, filename, flags, mode)");
    }
    {
	char *	dbtype = SvPV(ST(1),na);
	char *	filename = SvPV(ST(2),na);
	int	flags = (int)SvIV(ST(3));
	int	mode = (int)SvIV(ST(4));
	SDBM_File	RETVAL;

	RETVAL = sdbm_new(dbtype, filename, flags, mode);
	ST(0) = sv_newmortal();
	sv_setptrobj(ST(0), RETVAL, "SDBM_File");
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_DESTROY(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: SDBM_File::DESTROY(db)");
    }
    {
	SDBM_File	db;

	if (SvROK(ST(1))) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not a reference");
	sdbm_close(db);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_fetch(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: SDBM_File::fetch(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = sdbm_fetch(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_store(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 3 || items > 4) {
	croak("Usage: SDBM_File::store(db, key, value, flags = DBM_REPLACE)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	value;
	int	flags;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	value.dptr = SvPV(ST(3), na);
	value.dsize = (int)na;;

	if (items < 4)
	    flags = DBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = sdbm_store(db, key, value, flags);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_delete(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: SDBM_File::delete(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = sdbm_delete(db, key);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_firstkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: SDBM_File::firstkey(db)");
    }
    {
	SDBM_File	db;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	RETVAL = sdbm_firstkey(db);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_SDBM_File_nextkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: SDBM_File::nextkey(db, key)");
    }
    {
	SDBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = nextkey(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_error(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: SDBM_File::error(db)");
    }
    {
	SDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	RETVAL = sdbm_error(db);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_SDBM_File_sdbm_clearerr(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: SDBM_File::clearerr(db)");
    }
    {
	SDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "SDBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (SDBM_File) tmp;
	}
	else
	    croak("db is not of type SDBM_File");

	RETVAL = sdbm_clearerr(db);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

int boot_SDBM_File(ix,ax,items)
int ix;
int ax;
int items;
{
    char* file = __FILE__;

    newXSUB("SDBM_File::new", 0, XS_SDBM_File_sdbm_new, file);
    newXSUB("SDBM_File::DESTROY", 0, XS_SDBM_File_sdbm_DESTROY, file);
    newXSUB("SDBM_File::fetch", 0, XS_SDBM_File_sdbm_fetch, file);
    newXSUB("SDBM_File::store", 0, XS_SDBM_File_sdbm_store, file);
    newXSUB("SDBM_File::delete", 0, XS_SDBM_File_sdbm_delete, file);
    newXSUB("SDBM_File::firstkey", 0, XS_SDBM_File_sdbm_firstkey, file);
    newXSUB("SDBM_File::nextkey", 0, XS_SDBM_File_nextkey, file);
    newXSUB("SDBM_File::error", 0, XS_SDBM_File_sdbm_error, file);
    newXSUB("SDBM_File::clearerr", 0, XS_SDBM_File_sdbm_clearerr, file);
}
