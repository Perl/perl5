/* $Header: stab.h,v 1.0 87/12/18 13:06:18 root Exp $
 *
 * $Log:	stab.h,v $
 * Revision 1.0  87/12/18  13:06:18  root
 * Initial revision
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
    CMD		*stab_sub;
    char	stab_flags;
};

#define SF_VMAGIC 1		/* call routine to dereference STR val */

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
    char	type;
    char	flags;
};

#define IOF_ARGV 1	/* this fp iterates over ARGV */
#define IOF_START 2	/* check for null ARGV and substitute '-' */
#define IOF_FLUSH 4	/* this fp wants a flush after write op */

#define Nullstab Null(STAB*)

#define STAB_STR(s) (tmpstab = (s), tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val)
#define STAB_GET(s) (tmpstab = (s), str_get(tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val))
#define STAB_GNUM(s) (tmpstab = (s), str_gnum(tmpstab->stab_flags & SF_VMAGIC ? stab_str(tmpstab) : tmpstab->stab_val))

EXT STAB *tmpstab;

EXT STAB *stab_index[128];

EXT char *envname;	/* place for ENV name being assigned--gross cheat */
EXT char *signame;	/* place for SIG name being assigned--gross cheat */

EXT int statusvalue;
EXT int subsvalue;

STAB *aadd();
STAB *hadd();
