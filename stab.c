/* $Header: stab.c,v 2.0 88/06/05 00:11:01 root Exp $
 *
 * $Log:	stab.c,v $
 * Revision 2.0  88/06/05  00:11:01  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#include <signal.h>

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
extern int sys_nerr;
extern char *sys_errlist[];

STR *
stab_str(stab)
STAB *stab;
{
    register int paren;
    register char *s;
    register int i;

    switch (*stab->stab_name) {
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '&':
	if (curspat) {
	    paren = atoi(stab->stab_name);
	  getparen:
	    if (curspat->spat_regexp &&
	      paren <= curspat->spat_regexp->nparens &&
	      (s = curspat->spat_regexp->startp[paren]) ) {
		i = curspat->spat_regexp->endp[paren] - s;
		if (i >= 0)
		    str_nset(stab->stab_val,s,i);
		else
		    str_nset(stab->stab_val,"",0);
	    }
	    else
		str_nset(stab->stab_val,"",0);
	}
	break;
    case '+':
	if (curspat) {
	    paren = curspat->spat_regexp->lastparen;
	    goto getparen;
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
	str_numset(stab->stab_val,(double)curoutstab->stab_io->page_len);
	break;
    case '-':
	str_numset(stab->stab_val,(double)curoutstab->stab_io->lines_left);
	break;
    case '%':
	str_numset(stab->stab_val,(double)curoutstab->stab_io->page);
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
	str_numset(stab->stab_val, (double)errno);
	str_set(stab->stab_val,
	  errno < 0 || errno > sys_nerr ? "(unknown)" : sys_errlist[errno]);
	stab->stab_val->str_nok = 1;	/* what a wonderful hack! */
	break;
    case '<':
	str_numset(stab->stab_val,(double)uid);
	break;
    case '>':
	str_numset(stab->stab_val,(double)euid);
	break;
    case '(':
	s = tokenbuf;
	sprintf(s,"%d",(int)getgid());
	goto add_groups;
    case ')':
	s = tokenbuf;
	sprintf(s,"%d",(int)getegid());
      add_groups:
	while (*s) s++;
#ifdef GETGROUPS
#ifndef NGROUPS
#define NGROUPS 32
#endif
	{
	    GIDTYPE gary[NGROUPS];

	    i = getgroups(NGROUPS,gary);
	    while (--i >= 0) {
		sprintf(s," %ld", (long)gary[i]);
		while (*s) s++;
	    }
	}
#endif
	str_set(stab->stab_val,tokenbuf);
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
	    curoutstab->stab_io->top_name = s = savestr(str_get(str));
	    curoutstab->stab_io->top_stab = stabent(s,TRUE);
	    break;
	case '~':
	    safefree(curoutstab->stab_io->fmt_name);
	    curoutstab->stab_io->fmt_name = s = savestr(str_get(str));
	    curoutstab->stab_io->fmt_stab = stabent(s,TRUE);
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
	case '?':
	    statusvalue = (unsigned short)str_gnum(str);
	    break;
	case '!':
	    errno = (int)str_gnum(str);		/* will anyone ever use this? */
	    break;
	case '<':
#ifdef SETRUID
	    uid = (int)str_gnum(str);
	    if (setruid(uid) < 0)
		uid = (int)getuid();
#else
	    fatal("setruid() not implemented");
#endif
	    break;
	case '>':
#ifdef SETEUID
	    euid = (int)str_gnum(str);
	    if (seteuid(euid) < 0)
		euid = (int)geteuid();
#else
	    fatal("seteuid() not implemented");
#endif
	    break;
	case '(':
#ifdef SETRGID
	    setrgid((int)str_gnum(str));
#else
	    fatal("setrgid() not implemented");
#endif
	    break;
	case ')':
#ifdef SETEGID
	    setegid((int)str_gnum(str));
#else
	    fatal("setegid() not implemented");
#endif
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
	    break;		/* "read-only" registers */
	}
    }
    else if (stab == envstab && envname) {
	setenv(envname,str_get(str));
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
    else if (stab->stab_array) {
	afill(stab->stab_array, (int)str_gnum(str) - arybase);
    }
}

whichsig(sig)
char *sig;
{
    register char **sigv;

    for (sigv = sig_name+1; *sigv; sigv++)
	if (strEQ(sig,*sigv))
	    return sigv - sig_name;
    return 0;
}

sighandler(sig)
int sig;
{
    STAB *stab;
    ARRAY *savearray;
    STR *str;
    char *oldfile = filename;
    int oldsave = savestack->ary_fill;
    SUBR *sub;

    stab = stabent(str_get(hfetch(sigstab->stab_hash,sig_name[sig])),TRUE);
    sub = stab->stab_sub;
    if (!sub) {
	if (dowarn)
	    warn("SIG%s handler \"%s\" not defined.\n",
		sig_name[sig], stab->stab_name );
	return;
    }
    savearray = defstab->stab_array;
    defstab->stab_array = anew(defstab);
    str = str_new(0);
    str_set(str,sig_name[sig]);
    apush(defstab->stab_array,str);
    sub->depth++;
    if (sub->depth >= 2) {	/* save temporaries on recursion? */
	if (sub->depth == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",stab->stab_name);
	savelist(sub->tosave->ary_array,sub->tosave->ary_fill);
    }
    filename = sub->filename;

    str = cmd_exec(sub->cmd);		/* so do it already */

    sub->depth--;	/* assuming no longjumps out of here */
    afree(defstab->stab_array);  /* put back old $_[] */
    defstab->stab_array = savearray;
    filename = oldfile;
    if (savestack->ary_fill > oldsave)
	restorelist(oldsave);
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
	stab->stab_array = anew(stab);
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

STAB *
stabent(name,add)
register char *name;
int add;
{
    register STAB *stab;

    for (stab = stab_index[*name]; stab; stab = stab->stab_next) {
	if (strEQ(name,stab->stab_name)) {
	    stab->stab_flags |= SF_MULTI;	/* is okay, probably */
	    return stab;
	}
    }
    
    /* no entry--should we add one? */

    if (add) {
	stab = (STAB *) safemalloc(sizeof(STAB));
	bzero((char*)stab, sizeof(STAB));
	stab->stab_name = savestr(name);
	stab->stab_val = str_new(0);
	stab->stab_next = stab_index[*name];
	stab_index[*name] = stab;
	return stab;
    }
    return Nullstab;
}

STIO *
stio_new()
{
    STIO *stio = (STIO *) safemalloc(sizeof(STIO));

    bzero((char*)stio, sizeof(STIO));
    stio->page_len = 60;
    return stio;
}

stab_check(min,max)
int min;
register int max;
{
    register int i;
    register STAB *stab;

    for (i = min; i <= max; i++) {
	for (stab = stab_index[i]; stab; stab = stab->stab_next) {
	    if (stab->stab_flags & SF_MULTI)
		continue;
	    if (i == 'A' && strEQ(stab->stab_name, "ARGV"))
		continue;
	    if (i == 'E' && strEQ(stab->stab_name, "ENV"))
		continue;
	    if (i == 'S' && strEQ(stab->stab_name, "SIG"))
		continue;
	    if (i == 'I' && strEQ(stab->stab_name, "INC"))
		continue;
	    warn("Possible typo: %s,", stab->stab_name);
	}
    }
}
