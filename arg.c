/* $Header: arg.c,v 2.0 88/06/05 00:08:04 root Exp $
 *
 * $Log:	arg.c,v $
 * Revision 2.0  88/06/05  00:08:04  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#include <signal.h>
#include <errno.h>

extern int errno;

STR *
do_match(arg,retary,sarg,ptrmaxsarg,sargoff,cushion)
register ARG *arg;
STR ***retary;
register STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register SPAT *spat = arg[2].arg_ptr.arg_spat;
    register char *t;
    register char *s = str_get(sarg[1]);
    char *strend = s + sarg[1]->str_cur;

    if (!spat)
	return &str_yes;
    if (!s)
	fatal("panic: do_match");
    if (retary) {
	*retary = sarg;		/* assume no match */
	*ptrmaxsarg = sargoff;
    }
    if (spat->spat_flags & SPAT_USED) {
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT USED\n");
#endif
	return &str_no;
    }
    if (spat->spat_runtime) {
	t = str_get(eval(spat->spat_runtime,Null(STR***),-1));
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT /%s/\n",t);
#endif
	spat->spat_regexp = regcomp(t,spat->spat_flags & SPAT_FOLD,1);
	if (!*spat->spat_regexp->precomp && lastspat)
	    spat = lastspat;
	if (regexec(spat->spat_regexp, s, strend, TRUE, 0,
	  sarg[1]->str_pok & 4 ? sarg[1] : Nullstr)) {
	    if (spat->spat_regexp->subbase)
		curspat = spat;
	    lastspat = spat;
	    goto gotcha;
	}
	else
	    return &str_no;
    }
    else {
#ifdef DEBUGGING
	if (debug & 8) {
	    char ch;

	    if (spat->spat_flags & SPAT_ONCE)
		ch = '?';
	    else
		ch = '/';
	    deb("2.SPAT %c%s%c\n",ch,spat->spat_regexp->precomp,ch);
	}
#endif
	if (!*spat->spat_regexp->precomp && lastspat)
	    spat = lastspat;
	t = s;
	if (hint) {
	    if (hint < s || hint > strend)
		fatal("panic: hint in do_match");
	    s = hint;
	    hint = Nullch;
	    if (spat->spat_regexp->regback >= 0) {
		s -= spat->spat_regexp->regback;
		if (s < t)
		    s = t;
	    }
	    else
		s = t;
	}
	else if (spat->spat_short) {
	    if (spat->spat_flags & SPAT_SCANFIRST) {
		if (sarg[1]->str_pok == 5) {
		    if (screamfirst[spat->spat_short->str_rare] < 0)
			goto nope;
		    else if (!(s = screaminstr(sarg[1],spat->spat_short)))
			goto nope;
		    else if (spat->spat_flags & SPAT_ALL)
			goto yup;
		}
		else if (!(s = fbminstr(s, strend, spat->spat_short)))
		    goto nope;
		else if (spat->spat_flags & SPAT_ALL)
		    goto yup;
		else if (spat->spat_regexp->regback >= 0) {
		    ++*(long*)&spat->spat_short->str_nval;
		    s -= spat->spat_regexp->regback;
		    if (s < t)
			s = t;
		}
		else
		    s = t;
	    }
	    else if (!multiline && (*spat->spat_short->str_ptr != *s ||
	      strnNE(spat->spat_short->str_ptr, s, spat->spat_slen) ))
		goto nope;
	    if (--*(long*)&spat->spat_short->str_nval < 0) {
		str_free(spat->spat_short);
		spat->spat_short = Nullstr;	/* opt is being useless */
	    }
	}
	if (regexec(spat->spat_regexp, s, strend, s == t, 0,
	  sarg[1]->str_pok & 4 ? sarg[1] : Nullstr)) {
	    if (spat->spat_regexp->subbase)
		curspat = spat;
	    lastspat = spat;
	    if (spat->spat_flags & SPAT_ONCE)
		spat->spat_flags |= SPAT_USED;
	    goto gotcha;
	}
	else
	    return &str_no;
    }
    /*NOTREACHED*/

  gotcha:
    if (retary && curspat == spat) {
	int iters, i, len;

	iters = spat->spat_regexp->nparens;
	*ptrmaxsarg = iters + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (iters+2+cushion+sargoff)*sizeof(STR*)) + sargoff;

	for (i = 1; i <= iters; i++) {
	    sarg[i] = str_static(&str_no);
	    if (s = spat->spat_regexp->startp[i]) {
		len = spat->spat_regexp->endp[i] - s;
		if (len > 0)
		    str_nset(sarg[i],s,len);
	    }
	}
	*retary = sarg;
    }
    return &str_yes;

yup:
    ++*(long*)&spat->spat_short->str_nval;
    return &str_yes;

nope:
    ++*(long*)&spat->spat_short->str_nval;
    return &str_no;
}

int
do_subst(str,arg)
STR *str;
register ARG *arg;
{
    register SPAT *spat;
    register STR *dstr;
    register char *s = str_get(str);
    char *strend = s + str->str_cur;
    register char *m;

    spat = arg[2].arg_ptr.arg_spat;
    if (!spat || !s)
	fatal("panic: do_subst");
    else if (spat->spat_runtime) {
	m = str_get(eval(spat->spat_runtime,Null(STR***),-1));
	spat->spat_regexp = regcomp(m,spat->spat_flags & SPAT_FOLD,1);
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_regexp->precomp);
    }
#endif
    if (!*spat->spat_regexp->precomp && lastspat)
	spat = lastspat;
    m = s;
    if (hint) {
	if (hint < s || hint > strend)
	    fatal("panic: hint in do_match");
	s = hint;
	hint = Nullch;
	if (spat->spat_regexp->regback >= 0) {
	    s -= spat->spat_regexp->regback;
	    if (s < m)
		s = m;
	}
	else
	    s = m;
    }
    else if (spat->spat_short) {
	if (spat->spat_flags & SPAT_SCANFIRST) {
	    if (str->str_pok == 5) {
		if (screamfirst[spat->spat_short->str_rare] < 0)
		    goto nope;
		else if (!(s = screaminstr(str,spat->spat_short)))
		    goto nope;
	    }
	    else if (!(s = fbminstr(s, strend, spat->spat_short)))
		goto nope;
	    else if (spat->spat_regexp->regback >= 0) {
		++*(long*)&spat->spat_short->str_nval;
		s -= spat->spat_regexp->regback;
		if (s < m)
		    s = m;
	    }
	    else
		s = m;
	}
	else if (!multiline && (*spat->spat_short->str_ptr != *s ||
	  strnNE(spat->spat_short->str_ptr, s, spat->spat_slen) ))
	    goto nope;
	if (--*(long*)&spat->spat_short->str_nval < 0) {
	    str_free(spat->spat_short);
	    spat->spat_short = Nullstr;	/* opt is being useless */
	}
    }
    if (regexec(spat->spat_regexp, s, strend, s == m, 1,
      str->str_pok & 4 ? str : Nullstr)) {
	int iters = 0;

	dstr = str_new(str_len(str));
	str_nset(dstr,m,s-m);
	if (spat->spat_regexp->subbase)
	    curspat = spat;
	lastspat = spat;
	do {
	    m = spat->spat_regexp->startp[0];
	    if (iters++ > 10000)
		fatal("Substitution loop");
	    if (spat->spat_regexp->subbase)
		s = spat->spat_regexp->subbase;
	    str_ncat(dstr,s,m-s);
	    s = spat->spat_regexp->endp[0];
	    str_scat(dstr,eval(spat->spat_repl,Null(STR***),-1));
	    if (spat->spat_flags & SPAT_ONCE)
		break;
	} while (regexec(spat->spat_regexp, s, strend, FALSE, 1, Nullstr));
	str_cat(dstr,s);
	str_replace(str,dstr);
	STABSET(str);
	return iters;
    }
    return 0;

nope:
    ++*(long*)&spat->spat_short->str_nval;
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
	fatal("panic: do_trans");
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
do_split(spat,retary,sarg,ptrmaxsarg,sargoff,cushion)
register SPAT *spat;
STR ***retary;
register STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register char *s = str_get(sarg[1]);
    char *strend = s + sarg[1]->str_cur;
    register STR *dstr;
    register char *m;
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int iters = 0;
    int i;

    if (!spat || !s)
	fatal("panic: do_split");
    else if (spat->spat_runtime) {
	m = str_get(eval(spat->spat_runtime,Null(STR***),-1));
	if (!*m || (*m == ' ' && !m[1])) {
	    m = "\\s+";
	    spat->spat_flags |= SPAT_SKIPWHITE;
	}
	if (spat->spat_runtime->arg_type == O_ITEM &&
	  spat->spat_runtime[1].arg_type == A_SINGLE) {
	    arg_free(spat->spat_runtime);	/* it won't change, so */
	    spat->spat_runtime = Nullarg;	/* no point compiling again */
	}
	spat->spat_regexp = regcomp(m,spat->spat_flags & SPAT_FOLD,1);
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_regexp->precomp);
    }
#endif
    if (retary)
	ary = myarray;
    else
	ary = spat->spat_repl[1].arg_ptr.arg_stab->stab_array;
    if (!ary)
	myarray = ary = anew(Nullstab);
    ary->ary_fill = -1;
    if (spat->spat_flags & SPAT_SKIPWHITE) {
	while (isspace(*s))
	    s++;
    }
    if (spat->spat_short) {
	i = spat->spat_short->str_cur;
	while (*s && (m = fbminstr(s, strend, spat->spat_short))) {
	    dstr = str_new(m-s);
	    str_nset(dstr,s,m-s);
	    astore(ary, iters++, dstr);
	    if (iters > 10000)
		fatal("Substitution loop");
	    s = m + i;
	}
    }
    else {
	while (*s && regexec(spat->spat_regexp, s, strend, (iters == 0), 1,
	  Nullstr)) {
	    m = spat->spat_regexp->startp[0];
	    if (spat->spat_regexp->subbase)
		s = spat->spat_regexp->subbase;
	    dstr = str_new(m-s);
	    str_nset(dstr,s,m-s);
	    astore(ary, iters++, dstr);
	    if (iters > 10000)
		fatal("Substitution loop");
	    s = spat->spat_regexp->endp[0];
	}
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
	*ptrmaxsarg = iters + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (iters+2+cushion+sargoff)*sizeof(STR*)) + sargoff;

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
    register int items;

    (void)eval(arg[2].arg_ptr.arg_arg,&tmpary,-1);
    items = (int)str_gnum(*tmpary);
    elem = tmpary+1;
    if (items-- > 0)
	str_sset(str,*elem++);
    for (; items > 0; items--,elem++) {
	str_cat(str,delim);
	str_scat(str,*elem);
    }
    STABSET(str);
    safefree((char*)tmpary);
}

FILE *
forkopen(name,mode)
char *name;
char *mode;
{
    int pfd[2];

    if (pipe(pfd) < 0)
	return Nullfp;
    while ((forkprocess = fork()) == -1) {
	if (errno != EAGAIN)
	    return Nullfp;
	sleep(5);
    }
    if (*mode == 'w') {
	if (forkprocess) {
	    close(pfd[0]);
	    return fdopen(pfd[1],"w");
	}
	else {
	    close(pfd[1]);
	    close(0);
	    dup(pfd[0]);	/* substitute our pipe for stdin */
	    close(pfd[0]);
	    return Nullfp;
	}
    }
    else {
	if (forkprocess) {
	    close(pfd[1]);
	    return fdopen(pfd[0],"r");
	}
	else {
	    close(pfd[0]);
	    close(1);
	    if (dup(pfd[1]) == 0)
		dup(pfd[1]);	/* substitute our pipe for stdout */
	    close(pfd[1]);
	    return Nullfp;
	}
    }
}

bool
do_open(stab,name)
STAB *stab;
register char *name;
{
    FILE *fp;
    int len = strlen(name);
    register STIO *stio = stab->stab_io;
    char *myname = savestr(name);
    int result;
    int fd;

    name = myname;
    forkprocess = 1;		/* assume true if no fork */
    while (len && isspace(name[len-1]))
	name[--len] = '\0';
    if (!stio)
	stio = stab->stab_io = stio_new();
    if (stio->fp) {
	fd = fileno(stio->fp);
	if (stio->type == '|')
	    result = pclose(stio->fp);
	else if (stio->type != '-')
	    result = fclose(stio->fp);
	else
	    result = 0;
	if (result == EOF && fd > 2)
	    fprintf(stderr,"Warning: unable to close filehandle %s properly.\n",
	      stab->stab_name);
	stio->fp = Nullfp;
    }
    stio->type = *name;
    if (*name == '|') {
	for (name++; isspace(*name); name++) ;
	if (strNE(name,"-"))
	    fp = popen(name,"w");
	else {
	    fp = forkopen(name,"w");
	    stio->subprocess = forkprocess;
	    stio->type = '%';
	}
    }
    else if (*name == '>' && name[1] == '>') {
	stio->type = 'a';
	for (name += 2; isspace(*name); name++) ;
	fp = fopen(name,"a");
    }
    else if (*name == '>' && name[1] == '&') {
	for (name += 2; isspace(*name); name++) ;
	if (isdigit(*name))
	    fd = atoi(name);
	else {
	    stab = stabent(name,FALSE);
	    if (stab->stab_io && stab->stab_io->fp) {
		fd = fileno(stab->stab_io->fp);
		stio->type = stab->stab_io->type;
	    }
	    else
		fd = -1;
	}
	fp = fdopen(dup(fd),stio->type == 'a' ? "a" :
	  (stio->type == '<' ? "r" : "w") );
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
	    if (strNE(name,"-")) {
		fp = popen(name,"r");
		stio->type = '|';
	    }
	    else {
		fp = forkopen(name,"r");
		stio->subprocess = forkprocess;
		stio->type = '%';
	    }
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
    safefree(myname);
    if (!fp)
	return FALSE;
    if (stio->type &&
      stio->type != '|' && stio->type != '-' && stio->type != '%') {
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
    int filemode,fileuid,filegid;

    while (alen(stab->stab_array) >= 0) {
	str = ashift(stab->stab_array);
	str_sset(stab->stab_val,str);
	STABSET(stab->stab_val);
	oldname = str_get(stab->stab_val);
	if (do_open(stab,oldname)) {
	    if (inplace) {
		filemode = statbuf.st_mode;
		fileuid = statbuf.st_uid;
		filegid = statbuf.st_gid;
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
		else {
		    UNLINK(oldname);
		}
		sprintf(tokenbuf,">%s",oldname);
		errno = 0;		/* in case sprintf set errno */
		do_open(argvoutstab,tokenbuf);
		defoutstab = argvoutstab;
#ifdef FCHMOD
		fchmod(fileno(argvoutstab->stab_io->fp),filemode);
#else
		chmod(oldname,filemode);
#endif
#ifdef FCHOWN
		fchown(fileno(argvoutstab->stab_io->fp),fileuid,filegid);
#else
		chown(oldname,fileuid,filegid);
#endif
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
    int status;
    int tmp;

    if (!stio) {		/* never opened */
	if (dowarn && explicit)
	    warn("Close on unopened file <%s>",stab->stab_name);
	return FALSE;
    }
    if (stio->fp) {
	if (stio->type == '|')
	    retval = (pclose(stio->fp) >= 0);
	else if (stio->type == '-')
	    retval = TRUE;
	else {
	    retval = (fclose(stio->fp) != EOF);
	    if (stio->type == '%' && stio->subprocess) {
		while ((tmp = wait(&status)) != stio->subprocess && tmp != -1)
		    ;
		if (tmp == -1)
		    statusvalue = -1;
		else
		    statusvalue = (unsigned)status & 0xffff;
	    }
	}
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

    if (!stab)			/* eof() */
	stio = argvstab->stab_io;
    else
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
	if (!stab) {			/* not necessarily a real EOF yet? */
	    if (!nextargv(argvstab))	/* get another fp handy */
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

    if (!stab)
	goto phooey;

    stio = stab->stab_io;
    if (!stio || !stio->fp)
	goto phooey;

    return ftell(stio->fp);

phooey:
    if (dowarn)
	warn("tell() on unopened file");
    return -1L;
}

bool
do_seek(stab, pos, whence)
STAB *stab;
long pos;
int whence;
{
    register STIO *stio;

    if (!stab)
	goto nuts;

    stio = stab->stab_io;
    if (!stio || !stio->fp)
	goto nuts;

    return fseek(stio->fp, pos, whence) >= 0;

nuts:
    if (dowarn)
	warn("seek() on unopened file");
    return FALSE;
}

static CMD *sortcmd;
static STAB *firststab = Nullstab;
static STAB *secondstab = Nullstab;

do_sort(arg,stab,retary,sarg,ptrmaxsarg,sargoff,cushion)
register ARG *arg;
STAB *stab;
STR ***retary;
register STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    STR **tmpary;	/* must not be register */
    register STR **elem;
    register bool retval;
    register int max;
    register int i;
    int sortcmp();
    int sortsub();
    STR *oldfirst;
    STR *oldsecond;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
    max = (int)str_gnum(*tmpary);

    if (retary) {
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (max+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	for (i = 1; i <= max; i++)
	    sarg[i] = tmpary[i];
	*retary = sarg;
	if (max > 1) {
	    if (stab->stab_sub && (sortcmd = stab->stab_sub->cmd)) {
		if (!firststab) {
		    firststab = stabent("a",TRUE);
		    secondstab = stabent("b",TRUE);
		}
		oldfirst = firststab->stab_val;
		oldsecond = secondstab->stab_val;
		qsort((char*)(sarg+1),max,sizeof(STR*),sortsub);
		firststab->stab_val = oldfirst;
		secondstab->stab_val = oldsecond;
	    }
	    else
		qsort((char*)(sarg+1),max,sizeof(STR*),sortcmp);
	}
	while (max > 0 && !sarg[max])
	    max--;
	*ptrmaxsarg = max + sargoff;
    }
    safefree((char*)tmpary);
    return max;
}

int
sortcmp(str1,str2)
STR **str1;
STR **str2;
{
    char *tmps;

    if (!*str1)
	return -1;
    if (!*str2)
	return 1;
    tmps = str_get(*str1);
    return strcmp(tmps,str_get(*str2));
}

int
sortsub(str1,str2)
STR **str1;
STR **str2;
{
    STR *str;

    if (!*str1)
	return -1;
    if (!*str2)
	return 1;
    firststab->stab_val = *str1;
    secondstab->stab_val = *str2;
    return (int)str_gnum(cmd_exec(sortcmd));
}

do_stat(arg,retary,sarg,ptrmaxsarg,sargoff,cushion)
register ARG *arg;
STR ***retary;
register STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int max = 13;
    register int i;

    ary = myarray;
    if (!ary)
	myarray = ary = anew(Nullstab);
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
	*ptrmaxsarg = max + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (max+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

do_tms(retary,sarg,ptrmaxsarg,sargoff,cushion)
STR ***retary;
STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int max = 4;
    register int i;

    ary = myarray;
    if (!ary)
	myarray = ary = anew(Nullstab);
    ary->ary_fill = -1;
    times(&timesbuf);

#ifndef HZ
#define HZ 60
#endif

    if (retary) {
	if (max) {
	    apush(ary,str_nmake(((double)timesbuf.tms_utime)/HZ));
	    apush(ary,str_nmake(((double)timesbuf.tms_stime)/HZ));
	    apush(ary,str_nmake(((double)timesbuf.tms_cutime)/HZ));
	    apush(ary,str_nmake(((double)timesbuf.tms_cstime)/HZ));
	}
	*ptrmaxsarg = max + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (max+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

do_time(tmbuf,retary,sarg,ptrmaxsarg,sargoff,cushion)
struct tm *tmbuf;
STR ***retary;
STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register ARRAY *ary;
    static ARRAY *myarray = Null(ARRAY*);
    int max = 9;
    register int i;

    ary = myarray;
    if (!ary)
	myarray = ary = anew(Nullstab);
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
	*ptrmaxsarg = max + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (max+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
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
		t--;
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
	    case 'd': case 'x': case 'o': case 'c': case 'u':
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
		if (strEQ(s,"%s")) {	/* some printfs fail on >128 chars */
		    *buf = '\0';
		    str_scat(str,*(sarg++));  /* so handle simple case */
		}
		else
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
do_print(str,fp)
register STR *str;
FILE *fp;
{
    if (!fp) {
	if (dowarn)
	    warn("print to unopened file");
	return FALSE;
    }
    if (!str)
	return FALSE;
    if (ofmt &&
      ((str->str_nok && str->str_nval != 0.0) || str_gnum(str) != 0.0) )
	fprintf(fp, ofmt, str->str_nval);
    else
	fputs(str_get(str),fp);
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
    register int items;

    if (!fp) {
	if (dowarn)
	    warn("print to unopened file");
	return FALSE;
    }
    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
    items = (int)str_gnum(*tmpary);
    if (arg->arg_type == O_PRTF) {
	do_sprintf(arg->arg_ptr.arg_str,items,tmpary);
	retval = do_print(arg->arg_ptr.arg_str,fp);
    }
    else {
	retval = FALSE;
	for (elem = tmpary+1; items > 0; items--,elem++) {
	    if (retval && ofs)
		fputs(ofs, fp);
	    retval = do_print(*elem, fp);
	    if (!retval)
		break;
	}
	if (ors)
	    fputs(ors, fp);
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
    register int items;
    char **argv;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
    items = (int)str_gnum(*tmpary);
    if (items) {
	argv = (char**)safemalloc((items+1)*sizeof(char*));
	a = argv;
	for (elem = tmpary+1; items > 0; items--,elem++) {
	    if (*elem)
		*a++ = str_get(*elem);
	    else
		*a++ = "";
	}
	*a = Nullch;
	execvp(argv[0],argv);
	safefree((char*)argv);
    }
    safefree((char*)tmpary);
    return FALSE;
}

bool
do_exec(str)
STR *str;
{
    register char **a;
    register char *s;
    char **argv;
    char *cmd = str_get(str);

    /* see if there are shell metacharacters in it */

    for (s = cmd; *s; s++) {
	if (*s != ' ' && !isalpha(*s) && index("$&*(){}[]'\";\\|?<>~`",*s)) {
	    execl("/bin/sh","sh","-c",cmd,(char*)0);
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
    register int items;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
    items = (int)str_gnum(*tmpary);
    for (elem = tmpary+1; items > 0; items--,elem++) {
	str = str_new(0);
	if (*elem)
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
    register int items;

    (void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
    items = (int)str_gnum(*tmpary);
    aunshift(ary,items);
    i = 0;
    for (elem = tmpary+1; i < items; i++,elem++) {
	str = str_new(0);
	str_sset(str,*elem);
	astore(ary,i,str);
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
    register int items;
    register int val;
    register int val2;
    char *s;

    if (sarg) {
	tmpary = sarg;
	items = 0;
	for (elem = tmpary+1; *elem; elem++)
	    items++;
    }
    else {
	(void)eval(arg[1].arg_ptr.arg_arg,&tmpary,-1);
	items = (int)str_gnum(*tmpary);
    }
    switch (type) {
    case O_CHMOD:
	if (--items > 0) {
	    val = (int)str_gnum(tmpary[1]);
	    for (elem = tmpary+2; *elem; elem++)
		if (chmod(str_get(*elem),val))
		    items--;
	}
	break;
    case O_CHOWN:
	if (items > 2) {
	    items -= 2;
	    val = (int)str_gnum(tmpary[1]);
	    val2 = (int)str_gnum(tmpary[2]);
	    for (elem = tmpary+3; *elem; elem++)
		if (chown(str_get(*elem),val,val2))
		    items--;
	}
	else
	    items = 0;
	break;
    case O_KILL:
	if (--items > 0) {
	    val = (int)str_gnum(tmpary[1]);
	    if (val < 0) {
		val = -val;
		for (elem = tmpary+2; *elem; elem++)
#ifdef KILLPG
		    if (killpg((int)(str_gnum(*elem)),val))	/* BSD */
#else
		    if (kill(-(int)(str_gnum(*elem)),val))	/* SYSV */
#endif
			items--;
	    }
	    else {
		for (elem = tmpary+2; *elem; elem++)
		    if (kill((int)(str_gnum(*elem)),val))
			items--;
	    }
	}
	break;
    case O_UNLINK:
	for (elem = tmpary+1; *elem; elem++) {
	    s = str_get(*elem);
	    if (euid || unsafe) {
		if (UNLINK(s))
		    items--;
	    }
	    else {	/* don't let root wipe out directories without -U */
		if (stat(s,&statbuf) < 0 ||
		  (statbuf.st_mode & S_IFMT) == S_IFDIR )
		    items--;
		else {
		    if (UNLINK(s))
			items--;
		}
	    }
	}
	break;
    case O_UTIME:
	if (items > 2) {
	    struct {
		long    atime,
			mtime;
	    } utbuf;

	    utbuf.atime = (long)str_gnum(tmpary[1]);    /* time accessed */
	    utbuf.mtime = (long)str_gnum(tmpary[2]);    /* time modified */
	    items -= 2;
	    for (elem = tmpary+3; *elem; elem++)
		if (utime(str_get(*elem),&utbuf))
		    items--;
	}
	else
	    items = 0;
	break;
    }
    if (!sarg)
	safefree((char*)tmpary);
    return items;
}

STR *
do_subr(arg,sarg)
register ARG *arg;
register STR **sarg;
{
    register SUBR *sub;
    ARRAY *savearray;
    STR *str;
    STAB *stab;
    char *oldfile = filename;
    int oldsave = savestack->ary_fill;
    int oldtmps_base = tmps_base;

    if (arg[2].arg_type == A_WORD)
	stab = arg[2].arg_ptr.arg_stab;
    else
	stab = stabent(str_get(arg[2].arg_ptr.arg_stab->stab_val),TRUE);
    if (!stab) {
	if (dowarn)
	    warn("Undefined subroutine called");
	return &str_no;
    }
    sub = stab->stab_sub;
    if (!sub) {
	if (dowarn)
	    warn("Undefined subroutine \"%s\" called", stab->stab_name);
	return &str_no;
    }
    savearray = defstab->stab_array;
    defstab->stab_array = anew(defstab);
    if (arg[1].arg_flags & AF_SPECIAL)
	(void)do_push(arg,defstab->stab_array);
    else if (arg[1].arg_type != A_NULL) {
	str = str_new(0);
	str_sset(str,sarg[1]);
	apush(defstab->stab_array,str);
    }
    sub->depth++;
    if (sub->depth >= 2) {	/* save temporaries on recursion? */
	if (sub->depth == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",stab->stab_name);
	savelist(sub->tosave->ary_array,sub->tosave->ary_fill);
    }
    filename = sub->filename;
    tmps_base = tmps_max;

    str = cmd_exec(sub->cmd);		/* so do it already */

    sub->depth--;	/* assuming no longjumps out of here */
    afree(defstab->stab_array);  /* put back old $_[] */
    defstab->stab_array = savearray;
    filename = oldfile;
    tmps_base = oldtmps_base;
    if (savestack->ary_fill > oldsave) {
	str = str_static(str);	/* in case restore wipes old str */
	restorelist(oldsave);
    }
    return str;
}

void
do_assign(retstr,arg,sarg)
STR *retstr;
register ARG *arg;
register STR **sarg;
{
    STR **tmpary;	/* must not be register */
    register ARG *larg = arg[1].arg_ptr.arg_arg;
    register STR **elem;
    register STR *str;
    register ARRAY *ary;
    register int i;
    register int items;
    STR *tmpstr;

    if (arg[2].arg_flags & AF_SPECIAL) {
	(void)eval(arg[2].arg_ptr.arg_arg,&tmpary,-1);
	items = (int)str_gnum(*tmpary);
    }
    else {
	tmpary = sarg;
	sarg[1] = sarg[2];
	sarg[2] = Nullstr;
	items = 1;
    }

    if (arg->arg_flags & AF_COMMON) {	/* always true currently, alas */
	if (*(tmpary+1)) {
	    for (i=2,elem=tmpary+2; i <= items; i++,elem++) {
		*elem = str_static(*elem);
	    }
	}
    }
    if (larg->arg_type == O_LIST) {
	for (i=1,elem=tmpary+1; i <= larg->arg_len; i++) {
	    switch (larg[i].arg_type) {
	    case A_STAB:
	    case A_LVAL:
		str = STAB_STR(larg[i].arg_ptr.arg_stab);
		break;
	    case A_LEXPR:
		str = eval(larg[i].arg_ptr.arg_arg,Null(STR***),-1);
		break;
	    }
	    if (larg->arg_flags & AF_LOCAL) {
		apush(savestack,str);	/* save pointer */
		tmpstr = str_new(0);
		str_sset(tmpstr,str);
		apush(savestack,tmpstr); /* save value */
	    }
	    if (*elem)
		str_sset(str,*(elem++));
	    else
		str_set(str,"");
	    STABSET(str);
	}
    }
    else {			/* should be an array name */
	ary = larg[1].arg_ptr.arg_stab->stab_array;
	for (i=0,elem=tmpary+1; i < items; i++) {
	    str = str_new(0);
	    if (*elem)
		str_sset(str,*(elem++));
	    astore(ary,i,str);
	}
	ary->ary_fill = items - 1;/* they can get the extra ones back by */
    }				/*   setting $#ary larger than old fill */
    str_numset(retstr,(double)items);
    STABSET(retstr);
    if (tmpary != sarg);
	safefree((char*)tmpary);
}

int
do_kv(hash,kv,retary,sarg,ptrmaxsarg,sargoff,cushion)
HASH *hash;
int kv;
STR ***retary;
register STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
{
    register ARRAY *ary;
    int max = 0;
    int i;
    static ARRAY *myarray = Null(ARRAY*);
    register HENT *entry;

    ary = myarray;
    if (!ary)
	myarray = ary = anew(Nullstab);
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
	*ptrmaxsarg = max + sargoff;
	sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	  (max+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	for (i = 1; i <= max; i++)
	    sarg[i] = afetch(ary,i-1);
	*retary = sarg;
    }
    return max;
}

STR *
do_each(hash,retary,sarg,ptrmaxsarg,sargoff,cushion)
HASH *hash;
STR ***retary;
STR **sarg;
int *ptrmaxsarg;
int sargoff;
int cushion;
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
	    *ptrmaxsarg = 2 + sargoff;
	    sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	      (2+2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	    sarg[1] = mystr = str_make(hiterkey(entry));
	    retstr = sarg[2] = hiterval(entry);
	    *retary = sarg;
	}
	else {
	    *ptrmaxsarg = sargoff;
	    sarg = (STR**)saferealloc((char*)(sarg - sargoff),
	      (2+cushion+sargoff)*sizeof(STR*)) + sargoff;
	    retstr = Nullstr;
	    *retary = sarg;
	}
    }
    else
	retstr = hiterval(entry);
	
    return retstr;
}

int
mystat(arg,str)
ARG *arg;
STR *str;
{
    STIO *stio;

    if (arg[1].arg_flags & AF_SPECIAL) {
	stio = arg[1].arg_ptr.arg_stab->stab_io;
	if (stio && stio->fp)
	    return fstat(fileno(stio->fp), &statbuf);
	else {
	    if (dowarn)
		warn("Stat on unopened file <%s>",
		  arg[1].arg_ptr.arg_stab->stab_name);
	    return -1;
	}
    }
    else
	return stat(str_get(str),&statbuf);
}

STR *
do_fttext(arg,str)
register ARG *arg;
STR *str;
{
    int i;
    int len;
    int odd = 0;
    STDCHAR tbuf[512];
    register STDCHAR *s;
    register STIO *stio;

    if (arg[1].arg_flags & AF_SPECIAL) {
	stio = arg[1].arg_ptr.arg_stab->stab_io;
	if (stio && stio->fp) {
#ifdef STDSTDIO
	    if (stio->fp->_cnt <= 0) {
		i = getc(stio->fp);
		ungetc(i,stio->fp);
	    }
	    if (stio->fp->_cnt <= 0)	/* null file is anything */
		return &str_yes;
	    len = stio->fp->_cnt + (stio->fp->_ptr - stio->fp->_base);
	    s = stio->fp->_base;
#else
	    fatal("-T and -B not implemented on filehandles\n");
#endif
	}
	else {
	    if (dowarn)
		warn("Test on unopened file <%s>",
		  arg[1].arg_ptr.arg_stab->stab_name);
	    return &str_no;
	}
    }
    else {
	i = open(str_get(str),0);
	if (i < 0)
	    return &str_no;
	len = read(i,tbuf,512);
	if (len <= 0)		/* null file is anything */
	    return &str_yes;
	close(i);
	s = tbuf;
    }

    /* now scan s to look for textiness */

    for (i = 0; i < len; i++,s++) {
	if (!*s) {			/* null never allowed in text */
	    odd += len;
	    break;
	}
	else if (*s & 128)
	    odd++;
	else if (*s < 32 &&
	  *s != '\n' && *s != '\r' && *s != '\b' &&
	  *s != '\t' && *s != '\f' && *s != 27)
	    odd++;
    }

    if ((odd * 10 > len) == (arg->arg_type == O_FTTEXT)) /* allow 10% odd */
	return &str_no;
    else
	return &str_yes;
}

int
do_study(str)
STR *str;
{
    register char *s = str_get(str);
    register int pos = str->str_cur;
    register int ch;
    register int *sfirst;
    register int *snext;
    static int maxscream = -1;
    static STR *lastscream = Nullstr;

    if (lastscream && lastscream->str_pok == 5)
	lastscream->str_pok &= ~4;
    lastscream = str;
    if (pos <= 0)
	return 0;
    if (pos > maxscream) {
	if (maxscream < 0) {
	    maxscream = pos + 80;
	    screamfirst = (int*)safemalloc((MEM_SIZE)(256 * sizeof(int)));
	    screamnext = (int*)safemalloc((MEM_SIZE)(maxscream * sizeof(int)));
	}
	else {
	    maxscream = pos + pos / 4;
	    screamnext = (int*)saferealloc((char*)screamnext,
		(MEM_SIZE)(maxscream * sizeof(int)));
	}
    }

    sfirst = screamfirst;
    snext = screamnext;

    if (!sfirst || !snext)
	fatal("do_study: out of memory");

    for (ch = 256; ch; --ch)
	*sfirst++ = -1;
    sfirst -= 256;

    while (--pos >= 0) {
	ch = s[pos];
	if (sfirst[ch] >= 0)
	    snext[pos] = sfirst[ch] - pos;
	else
	    snext[pos] = -pos;
	sfirst[ch] = pos;
    }

    str->str_pok |= 4;
    return 1;
}

init_eval()
{
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
    opargs[O_PRINT] =		A(1,1,0);
    opargs[O_CHDIR] =		A(1,0,0);
    opargs[O_DIE] =		A(1,0,0);
    opargs[O_EXIT] =		A(1,0,0);
    opargs[O_RESET] =		A(1,0,0);
    opargs[O_LIST] =		A(0,0,0);
    opargs[O_EOF] =		A(1,0,0);
    opargs[O_TELL] =		A(1,0,0);
    opargs[O_SEEK] =		A(1,1,1);
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
    opargs[O_PRTF] =		A(1,1,0);
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
    opargs[O_FTEREAD] =		A(1,0,0);
    opargs[O_FTEWRITE] =	A(1,0,0);
    opargs[O_FTEEXEC] =		A(1,0,0);
    opargs[O_FTEOWNED] =	A(1,0,0);
    opargs[O_FTRREAD] =		A(1,0,0);
    opargs[O_FTRWRITE] =	A(1,0,0);
    opargs[O_FTREXEC] =		A(1,0,0);
    opargs[O_FTROWNED] =	A(1,0,0);
    opargs[O_FTIS] =		A(1,0,0);
    opargs[O_FTZERO] =		A(1,0,0);
    opargs[O_FTSIZE] =		A(1,0,0);
    opargs[O_FTFILE] =		A(1,0,0);
    opargs[O_FTDIR] =		A(1,0,0);
    opargs[O_FTLINK] =		A(1,0,0);
    opargs[O_SYMLINK] =		A(1,1,0);
    opargs[O_FTPIPE] =		A(1,0,0);
    opargs[O_FTSUID] =		A(1,0,0);
    opargs[O_FTSGID] =		A(1,0,0);
    opargs[O_FTSVTX] =		A(1,0,0);
    opargs[O_FTCHR] =		A(1,0,0);
    opargs[O_FTBLK] =		A(1,0,0);
    opargs[O_FTSOCK] =		A(1,0,0);
    opargs[O_FTTTY] =		A(1,0,0);
    opargs[O_DOFILE] =		A(1,0,0);
    opargs[O_FTTEXT] =		A(1,0,0);
    opargs[O_FTBINARY] =	A(1,0,0);
    opargs[O_UTIME] =		A(1,0,0);
    opargs[O_WAIT] =		A(0,0,0);
    opargs[O_SORT] =		A(1,0,0);
    opargs[O_STUDY] =		A(1,0,0);
    opargs[O_DELETE] =		A(1,0,0);
}
