/*
 * sdbm - ndbm work-alike hashed database library
 * tuning and portability constructs [not nearly enough]
 * author: oz@nexus.yorku.ca
 */

#define BYTESIZ		8

#ifdef SVID
#include <unistd.h>
#endif

#ifdef BSD42
#define SEEK_SET	L_SET
#define	memset(s,c,n)	bzero(s, n)		/* only when c is zero */
#define	memcpy(s1,s2,n)	bcopy(s2, s1, n)
#define	memcmp(s1,s2,n)	bcmp(s1,s2,n)
#endif

/*
 * important tuning parms (hah)
 */

#define SEEDUPS			/* always detect duplicates */
#define BADMESS			/* generate a message for worst case:
				   cannot make room after SPLTMAX splits */
/*
 * misc
 */
#ifdef DEBUG
#define debug(x)	printf x
#else
#define debug(x)
#endif
