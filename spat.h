/* $Header: spat.h,v 2.0 88/06/05 00:10:58 root Exp $
 *
 * $Log:	spat.h,v $
 * Revision 2.0  88/06/05  00:10:58  root
 * Baseline version 2.0.
 * 
 */

struct scanpat {
    SPAT	*spat_next;		/* list of all scanpats */
    REGEXP	*spat_regexp;		/* compiled expression */
    ARG		*spat_repl;		/* replacement string for subst */
    ARG		*spat_runtime;		/* compile pattern at runtime */
    STR		*spat_short;		/* for a fast bypass of execute() */
    bool	spat_flags;
    char	spat_slen;
};

#define SPAT_USED 1			/* spat has been used once already */
#define SPAT_ONCE 2			/* use pattern only once per article */
#define SPAT_SCANFIRST 4		/* initial constant not anchored */
#define SPAT_ALL 8			/* initial constant is whole pat */
#define SPAT_SKIPWHITE 16		/* skip leading whitespace for split */
#define SPAT_FOLD 32			/* case insensitivity */

EXT SPAT *spat_root;		/* list of all spats */
EXT SPAT *curspat;		/* what to do \ interps from */
EXT SPAT *lastspat;		/* what to use in place of null pattern */

EXT char *hint INIT(Nullch);	/* hint from cmd_exec to do_match et al */

#define Nullspat Null(SPAT*)
