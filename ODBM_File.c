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

static int
XS_ODBM_File_odbm_new(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 4) {
	croak("Usage: ODBM_File::new(dbtype, filename, flags, mode)");
    }
    {
	char *	dbtype = SvPV(ST(1),na);
	char *	filename = SvPV(ST(2),na);
	int	flags = (int)SvIV(ST(3));
	int	mode = (int)SvIV(ST(4));
	ODBM_File	RETVAL;
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
    }
    return ax;
}

static int
XS_ODBM_File_DESTROY(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: ODBM_File::DESTROY(db)");
    }
    {
	ODBM_File	db;

	if (SvROK(ST(1))) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not a reference");
	dbmrefcnt--;
	dbmclose();
    }
    return ax;
}

static int
XS_ODBM_File_odbm_fetch(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: ODBM_File::fetch(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = odbm_fetch(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_ODBM_File_odbm_store(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 3 || items > 4) {
	croak("Usage: ODBM_File::store(db, key, value, flags = DBM_REPLACE)");
    }
    {
	ODBM_File	db;
	datum	key;
	datum	value;
	int	flags;
	int	RETVAL;

	if (sv_isa(ST(1), "ODBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	value.dptr = SvPV(ST(3), na);
	value.dsize = (int)na;;

	if (items < 4)
	    flags = DBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = odbm_store(db, key, value, flags);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_ODBM_File_odbm_delete(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: ODBM_File::delete(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "ODBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = odbm_delete(db, key);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_ODBM_File_odbm_firstkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: ODBM_File::firstkey(db)");
    }
    {
	ODBM_File	db;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not of type ODBM_File");

	RETVAL = odbm_firstkey(db);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

static int
XS_ODBM_File_odbm_nextkey(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: ODBM_File::nextkey(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    db = (ODBM_File) tmp;
	}
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), na);
	key.dsize = (int)na;;

	RETVAL = odbm_nextkey(db, key);
	ST(0) = sv_newmortal();
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return ax;
}

int boot_ODBM_File(ix,ax,items)
int ix;
int ax;
int items;
{
    char* file = __FILE__;

    newXSUB("ODBM_File::new", 0, XS_ODBM_File_odbm_new, file);
    newXSUB("ODBM_File::DESTROY", 0, XS_ODBM_File_DESTROY, file);
    newXSUB("ODBM_File::fetch", 0, XS_ODBM_File_odbm_fetch, file);
    newXSUB("ODBM_File::store", 0, XS_ODBM_File_odbm_store, file);
    newXSUB("ODBM_File::delete", 0, XS_ODBM_File_odbm_delete, file);
    newXSUB("ODBM_File::firstkey", 0, XS_ODBM_File_odbm_firstkey, file);
    newXSUB("ODBM_File::nextkey", 0, XS_ODBM_File_odbm_nextkey, file);
}
