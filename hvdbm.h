#define DBM_CACHE_MAX 63	/* cache 64 entries for dbm file */
				/* (resident array acts as a write-thru cache)*/
#ifdef WANT_DBZ
#   include <dbz.h>
#   define SOME_DBM
#   define dbm_fetch(db,dkey) fetch(dkey)
#   define dbm_delete(db,dkey) croak("dbz doesn't implement delete")
#   define dbm_store(db,dkey,dcontent,flags) store(dkey,dcontent)
#   define dbm_close(db) dbmclose()
#   define dbm_firstkey(db) (croak("dbz doesn't implement traversal"),fetch())
#   define nextkey() (croak("dbz doesn't implement traversal"),fetch())
#   define dbm_nextkey(db) (croak("dbz doesn't implement traversal"),fetch())
#   ifdef I_NDBM
#	undef I_NDBM
#   endif
#   ifndef I_DBM
#	define I_DBM
#   endif
#else
#   ifdef HAS_GDBM
#	ifdef I_GDBM
#	    include <gdbm.h>
#	endif
#	define SOME_DBM
#	ifdef I_NDBM
#	    undef I_NDBM
#	endif
#	ifdef I_DBM
#	    undef I_DBM
#	endif
#   else
#	ifdef I_NDBM
#	    include <ndbm.h>
#	    define SOME_DBM
#	    ifdef I_DBM
#		undef I_DBM
#	    endif
#	else
#	    ifdef I_DBM
#		ifdef NULL
#		    undef NULL		/* suppress redefinition message */
#		endif
#		include <dbm.h>
#		ifdef NULL
#		    undef NULL
#		endif
#		define NULL 0	/* silly thing is, we don't even use this... */
#		define SOME_DBM
#		define dbm_fetch(db,dkey) fetch(dkey)
#		define dbm_delete(db,dkey) delete(dkey)
#		define dbm_store(db,dkey,dcontent,flags) store(dkey,dcontent)
#		define dbm_close(db) dbmclose()
#		define dbm_firstkey(db) firstkey()
#	    endif /* I_DBM */
#	endif /* I_NDBM */
#   endif /* HAS_GDBM */
#endif /* WANT_DBZ */

