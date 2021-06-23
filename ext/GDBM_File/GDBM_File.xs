#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gdbm.h>
#include <fcntl.h>

#define fetch_key 0
#define store_key 1
#define fetch_value 2
#define store_value 3

typedef struct {
	GDBM_FILE 	dbp ;
	SV *    filter[4];
	int     filtering ;
	} GDBM_File_type;

typedef GDBM_File_type * GDBM_File ;
typedef datum datum_key ;
typedef datum datum_value ;
typedef datum datum_key_copy;

/* Indexes for gdbm_flags aliases */
enum {
    opt_flags = 0,
    opt_cache_size,
    opt_sync_mode,
    opt_centfree,
    opt_coalesce,
    opt_dbname,
    opt_block_size,
    opt_mmap,
    opt_mmapsize
};

/* Names of gdbm_flags aliases, for error reporting.
   Indexed by opt_ constants above.
*/
char const *opt_names[] = {
    "GDBM_File::flags",
    "GDBM_File::cache_size",
    "GDBM_File::sync_mode",
    "GDBM_File::centfree",
    "GDBM_File::coalesce",
    "GDBM_File::dbname",
    "GDBM_File::block_size",
    "GDBM_File::mmap",
    "GDBM_File::mmapsize"
};    

#ifdef GDBM_VERSION_MAJOR
# define GDBM_VERSION_GUESS 0
#else
/* Try educated guess
 * The value of GDBM_VERSION_GUESS indicates how rough the guess is:
 *   1 - Precise; based on the CVS logs and existing archives
 *   2 - Moderate. The major and minor number are correct. The patchlevel
 *       is set to the upper bound.
 *   3 - Rough; The version is guaranteed to be not newer than major.minor.
 */
# if defined(GDBM_SYNCMODE)
/* CHANGES from 1.7.3 to 1.8
 *   1.  Added GDBM_CENTFREE functionality and option.
 */  
#  define GDBM_VERSION_MAJOR 1
#  define GDBM_VERSION_MINOR 8
#  define GDBM_VERSION_PATCH 3
#  define GDBM_VERSION_GUESS 1
# elif defined(GDBM_FASTMODE)
/* CHANGES from 1.7.2 to 1.7.3
 *  1.  Fixed a couple of last minute problems. (Namely, no autoconf.h in
 *      version.c, and no GDBM_FASTMODE in gdbm.h!)
 */
#  define GDBM_VERSION_MAJOR 1
#  define GDBM_VERSION_MINOR 7
#  define GDBM_VERSION_PATCH 3
#  define GDBM_VERSION_GUESS 1
# elif defined(GDBM_FAST)
/* From CVS logs:
 * Mon May 17 12:32:02 1993  Phil Nelson  (phil at cs.wwu.edu)
 *
 * * gdbm.proto: Added GDBM_FAST to the read_write flags.
 */
#  define GDBM_VERSION_MAJOR 1
#  define GDBM_VERSION_MINOR 7
#  define GDBM_VERSION_PATCH 2
#  define GDBM_VERSION_GUESS 2
# else
#  define GDBM_VERSION_MAJOR 1
#  define GDBM_VERSION_MINOR 6
#  define GDBM_VERSION_GUESS 3
# endif
#endif

#ifndef GDBM_VERSION_PATCH
# define GDBM_VERSION_PATCH 0
#endif

/* The use of fatal_func argument to gdbm_open is deprecated since 1.13 */
#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13
# define FATALFUNC NULL
#elif GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 9
# define FATALFUNC croak_string
# define NEED_FATALFUNC 1
#else
# define FATALFUNC (void (*)()) croak_string
# define NEED_FATALFUNC 1
#endif

#ifdef NEED_FATALFUNC
static void
croak_string(const char *message) {
    Perl_croak_nocontext("%s", message);
}
#endif

#define not_here(s) (croak("GDBM_File::%s not implemented", #s),-1)

#if ! (GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 11)
typedef unsigned gdbm_count_t;
#endif

/* GDBM allocates the datum with system malloc() and expects the user
 * to free() it.  So we either have to free() it immediately, or have
 * perl free() it when it deallocates the SV, depending on whether
 * perl uses malloc()/free() or not. */
static void
output_datum(pTHX_ SV *arg, char *str, int size)
{
	sv_setpvn(arg, str, size);
#	undef free
	free(str);
}

/* Versions of gdbm prior to 1.7x might not have the gdbm_sync,
   gdbm_exists, and gdbm_setopt functions.  Apparently Slackware
   (Linux) 2.1 contains gdbm-1.5 (which dates back to 1991).
*/
#ifndef GDBM_FAST
#define gdbm_exists(db,key) not_here("gdbm_exists")
#define gdbm_sync(db) (void) not_here("gdbm_sync")
#define gdbm_setopt(db,optflag,optval,optlen) not_here("gdbm_setopt")
#endif

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR < 13
/* Prior to 1.13, only gdbm_fetch set GDBM_ITEM_NOT_FOUND if the requested
   key did not exist.  Other similar functions would set GDBM_NO_ERROR instead.
   The GDBM_ITEM_NOT_FOUND existed as early as in 1.7.3 */
# define ITEM_NOT_FOUND()  (gdbm_errno == GDBM_NO_ERROR || gdbm_errno == GDBM_ITEM_NOT_FOUND)
#else
# define ITEM_NOT_FOUND()  (gdbm_errno == GDBM_ITEM_NOT_FOUND)
#endif

#define CHECKDB(db) do {                        \
    if (!db->dbp) {                             \
        croak("database was closed");           \
    }                                           \
 } while (0)

static void
dbcroak(GDBM_File db, char const *func)
{
#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13        
    croak("%s: %s", func, gdbm_db_strerror(db->dbp));
#else
    (void)db;
    croak("%s: %s", func, gdbm_strerror(gdbm_errno));
#endif
}

#if GDBM_VERSION_MAJOR == 1 && (GDBM_VERSION_MINOR > 16 || GDBM_VERSION_PATCH >= 90)
# define gdbm_close(db)    gdbm_close(db->dbp)
#else
# define gdbm_close(db)    (gdbm_close(db->dbp),0)
#endif
static int
gdbm_file_close(GDBM_File db)
{
    int rc = 0;
    if (db->dbp) {
        rc = gdbm_close(db);
        db->dbp = NULL;
    }
    return rc;
}

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13
/* Error-reporting wrapper for gdbm_recover */
static void
rcvr_errfun(void *cv, char const *fmt, ...)
{
    dTHX;
    dSP;
    va_list ap;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    va_start(ap, fmt);
    XPUSHs(sv_2mortal(vnewSVpvf(fmt, &ap)));
    va_end(ap);
    PUTBACK;

    call_sv((SV*)cv, G_DISCARD);

    FREETMPS;
    LEAVE;
}
#endif

#include "const-c.inc"

MODULE = GDBM_File	PACKAGE = GDBM_File	PREFIX = gdbm_

INCLUDE: const-xs.inc

void
gdbm_GDBM_version(package)
    PPCODE:
	I32 gimme = GIMME_V;
        if (gimme == G_VOID) {
	    /* nothing */;
        } else if (gimme == G_SCALAR) {
	    static char const *guess[] = {
		    "",
		    " (exact guess)",
		    " (approximate)",
		    " (rough guess)"
	    };
 	    if (GDBM_VERSION_PATCH > 0) {
		XPUSHs(sv_2mortal(newSVpvf("%d.%d.%d%s",
					   GDBM_VERSION_MAJOR,
					   GDBM_VERSION_MINOR,
					   GDBM_VERSION_PATCH,
					   guess[GDBM_VERSION_GUESS])));
	    } else {
		XPUSHs(sv_2mortal(newSVpvf("%d.%d%s",
					   GDBM_VERSION_MAJOR,
					   GDBM_VERSION_MINOR,
					   guess[GDBM_VERSION_GUESS])));
	    }
	} else {
		XPUSHs(sv_2mortal(newSVuv(GDBM_VERSION_MAJOR)));
		XPUSHs(sv_2mortal(newSVuv(GDBM_VERSION_MINOR)));
		XPUSHs(sv_2mortal(newSVuv(GDBM_VERSION_PATCH)));
		if (GDBM_VERSION_GUESS > 0) {
			XPUSHs(sv_2mortal(newSVuv(GDBM_VERSION_GUESS)));
		}
	}
	
GDBM_File
gdbm_TIEHASH(dbtype, name, read_write, mode)
	char *		dbtype
	char *		name
	int		read_write
	int		mode
	PREINIT:
	GDBM_FILE dbp;
	CODE:
	dbp = gdbm_open(name, 0, read_write, mode, FATALFUNC);
	if (!dbp && gdbm_errno == GDBM_BLOCK_SIZE_ERROR) {
	    /*
	     * By specifying a block size of 0 above, we asked gdbm to
	     * default to the filesystem's block size.	That's usually the
	     * right size to choose.  But some versions of gdbm require
	     * a power-of-two block size, and some unusual filesystems
	     * or devices have a non-power-of-two size that cause this
	     * defaulting to fail.  In that case, force an acceptable
	     * block size.
	     */
	    dbp = gdbm_open(name, 4096, read_write, mode, FATALFUNC);
	}
	if (dbp) {
	    RETVAL = (GDBM_File)safecalloc(1, sizeof(GDBM_File_type));
	    RETVAL->dbp = dbp;
	} else {
	    RETVAL = NULL;
	}
	OUTPUT:
	  RETVAL
	
void
gdbm_DESTROY(db)
	GDBM_File	db
	PREINIT:
	int i = store_value;
    CODE:
        if (gdbm_file_close(db)) {
            croak("gdbm_close: %s; %s", gdbm_strerror(gdbm_errno),
                  strerror(errno));
	}
	do {
	    if (db->filter[i])
		SvREFCNT_dec(db->filter[i]);
	} while (i-- > 0);
	safefree(db);

void
gdbm_UNTIE(db, count)
	GDBM_File	db
        unsigned count
    CODE:
        if (count == 0) {
            if (gdbm_file_close(db))
                croak("gdbm_close: %s; %s",
                      gdbm_strerror(gdbm_errno),
                      strerror(errno));
	}


#define gdbm_FETCH(db,key)			gdbm_fetch(db->dbp,key)
datum_value
gdbm_FETCH(db, key)
	GDBM_File	db
	datum_key_copy	key
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL.dptr == NULL && !ITEM_NOT_FOUND()) {
            dbcroak(db, "gdbm_fetch");
        }

#define gdbm_STORE(db,key,value,flags)		gdbm_store(db->dbp,key,value,flags)
int
gdbm_STORE(db, key, value, flags = GDBM_REPLACE)
	GDBM_File	db
	datum_key	key
	datum_value	value
	int		flags
    INIT:
        CHECKDB(db);
    CLEANUP:
	if (RETVAL) {
	    dbcroak(db, "gdbm_store");
	}

#define gdbm_DELETE(db,key)			gdbm_delete(db->dbp,key)
int
gdbm_DELETE(db, key)
	GDBM_File	db
	datum_key	key
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL && !ITEM_NOT_FOUND()) {
            dbcroak(db, "gdbm_delete");
        }

#define gdbm_FIRSTKEY(db)			gdbm_firstkey(db->dbp)
datum_key
gdbm_FIRSTKEY(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL.dptr == NULL && !ITEM_NOT_FOUND()) {
            dbcroak(db, "gdbm_firstkey");
        }

#define gdbm_NEXTKEY(db,key)			gdbm_nextkey(db->dbp,key)
datum_key
gdbm_NEXTKEY(db, key)
	GDBM_File	db
	datum_key	key 
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL.dptr == NULL && !ITEM_NOT_FOUND()) {
            dbcroak(db, "gdbm_nextkey");
        }

#define gdbm_EXISTS(db,key)			gdbm_exists(db->dbp,key)
int
gdbm_EXISTS(db, key)
	GDBM_File	db
	datum_key	key
    INIT:
        CHECKDB(db);

##
    
int
gdbm_close(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
    CODE:
        RETVAL = gdbm_file_close(db);
    OUTPUT:
        RETVAL

int
gdbm_errno(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
    CODE:
#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13        
        RETVAL = gdbm_last_errno(db->dbp);
#else
        RETVAL = gdbm_errno;
#endif
    OUTPUT:
        RETVAL

int
gdbm_syserrno(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
    CODE:
#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13
    {
        int ec = gdbm_last_errno(db->dbp);
        if (gdbm_check_syserr(ec)) {
            RETVAL = gdbm_last_syserr(db->dbp);
        } else {
            RETVAL = 0;
        }
    }
#else
        not_here("syserrno");
#endif
    OUTPUT:
        RETVAL

SV *
gdbm_strerror(db)
	GDBM_File	db
    PREINIT:
        char const *errstr;
    INIT:
        CHECKDB(db);
    CODE:
#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13        
        errstr = gdbm_db_strerror(db->dbp);
#else
        errstr = gdbm_strerror(gdbm_errno);
#endif
        RETVAL = newSVpv(errstr, 0);            
    OUTPUT:
        RETVAL

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13        
# define gdbm_clear_error(db)        gdbm_clear_error(db->dbp)
#else
# define gdbm_clear_error(db)        (gdbm_errno = 0)
#endif        
void
gdbm_clear_error(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13        
# define gdbm_needs_recovery(db)     gdbm_needs_recovery(db->dbp)
#else
# define gdbm_needs_recovery(db)     not_here("gdbm_needs_recovery")
#endif        
int            
gdbm_needs_recovery(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
            
#define gdbm_reorganize(db)			gdbm_reorganize(db->dbp)
int
gdbm_reorganize(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);


# Arguments:
#   err => sub { ... }
#   max_failed_keys => $n
#   max_failed_buckets => $n
#   max_failures => $n
#   backup => \$str
#   stat => \%hash            

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 13

void
gdbm_recover(db, ...)
	GDBM_File	db
    PREINIT:
        int flags = GDBM_RCVR_FORCE;
        SV *backup_ref = &PL_sv_undef;
        SV *stat_ref = &PL_sv_undef;
        gdbm_recovery rcvr;
    INIT:
        CHECKDB(db);
    CODE:
        if (items > 1) {
            int i;
            if ((items % 2) == 0) {
                croak("bad number of arguments");
            }
            for (i = 1; i < items; i += 2) {
                char *kw;
                SV *sv = ST(i);
                SV *val = ST(i+1);

                if (!SvPOK(sv))
                    croak("bad arguments near #%d", i);
                kw = SvPV_nolen(sv);
                if (strcmp(kw, "err") == 0) {
                    if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
                        rcvr.data = SvRV(val);
                    } else {
                        croak("%s must be a code ref", kw);
                    }
                    rcvr.errfun = rcvr_errfun;
                    flags |= GDBM_RCVR_ERRFUN;
                } else if (strcmp(kw, "max_failed_keys") == 0) {
                    if (SvIOK(val)) {
                        rcvr.max_failed_keys = SvUV(val);
                    } else {
                        croak("max_failed_keys must be numeric");
                    }
                    flags |= GDBM_RCVR_MAX_FAILED_KEYS;
                } else if (strcmp(kw, "max_failed_buckets") == 0) {
                    if (SvIOK(val)) {
                        rcvr.max_failed_buckets = SvUV(val);
                    } else {
                        croak("max_failed_buckets must be numeric");
                    }
                    flags |= GDBM_RCVR_MAX_FAILED_BUCKETS;
                } else if (strcmp(kw, "max_failures") == 0) {
                    if (SvIOK(val)) {
                        rcvr.max_failures = SvUV(val);
                    } else {
                        croak("max_failures must be numeric");
                    }
                    flags |= GDBM_RCVR_MAX_FAILURES;
                } else if (strcmp(kw, "backup") == 0) {
                    if (SvROK(val) && SvTYPE(SvRV(val)) < SVt_PVAV) {
                        backup_ref = val;
                    } else {
                        croak("backup must be a scalar reference");
                    } 
                    flags |= GDBM_RCVR_BACKUP;
                } else if (strcmp(kw, "stat") == 0) {
                    if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                        stat_ref = val;
                    } else {
                        croak("backup must be a scalar reference");
                    } 
                } else {
                    croak("%s: unrecognized argument", kw);
                }
            }
        }
        if (gdbm_recover(db->dbp, &rcvr, flags)) {
            dbcroak(db, "gdbm_recover");
        }
        if (stat_ref != &PL_sv_undef) {
            HV *hv = (HV*)SvRV(stat_ref);
#define STAT_RECOVERED_KEYS_STR "recovered_keys"
#define STAT_RECOVERED_KEYS_LEN (sizeof(STAT_RECOVERED_KEYS_STR)-1)
#define STAT_RECOVERED_BUCKETS_STR "recovered_buckets"
#define STAT_RECOVERED_BUCKETS_LEN (sizeof(STAT_RECOVERED_BUCKETS_STR)-1)
#define STAT_FAILED_KEYS_STR "failed_keys"
#define STAT_FAILED_KEYS_LEN (sizeof(STAT_FAILED_KEYS_STR)-1)
#define STAT_FAILED_BUCKETS_STR "failed_buckets"
#define STAT_FAILED_BUCKETS_LEN (sizeof(STAT_FAILED_BUCKETS_STR)-1)
            hv_store(hv, STAT_RECOVERED_KEYS_STR, STAT_RECOVERED_KEYS_LEN,
                     newSVuv(rcvr.recovered_keys), 0);
            hv_store(hv,
                     STAT_RECOVERED_BUCKETS_STR,
                     STAT_RECOVERED_BUCKETS_LEN,
                     newSVuv(rcvr.recovered_buckets), 0);
            hv_store(hv,
                     STAT_FAILED_KEYS_STR,
                     STAT_FAILED_KEYS_LEN,
                     newSVuv(rcvr.failed_keys), 0);
            hv_store(hv,
                     STAT_FAILED_BUCKETS_STR,
                     STAT_FAILED_BUCKETS_LEN,
                     newSVuv(rcvr.failed_buckets), 0);
        }
        if (backup_ref != &PL_sv_undef) {
            SV *sv = SvRV(backup_ref);
            sv_setpv(sv, rcvr.backup_name);
            free(rcvr.backup_name);
        }

#endif

#if GDBM_VERSION_MAJOR == 1 && (GDBM_VERSION_MINOR > 16 || GDBM_VERSION_PATCH >= 90)
# define gdbm_sync(db)				gdbm_sync(db->dbp)
#else
# define gdbm_sync(db)				(gdbm_sync(db->dbp),0)
#endif
int
gdbm_sync(db)
	GDBM_File	db
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL) {
            dbcroak(db, "gdbm_sync");
        }

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 11

gdbm_count_t
gdbm_count(db)            
	GDBM_File	db
   PREINIT:
        gdbm_count_t c;
   INIT:
        CHECKDB(db);
   CODE:
        if (gdbm_count(db->dbp, &c)) {
            dbcroak(db, "gdbm_count");
        }
        RETVAL = c;
   OUTPUT:
        RETVAL

#endif
        
#define OPTNAME(a,b) a ## b        
#define INTOPTSETUP(opt)                                           \
        do {                                                       \
            if (items == 1) {                                      \
                opcode = OPTNAME(GDBM_GET, opt);                   \
            } else {                                               \
                opcode = OPTNAME(GDBM_SET, opt);                   \
                sv = ST(1);                                        \
                if (!SvIOK(sv)) {                                  \
                    croak("%s: bad argument type", opt_names[ix]); \
                }                                                  \
                c_iv = SvIV(sv);                                   \
            }                                                      \
        } while (0)

#if GDBM_VERSION_MAJOR == 1 && GDBM_VERSION_MINOR >= 9
# define OPTVALPTR void *
#else
# define OPTVALPTR int *
#endif        
        
# GDBM_GET defines appeared in version 1.9 (2011-08-12).
#
# Provide definitions for earlier versions. These will cause gdbm_setopt
# to fail with GDBM_OPT_ILLEGAL

#ifndef GDBM_GETFLAGS        
# define GDBM_GETFLAGS        -1
#endif
#ifndef GDBM_GETMMAP        
# define GDBM_GETMMAP         -1
#endif
#ifndef GDBM_GETCACHESIZE        
# define GDBM_GETCACHESIZE    -1
#endif
#ifndef GDBM_GETSYNCMODE
# define GDBM_GETSYNCMODE     -1
#endif
#ifndef GDBM_GETCENTFREE              
# define GDBM_GETCENTFREE     -1
#endif
#ifndef GDBM_GETCOALESCEBLKS
# define GDBM_GETCOALESCEBLKS -1
#endif
#ifndef GDBM_GETMAXMAPSIZE
# define GDBM_GETMAXMAPSIZE   -1
#endif
#ifndef GDBM_GETDBNAME
# define GDBM_GETDBNAME       -1
#endif
#ifndef GDBM_GETBLOCKSIZE
# define GDBM_GETBLOCKSIZE    -1
#endif

# These two appeared in version 1.10:
        
#ifndef GDBM_SETMAXMAPSIZE        
# define GDBM_SETMAXMAPSIZE   -1
#endif
#ifndef GDBM_SETMMAP        
# define GDBM_SETMMAP         -1
#endif
        
# These GDBM_SET defines appeared in 1.10, replacing obsolete opcodes.
# Provide definitions for older versions
        
#ifndef GDBM_SETCACHESIZE        
# define GDBM_SETCACHESIZE    GDBM_CACHESIZE
#endif        
#ifndef GDBM_SETSYNCMODE
# define GDBM_SETSYNCMODE     GDBM_SYNCMODE
#endif        
#ifndef GDBM_SETCENTFREE
# define GDBM_SETCENTFREE     GDBM_CENTFREE
#endif        
#ifndef GDBM_SETCOALESCEBLKS
# define GDBM_SETCOALESCEBLKS GDBM_COALESCEBLKS
#endif

SV *
gdbm_flags(db, ...)       
	GDBM_File	db
	SV *		RETVAL = &PL_sv_undef;
    ALIAS:
        GDBM_File::cache_size = opt_cache_size 
        GDBM_File::sync_mode  = opt_sync_mode  
        GDBM_File::centfree   = opt_centfree   
        GDBM_File::coalesce   = opt_coalesce
        GDBM_File::dbname     = opt_dbname
        GDBM_File::block_size = opt_block_size
        GDBM_File::mmap       = opt_mmap    
        GDBM_File::mmapsize   = opt_mmapsize
    PREINIT:
        int opcode = -1;
        int c_iv;
        unsigned c_uv;
        char *c_cv;
        OPTVALPTR vptr = (OPTVALPTR) &c_iv;
        size_t vsiz = sizeof(c_iv);
        SV *sv;
    INIT:
        CHECKDB(db);
    CODE:
        if (items > 2) {
            croak("%s: too many arguments", opt_names[ix]);
        }
            
        switch (ix) {
        case opt_flags:
            if (items > 1) {
                croak("%s: too many arguments", opt_names[ix]);
            }
            opcode = GDBM_GETFLAGS;
            break;
        case opt_cache_size:
            INTOPTSETUP(CACHESIZE);
            break;
        case opt_sync_mode:
            INTOPTSETUP(SYNCMODE);
            break;
        case opt_centfree:
            INTOPTSETUP(CENTFREE);
            break;
        case opt_coalesce:
            INTOPTSETUP(COALESCEBLKS);
            break;
        case opt_dbname:
            if (items > 1) {
                croak("%s: too many arguments", opt_names[ix]);
            }
            opcode = GDBM_GETDBNAME;
            vptr = (OPTVALPTR) &c_cv;
            vsiz = sizeof(c_cv);
            break;
        case opt_block_size:
            if (items > 1) {
                croak("%s: too many arguments", opt_names[ix]);
            }
            opcode = GDBM_GETBLOCKSIZE;
            break;
        case opt_mmap:
            if (items > 1) {
                croak("%s: too many arguments", opt_names[ix]);
            }
            opcode = GDBM_GETMMAP;
            break;
        case opt_mmapsize:
            vptr = (OPTVALPTR) &c_uv;
            vsiz = sizeof(c_uv);
            if (items == 1) {                             
                opcode = GDBM_GETMAXMAPSIZE;
            } else {                                      
                opcode = GDBM_SETMAXMAPSIZE;
                sv = ST(1);                               
                if (!SvUOK(sv)) {                         
                    croak("%s: bad argument type", opt_names[ix]);           
                }                                         
                c_uv = SvUV(sv);                          
            }                                             
            break;
        }

        if (gdbm_setopt(db->dbp, opcode, vptr, vsiz)) {
            if (gdbm_errno == GDBM_OPT_ILLEGAL)
                croak("%s not implemented", opt_names[ix]);
            dbcroak(db, "gdbm_setopt");
        }

        if (vptr == (OPTVALPTR) &c_iv) {
            RETVAL = newSViv(c_iv);
        } else if (vptr == (OPTVALPTR) &c_uv) {
            RETVAL = newSVuv(c_uv);
        } else {
            RETVAL = newSVpv(c_cv, 0);
            free(c_cv);
        }
    OUTPUT:
        RETVAL
            
#define gdbm_setopt(db,optflag, optval, optlen)	gdbm_setopt(db->dbp,optflag, optval, optlen)
int
gdbm_setopt (db, optflag, optval, optlen)
	GDBM_File	db
	int		optflag
	int		&optval
	int		optlen
    INIT:
        CHECKDB(db);
    CLEANUP:
        if (RETVAL) {
            dbcroak(db, "gdbm_setopt");
        }

SV *
filter_fetch_key(db, code)
	GDBM_File	db
	SV *		code
	SV *		RETVAL = &PL_sv_undef ;
    ALIAS:
	GDBM_File::filter_fetch_key = fetch_key
	GDBM_File::filter_store_key = store_key
	GDBM_File::filter_fetch_value = fetch_value
	GDBM_File::filter_store_value = store_value
    CODE:
        DBM_setFilter(db->filter[ix], code);

