#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ndbm.h>

typedef struct {
	DBM * 	dbp ;
	SV *    filter_fetch_key ;
	SV *    filter_store_key ;
	SV *    filter_fetch_value ;
	SV *    filter_store_value ;
	int     filtering ;
	} NDBM_File_type;

typedef NDBM_File_type * NDBM_File ;
typedef datum datum_key ;
typedef datum datum_value ;

#define ckFilter(arg,type,name)					\
	if (db->type) {						\
	    SV * save_defsv ;					\
            /* printf("filtering %s\n", name) ;*/		\
	    if (db->filtering)					\
	        croak("recursion detected in %s", name) ;	\
	    db->filtering = TRUE ;				\
	    save_defsv = newSVsv(DEFSV) ;			\
	    sv_setsv(DEFSV, arg) ;				\
	    PUSHMARK(sp) ;					\
	    (void) perl_call_sv(db->type, G_DISCARD|G_NOARGS); 	\
	    sv_setsv(arg, DEFSV) ;				\
	    sv_setsv(DEFSV, save_defsv) ;			\
	    SvREFCNT_dec(save_defsv) ;				\
	    db->filtering = FALSE ;				\
	    /*printf("end of filtering %s\n", name) ;*/		\
	}


MODULE = NDBM_File	PACKAGE = NDBM_File	PREFIX = dbm_

NDBM_File
dbm_TIEHASH(dbtype, filename, flags, mode)
	char *		dbtype
	char *		filename
	int		flags
	int		mode
	CODE:
	{
	    DBM * 	dbp ;

	    RETVAL = NULL ;
	    if (dbp =  dbm_open(filename, flags, mode)) {
	        RETVAL = (NDBM_File)safemalloc(sizeof(NDBM_File_type)) ;
    	        Zero(RETVAL, 1, NDBM_File_type) ;
		RETVAL->dbp = dbp ;
	    }
	    
	}
	OUTPUT:
	  RETVAL

void
dbm_DESTROY(db)
	NDBM_File	db
	CODE:
	dbm_close(db->dbp);

#define dbm_FETCH(db,key)			dbm_fetch(db->dbp,key)
datum_value
dbm_FETCH(db, key)
	NDBM_File	db
	datum_key	key

#define dbm_STORE(db,key,value,flags)		dbm_store(db->dbp,key,value,flags)
int
dbm_STORE(db, key, value, flags = DBM_REPLACE)
	NDBM_File	db
	datum_key	key
	datum_value	value
	int		flags
    CLEANUP:
	if (RETVAL) {
	    if (RETVAL < 0 && errno == EPERM)
		croak("No write permission to ndbm file");
	    croak("ndbm store returned %d, errno %d, key \"%s\"",
			RETVAL,errno,key.dptr);
	    dbm_clearerr(db->dbp);
	}

#define dbm_DELETE(db,key)			dbm_delete(db->dbp,key)
int
dbm_DELETE(db, key)
	NDBM_File	db
	datum_key	key

#define dbm_FIRSTKEY(db)			dbm_firstkey(db->dbp)
datum_key
dbm_FIRSTKEY(db)
	NDBM_File	db

#define dbm_NEXTKEY(db,key)			dbm_nextkey(db->dbp)
datum_key
dbm_NEXTKEY(db, key)
	NDBM_File	db
	datum_key	key

#define dbm_error(db)				dbm_error(db->dbp)
int
dbm_error(db)
	NDBM_File	db

#define dbm_clearerr(db)			dbm_clearerr(db->dbp)
void
dbm_clearerr(db)
	NDBM_File	db


#define setFilter(type)					\
	{						\
	    if (db->type)				\
	        RETVAL = newSVsv(db->type) ; 		\
	    if (db->type && (code == &PL_sv_undef)) {	\
                SvREFCNT_dec(db->type) ;		\
	        db->type = NULL ;			\
	    }						\
	    else if (code) {				\
	        if (db->type)				\
	            sv_setsv(db->type, code) ;		\
	        else					\
	            db->type = newSVsv(code) ;		\
	    }	    					\
	}



SV *
filter_fetch_key(db, code)
	NDBM_File	db
	SV *		code
	SV *		RETVAL = &PL_sv_undef ;
	CODE:
	    setFilter(filter_fetch_key) ;
	OUTPUT:
	    RETVAL

SV *
filter_store_key(db, code)
	NDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_store_key) ;
	OUTPUT:
	    RETVAL

SV *
filter_fetch_value(db, code)
	NDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_fetch_value) ;
	OUTPUT:
	    RETVAL

SV *
filter_store_value(db, code)
	NDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_store_value) ;
	OUTPUT:
	    RETVAL

