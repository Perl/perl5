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

static int
XS_GDBM_File_gdbm_new(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 5 || items > 6) {
	fatal("Usage: GDBM_File::new(dbtype, name, block_size, read_write, mode, fatal_func = (FATALFUNC)fatal)");
    }
    {
	char *	dbtype = SvPV(ST(1),na);
	char *	name = SvPV(ST(2),na);
	int	block_size = (int)SvIV(ST(3));
	int	read_write = (int)SvIV(ST(4));
	int	mode = (int)SvIV(ST(5));
	FATALFUNC	fatal_func;
	GDBM_File	RETVAL;

	if (items < 6)
	    fatal_func = (FATALFUNC)fatal;
	else {
	    fatal_func = (FATALFUNC)SvPV(ST(6),na);
	}

	RETVAL = gdbm_new(dbtype, name, block_size, read_write, mode, fatal_func);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setptrobj(ST(0), RETVAL, "GDBM_File");
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_open(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 4 || items > 5) {
	fatal("Usage: GDBM_File::open(name, block_size, read_write, mode, fatal_func = (FATALFUNC)fatal)");
    }
    {
	char *	name = SvPV(ST(1),na);
	int	block_size = (int)SvIV(ST(2));
	int	read_write = (int)SvIV(ST(3));
	int	mode = (int)SvIV(ST(4));
	FATALFUNC	fatal_func;
	GDBM_File	RETVAL;

	if (items < 5)
	    fatal_func = (FATALFUNC)fatal;
	else {
	    fatal_func = (FATALFUNC)SvPV(ST(5),na);
	}

	RETVAL = gdbm_open(name, block_size, read_write, mode, fatal_func);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setptrobj(ST(0), RETVAL, "GDBM_File");
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_close(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: GDBM_File::close(db)");
    }
    {
	GDBM_File	db;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	gdbm_close(db);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_DESTROY(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: GDBM_File::DESTROY(db)");
    }
    {
	GDBM_File	db;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");
	gdbm_close(db);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_fetch(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: GDBM_File::fetch(db, key)");
    }
    {
	GDBM_File	db;
	datum	key;
	gdatum	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = gdbm_fetch(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_usepvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_store(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 3 || items > 4) {
	fatal("Usage: GDBM_File::store(db, key, value, flags = GDBM_REPLACE)");
    }
    {
	GDBM_File	db;
	datum	key;
	datum	value;
	int	flags;
	int	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	value.dptr = SvPV(ST(3), value.dsize);;

	if (items < 4)
	    flags = GDBM_REPLACE;
	else {
	    flags = (int)SvIV(ST(4));
	}

	RETVAL = gdbm_store(db, key, value, flags);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_delete(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: GDBM_File::delete(db, key)");
    }
    {
	GDBM_File	db;
	datum	key;
	int	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = gdbm_delete(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_firstkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: GDBM_File::firstkey(db)");
    }
    {
	GDBM_File	db;
	gdatum	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	RETVAL = gdbm_firstkey(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_usepvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_nextkey(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 2 || items > 2) {
	fatal("Usage: GDBM_File::nextkey(db, key)");
    }
    {
	GDBM_File	db;
	datum	key;
	gdatum	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	key.dptr = SvPV(ST(2), key.dsize);;

	RETVAL = gdbm_nextkey(db, key);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_usepvn(ST(0), RETVAL.dptr, RETVAL.dsize);
    }
    return sp;
}

static int
XS_GDBM_File_gdbm_reorganize(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	fatal("Usage: GDBM_File::reorganize(db)");
    }
    {
	GDBM_File	db;
	int	RETVAL;

	if (sv_isa(ST(1), "GDBM_File"))
	    db = (GDBM_File)(unsigned long)SvNV((SV*)SvANY(ST(1)));
	else
	    fatal("db is not of type GDBM_File");

	RETVAL = gdbm_reorganize(db);
	ST(0) = sv_mortalcopy(&sv_undef);
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return sp;
}

int init_GDBM_File(ix,sp,items)
int ix;
int sp;
int items;
{
    char* file = __FILE__;

    newXSUB("GDBM_File::new", 0, XS_GDBM_File_gdbm_new, file);
    newXSUB("GDBM_File::open", 0, XS_GDBM_File_gdbm_open, file);
    newXSUB("GDBM_File::close", 0, XS_GDBM_File_gdbm_close, file);
    newXSUB("GDBM_File::DESTROY", 0, XS_GDBM_File_gdbm_DESTROY, file);
    newXSUB("GDBM_File::fetch", 0, XS_GDBM_File_gdbm_fetch, file);
    newXSUB("GDBM_File::store", 0, XS_GDBM_File_gdbm_store, file);
    newXSUB("GDBM_File::delete", 0, XS_GDBM_File_gdbm_delete, file);
    newXSUB("GDBM_File::firstkey", 0, XS_GDBM_File_gdbm_firstkey, file);
    newXSUB("GDBM_File::nextkey", 0, XS_GDBM_File_gdbm_nextkey, file);
    newXSUB("GDBM_File::reorganize", 0, XS_GDBM_File_gdbm_reorganize, file);
}
