#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gdbm.h>
#include <fcntl.h>

typedef struct {
	GDBM_FILE 	dbp ;
	SV *    filter_fetch_key ;
	SV *    filter_store_key ;
	SV *    filter_fetch_value ;
	SV *    filter_store_value ;
	int     filtering ;
	} GDBM_File_type;

typedef GDBM_File_type * GDBM_File ;
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



#define GDBM_BLOCKSIZE 0 /* gdbm defaults to stat blocksize */

typedef void (*FATALFUNC)();

#ifndef GDBM_FAST
static int
not_here(char *s)
{
    croak("GDBM_File::%s not implemented on this architecture", s);
    return -1;
}
#endif

/* GDBM allocates the datum with system malloc() and expects the user
 * to free() it.  So we either have to free() it immediately, or have
 * perl free() it when it deallocates the SV, depending on whether
 * perl uses malloc()/free() or not. */
static void
output_datum(pTHX_ SV *arg, char *str, int size)
{
#if (!defined(MYMALLOC) || (defined(MYMALLOC) && defined(PERL_POLLUTE_MALLOC))) && !defined(LEAKTEST)
	sv_usepvn(arg, str, size);
#else
	sv_setpvn(arg, str, size);
	safesysfree(str);
#endif
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

#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISUNDEF	8
#define PERL_constant_ISUV	9
#define PERL_constant_ISYES	10

static int
constant (const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!../../perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(GDBM_CACHESIZE GDBM_FAST GDBM_FASTMODE GDBM_INSERT GDBM_NEWDB
	       GDBM_NOLOCK GDBM_READER GDBM_REPLACE GDBM_WRCREAT GDBM_WRITER));

print constant_types(); # macro defs
foreach (C_constant ("GDBM_File", 'constant', 'IV', $types, undef, 8, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("GDBM_File", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "GDBM_FAST", 9)) {
#ifdef GDBM_FAST
      *iv_return = GDBM_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    if (memEQ(name, "GDBM_NEWDB", 10)) {
#ifdef GDBM_NEWDB
      *iv_return = GDBM_NEWDB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* GDBM_INSERT GDBM_NOLOCK GDBM_READER GDBM_WRITER */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'E':
      if (memEQ(name, "GDBM_READER", 11)) {
      /*                     ^           */
#ifdef GDBM_READER
        *iv_return = GDBM_READER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "GDBM_INSERT", 11)) {
      /*                     ^           */
#ifdef GDBM_INSERT
        *iv_return = GDBM_INSERT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "GDBM_NOLOCK", 11)) {
      /*                     ^           */
#ifdef GDBM_NOLOCK
        *iv_return = GDBM_NOLOCK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "GDBM_WRITER", 11)) {
      /*                     ^           */
#ifdef GDBM_WRITER
        *iv_return = GDBM_WRITER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    /* Names all of length 12.  */
    /* GDBM_REPLACE GDBM_WRCREAT */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'A':
      if (memEQ(name, "GDBM_WRCREAT", 12)) {
      /*                         ^        */
#ifdef GDBM_WRCREAT
        *iv_return = GDBM_WRCREAT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'C':
      if (memEQ(name, "GDBM_REPLACE", 12)) {
      /*                         ^        */
#ifdef GDBM_REPLACE
        *iv_return = GDBM_REPLACE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 13:
    if (memEQ(name, "GDBM_FASTMODE", 13)) {
#ifdef GDBM_FASTMODE
      *iv_return = GDBM_FASTMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "GDBM_CACHESIZE", 14)) {
#ifdef GDBM_CACHESIZE
      *iv_return = GDBM_CACHESIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

MODULE = GDBM_File	PACKAGE = GDBM_File	PREFIX = gdbm_

void
constant(sv)
    PREINIT:
	dXSTARG;
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid GDBM_File macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined GDBM_File macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing GDBM_File macro %s, used",
               type, s));
          PUSHs(sv);
        }


GDBM_File
gdbm_TIEHASH(dbtype, name, read_write, mode, fatal_func = (FATALFUNC)croak)
	char *		dbtype
	char *		name
	int		read_write
	int		mode
	FATALFUNC	fatal_func
	CODE:
	{
	    GDBM_FILE  	dbp ;

	    RETVAL = NULL ;
	    if ((dbp =  gdbm_open(name, GDBM_BLOCKSIZE, read_write, mode, fatal_func))) {
	        RETVAL = (GDBM_File)safemalloc(sizeof(GDBM_File_type)) ;
    	        Zero(RETVAL, 1, GDBM_File_type) ;
		RETVAL->dbp = dbp ;
	    }
	    
	}
	OUTPUT:
	  RETVAL
	

#define gdbm_close(db)			gdbm_close(db->dbp)
void
gdbm_close(db)
	GDBM_File	db
	CLEANUP:

void
gdbm_DESTROY(db)
	GDBM_File	db
	CODE:
	gdbm_close(db);
	safefree(db);

#define gdbm_FETCH(db,key)			gdbm_fetch(db->dbp,key)
datum_value
gdbm_FETCH(db, key)
	GDBM_File	db
	datum_key	key

#define gdbm_STORE(db,key,value,flags)		gdbm_store(db->dbp,key,value,flags)
int
gdbm_STORE(db, key, value, flags = GDBM_REPLACE)
	GDBM_File	db
	datum_key	key
	datum_value	value
	int		flags
    CLEANUP:
	if (RETVAL) {
	    if (RETVAL < 0 && errno == EPERM)
		croak("No write permission to gdbm file");
	    croak("gdbm store returned %d, errno %d, key \"%.*s\"",
			RETVAL,errno,key.dsize,key.dptr);
	}

#define gdbm_DELETE(db,key)			gdbm_delete(db->dbp,key)
int
gdbm_DELETE(db, key)
	GDBM_File	db
	datum_key	key

#define gdbm_FIRSTKEY(db)			gdbm_firstkey(db->dbp)
datum_key
gdbm_FIRSTKEY(db)
	GDBM_File	db

#define gdbm_NEXTKEY(db,key)			gdbm_nextkey(db->dbp,key)
datum_key
gdbm_NEXTKEY(db, key)
	GDBM_File	db
	datum_key	key

#define gdbm_reorganize(db)			gdbm_reorganize(db->dbp)
int
gdbm_reorganize(db)
	GDBM_File	db


#define gdbm_sync(db)				gdbm_sync(db->dbp)
void
gdbm_sync(db)
	GDBM_File	db

#define gdbm_EXISTS(db,key)			gdbm_exists(db->dbp,key)
int
gdbm_EXISTS(db, key)
	GDBM_File	db
	datum_key	key

#define gdbm_setopt(db,optflag, optval, optlen)	gdbm_setopt(db->dbp,optflag, optval, optlen)
int
gdbm_setopt (db, optflag, optval, optlen)
	GDBM_File	db
	int		optflag
	int		&optval
	int		optlen


#define setFilter(type)					\
	{						\
	    if (db->type)				\
	        RETVAL = sv_mortalcopy(db->type) ; 	\
	    ST(0) = RETVAL ;				\
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
	GDBM_File	db
	SV *		code
	SV *		RETVAL = &PL_sv_undef ;
	CODE:
	    setFilter(filter_fetch_key) ;

SV *
filter_store_key(db, code)
	GDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_store_key) ;

SV *
filter_fetch_value(db, code)
	GDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_fetch_value) ;

SV *
filter_store_value(db, code)
	GDBM_File	db
	SV *		code
	SV *		RETVAL =  &PL_sv_undef ;
	CODE:
	    setFilter(filter_store_value) ;

