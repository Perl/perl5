/* $Header: arg.c,v 1.0.1.7 88/02/02 11:22:19 root Exp $
 *
 * $Log:	arg.c,v $
 * Revision 1.0.1.7  88/02/02  11:22:19  root
 * patch13: fixed split(' ') to work right second time.  Added CRYPT dependency.
 * 
 * Revision 1.0.1.6  88/02/01  17:32:26  root
 * patch12: made split(' ') behave like awk in ignoring leading white space.
 * 
 * Revision 1.0.1.5  88/01/30  08:53:16  root
 * patch9: fixed some missing right parens introduced (?) by patch 2
 * 
 * Revision 1.0.1.4  88/01/28  10:22:06  root
 * patch8: added eval operator.
 * 
 * Revision 1.0.1.2  88/01/24  03:52:34  root
 * patch 2: added STATBLKS dependencies.
 * 
 * Revision 1.0.1.1  88/01/21  21:27:10  root
 * Now defines signal return values correctly using VOIDSIG.
 * 
 * Revision 1.0  87/12/18  13:04:33  root
 * Initial revision
 * 
 */

#include <signal.h>
#include "handy.h"
#include "EXTERN.h"
#include "search.h"
#include "util.h"
#include "perl.h"

ARG *debarg;

bool
do_match(s,arg)
register char *s;
register ARG *arg;
{
    register SPAT *spat = arg[2].arg_ptr.arg_spat;
    register char *d;
    register char *t;

    if (!spat || !s)
	fatal("panic: do_match\n");
    if (spat->spat_flags & SPAT_USED) {
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT USED\n");
#endif
	return FALSE;
    }
    if (spat->spat_runtime) {
	t = str_get(eval(spat->spat_runtime,Null(STR***)));
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT /%s/\n",t);
#endif
	if (d = compile(&spat->spat_compex,t,TRUE,FALSE)) {
#ifdef DEBUGGING
	    deb("/%s/: %s\n", t, d);
#endif
	    return FALSE;
	}
	if (spat->spat_compex.complen <= 1 && curspat)
	    spat = curspat;
	if (execute(&spat->spat_compex, s, TRUE, 0)) {
	    if (spat->spat_compex.numsubs)
		curspat = spat;
	    return TRUE;
	}
	else
	    return FALSE;
    }
    else {
#ifdef DEBUGGING
	if (debug & 8) {
	    char ch;

	    if (spat->spat_flags & SPAT_USE_ONCE)
		ch = '?';
	    else
		ch = '/';
	    deb("2.SPAT %c%s%c\n",ch,spat->spat_compex.precomp,ch);
	}
#endif
	if (spat->spat_compex.complen <= 1 && curspat)
	    spat = curspat;
	if (spat->spat_first) {
	    if (spat->spat_flags & SPAT_SCANFIRST) {
		str_free(spat->spat_first);
		spat->spat_first = Nullstr;	/* disable optimization */
	    }
	    else if (*spat->spat_first->str_ptr != *s ||
	      strnNE(spat->spat_first->str_ptr, s, spat->spat_flen) )
		return FALSE;
	}
	if (execute(&spat->spat_compex, s, TRUE, 0)) {
	    if (spat->spat_compex.numsubs)
		curspat = spat;
	    if (spat->spat_flags & SPAT_USE_ONCE)
		spat->spat_flags |= SPAT_USED;
	    return TRUE;
	}
	else
	    return FALSE;
    }
    /*NOTREACHED*/
}

int
do_subst(str,arg)
STR *str;
register ARG *arg;
{
    register SPAT *spat;
    register STR *dstr;
    register char *s;
    register char *m;

    spat = arg[2].arg_ptr.arg_spat;
    s = str_get(str);
    if (!spat || !s)
	fatal("panic: do_subst\n");
    else if (spat->spat_runtime) {
	char *d;

	m = str_get(eval(spat->spat_runtime,Null(STR***)));
	if (d = compile(&spat->spat_compex,m,TRUE,FALSE)) {
#ifdef DEBUGGING
	    deb("/%s/: %s\n", m, d);
#endif
	    return 0;
	}
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_compex.precomp);
    }
#endif
    if (spat->spat_compex.complen <= 1 && curspat)
	spat = curspat;
    if (spat->spat_first) {
	if (spat->spat_flags & SPAT_SCANFIRST) {
	    str_free(spat->spat_first);
	    spat->spat_first = Nullstr;	/* disable optimization */
	}
	else if (*spat->spat_first->str_ptr != *s ||
	  strnNE(spat->spat_first->str_ptr, s, spat->spat_flen) )
	    return 0;
    }
    if (m = execute(&spat->spat_compex, s, TRUE, 1)) {
	int iters = 0;

	dstr = str_new(str_len(str));
	if (spat->spat_compex.numsubs)
	    curspat = spat;
	do {
	    if (iters++ > 10000)
		fatal("Substitution loop?\n");
	    if (spat->spat_compex.numsubs)
		s = spat->spat_compex.subbase;
	    str_ncat(dstr,s,m-s);
	    s = spat->spat_compex.subend[0];
	    str_scat(dstr,eval(spat->spat_repl,Null(STR***)));
	    if (spat->spat_flags & SPAT_USE_ONCE)
		break;
	} while (m = execute(&spat->spat_compex, s, FALSE, 1));
	str_cat(dstr,s);
	str_replace(str,dstr);
	STABSET(str);
	return iters;
    }
    return 0;
}

int
do_trans(str,arg)
STR *str;
register ARG *arg;
{
    register char *tbl;
    register char *s;
    register int matches = 0;
    register int ch;

    tbl = arg[2].arg_ptr.arg_cval;
    s = str_get(str);
    if (!tbl || !s)
	fatal("panic: do_trans\n");
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.TBL\n");
    }
#endif
    while (*s) {
	if (ch = tbl[*s & 0377]) {
	    matches++;
	    *s = ch;
	}
	s++;
    }
    STABSET(str);
    return matches;
}

int
do_split(s,spat,retary)
register char *s;
register SPAT *spat;
STR ***retary;
{
    register STR *dstr;
    register char *m;
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int iters = 0;
    STR **sarg;
    register char *e;
    int i;

    if (!spat || !s)
	fatal("panic: do_split\n");
    else if (spat->spat_runtime) {
	char *d;

	m = str_get(eval(spat->spat_runtime,Null(STR***)));
	if (!*m || (*m == ' ' && !m[1])) {
	    m = "[ \\t\\n]+";
	    spat->spat_flags |= SPAT_SKIPWHITE;
	}
	if (spat->spat_runtime->arg_type == O_ITEM &&
	  spat->spat_runtime[1].arg_type == A_SINGLE) {
	    arg_free(spat->spat_runtime);	/* it won't change, so */
	    spat->spat_runtime = Nullarg;	/* no point compiling again */
	}
	if (d = compile(&spat->spat_compex,m,TRUE,FALSE)) {
#ifdef DEBUGGING
	    deb("/%s/: %s\n", m, d);
#endif
	    return FALSE;
	}
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_compex.precomp);
    }
#endif
    if (retary)
	ary = myarray;
    else
	ary = spat->spat_repl[1].arg_ptr.arg_stab->stab_array;
    if (!ary)
	myarray = ary = anew();
    ary->ary_fill = -1;
    if (spat->spat_flags & SPAT_SKIPWHITE) {
	while (isspace(*s))
	    s++;
    }
    while (*s && (m = execute(&spat->spat_compex, s, (iters == 0), 1))) {
	if (spat->spat_compex.numsubs)
	    s = spat->spat_compex.subbase;
	dstr = str_new(m-s);
	str_nset(dstr,s,m-s);
	astore(ary, iters++, dstr);
	if (iters > 10000)
	    fatal("Substitution loop?\n");
	s = spat->spat_compex.subend[0];
    }
    if (*s) {			/* ignore field after final "whitespace" */
	dstr = str_new(0);	/*   if they interpolate, it's null anyway */
	str_set(dstr,s);
	astore(ary, iters++, dstr);
    }
    else {
	while (iters > 0 && !*str_get(afetch(ary,iters-1)))
	    iters--;
    }
    if (retary) {
	sarg = (STR**)safemalloc((iters+2)*sizeof(STR*));

	sarg[0] = Nullstr;
	sarg[iters+1] = Nullstr;
	for (i = 1; i <= iters; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return iters;
}

void
do_join(arg,delim,str)
register ARG *arg;
register char *delim;
register STR *str;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;

    (void)eval(arg[2].arg_ptr.arg_arg,&tmpary);
    elem = tmpary+1;
    if (*elem)
    str_sset(str,*elem++);
    for (; *elem; elem++) {
	str_cat(str,delim);
	str_scat(str,*elem);
    }
    STABSET(str);
    safefree((char*)tmpary);
}

bool
do_open(stab,name)
STAB *stab;
register char *name;
{
    FILE *fp;
    int len = strlen(name);
    register STIO *stio = stab->stab_io;

    while (len && isspace(name[len-1]))
	name[--len] = '\0';
    if (!stio)
	stio = stab->stab_io = stio_new();
    if (stio->fp) {
	if (stio->type == '|')
	    pclose(stio->fp);
	else if (stio->type != '-')
	    fclose(stio->fp);
	stio->fp = Nullfp;
    }
    stio->type = *name;
    if (*name == '|') {
	for (name++; isspace(*name); name++) ;
	fp = popen(name,"w");
    }
    else if (*name == '>' && name[1] == '>') {
	for (name += 2; isspace(*name); name++) ;
	fp = fopen(name,"a");
    }
    else if (*name == '>') {
	for (name++; isspace(*name); name++) ;
	if (strEQ(name,"-")) {
	    fp = stdout;
	    stio->type = '-';
	}
	else
	    fp = fopen(name,"w");
    }
    else {
	if (*name == '<') {
	    for (name++; isspace(*name); name++) ;
	    if (strEQ(name,"-")) {
		fp = stdin;
		stio->type = '-';
	    }
	    else
		fp = fopen(name,"r");
	}
	else if (name[len-1] == '|') {
	    name[--len] = '\0';
	    while (len && isspace(name[len-1]))
		name[--len] = '\0';
	    for (; isspace(*name); name++) ;
	    fp = popen(name,"r");
	    stio->type = '|';
	}
	else {
	    stio->type = '<';
	    for (; isspace(*name); name++) ;
	    if (strEQ(name,"-")) {
		fp = stdin;
		stio->type = '-';
	    }
	    else
		fp = fopen(name,"r");
	}
    }
    if (!fp)
	return FALSE;
    if (stio->type != '|' && stio->type != '-') {
	if (fstat(fileno(fp),&statbuf) < 0) {
	    fclose(fp);
	    return FALSE;
	}
	if ((statbuf.st_mode & S_IFMT) != S_IFREG &&
	    (statbuf.st_mode & S_IFMT) != S_IFCHR) {
	    fclose(fp);
	    return FALSE;
	}
    }
    stio->fp = fp;
    return TRUE;
}

FILE *
nextargv(stab)
register STAB *stab;
{
    register STR *str;
    char *oldname;

    while (alen(stab->stab_array) >= 0L) {
	str = ashift(stab->stab_array);
	str_sset(stab->stab_val,str);
	STABSET(stab->stab_val);
	oldname = str_get(stab->stab_val);
	if (do_open(stab,oldname)) {
	    if (inplace) {
		if (*inplace) {
		    str_cat(str,inplace);
#ifdef RENAME
		    rename(oldname,str->str_ptr);
#else
		    UNLINK(str->str_ptr);
		    link(oldname,str->str_ptr);
		    UNLINK(oldname);
#endif
		}
		sprintf(tokenbuf,">%s",oldname);
		do_open(argvoutstab,tokenbuf);
		defoutstab = argvoutstab;
	    }
	    str_free(str);
	    return stab->stab_io->fp;
	}
	else
	    fprintf(stderr,"Can't open %s\n",str_get(str));
	str_free(str);
    }
    if (inplace) {
	do_close(argvoutstab,FALSE);
	defoutstab = stabent("stdout",TRUE);
    }
    return Nullfp;
}

bool
do_close(stab,explicit)
STAB *stab;
bool explicit;
{
    bool retval = FALSE;
    register STIO *stio = stab->stab_io;

    if (!stio)		/* never opened */
	return FALSE;
    if (stio->fp) {
	if (stio->type == '|')
	    retval = (pclose(stio->fp) >= 0);
	else if (stio->type == '-')
	    retval = TRUE;
	else
	    retval = (fclose(stio->fp) != EOF);
	stio->fp = Nullfp;
    }
    if (explicit)
	stio->lines = 0;
    stio->type = ' ';
    return retval;
}

bool
do_eof(stab)
STAB *stab;
{
    register STIO *stio;
    int ch;

    if (!stab)
	return TRUE;

    stio = stab->stab_io;
    if (!stio)
	return TRUE;

    while (stio->fp) {

#ifdef STDSTDIO			/* (the code works without this) */
	if (stio->fp->_cnt)		/* cheat a little, since */
	    return FALSE;		/* this is the most usual case */
#endif

	ch = getc(stio->fp);
	if (ch != EOF) {
	    ungetc(ch, stio->fp);
	    return FALSE;
	}
	if (stio->flags & IOF_ARGV) {	/* not necessarily a real EOF yet? */
	    if (!nextargv(stab))	/* get another fp handy */
		return TRUE;
	}
	else
	    return TRUE;		/* normal fp, definitely end of file */
    }
    return TRUE;
}

long
do_tell(stab)
STAB *stab;
{
    register STIO *stio;
    int ch;

    if (!stab)
	return -1L;

    stio = stab->stab_io;
    if (!stio || !stio->fp)
	return -1L;

    return ftell(stio->fp);
}

bool
do_seek(stab, pos, whence)
STAB *stab;
long pos;
int whence;
{
    register STIO *stio;

    if (!stab)
	return FALSE;

    stio = stab->stab_io;
    if (!stio || !stio->fp)
	return FALSE;

    return fseek(stio->fp, pos, whence) >= 0;
}

do_stat(arg,sarg,retary)
register ARG *arg;
register STR **sarg;
STR ***retary;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int max = 13;
    register int i;

    ary = myarray;
    if (!ary)
	myarray = ary = anew();
    ary->ary_fill = -1;
    if (arg[1].arg_type == A_LVAL) {
	tmpstab = arg[1].arg_ptr.arg_stab;
	if (!tmpstab->stab_io ||
	  fstat(fileno(tmpstab->stab_io->fp),&statbuf) < 0) {
	    max = 0;
	}
    }
    else
	if (stat(str_get(sarg[1]),&statbuf) < 0)
	    max = 0;

    if (retary) {
	if (max) {
	    apush(ary,str_nmake((double)statbuf.st_dev));
	    apush(ary,str_nmake((double)statbuf.st_ino));
	    apush(ary,str_nmake((double)statbuf.st_mode));
	    apush(ary,str_nmake((double)statbuf.st_nlink));
	    apush(ary,str_nmake((double)statbuf.st_uid));
	    apush(ary,str_nmake((double)statbuf.st_gid));
	    apush(ary,str_nmake((double)statbuf.st_rdev));
	    apush(ary,str_nmake((double)statbuf.st_size));
	    apush(ary,str_nmake((double)statbuf.st_atime));
	    apush(ary,str_nmake((double)statbuf.st_mtime));
	    apush(ary,str_nmake((double)statbuf.st_ctime));
#ifdef STATBLOCKS
	    apush(ary,str_nmake((double)statbuf.st_blksize));
	    apush(ary,str_nmake((double)statbuf.st_blocks));
#else
	    apush(ary,str_make(""));
	    apush(ary,str_make(""));
#endif
	}
	sarg = (STR**)safemalloc((max+2)*sizeof(STR*));
	sarg[0] = Nullstr;
	sarg[max+1] = Nullstr;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

do_tms(retary)
STR ***retary;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    register STR **sarg;
    int max = 4;
    register int i;

    ary = myarray;
    if (!ary)
	myarray = ary = anew();
    ary->ary_fill = -1;
    if (times(&timesbuf) < 0)
	max = 0;

    if (retary) {
	if (max) {
	    apush(ary,str_nmake(((double)timesbuf.tms_utime)/60.0));
	    apush(ary,str_nmake(((double)timesbuf.tms_stime)/60.0));
	    apush(ary,str_nmake(((double)timesbuf.tms_cutime)/60.0));
	    apush(ary,str_nmake(((double)timesbuf.tms_cstime)/60.0));
	}
	sarg = (STR**)safemalloc((max+2)*sizeof(STR*));
	sarg[0] = Nullstr;
	sarg[max+1] = Nullstr;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

do_time(tmbuf,retary)
struct tm *tmbuf;
STR ***retary;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    register STR **sarg;
    int max = 9;
    register int i;
    STR *str;

    ary = myarray;
    if (!ary)
	myarray = ary = anew();
    ary->ary_fill = -1;
    if (!tmbuf)
	max = 0;

    if (retary) {
	if (max) {
	    apush(ary,str_nmake((double)tmbuf->tm_sec));
	    apush(ary,str_nmake((double)tmbuf->tm_min));
	    apush(ary,str_nmake((double)tmbuf->tm_hour));
	    apush(ary,str_nmake((double)tmbuf->tm_mday));
	    apush(ary,str_nmake((double)tmbuf->tm_mon));
	    apush(ary,str_nmake((double)tmbuf->tm_year));
	    apush(ary,str_nmake((double)tmbuf->tm_wday));
	    apush(ary,str_nmake((double)tmbuf->tm_yday));
	    apush(ary,str_nmake((double)tmbuf->tm_isdst));
	}
	sarg = (STR**)safemalloc((max+2)*sizeof(STR*));
	sarg[0] = Nullstr;
	sarg[max+1] = Nullstr;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

void
do_sprintf(str,len,sarg)
register STR *str;
register int len;
register STR **sarg;
{
    register char *s;
    register char *t;
    bool dolong;
    char ch;
    static STR *sargnull = &str_no;

    str_set(str,"");
    len--;			/* don't count pattern string */
    sarg++;
    for (s = str_get(*(sarg++)); *s; len--) {
	if (len <= 0 || !*sarg) {
	    sarg = &sargnull;
	    len = 0;
	}
	dolong = FALSE;
	for (t = s; *t && *t != '%'; t++) ;
	if (!*t)
	    break;		/* not enough % patterns, oh well */
	for (t++; *sarg && *t && t != s; t++) {
	    switch (*t) {
	    case '\0':
		break;
	    case '%':
		ch = *(++t);
		*t = '\0';
		sprintf(buf,s);
		s = t;
		*(t--) = ch;
		break;
	    case 'l':
		dolong = TRUE;
		break;
	    case 'D': case 'X': case 'O':
		dolong = TRUE;
		/* FALL THROUGH */
	    case 'd': case 'x': case 'o': case 'c':
		ch = *(++t);
		*t = '\0';
		if (dolong)
		    sprintf(buf,s,(long)str_gnum(*(sarg++)));
		else
		    sprintf(buf,s,(int)str_gnum(*(sarg++)));
		s = t;
		*(t--) = ch;
		break;
	    case 'E': case 'e': case 'f': case 'G': case 'g':
		ch = *(++t);
		*t = '\0';
		sprintf(buf,s,str_gnum(*(sarg++)));
		s = t;
		*(t--) = ch;
		break;
	    case 's':
		ch = *(++t);
		*t = '\0';
		sprintf(buf,s,str_get(*(sarg++)));
		s = t;
		*(t--) = ch;
		break;
	    }
	}
	str_cat(str,buf);
    }
    if (*s)
	str_cat(str,s);
    STABSET(str);
}

bool
do_print(s,fp)
char *s;
FILE *fp;
{
    if (!fp || !s)
	return FALSE;
    fputs(s,fp);
    return TRUE;
}

bool
do_aprint(arg,fp)
register ARG *arg;
register FILE *fp;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register bool retval;
    double value;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary);
    if (arg->arg_type == O_PRTF) {
	do_sprintf(arg->arg_ptr.arg_str,32767,tmpary);
	retval = do_print(str_get(arg->arg_ptr.arg_str),fp);
    }
    else {
	retval = FALSE;
	for (elem = tmpary+1; *elem; elem++) {
	    if (retval && ofs)
		do_print(ofs, fp);
	    if (ofmt && fp) {
		if ((*elem)->str_nok || str_gnum(*elem) != 0.0)
		    fprintf(fp, ofmt, str_gnum(*elem));
		retval = TRUE;
	    }
	    else
		retval = do_print(str_get(*elem), fp);
	    if (!retval)
		break;
	}
	if (ors)
	    retval = do_print(ors, fp);
    }
    safefree((char*)tmpary);
    return retval;
}

bool
do_aexec(arg)
register ARG *arg;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register char **a;
    register int i;
    char **argv;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary);
    i = 0;
    for (elem = tmpary+1; *elem; elem++)
	i++;
    if (i) {
	argv = (char**)safemalloc((i+1)*sizeof(char*));
	a = argv;
	for (elem = tmpary+1; *elem; elem++) {
	    *a++ = str_get(*elem);
	}
	*a = Nullch;
	execvp(argv[0],argv);
	safefree((char*)argv);
    }
    safefree((char*)tmpary);
    return FALSE;
}

bool
do_exec(cmd)
char *cmd;
{
    STR **tmpary;	/* must not be register */
    register char **a;
    register char *s;
    char **argv;

    /* see if there are shell metacharacters in it */

    for (s = cmd; *s; s++) {
	if (*s != ' ' && !isalpha(*s) && index("$&*(){}[]'\";\\|?<>~`",*s)) {
	    execl("/bin/sh","sh","-c",cmd,0);
	    return FALSE;
	}
    }
    argv = (char**)safemalloc(((s - cmd) / 2 + 2)*sizeof(char*));

    a = argv;
    for (s = cmd; *s;) {
	while (isspace(*s)) s++;
	if (*s)
	    *(a++) = s;
	while (*s && !isspace(*s)) s++;
	if (*s)
	    *s++ = '\0';
    }
    *a = Nullch;
    if (argv[0])
	execvp(argv[0],argv);
    safefree((char*)argv);
    return FALSE;
}

STR *
do_push(arg,ary)
register ARG *arg;
register ARRAY *ary;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register STR *str = &str_no;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary);
    for (elem = tmpary+1; *elem; elem++) {
	str = str_new(0);
	str_sset(str,*elem);
	apush(ary,str);
    }
    safefree((char*)tmpary);
    return str;
}

do_unshift(arg,ary)
register ARG *arg;
register ARRAY *ary;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register STR *str = &str_no;
    register int i;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary);
    i = 0;
    for (elem = tmpary+1; *elem; elem++)
	i++;
    aunshift(ary,i);
    i = 0;
    for (elem = tmpary+1; *elem; elem++) {
	str = str_new(0);
	str_sset(str,*elem);
	astore(ary,i++,str);
    }
    safefree((char*)tmpary);
}

apply(type,arg,sarg)
int type;
register ARG *arg;
STR **sarg;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register int i;
    register int val;
    register int val2;

    if (sarg)
	tmpary = sarg;
    else
	(void)eval(arg[1].arg_ptr.arg_arg,&tmpary);
    i = 0;
    for (elem = tmpary+1; *elem; elem++)
	i++;
    switch (type) {
    case O_CHMOD:
	if (--i > 0) {
	    val = (int)str_gnum(tmpary[1]);
	    for (elem = tmpary+2; *elem; elem++)
		if (chmod(str_get(*elem),val))
		    i--;
	}
	break;
    case O_CHOWN:
	if (i > 2) {
	    i -= 2;
	    val = (int)str_gnum(tmpary[1]);
	    val2 = (int)str_gnum(tmpary[2]);
	    for (elem = tmpary+3; *elem; elem++)
		if (chown(str_get(*elem),val,val2))
		    i--;
	}
	else
	    i = 0;
	break;
    case O_KILL:
	if (--i > 0) {
	    val = (int)str_gnum(tmpary[1]);
	    if (val < 0)
		val = -val;
	    for (elem = tmpary+2; *elem; elem++)
		if (kill(atoi(str_get(*elem)),val))
		    i--;
	}
	break;
    case O_UNLINK:
	for (elem = tmpary+1; *elem; elem++)
	    if (UNLINK(str_get(*elem)))
		i--;
	break;
    }
    if (!sarg)
	safefree((char*)tmpary);
    return i;
}

STR *
do_subr(arg,sarg)
register ARG *arg;
register char **sarg;
{
    ARRAY *savearray;
    STR *str;

    savearray = defstab->stab_array;
    defstab->stab_array = anew();
    if (arg[1].arg_flags & AF_SPECIAL)
	(void)do_push(arg,defstab->stab_array);
    else if (arg[1].arg_type != A_NULL) {
	str = str_new(0);
	str_sset(str,sarg[1]);
	apush(defstab->stab_array,str);
    }
    str = cmd_exec(arg[2].arg_ptr.arg_stab->stab_sub);
    afree(defstab->stab_array);  /* put back old $_[] */
    defstab->stab_array = savearray;
    return str;
}

void
do_assign(retstr,arg)
STR *retstr;
register ARG *arg;
{
    STR **tmpary;	/* must not be register */
    register ARG *larg = arg[1].arg_ptr.arg_arg;
    register STR **elem;
    register STR *str;
    register ARRAY *ary;
    register int i;
    register int lasti;
    char *s;

    (void)eval(arg[2].arg_ptr.arg_arg,&tmpary);

    if (arg->arg_flags & AF_COMMON) {
	if (*(tmpary+1)) {
	    for (elem=tmpary+2; *elem; elem++) {
		*elem = str_static(*elem);
	    }
	}
    }
    if (larg->arg_type == O_LIST) {
	lasti = larg->arg_len;
	for (i=1,elem=tmpary+1; i <= lasti; i++) {
	    if (*elem)
		s = str_get(*(elem++));
	    else
		s = "";
	    switch (larg[i].arg_type) {
	    case A_STAB:
	    case A_LVAL:
		str = STAB_STR(larg[i].arg_ptr.arg_stab);
		break;
	    case A_LEXPR:
		str = eval(larg[i].arg_ptr.arg_arg,Null(STR***));
		break;
	    }
	    str_set(str,s);
	    STABSET(str);
	}
	i = elem - tmpary - 1;
    }
    else {			/* should be an array name */
	ary = larg[1].arg_ptr.arg_stab->stab_array;
	for (i=0,elem=tmpary+1; *elem; i++) {
	    str = str_new(0);
	    if (*elem)
		str_sset(str,*(elem++));
	    astore(ary,i,str);
	}
	ary->ary_fill = i - 1;	/* they can get the extra ones back by */
    }				/*   setting an element larger than old fill */
    str_numset(retstr,(double)i);
    STABSET(retstr);
    safefree((char*)tmpary);
}

int
do_kv(hash,kv,sarg,retary)
HASH *hash;
int kv;
register STR **sarg;
STR ***retary;
{
    register ARRAY *ary;
    int max = 0;
    int i;
    static ARRAY *myarray = Null(ARRAY*);
    register HENT *entry;

    ary = myarray;
    if (!ary)
	myarray = ary = anew();
    ary->ary_fill = -1;

    hiterinit(hash);
    while (entry = hiternext(hash)) {
	max++;
	if (kv == O_KEYS)
	    apush(ary,str_make(hiterkey(entry)));
	else
	    apush(ary,str_make(str_get(hiterval(entry))));
    }
    if (retary) { /* array wanted */
	sarg = (STR**)safemalloc((max+2)*sizeof(STR*));
	sarg[0] = Nullstr;
	sarg[max+1] = Nullstr;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

STR *
do_each(hash,sarg,retary)
HASH *hash;
register STR **sarg;
STR ***retary;
{
    static STR *mystr = Nullstr;
    STR *retstr;
    HENT *entry = hiternext(hash);

    if (mystr) {
	str_free(mystr);
	mystr = Nullstr;
    }

    if (retary) { /* array wanted */
	if (entry) {
	    sarg = (STR**)safemalloc(4*sizeof(STR*));
	    sarg[0] = Nullstr;
	    sarg[3] = Nullstr;
	    sarg[1] = mystr = str_make(hiterkey(entry));
	    retstr = sarg[2] = hiterval(entry);
	    *retary = sarg;
	}
	else {
	    sarg = (STR**)safemalloc(2*sizeof(STR*));
	    sarg[0] = Nullstr;
	    sarg[1] = retstr = Nullstr;
	    *retary = sarg;
	}
    }
    else
	retstr = hiterval(entry);
	
    return retstr;
}

init_eval()
{
    register int i;

#define A(e1,e2,e3) (e1+(e2<<1)+(e3<<2))
    opargs[O_ITEM] =		A(1,0,0);
    opargs[O_ITEM2] =		A(0,0,0);
    opargs[O_ITEM3] =		A(0,0,0);
    opargs[O_CONCAT] =		A(1,1,0);
    opargs[O_MATCH] =		A(1,0,0);
    opargs[O_NMATCH] =		A(1,0,0);
    opargs[O_SUBST] =		A(1,0,0);
    opargs[O_NSUBST] =		A(1,0,0);
    opargs[O_ASSIGN] =		A(1,1,0);
    opargs[O_MULTIPLY] =	A(1,1,0);
    opargs[O_DIVIDE] =		A(1,1,0);
    opargs[O_MODULO] =		A(1,1,0);
    opargs[O_ADD] =		A(1,1,0);
    opargs[O_SUBTRACT] =	A(1,1,0);
    opargs[O_LEFT_SHIFT] =	A(1,1,0);
    opargs[O_RIGHT_SHIFT] =	A(1,1,0);
    opargs[O_LT] =		A(1,1,0);
    opargs[O_GT] =		A(1,1,0);
    opargs[O_LE] =		A(1,1,0);
    opargs[O_GE] =		A(1,1,0);
    opargs[O_EQ] =		A(1,1,0);
    opargs[O_NE] =		A(1,1,0);
    opargs[O_BIT_AND] =		A(1,1,0);
    opargs[O_XOR] =		A(1,1,0);
    opargs[O_BIT_OR] =		A(1,1,0);
    opargs[O_AND] =		A(1,0,0);	/* don't eval arg 2 (yet) */
    opargs[O_OR] =		A(1,0,0);	/* don't eval arg 2 (yet) */
    opargs[O_COND_EXPR] =	A(1,0,0);	/* don't eval args 2 or 3 */
    opargs[O_COMMA] =		A(1,1,0);
    opargs[O_NEGATE] =		A(1,0,0);
    opargs[O_NOT] =		A(1,0,0);
    opargs[O_COMPLEMENT] =	A(1,0,0);
    opargs[O_WRITE] =		A(1,0,0);
    opargs[O_OPEN] =		A(1,1,0);
    opargs[O_TRANS] =		A(1,0,0);
    opargs[O_NTRANS] =		A(1,0,0);
    opargs[O_CLOSE] =		A(0,0,0);
    opargs[O_ARRAY] =		A(1,0,0);
    opargs[O_HASH] =		A(1,0,0);
    opargs[O_LARRAY] =		A(1,0,0);
    opargs[O_LHASH] =		A(1,0,0);
    opargs[O_PUSH] =		A(1,0,0);
    opargs[O_POP] =		A(0,0,0);
    opargs[O_SHIFT] =		A(0,0,0);
    opargs[O_SPLIT] =		A(1,0,0);
    opargs[O_LENGTH] =		A(1,0,0);
    opargs[O_SPRINTF] =		A(1,0,0);
    opargs[O_SUBSTR] =		A(1,1,1);
    opargs[O_JOIN] =		A(1,0,0);
    opargs[O_SLT] =		A(1,1,0);
    opargs[O_SGT] =		A(1,1,0);
    opargs[O_SLE] =		A(1,1,0);
    opargs[O_SGE] =		A(1,1,0);
    opargs[O_SEQ] =		A(1,1,0);
    opargs[O_SNE] =		A(1,1,0);
    opargs[O_SUBR] =		A(1,0,0);
    opargs[O_PRINT] =		A(1,0,0);
    opargs[O_CHDIR] =		A(1,0,0);
    opargs[O_DIE] =		A(1,0,0);
    opargs[O_EXIT] =		A(1,0,0);
    opargs[O_RESET] =		A(1,0,0);
    opargs[O_LIST] =		A(0,0,0);
    opargs[O_EOF] =		A(0,0,0);
    opargs[O_TELL] =		A(0,0,0);
    opargs[O_SEEK] =		A(0,1,1);
    opargs[O_LAST] =		A(1,0,0);
    opargs[O_NEXT] =		A(1,0,0);
    opargs[O_REDO] =		A(1,0,0);
    opargs[O_GOTO] =		A(1,0,0);
    opargs[O_INDEX] =		A(1,1,0);
    opargs[O_TIME] = 		A(0,0,0);
    opargs[O_TMS] = 		A(0,0,0);
    opargs[O_LOCALTIME] =	A(1,0,0);
    opargs[O_GMTIME] =		A(1,0,0);
    opargs[O_STAT] =		A(1,0,0);
    opargs[O_CRYPT] =		A(1,1,0);
    opargs[O_EXP] =		A(1,0,0);
    opargs[O_LOG] =		A(1,0,0);
    opargs[O_SQRT] =		A(1,0,0);
    opargs[O_INT] =		A(1,0,0);
    opargs[O_PRTF] =		A(1,0,0);
    opargs[O_ORD] = 		A(1,0,0);
    opargs[O_SLEEP] =		A(1,0,0);
    opargs[O_FLIP] =		A(1,0,0);
    opargs[O_FLOP] =		A(0,1,0);
    opargs[O_KEYS] =		A(0,0,0);
    opargs[O_VALUES] =		A(0,0,0);
    opargs[O_EACH] =		A(0,0,0);
    opargs[O_CHOP] =		A(1,0,0);
    opargs[O_FORK] =		A(1,0,0);
    opargs[O_EXEC] =		A(1,0,0);
    opargs[O_SYSTEM] =		A(1,0,0);
    opargs[O_OCT] =		A(1,0,0);
    opargs[O_HEX] =		A(1,0,0);
    opargs[O_CHMOD] =		A(1,0,0);
    opargs[O_CHOWN] =		A(1,0,0);
    opargs[O_KILL] =		A(1,0,0);
    opargs[O_RENAME] =		A(1,1,0);
    opargs[O_UNLINK] =		A(1,0,0);
    opargs[O_UMASK] =		A(1,0,0);
    opargs[O_UNSHIFT] =		A(1,0,0);
    opargs[O_LINK] =		A(1,1,0);
    opargs[O_REPEAT] =		A(1,1,0);
    opargs[O_EVAL] =		A(1,0,0);
}

#ifdef VOIDSIG
static void (*ihand)();
static void (*qhand)();
#else
static int (*ihand)();
static int (*qhand)();
#endif

STR *
eval(arg,retary)
register ARG *arg;
STR ***retary;		/* where to return an array to, null if nowhere */
{
    register STR *str;
    register int anum;
    register int optype;
    register int maxarg;
    double value;
    STR *quicksarg[5];
    register STR **sarg = quicksarg;
    register char *tmps;
    char *tmps2;
    int argflags;
    long tmplong;
    FILE *fp;
    STR *tmpstr;
    FCMD *form;
    STAB *stab;
    ARRAY *ary;
    bool assigning = FALSE;
    double exp(), log(), sqrt(), modf();
    char *crypt(), *getenv();

    if (!arg)
	return &str_no;
    str = arg->arg_ptr.arg_str;
    optype = arg->arg_type;
    maxarg = arg->arg_len;
    if (maxarg > 3 || retary) {
	sarg = (STR **)safemalloc((maxarg+2) * sizeof(STR*));
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("%s (%lx) %d args:\n",opname[optype],arg,maxarg);
    }
    debname[dlevel] = opname[optype][0];
    debdelim[dlevel++] = ':';
#endif
    for (anum = 1; anum <= maxarg; anum++) {
	argflags = arg[anum].arg_flags;
	if (argflags & AF_SPECIAL)
	    continue;
      re_eval:
	switch (arg[anum].arg_type) {
	default:
	    sarg[anum] = &str_no;
#ifdef DEBUGGING
	    tmps = "NULL";
#endif
	    break;
	case A_EXPR:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "EXPR";
		deb("%d.EXPR =>\n",anum);
	    }
#endif
	    sarg[anum] = eval(arg[anum].arg_ptr.arg_arg, Null(STR***));
	    break;
	case A_CMD:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "CMD";
		deb("%d.CMD (%lx) =>\n",anum,arg[anum].arg_ptr.arg_cmd);
	    }
#endif
	    sarg[anum] = cmd_exec(arg[anum].arg_ptr.arg_cmd);
	    break;
	case A_STAB:
	    sarg[anum] = STAB_STR(arg[anum].arg_ptr.arg_stab);
#ifdef DEBUGGING
	    if (debug & 8) {
		sprintf(buf,"STAB $%s ==",arg[anum].arg_ptr.arg_stab->stab_name);
		tmps = buf;
	    }
#endif
	    break;
	case A_LEXPR:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "LEXPR";
		deb("%d.LEXPR =>\n",anum);
	    }
#endif
	    str = eval(arg[anum].arg_ptr.arg_arg,Null(STR***));
	    if (!str)
		fatal("panic: A_LEXPR\n");
	    goto do_crement;
	case A_LVAL:
#ifdef DEBUGGING
	    if (debug & 8) {
		sprintf(buf,"LVAL $%s ==",arg[anum].arg_ptr.arg_stab->stab_name);
		tmps = buf;
	    }
#endif
	    str = STAB_STR(arg[anum].arg_ptr.arg_stab);
	    if (!str)
		fatal("panic: A_LVAL\n");
	  do_crement:
	    assigning = TRUE;
	    if (argflags & AF_PRE) {
		if (argflags & AF_UP)
		    str_inc(str);
		else
		    str_dec(str);
		STABSET(str);
		sarg[anum] = str;
		str = arg->arg_ptr.arg_str;
	    }
	    else if (argflags & AF_POST) {
		sarg[anum] = str_static(str);
		if (argflags & AF_UP)
		    str_inc(str);
		else
		    str_dec(str);
		STABSET(str);
		str = arg->arg_ptr.arg_str;
	    }
	    else {
		sarg[anum] = str;
	    }
	    break;
	case A_ARYLEN:
	    sarg[anum] = str_static(&str_no);
	    str_numset(sarg[anum],
		(double)alen(arg[anum].arg_ptr.arg_stab->stab_array));
#ifdef DEBUGGING
	    tmps = "ARYLEN";
#endif
	    break;
	case A_SINGLE:
	    sarg[anum] = arg[anum].arg_ptr.arg_str;
#ifdef DEBUGGING
	    tmps = "SINGLE";
#endif
	    break;
	case A_DOUBLE:
	    (void) interp(str,str_get(arg[anum].arg_ptr.arg_str));
	    sarg[anum] = str;
#ifdef DEBUGGING
	    tmps = "DOUBLE";
#endif
	    break;
	case A_BACKTICK:
	    tmps = str_get(arg[anum].arg_ptr.arg_str);
	    fp = popen(str_get(interp(str,tmps)),"r");
	    tmpstr = str_new(80);
	    str_set(str,"");
	    if (fp) {
		while (str_gets(tmpstr,fp) != Nullch) {
		    str_scat(str,tmpstr);
		}
		statusvalue = pclose(fp);
	    }
	    else
		statusvalue = -1;
	    str_free(tmpstr);

	    sarg[anum] = str;
#ifdef DEBUGGING
	    tmps = "BACK";
#endif
	    break;
	case A_READ:
	    fp = Nullfp;
	    last_in_stab = arg[anum].arg_ptr.arg_stab;
	    if (last_in_stab->stab_io) {
		fp = last_in_stab->stab_io->fp;
		if (!fp && (last_in_stab->stab_io->flags & IOF_ARGV)) {
		    if (last_in_stab->stab_io->flags & IOF_START) {
			last_in_stab->stab_io->flags &= ~IOF_START;
			last_in_stab->stab_io->lines = 0;
			if (alen(last_in_stab->stab_array) < 0L) {
			    tmpstr = str_make("-");	/* assume stdin */
			    apush(last_in_stab->stab_array, tmpstr);
			}
		    }
		    fp = nextargv(last_in_stab);
		    if (!fp)	/* Note: fp != last_in_stab->stab_io->fp */
			do_close(last_in_stab,FALSE);	/* now it does */
		}
	    }
	  keepgoing:
	    if (!fp)
		sarg[anum] = &str_no;
	    else if (!str_gets(str,fp)) {
		if (last_in_stab->stab_io->flags & IOF_ARGV) {
		    fp = nextargv(last_in_stab);
		    if (fp)
			goto keepgoing;
		    do_close(last_in_stab,FALSE);
		    last_in_stab->stab_io->flags |= IOF_START;
		}
		if (fp == stdin) {
		    clearerr(fp);
		}
		sarg[anum] = &str_no;
		break;
	    }
	    else {
		last_in_stab->stab_io->lines++;
		sarg[anum] = str;
	    }
#ifdef DEBUGGING
	    tmps = "READ";
#endif
	    break;
	}
#ifdef DEBUGGING
	if (debug & 8)
	    deb("%d.%s = '%s'\n",anum,tmps,str_peek(sarg[anum]));
#endif
    }
    switch (optype) {
    case O_ITEM:
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	STABSET(str);
	break;
    case O_ITEM2:
	if (str != sarg[2])
	    str_sset(str,sarg[2]);
	STABSET(str);
	break;
    case O_ITEM3:
	if (str != sarg[3])
	    str_sset(str,sarg[3]);
	STABSET(str);
	break;
    case O_CONCAT:
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	str_scat(str,sarg[2]);
	STABSET(str);
	break;
    case O_REPEAT:
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	anum = (long)str_gnum(sarg[2]);
	if (anum >= 1) {
	    tmpstr = str_new(0);
	    str_sset(tmpstr,str);
	    for (anum--; anum; anum--)
		str_scat(str,tmpstr);
	}
	else
	    str_sset(str,&str_no);
	STABSET(str);
	break;
    case O_MATCH:
	str_set(str, do_match(str_get(sarg[1]),arg) ? Yes : No);
	STABSET(str);
	break;
    case O_NMATCH:
	str_set(str, do_match(str_get(sarg[1]),arg) ? No : Yes);
	STABSET(str);
	break;
    case O_SUBST:
	value = (double) do_subst(str, arg);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_NSUBST:
	str_set(arg->arg_ptr.arg_str, do_subst(str, arg) ? No : Yes);
	str = arg->arg_ptr.arg_str;
	break;
    case O_ASSIGN:
	if (arg[2].arg_flags & AF_SPECIAL)
	    do_assign(str,arg);
	else {
	    if (str != sarg[2])
		str_sset(str, sarg[2]);
	    STABSET(str);
	}
	break;
    case O_CHOP:
	tmps = str_get(str);
	tmps += str->str_cur - (str->str_cur != 0);
	str_set(arg->arg_ptr.arg_str,tmps);	/* remember last char */
	*tmps = '\0';				/* wipe it out */
	str->str_cur = tmps - str->str_ptr;
	str->str_nok = 0;
	str = arg->arg_ptr.arg_str;
	break;
    case O_MULTIPLY:
	value = str_gnum(sarg[1]);
	value *= str_gnum(sarg[2]);
	goto donumset;
    case O_DIVIDE:
	value = str_gnum(sarg[1]);
	value /= str_gnum(sarg[2]);
	goto donumset;
    case O_MODULO:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) % (long)str_gnum(sarg[2]));
	goto donumset;
    case O_ADD:
	value = str_gnum(sarg[1]);
	value += str_gnum(sarg[2]);
	goto donumset;
    case O_SUBTRACT:
	value = str_gnum(sarg[1]);
	value -= str_gnum(sarg[2]);
	goto donumset;
    case O_LEFT_SHIFT:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) << (long)str_gnum(sarg[2]));
	goto donumset;
    case O_RIGHT_SHIFT:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) >> (long)str_gnum(sarg[2]));
	goto donumset;
    case O_LT:
	value = str_gnum(sarg[1]);
	value = (double)(value < str_gnum(sarg[2]));
	goto donumset;
    case O_GT:
	value = str_gnum(sarg[1]);
	value = (double)(value > str_gnum(sarg[2]));
	goto donumset;
    case O_LE:
	value = str_gnum(sarg[1]);
	value = (double)(value <= str_gnum(sarg[2]));
	goto donumset;
    case O_GE:
	value = str_gnum(sarg[1]);
	value = (double)(value >= str_gnum(sarg[2]));
	goto donumset;
    case O_EQ:
	value = str_gnum(sarg[1]);
	value = (double)(value == str_gnum(sarg[2]));
	goto donumset;
    case O_NE:
	value = str_gnum(sarg[1]);
	value = (double)(value != str_gnum(sarg[2]));
	goto donumset;
    case O_BIT_AND:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) & (long)str_gnum(sarg[2]));
	goto donumset;
    case O_XOR:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) ^ (long)str_gnum(sarg[2]));
	goto donumset;
    case O_BIT_OR:
	value = str_gnum(sarg[1]);
	value = (double)(((long)value) | (long)str_gnum(sarg[2]));
	goto donumset;
    case O_AND:
	if (str_true(sarg[1])) {
	    anum = 2;
	    optype = O_ITEM2;
	    maxarg = 0;
	    argflags = arg[anum].arg_flags;
	    goto re_eval;
	}
	else {
	    if (assigning) {
		str_sset(str, sarg[1]);
		STABSET(str);
	    }
	    else
		str = sarg[1];
	    break;
	}
    case O_OR:
	if (str_true(sarg[1])) {
	    if (assigning) {
		str_set(str, sarg[1]);
		STABSET(str);
	    }
	    else
		str = sarg[1];
	    break;
	}
	else {
	    anum = 2;
	    optype = O_ITEM2;
	    maxarg = 0;
	    argflags = arg[anum].arg_flags;
	    goto re_eval;
	}
    case O_COND_EXPR:
	anum = (str_true(sarg[1]) ? 2 : 3);
	optype = (anum == 2 ? O_ITEM2 : O_ITEM3);
	maxarg = 0;
	argflags = arg[anum].arg_flags;
	goto re_eval;
    case O_COMMA:
	str = sarg[2];
	break;
    case O_NEGATE:
	value = -str_gnum(sarg[1]);
	goto donumset;
    case O_NOT:
	value = (double) !str_true(sarg[1]);
	goto donumset;
    case O_COMPLEMENT:
	value = (double) ~(long)str_gnum(sarg[1]);
	goto donumset;
    case O_SELECT:
	if (arg[1].arg_type == A_LVAL)
	    defoutstab = arg[1].arg_ptr.arg_stab;
	else
	    defoutstab = stabent(str_get(sarg[1]),TRUE);
	if (!defoutstab->stab_io)
	    defoutstab->stab_io = stio_new();
	curoutstab = defoutstab;
	str_set(str,curoutstab->stab_io->fp ? Yes : No);
	STABSET(str);
	break;
    case O_WRITE:
	if (maxarg == 0)
	    stab = defoutstab;
	else if (arg[1].arg_type == A_LVAL)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	if (!stab->stab_io) {
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	curoutstab = stab;
	fp = stab->stab_io->fp;
	debarg = arg;
	if (stab->stab_io->fmt_stab)
	    form = stab->stab_io->fmt_stab->stab_form;
	else
	    form = stab->stab_form;
	if (!form || !fp) {
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	format(&outrec,form);
	do_write(&outrec,stab->stab_io);
	if (stab->stab_io->flags & IOF_FLUSH)
	    fflush(fp);
	str_set(str, Yes);
	STABSET(str);
	break;
    case O_OPEN:
	if (do_open(arg[1].arg_ptr.arg_stab,str_get(sarg[2]))) {
	    str_set(str, Yes);
	    arg[1].arg_ptr.arg_stab->stab_io->lines = 0;
	}
	else
	    str_set(str, No);
	STABSET(str);
	break;
    case O_TRANS:
	value = (double) do_trans(str,arg);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_NTRANS:
	str_set(arg->arg_ptr.arg_str, do_trans(str,arg) == 0 ? Yes : No);
	str = arg->arg_ptr.arg_str;
	break;
    case O_CLOSE:
	str_set(str,
	    do_close(arg[1].arg_ptr.arg_stab,TRUE) ? Yes : No );
	STABSET(str);
	break;
    case O_EACH:
	str_sset(str,do_each(arg[1].arg_ptr.arg_stab->stab_hash,sarg,retary));
	retary = Null(STR***);		/* do_each already did retary */
	STABSET(str);
	break;
    case O_VALUES:
    case O_KEYS:
	value = (double) do_kv(arg[1].arg_ptr.arg_stab->stab_hash,
	  optype,sarg,retary);
	retary = Null(STR***);		/* do_keys already did retary */
	goto donumset;
    case O_ARRAY:
	if (maxarg == 1) {
	    ary = arg[1].arg_ptr.arg_stab->stab_array;
	    maxarg = ary->ary_fill;
	    if (retary) { /* array wanted */
		sarg =
		  (STR **)saferealloc((char*)sarg,(maxarg+3)*sizeof(STR*));
		for (anum = 0; anum <= maxarg; anum++) {
		    sarg[anum+1] = str = afetch(ary,anum);
		}
		maxarg++;
	    }
	    else
		str = afetch(ary,maxarg);
	}
	else
	    str = afetch(arg[2].arg_ptr.arg_stab->stab_array,
		((int)str_gnum(sarg[1])) - arybase);
	if (!str)
	    return &str_no;
	break;
    case O_HASH:
	tmpstab = arg[2].arg_ptr.arg_stab;		/* XXX */
	str = hfetch(tmpstab->stab_hash,str_get(sarg[1]));
	if (!str)
	    return &str_no;
	break;
    case O_LARRAY:
	anum = ((int)str_gnum(sarg[1])) - arybase;
	str = afetch(arg[2].arg_ptr.arg_stab->stab_array,anum);
	if (!str || str == &str_no) {
	    str = str_new(0);
	    astore(arg[2].arg_ptr.arg_stab->stab_array,anum,str);
	}
	break;
    case O_LHASH:
	tmpstab = arg[2].arg_ptr.arg_stab;
	str = hfetch(tmpstab->stab_hash,str_get(sarg[1]));
	if (!str) {
	    str = str_new(0);
	    hstore(tmpstab->stab_hash,str_get(sarg[1]),str);
	}
	if (tmpstab == envstab) {	/* heavy wizardry going on here */
	    str->str_link.str_magic = tmpstab;/* str is now magic */
	    envname = savestr(str_get(sarg[1]));
					/* he threw the brick up into the air */
	}
	else if (tmpstab == sigstab) {	/* same thing, only different */
	    str->str_link.str_magic = tmpstab;
	    signame = savestr(str_get(sarg[1]));
	}
	break;
    case O_PUSH:
	if (arg[1].arg_flags & AF_SPECIAL)
	    str = do_push(arg,arg[2].arg_ptr.arg_stab->stab_array);
	else {
	    str = str_new(0);		/* must copy the STR */
	    str_sset(str,sarg[1]);
	    apush(arg[2].arg_ptr.arg_stab->stab_array,str);
	}
	break;
    case O_POP:
	str = apop(arg[1].arg_ptr.arg_stab->stab_array);
	if (!str)
	    return &str_no;
#ifdef STRUCTCOPY
	*(arg->arg_ptr.arg_str) = *str;
#else
	bcopy((char*)str, (char*)arg->arg_ptr.arg_str, sizeof *str);
#endif
	safefree((char*)str);
	str = arg->arg_ptr.arg_str;
	break;
    case O_SHIFT:
	str = ashift(arg[1].arg_ptr.arg_stab->stab_array);
	if (!str)
	    return &str_no;
#ifdef STRUCTCOPY
	*(arg->arg_ptr.arg_str) = *str;
#else
	bcopy((char*)str, (char*)arg->arg_ptr.arg_str, sizeof *str);
#endif
	safefree((char*)str);
	str = arg->arg_ptr.arg_str;
	break;
    case O_SPLIT:
	value = (double) do_split(str_get(sarg[1]),arg[2].arg_ptr.arg_spat,retary);
	retary = Null(STR***);		/* do_split already did retary */
	goto donumset;
    case O_LENGTH:
	value = (double) str_len(sarg[1]);
	goto donumset;
    case O_SPRINTF:
	sarg[maxarg+1] = Nullstr;
	do_sprintf(str,arg->arg_len,sarg);
	break;
    case O_SUBSTR:
	anum = ((int)str_gnum(sarg[2])) - arybase;
	for (tmps = str_get(sarg[1]); *tmps && anum > 0; tmps++,anum--) ;
	anum = (int)str_gnum(sarg[3]);
	if (anum >= 0 && strlen(tmps) > anum)
	    str_nset(str, tmps, anum);
	else
	    str_set(str, tmps);
	break;
    case O_JOIN:
	if (arg[2].arg_flags & AF_SPECIAL && arg[2].arg_type == A_EXPR)
	    do_join(arg,str_get(sarg[1]),str);
	else
	    ajoin(arg[2].arg_ptr.arg_stab->stab_array,str_get(sarg[1]),str);
	break;
    case O_SLT:
	tmps = str_get(sarg[1]);
	value = (double) strLT(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SGT:
	tmps = str_get(sarg[1]);
	value = (double) strGT(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SLE:
	tmps = str_get(sarg[1]);
	value = (double) strLE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SGE:
	tmps = str_get(sarg[1]);
	value = (double) strGE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SEQ:
	tmps = str_get(sarg[1]);
	value = (double) strEQ(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SNE:
	tmps = str_get(sarg[1]);
	value = (double) strNE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SUBR:
	str_sset(str,do_subr(arg,sarg));
	STABSET(str);
	break;
    case O_PRTF:
    case O_PRINT:
	if (maxarg <= 1)
	    stab = defoutstab;
	else {
	    stab = arg[2].arg_ptr.arg_stab;
	    if (!stab)
		stab = defoutstab;
	}
	if (!stab->stab_io)
	    value = 0.0;
	else if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)do_aprint(arg,stab->stab_io->fp);
	else {
	    value = (double)do_print(str_get(sarg[1]),stab->stab_io->fp);
	    if (ors && optype == O_PRINT)
		do_print(ors, stab->stab_io->fp);
	}
	if (stab->stab_io->flags & IOF_FLUSH)
	    fflush(stab->stab_io->fp);
	goto donumset;
    case O_CHDIR:
	tmps = str_get(sarg[1]);
	if (!tmps || !*tmps)
	    tmps = getenv("HOME");
	if (!tmps || !*tmps)
	    tmps = getenv("LOGDIR");
	value = (double)(chdir(tmps) >= 0);
	goto donumset;
    case O_DIE:
	tmps = str_get(sarg[1]);
	if (!tmps || !*tmps)
	    exit(1);
	fatal("%s\n",str_get(sarg[1]));
	value = 0.0;
	goto donumset;
    case O_EXIT:
	exit((int)str_gnum(sarg[1]));
	value = 0.0;
	goto donumset;
    case O_RESET:
	str_reset(str_get(sarg[1]));
	value = 1.0;
	goto donumset;
    case O_LIST:
	if (maxarg > 0)
	    str = sarg[maxarg];	/* unwanted list, return last item */
	else
	    str = &str_no;
	break;
    case O_EOF:
	str_set(str, do_eof(maxarg > 0 ? arg[1].arg_ptr.arg_stab : last_in_stab) ? Yes : No);
	STABSET(str);
	break;
    case O_TELL:
	value =	(double)do_tell(maxarg > 0 ? arg[1].arg_ptr.arg_stab : last_in_stab);
	goto donumset;
	break;
    case O_SEEK:
	value = str_gnum(sarg[2]);
	str_set(str, do_seek(arg[1].arg_ptr.arg_stab,
	  (long)value, (int)str_gnum(sarg[3]) ) ? Yes : No);
	STABSET(str);
	break;
    case O_REDO:
    case O_NEXT:
    case O_LAST:
	if (maxarg > 0) {
	    tmps = str_get(sarg[1]);
	    while (loop_ptr >= 0 && (!loop_stack[loop_ptr].loop_label ||
	      strNE(tmps,loop_stack[loop_ptr].loop_label) )) {
#ifdef DEBUGGING
		if (debug & 4) {
		    deb("(Skipping label #%d %s)\n",loop_ptr,
			loop_stack[loop_ptr].loop_label);
		}
#endif
		loop_ptr--;
	    }
#ifdef DEBUGGING
	    if (debug & 4) {
		deb("(Found label #%d %s)\n",loop_ptr,
		    loop_stack[loop_ptr].loop_label);
	    }
#endif
	}
	if (loop_ptr < 0)
	    fatal("Bad label: %s\n", maxarg > 0 ? tmps : "<null>");
	longjmp(loop_stack[loop_ptr].loop_env, optype);
    case O_GOTO:/* shudder */
	goto_targ = str_get(sarg[1]);
	longjmp(top_env, 1);
    case O_INDEX:
	tmps = str_get(sarg[1]);
	if (!(tmps2 = instr(tmps,str_get(sarg[2]))))
	    value = (double)(-1 + arybase);
	else
	    value = (double)(tmps2 - tmps + arybase);
	goto donumset;
    case O_TIME:
	value = (double) time(0);
	goto donumset;
    case O_TMS:
	value = (double) do_tms(retary);
	retary = Null(STR***);		/* do_tms already did retary */
	goto donumset;
    case O_LOCALTIME:
	tmplong = (long) str_gnum(sarg[1]);
	value = (double) do_time(localtime(&tmplong),retary);
	retary = Null(STR***);		/* do_localtime already did retary */
	goto donumset;
    case O_GMTIME:
	tmplong = (long) str_gnum(sarg[1]);
	value = (double) do_time(gmtime(&tmplong),retary);
	retary = Null(STR***);		/* do_gmtime already did retary */
	goto donumset;
    case O_STAT:
	value = (double) do_stat(arg,sarg,retary);
	retary = Null(STR***);		/* do_stat already did retary */
	goto donumset;
    case O_CRYPT:
#ifdef HAS_CRYPT
	tmps = str_get(sarg[1]);
	str_set(str,crypt(tmps,str_get(sarg[2])));
#else
	fatal(
	  "The crypt() function is unimplemented due to excessive paranoia.");
#endif
	break;
    case O_EXP:
	value = exp(str_gnum(sarg[1]));
	goto donumset;
    case O_LOG:
	value = log(str_gnum(sarg[1]));
	goto donumset;
    case O_SQRT:
	value = sqrt(str_gnum(sarg[1]));
	goto donumset;
    case O_INT:
	modf(str_gnum(sarg[1]),&value);
	goto donumset;
    case O_ORD:
	value = (double) *str_get(sarg[1]);
	goto donumset;
    case O_SLEEP:
	tmps = str_get(sarg[1]);
	time(&tmplong);
	if (!tmps || !*tmps)
	    sleep((32767<<16)+32767);
	else
	    sleep(atoi(tmps));
	value = (double)tmplong;
	time(&tmplong);
	value = ((double)tmplong) - value;
	goto donumset;
    case O_FLIP:
	if (str_true(sarg[1])) {
	    str_numset(str,0.0);
	    anum = 2;
	    arg->arg_type = optype = O_FLOP;
	    maxarg = 0;
	    arg[2].arg_flags &= ~AF_SPECIAL;
	    arg[1].arg_flags |= AF_SPECIAL;
	    argflags = arg[anum].arg_flags;
	    goto re_eval;
	}
	str_set(str,"");
	break;
    case O_FLOP:
	str_inc(str);
	if (str_true(sarg[2])) {
	    arg->arg_type = O_FLIP;
	    arg[1].arg_flags &= ~AF_SPECIAL;
	    arg[2].arg_flags |= AF_SPECIAL;
	    str_cat(str,"E0");
	}
	break;
    case O_FORK:
	value = (double)fork();
	goto donumset;
    case O_SYSTEM:
	if (anum = vfork()) {
	    ihand = signal(SIGINT, SIG_IGN);
	    qhand = signal(SIGQUIT, SIG_IGN);
	    while ((maxarg = wait(&argflags)) != anum && maxarg != -1)
		;
	    if (maxarg == -1)
		argflags = -1;
	    signal(SIGINT, ihand);
	    signal(SIGQUIT, qhand);
	    value = (double)argflags;
	    goto donumset;
	}
	/* FALL THROUGH */
    case O_EXEC:
	if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)do_aexec(arg);
	else {
	    value = (double)do_exec(str_get(sarg[1]));
	}
	goto donumset;
    case O_HEX:
	maxarg = 4;
	goto snarfnum;

    case O_OCT:
	maxarg = 3;

      snarfnum:
	anum = 0;
	tmps = str_get(sarg[1]);
	for (;;) {
	    switch (*tmps) {
	    default:
		goto out;
	    case '8': case '9':
		if (maxarg != 4)
		    goto out;
		/* FALL THROUGH */
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7':
		anum <<= maxarg;
		anum += *tmps++ & 15;
		break;
	    case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
	    case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
		if (maxarg != 4)
		    goto out;
		anum <<= 4;
		anum += (*tmps++ & 7) + 9;
		break;
	    case 'x':
		maxarg = 4;
		tmps++;
		break;
	    }
	}
      out:
	value = (double)anum;
	goto donumset;
    case O_CHMOD:
    case O_CHOWN:
    case O_KILL:
    case O_UNLINK:
	if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)apply(optype,arg,Null(STR**));
	else {
	    sarg[2] = Nullstr;
	    value = (double)apply(optype,arg,sarg);
	}
	goto donumset;
    case O_UMASK:
	value = (double)umask((int)str_gnum(sarg[1]));
	goto donumset;
    case O_RENAME:
	tmps = str_get(sarg[1]);
#ifdef RENAME
	value = (double)(rename(tmps,str_get(sarg[2])) >= 0);
#else
	tmps2 = str_get(sarg[2]);
	UNLINK(tmps2);
	if (!(anum = link(tmps,tmps2)))
	    anum = UNLINK(tmps);
	value = (double)(anum >= 0);
#endif
	goto donumset;
    case O_LINK:
	tmps = str_get(sarg[1]);
	value = (double)(link(tmps,str_get(sarg[2])) >= 0);
	goto donumset;
    case O_UNSHIFT:
	ary = arg[2].arg_ptr.arg_stab->stab_array;
	if (arg[1].arg_flags & AF_SPECIAL)
	    do_unshift(arg,ary);
	else {
	    str = str_new(0);		/* must copy the STR */
	    str_sset(str,sarg[1]);
	    aunshift(ary,1);
	    astore(ary,0,str);
	}
	value = (double)(ary->ary_fill + 1);
	break;
    case O_EVAL:
	str_sset(str,
	    do_eval(arg[1].arg_type != A_NULL ? sarg[1] : defstab->stab_val) );
	STABSET(str);
	break;
    }
#ifdef DEBUGGING
    dlevel--;
    if (debug & 8)
	deb("%s RETURNS \"%s\"\n",opname[optype],str_get(str));
#endif
    goto freeargs;

donumset:
    str_numset(str,value);
    STABSET(str);
#ifdef DEBUGGING
    dlevel--;
    if (debug & 8)
	deb("%s RETURNS \"%f\"\n",opname[optype],value);
#endif

freeargs:
    if (sarg != quicksarg) {
	if (retary) {
	    if (optype == O_LIST)
		sarg[0] = &str_no;
	    else
		sarg[0] = Nullstr;
	    sarg[maxarg+1] = Nullstr;
	    *retary = sarg;	/* up to them to free it */
	}
	else
	    safefree(sarg);
    }
    return str;

nullarray:
    maxarg = 0;
#ifdef DEBUGGING
    dlevel--;
    if (debug & 8)
	deb("%s RETURNS ()\n",opname[optype],value);
#endif
    goto freeargs;
}
