/* $Header: spat.h,v 3.0 89/10/18 15:23:14 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	spat.h,v $
 * Revision 3.0  89/10/18  15:23:14  lwall
 * 3.0 baseline
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
#define SPAT_ONCE 2			/* use pattern only once per reset */
#define SPAT_SCANFIRST 4		/* initial constant not anchored */
#define SPAT_ALL 8			/* initial constant is whole pat */
#define SPAT_SKIPWHITE 16		/* skip leading whitespace for split */
#define SPAT_FOLD 32			/* case insensitivity */
#define SPAT_CONST 64			/* subst replacement is constant */
#define SPAT_KEEP 128			/* keep 1st runtime pattern forever */

EXT SPAT *curspat;		/* what to do \ interps from */
EXT SPAT *lastspat;		/* what to use in place of null pattern */

EXT char *hint INIT(Nullch);	/* hint from cmd_exec to do_match et al */

#define Nullspat Null(SPAT*)
