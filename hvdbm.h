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
#   ifdef HAS_NDBM
#	undef HAS_NDBM
#   endif
#   ifndef HAS_ODBM
#	define HAS_ODBM
#   endif
#else
#   ifdef HAS_GDBM
#	ifdef I_GDBM
#	    include <gdbm.h>
#	endif
#	define SOME_DBM
#	ifdef HAS_NDBM
#	    undef HAS_NDBM
#	endif
#	ifdef HAS_ODBM
#	    undef HAS_ODBM
#	endif
#   else
#	ifdef HAS_NDBM
#	    include <ndbm.h>
#	    define SOME_DBM
#	    ifdef HAS_ODBM
#		undef HAS_ODBM
#	    endif
#	else
#	    ifdef HAS_ODBM
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
#	    endif /* HAS_ODBM */
#	endif /* HAS_NDBM */
#   endif /* HAS_GDBM */
#endif /* WANT_DBZ */

