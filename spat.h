/* $Header: spat.h,v 1.0.1.1 88/02/02 11:24:37 root Exp $
 *
 * $Log:	spat.h,v $
 * Revision 1.0.1.1  88/02/02  11:24:37  root
 * patch13: added flag for stripping leading spaces on split.
 * 
 * Revision 1.0  87/12/18  13:06:10  root
 * Initial revision
 * 
 */

struct scanpat {
    SPAT	*spat_next;		/* list of all scanpats */
    COMPEX	spat_compex;		/* compiled expression */
    ARG		*spat_repl;		/* replacement string for subst */
    ARG		*spat_runtime;		/* compile pattern at runtime */
    STR		*spat_first;		/* for a fast bypass of execute() */
    bool	spat_flags;
    char	spat_flen;
};

#define SPAT_USED 1			/* spat has been used once already */
#define SPAT_USE_ONCE 2			/* use pattern only once per article */
#define SPAT_SCANFIRST 4		/* initial constant not anchored */
#define SPAT_SCANALL 8			/* initial constant is whole pat */
#define SPAT_SKIPWHITE 16		/* skip leading whitespace for split */

EXT SPAT *spat_root;		/* list of all spats */
EXT SPAT *curspat;		/* what to do \ interps from */

#define Nullspat Null(SPAT*)
