/* $Header: stab.h,v 2.0 88/06/05 00:11:05 root Exp $
 *
 * $Log:	stab.h,v $
 * Revision 2.0  88/06/05  00:11:05  root
 * Baseline version 2.0.
 * 
 */

struct stab {
    struct stab *stab_next;
    char	*stab_name;
    STR		*stab_val;
    struct stio *stab_io;
    FCMD	*stab_form;
    ARRAY	*stab_array;
    HASH	*stab_hash;
    SUBR	*stab_sub;
    char	stab_flags;
};

#define SF_VMAGIC 1		/* call routine to dereference STR val */
#define SF_MULTI 2		/* seen more than once */

struct stio {
    FILE	*fp;
    long	lines;
    long	page;
    long	page_len;
    long	lines_left;
    char	*top_name;
    STAB	*top_stab;
    char	*fmt_name;
    STAB	*fmt_stab;
    short	subprocess;
    char	type;
    char	flags;
};

#define IOF_ARGV 1	/* this fp iterates over ARGV */
#define IOF_START 2	/* check for null ARGV and substitute '-' */
#define IOF_FLUSH 4	/* this fp wants a flush after write op */

struct sub {
    CMD		*cmd;
    char	*filename;
    long	depth;	/* >= 2 indicates recursive call */
    ARRAY	*tosave;
};

#define Nullstab Null(STAB*)

#define STAB_STR(s) (tmpstab = (s), tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val)
#define STAB_GET(s) (tmpstab = (s), str_get(tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val))
#define STAB_GNUM(s) (tmpstab = (s), str_gnum(tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val))

EXT STAB *tmpstab;

EXT STAB *stab_index[128];

EXT char *envname;	/* place for ENV name being assigned--gross cheat */
EXT char *signame;	/* place for SIG name being assigned--gross cheat */

EXT unsigned short statusvalue;

STAB *aadd();
STAB *hadd();
