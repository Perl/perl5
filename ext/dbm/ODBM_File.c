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

#define DBM_REPLACE 0

static int
XS_ODBM_File_odbm_new(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 4 || items > 4) {
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
    return sp;
}

static int
XS_ODBM_File_DESTROY(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	croak("Usage: ODBM_File::DESTROY(db)");
    }
    {
	ODBM_File	db;

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");
	dbmrefcnt--;
	dbmclose();
    }
    return sp;
}

static int
XS_ODBM_File_odbm_fetch(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	croak("Usage: ODBM_File::fetch(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = odbm_fetch(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_ODBM_File_odbm_store(ix, sp, items)
register int ix;
register int sp;
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

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	value.dptr = SvPV(ST(3), value.dsize);;

	if (items < 4)
	    flags = DBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = odbm_store(db, key, value, flags);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_ODBM_File_odbm_delete(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	croak("Usage: ODBM_File::delete(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = odbm_delete(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_ODBM_File_odbm_firstkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	croak("Usage: ODBM_File::firstkey(db)");
    }
    {
	ODBM_File	db;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");

	RETVAL = odbm_firstkey(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_ODBM_File_odbm_nextkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	croak("Usage: ODBM_File::nextkey(db, key)");
    }
    {
	ODBM_File	db;
	datum	key;
	datum	RETVAL;

	if (sv_isa(ST(1), "ODBM_File"))
	    db = (ODBM_File)(unsigned long)SvNV((SV*)SvRV(ST(1)));
	else
	    croak("db is not of type ODBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = odbm_nextkey(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setpvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

int boot_ODBM_File(ix,sp,items)
int ix;
int sp;
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
