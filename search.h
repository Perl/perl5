/* $Header: search.h,v 1.0 87/12/18 13:06:06 root Exp $
 *
 * $Log:	search.h,v $
 * Revision 1.0  87/12/18  13:06:06  root
 * Initial revision
 * 
 */

#ifndef MAXSUB
#define	MAXSUB	10		/* how many sub-patterns are allowed */
#define MAXALT	10		/* how many alternatives are allowed */
 
typedef struct {	
    char *precomp;		/* the original pattern, for debug output */
    char *compbuf;		/* the compiled pattern */
    int complen;		/* length of compbuf */
    char *alternatives[MAXALT];	/* list of alternatives */
    char *subbeg[MAXSUB];	/* subpattern start list */
    char *subend[MAXSUB];	/* subpattern end list */
    char *subbase;		/* saved match string after execute() */
    char lastparen;		/* which subpattern matched last */
    char numsubs;		/* how many subpatterns the compiler saw */
    bool do_folding;		/* fold upper and lower case? */
} COMPEX;

EXT int multiline INIT(0);

void	search_init();
void	init_compex();
void	free_compex();
char	*getparen();
void	case_fold();
char	*compile(); 
void	grow_comp();
char	*execute(); 
bool	try();
bool	subpat(); 
bool	cclass(); 
#endif
