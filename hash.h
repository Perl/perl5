/* $Header: hash.h,v 3.0 89/10/18 15:18:39 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	hash.h,v $
 * Revision 3.0  89/10/18  15:18:39  lwall
 * 3.0 baseline
 * 
 */

#define FILLPCT 80		/* don't make greater than 99 */
#define DBM_CACHE_MAX 63	/* cache 64 entries for dbm file */
				/* (resident array acts as a write-thru cache)*/

#define COEFFSIZE (16 * 8)	/* size of array below */
#ifdef DOINIT
char coeff[] = {
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1,
		61,59,53,47,43,41,37,31,29,23,17,13,11,7,3,1};
#else
extern char coeff[];
#endif

typedef struct hentry HENT;

struct hentry {
    HENT	*hent_next;
    char	*hent_key;
    STR		*hent_val;
    int		hent_hash;
    int		hent_klen;
};

struct htbl {
    HENT	**tbl_array;
    int		tbl_max;	/* subscript of last element of tbl_array */
    int		tbl_dosplit;	/* how full to get before splitting */
    int		tbl_fill;	/* how full tbl_array currently is */
    int		tbl_riter;	/* current root of iterator */
    HENT	*tbl_eiter;	/* current entry of iterator */
    SPAT 	*tbl_spatroot;	/* list of spats for this package */
#ifdef SOME_DBM
#ifdef NDBM
    DBM		*tbl_dbm;
#else
    int		tbl_dbm;
#endif
#endif
    unsigned char tbl_coeffsize;	/* is 0 for symbol tables */
};

STR *hfetch();
bool hstore();
STR *hdelete();
HASH *hnew();
void hclear();
void hentfree();
int hiterinit();
HENT *hiternext();
char *hiterkey();
STR *hiterval();
bool hdbmopen();
void hdbmclose();
bool hdbmstore();
