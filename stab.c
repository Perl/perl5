/* $Header: stab.c,v 1.0.1.2 88/02/02 11:25:53 root Exp $
 *
 * $Log:	stab.c,v $
 * Revision 1.0.1.2  88/02/02  11:25:53  root
 * patch13: moved extern int out of function for a poor Xenix machine.
 * 
 * Revision 1.0.1.1  88/01/28  10:35:17  root
 * patch8: changed some stabents to support eval operator.
 * 
 * Revision 1.0  87/12/18  13:06:14  root
 * Initial revision
 * 
 */

#include <signal.h>
#include "handy.h"
#include "EXTERN.h"
#include "search.h"
#include "util.h"
#include "perl.h"

static char *sig_name[] = {
    "",
    "HUP",
    "INT",
    "QUIT",
    "ILL",
    "TRAP",
    "IOT",
    "EMT",
    "FPE",
    "KILL",
    "BUS",
    "SEGV",
    "SYS",
    "PIPE",
    "ALRM",
    "TERM",
    "???"
#ifdef SIGTSTP
    ,"STOP",
    "TSTP",
    "CONT",
    "CHLD",
    "TTIN",
    "TTOU",
    "TINT",
    "XCPU",
    "XFSZ"
#ifdef SIGPROF
    ,"VTALARM",
    "PROF"
#ifdef SIGWINCH
    ,"WINCH"
#ifdef SIGLOST
    ,"LOST"
#ifdef SIGUSR1
    ,"USR1"
#endif
#ifdef SIGUSR2
    ,"USR2"
#endif /* SIGUSR2 */
#endif /* SIGLOST */
#endif /* SIGWINCH */
#endif /* SIGPROF */
#endif /* SIGTSTP */
    ,0
    };

extern int errno;

STR *
stab_str(stab)
STAB *stab;
{
    register int paren;
    register char *s;

    switch (*stab->stab_name) {
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '&':
	if (curspat) {
	    paren = atoi(stab->stab_name);
	    if (curspat->spat_compex.subend[paren] &&
	      (s = getparen(&curspat->spat_compex,paren))) {
		curspat->spat_compex.subend[paren] = Nullch;
		str_set(stab->stab_val,s);
	    }
	}
	break;
    case '+':
	if (curspat) {
	    paren = curspat->spat_compex.lastparen;
	    if (curspat->spat_compex.subend[paren] &&
	      (s = getparen(&curspat->spat_compex,paren))) {
		curspat->spat_compex.subend[paren] = Nullch;
		str_set(stab->stab_val,s);
	    }
	}
	break;
    case '.':
	if (last_in_stab) {
	    str_numset(stab->stab_val,(double)last_in_stab->stab_io->lines);
	}
	break;
    case '?':
	str_numset(stab->stab_val,(double)statusvalue);
	break;
    case '^':
	s = curoutstab->stab_io->top_name;
	str_set(stab->stab_val,s);
	break;
    case '~':
	s = curoutstab->stab_io->fmt_name;
	str_set(stab->stab_val,s);
	break;
    case '=':
	str_numset(stab->stab_val,(double)curoutstab->stab_io->lines);
	break;
    case '-':
	str_numset(stab->stab_val,(double)curoutstab->stab_io->lines_left);
	break;
    case '%':
	str_numset(stab->stab_val,(double)curoutstab->stab_io->page);
	break;
    case '(':
	if (curspat) {
	    str_numset(stab->stab_val,(double)(curspat->spat_compex.subbeg[0] -
		curspat->spat_compex.subbase));
	}
	break;
    case ')':
	if (curspat) {
	    str_numset(stab->stab_val,(double)(curspat->spat_compex.subend[0] -
		curspat->spat_compex.subbeg[0]));
	}
	break;
    case '/':
	*tokenbuf = record_separator;
	tokenbuf[1] = '\0';
	str_set(stab->stab_val,tokenbuf);
	break;
    case '[':
	str_numset(stab->stab_val,(double)arybase);
	break;
    case '|':
	str_numset(stab->stab_val,
	   (double)((curoutstab->stab_io->flags & IOF_FLUSH) != 0) );
	break;
    case ',':
	str_set(stab->stab_val,ofs);
	break;
    case '\\':
	str_set(stab->stab_val,ors);
	break;
    case '#':
	str_set(stab->stab_val,ofmt);
	break;
    case '!':
	str_numset(stab->stab_val,(double)errno);
	break;
    }
    return stab->stab_val;
}

stabset(stab,str)
register STAB *stab;
STR *str;
{
    char *s;
    int i;
    int sighandler();

    if (stab->stab_flags & SF_VMAGIC) {
	switch (stab->stab_name[0]) {
	case '^':
	    safefree(curoutstab->stab_io->top_name);
	    curoutstab->stab_io->top_name = str_get(str);
	    curoutstab->stab_io->top_stab = stabent(str_get(str),TRUE);
	    break;
	case '~':
	    /* FIXME: investigate more carefully.  When the following
	     * safefree is allowed to happen the subsequent stabent call
	     * results in a segfault.  Commenting it out is a cheap band-aid
	     * and probably a memory leak rolled into one 
	     * 	-- richardc 2002-08-14
	     */
	    /* safefree(curoutstab->stab_io->fmt_name); */
	    curoutstab->stab_io->fmt_name = str_get(str);
	    curoutstab->stab_io->fmt_stab = stabent(str_get(str),TRUE);
	    break;
	case '=':
	    curoutstab->stab_io->page_len = (long)str_gnum(str);
	    break;
	case '-':
	    curoutstab->stab_io->lines_left = (long)str_gnum(str);
	    break;
	case '%':
	    curoutstab->stab_io->page = (long)str_gnum(str);
	    break;
	case '|':
	    curoutstab->stab_io->flags &= ~IOF_FLUSH;
	    if (str_gnum(str) != 0.0) {
		curoutstab->stab_io->flags |= IOF_FLUSH;
	    }
	    break;
	case '*':
	    multiline = (int)str_gnum(str) != 0;
	    break;
	case '/':
	    record_separator = *str_get(str);
	    break;
	case '\\':
	    if (ors)
		safefree(ors);
	    ors = savestr(str_get(str));
	    break;
	case ',':
	    if (ofs)
		safefree(ofs);
	    ofs = savestr(str_get(str));
	    break;
	case '#':
	    if (ofmt)
		safefree(ofmt);
	    ofmt = savestr(str_get(str));
	    break;
	case '[':
	    arybase = (int)str_gnum(str);
	    break;
	case '!':
	    errno = (int)str_gnum(str);		/* will anyone ever use this? */
	    break;
	case '.':
	case '+':
	case '&':
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	case '(':
	case ')':
	    break;		/* "read-only" registers */
	}
    }
    else if (stab == envstab && envname) {
	PL_setenv(envname,str_get(str));
				/* And you'll never guess what the dog had */
	safefree(envname);	/*   in its mouth... */
	envname = Nullch;
    }
    else if (stab == sigstab && signame) {
	s = str_get(str);
	i = whichsig(signame);	/* ...no, a brick */
	if (strEQ(s,"IGNORE"))
	    signal(i,SIG_IGN);
	else if (strEQ(s,"DEFAULT") || !*s)
	    signal(i,SIG_DFL);
	else
	    signal(i,sighandler);
	safefree(signame);
	signame = Nullch;
    }
}

whichsig(signame)
char *signame;
{
    register char **sigv;

    for (sigv = sig_name+1; *sigv; sigv++)
	if (strEQ(signame,*sigv))
	    return sigv - sig_name;
    return 0;
}

sighandler(sig)
int sig;
{
    STAB *stab;
    ARRAY *savearray;
    STR *str;

    stab = stabent(str_get(hfetch(sigstab->stab_hash,sig_name[sig])),TRUE);
    savearray = defstab->stab_array;
    defstab->stab_array = anew();
    str = str_new(0);
    str_set(str,sig_name[sig]);
    apush(defstab->stab_array,str);
    str = cmd_exec(stab->stab_sub);
    afree(defstab->stab_array);  /* put back old $_[] */
    defstab->stab_array = savearray;
}

char *
reg_get(name)
char *name;
{
    return STAB_GET(stabent(name,TRUE));
}

#ifdef NOTUSED
reg_set(name,value)
char *name;
char *value;
{
    str_set(STAB_STR(stabent(name,TRUE)),value);
}
#endif

STAB *
aadd(stab)
register STAB *stab;
{
    if (!stab->stab_array)
	stab->stab_array = anew();
    return stab;
}

STAB *
hadd(stab)
register STAB *stab;
{
    if (!stab->stab_hash)
	stab->stab_hash = hnew();
    return stab;
}
