/* $Header: stab.c,v 3.0.1.10 90/11/10 02:02:05 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	stab.c,v $
 * Revision 3.0.1.10  90/11/10  02:02:05  lwall
 * patch38: random cleanup
 * 
 * Revision 3.0.1.9  90/10/16  10:32:05  lwall
 * patch29: added -M, -A and -C
 * patch29: taintperl now checks for world writable PATH components
 * patch29: *foo now prints as *package'foo
 * patch29: scripts now run at almost full speed under the debugger
 * patch29: package behavior is now more consistent
 * 
 * Revision 3.0.1.8  90/08/13  22:30:17  lwall
 * patch28: the NSIG hack didn't work right on Xenix
 * 
 * Revision 3.0.1.7  90/08/09  05:17:48  lwall
 * patch19: fixed double include of <signal.h>
 * patch19: $' broke on embedded nulls
 * patch19: $< and $> better supported on machines without setreuid
 * patch19: Added support for linked-in C subroutines
 * patch19: %ENV wasn't forced to be global like it should
 * patch19: $| didn't work before the filehandle was opened
 * patch19: $! now returns "" in string context if errno == 0
 * 
 * Revision 3.0.1.6  90/03/27  16:22:11  lwall
 * patch16: support for machines that can't cast negative floats to unsigned ints
 * 
 * Revision 3.0.1.5  90/03/12  17:00:11  lwall
 * patch13: undef $/ didn't work as advertised
 * 
 * Revision 3.0.1.4  90/02/28  18:19:14  lwall
 * patch9: $0 is now always the command name
 * patch9: you may now undef $/ to have no input record separator
 * patch9: local($.) didn't work
 * patch9: sometimes perl thought ordinary data was a symbol table entry
 * patch9: stab_array() and stab_hash() weren't defined on MICROPORT
 * 
 * Revision 3.0.1.3  89/12/21  20:18:40  lwall
 * patch7: ANSI strerror() is now supported
 * patch7: errno may now be a macro with an lvalue
 * patch7: in stab.c, sighandler() may now return either void or int
 * 
 * Revision 3.0.1.2  89/11/17  15:35:37  lwall
 * patch5: sighandler() needed to be static
 * 
 * Revision 3.0.1.1  89/11/11  04:55:07  lwall
 * patch2: sys_errlist[sys_nerr] is illegal
 * 
 * Revision 3.0  89/10/18  15:23:23  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX)
#include <signal.h>
#endif

static char *sig_name[] = {
    SIG_NAME,0
};

#ifdef VOIDSIG
#define handlertype void
#else
#define handlertype int
#endif

static handlertype sighandler();

STR *
stab_str(str)
STR *str;
{
    STAB *stab = str->str_u.str_stab;
    register int paren;
    register char *s;
    register int i;

    if (str->str_rare)
	return stab_val(stab);

    switch (*stab->str_magic->str_ptr) {
    case '\024':		/* ^T */
	str_numset(stab_val(stab),(double)basetime);
	break;
    case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '&':
	if (curspat) {
	    paren = atoi(stab_name(stab));
	  getparen:
	    if (curspat->spat_regexp &&
	      paren <= curspat->spat_regexp->nparens &&
	      (s = curspat->spat_regexp->startp[paren]) ) {
		i = curspat->spat_regexp->endp[paren] - s;
		if (i >= 0)
		    str_nset(stab_val(stab),s,i);
		else
		    str_sset(stab_val(stab),&str_undef);
	    }
	    else
		str_sset(stab_val(stab),&str_undef);
	}
	break;
    case '+':
	if (curspat) {
	    paren = curspat->spat_regexp->lastparen;
	    goto getparen;
	}
	break;
    case '`':
	if (curspat) {
	    if (curspat->spat_regexp &&
	      (s = curspat->spat_regexp->subbase) ) {
		i = curspat->spat_regexp->startp[0] - s;
		if (i >= 0)
		    str_nset(stab_val(stab),s,i);
		else
		    str_nset(stab_val(stab),"",0);
	    }
	    else
		str_nset(stab_val(stab),"",0);
	}
	break;
    case '\'':
	if (curspat) {
	    if (curspat->spat_regexp &&
	      (s = curspat->spat_regexp->endp[0]) ) {
		str_nset(stab_val(stab),s, curspat->spat_regexp->subend - s);
	    }
	    else
		str_nset(stab_val(stab),"",0);
	}
	break;
    case '.':
#ifndef lint
	if (last_in_stab) {
	    str_numset(stab_val(stab),(double)stab_io(last_in_stab)->lines);
	}
#endif
	break;
    case '?':
	str_numset(stab_val(stab),(double)statusvalue);
	break;
    case '^':
	s = stab_io(curoutstab)->top_name;
	str_set(stab_val(stab),s);
	break;
    case '~':
	s = stab_io(curoutstab)->fmt_name;
	str_set(stab_val(stab),s);
	break;
#ifndef lint
    case '=':
	str_numset(stab_val(stab),(double)stab_io(curoutstab)->page_len);
	break;
    case '-':
	str_numset(stab_val(stab),(double)stab_io(curoutstab)->lines_left);
	break;
    case '%':
	str_numset(stab_val(stab),(double)stab_io(curoutstab)->page);
	break;
#endif
    case '/':
	if (record_separator != 12345) {
	    *tokenbuf = record_separator;
	    tokenbuf[1] = '\0';
	    str_nset(stab_val(stab),tokenbuf,rslen);
	}
	break;
    case '[':
	str_numset(stab_val(stab),(double)arybase);
	break;
    case '|':
	if (!stab_io(curoutstab))
	    stab_io(curoutstab) = stio_new();
	str_numset(stab_val(stab),
	   (double)((stab_io(curoutstab)->flags & IOF_FLUSH) != 0) );
	break;
    case ',':
	str_nset(stab_val(stab),ofs,ofslen);
	break;
    case '\\':
	str_nset(stab_val(stab),ors,orslen);
	break;
    case '#':
	str_set(stab_val(stab),ofmt);
	break;
    case '!':
	str_numset(stab_val(stab), (double)errno);
	str_set(stab_val(stab), errno ? strerror(errno) : "");
	stab_val(stab)->str_nok = 1;	/* what a wonderful hack! */
	break;
    case '<':
	str_numset(stab_val(stab),(double)uid);
	break;
    case '>':
	str_numset(stab_val(stab),(double)euid);
	break;
    case '(':
	s = buf;
	(void)sprintf(s,"%d",(int)gid);
	goto add_groups;
    case ')':
	s = buf;
	(void)sprintf(s,"%d",(int)egid);
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
		(void)sprintf(s," %ld", (long)gary[i]);
		while (*s) s++;
	    }
	}
#endif
	str_set(stab_val(stab),buf);
	break;
    default:
	{
	    struct ufuncs *uf = (struct ufuncs *)str->str_ptr;

	    if (uf && uf->uf_val)
		(*uf->uf_val)(uf->uf_index, stab_val(stab));
	}
	break;
    }
    return stab_val(stab);
}

stabset(mstr,str)
register STR *mstr;
STR *str;
{
    STAB *stab = mstr->str_u.str_stab;
    char *s;
    int i;

    switch (mstr->str_rare) {
    case 'E':
	setenv(mstr->str_ptr,str_get(str));
				/* And you'll never guess what the dog had */
				/*   in its mouth... */
#ifdef TAINT
	if (strEQ(mstr->str_ptr,"PATH")) {
	    char *strend = str->str_ptr + str->str_cur;

	    s = str->str_ptr;
	    while (s < strend) {
		s = cpytill(tokenbuf,s,strend,':',&i);
		s++;
		if (*tokenbuf != '/'
		  || (stat(tokenbuf,&statbuf) && (statbuf.st_mode & 2)) )
		    str->str_tainted = 2;
	    }
	}
#endif
	break;
    case 'S':
	s = str_get(str);
	i = whichsig(mstr->str_ptr);	/* ...no, a brick */
	if (strEQ(s,"IGNORE"))
#ifndef lint
	    (void)signal(i,SIG_IGN);
#else
	    ;
#endif
	else if (strEQ(s,"DEFAULT") || !*s)
	    (void)signal(i,SIG_DFL);
	else {
	    (void)signal(i,sighandler);
	    if (!index(s,'\'')) {
		sprintf(tokenbuf, "main'%s",s);
		str_set(str,tokenbuf);
	    }
	}
	break;
#ifdef SOME_DBM
    case 'D':
	hdbmstore(stab_hash(stab),mstr->str_ptr,mstr->str_cur,str);
	break;
#endif
    case 'L':
	{
	    CMD *cmd;

	    i = str_true(str);
	    str = afetch(stab_xarray(stab),atoi(mstr->str_ptr), FALSE);
	    cmd = str->str_magic->str_u.str_cmd;
	    cmd->c_flags &= ~CF_OPTIMIZE;
	    cmd->c_flags |= i? CFT_D1 : CFT_D0;
	}
	break;
    case '#':
	afill(stab_array(stab), (int)str_gnum(str) - arybase);
	break;
    case 'X':	/* merely a copy of a * string */
	break;
    case '*':
	s = str_get(str);
	if (strNE(s,"StB") || str->str_cur != sizeof(STBP)) {
	    if (!*s) {
		STBP *stbp;

		(void)savenostab(stab);	/* schedule a free of this stab */
		if (stab->str_len)
		    Safefree(stab->str_ptr);
		Newz(601,stbp, 1, STBP);
		stab->str_ptr = stbp;
		stab->str_len = stab->str_cur = sizeof(STBP);
		stab->str_pok = 1;
		strcpy(stab_magic(stab),"StB");
		stab_val(stab) = Str_new(70,0);
		stab_line(stab) = curcmd->c_line;
	    }
	    else {
		stab = stabent(s,TRUE);
		if (!stab_xarray(stab))
		    aadd(stab);
		if (!stab_xhash(stab))
		    hadd(stab);
		if (!stab_io(stab))
		    stab_io(stab) = stio_new();
	    }
	    str_sset(str,stab);
	}
	break;
    case 's': {
	    struct lstring *lstr = (struct lstring*)str;

	    mstr->str_rare = 0;
	    str->str_magic = Nullstr;
	    str_insert(mstr,lstr->lstr_offset,lstr->lstr_len,
	      str->str_ptr,str->str_cur);
	}
	break;

    case 'v':
	do_vecset(mstr,str);
	break;

    case 0:
	switch (*stab->str_magic->str_ptr) {
	case '\024':	/* ^T */
	    basetime = (long)str_gnum(str);
	    break;
	case '.':
	    if (localizing)
		savesptr((STR**)&last_in_stab);
	    break;
	case '^':
	    Safefree(stab_io(curoutstab)->top_name);
	    stab_io(curoutstab)->top_name = s = savestr(str_get(str));
	    stab_io(curoutstab)->top_stab = stabent(s,TRUE);
	    break;
	case '~':
	    Safefree(stab_io(curoutstab)->fmt_name);
	    stab_io(curoutstab)->fmt_name = s = savestr(str_get(str));
	    stab_io(curoutstab)->fmt_stab = stabent(s,TRUE);
	    break;
	case '=':
	    stab_io(curoutstab)->page_len = (long)str_gnum(str);
	    break;
	case '-':
	    stab_io(curoutstab)->lines_left = (long)str_gnum(str);
	    if (stab_io(curoutstab)->lines_left < 0L)
		stab_io(curoutstab)->lines_left = 0L;
	    break;
	case '%':
	    stab_io(curoutstab)->page = (long)str_gnum(str);
	    break;
	case '|':
	    if (!stab_io(curoutstab))
		stab_io(curoutstab) = stio_new();
	    stab_io(curoutstab)->flags &= ~IOF_FLUSH;
	    if (str_gnum(str) != 0.0) {
		stab_io(curoutstab)->flags |= IOF_FLUSH;
	    }
	    break;
	case '*':
	    i = (int)str_gnum(str);
	    multiline = (i != 0);
	    break;
	case '/':
	    if (str->str_pok) {
		record_separator = *str_get(str);
		rslen = str->str_cur;
	    }
	    else {
		record_separator = 12345;	/* fake a non-existent char */
		rslen = 1;
	    }
	    break;
	case '\\':
	    if (ors)
		Safefree(ors);
	    ors = savestr(str_get(str));
	    orslen = str->str_cur;
	    break;
	case ',':
	    if (ofs)
		Safefree(ofs);
	    ofs = savestr(str_get(str));
	    ofslen = str->str_cur;
	    break;
	case '#':
	    if (ofmt)
		Safefree(ofmt);
	    ofmt = savestr(str_get(str));
	    break;
	case '[':
	    arybase = (int)str_gnum(str);
	    break;
	case '?':
	    statusvalue = U_S(str_gnum(str));
	    break;
	case '!':
	    errno = (int)str_gnum(str);		/* will anyone ever use this? */
	    break;
	case '<':
	    uid = (int)str_gnum(str);
#ifdef SETREUID
	    if (delaymagic) {
		delaymagic |= DM_REUID;
		break;				/* don't do magic till later */
	    }
#endif /* SETREUID */
#ifdef SETRUID
	    if (setruid((UIDTYPE)uid) < 0)
		uid = (int)getuid();
#else
#ifdef SETREUID
	    if (setreuid((UIDTYPE)uid, (UIDTYPE)-1) < 0)
		uid = (int)getuid();
#else
	    if (uid == euid)		/* special case $< = $> */
		setuid(uid);
	    else
		fatal("setruid() not implemented");
#endif
#endif
	    break;
	case '>':
	    euid = (int)str_gnum(str);
#ifdef SETREUID
	    if (delaymagic) {
		delaymagic |= DM_REUID;
		break;				/* don't do magic till later */
	    }
#endif /* SETREUID */
#ifdef SETEUID
	    if (seteuid((UIDTYPE)euid) < 0)
		euid = (int)geteuid();
#else
#ifdef SETREUID
	    if (setreuid((UIDTYPE)-1, (UIDTYPE)euid) < 0)
		euid = (int)geteuid();
#else
	    if (euid == uid)		/* special case $> = $< */
		setuid(euid);
	    else
		fatal("seteuid() not implemented");
#endif
#endif
	    break;
	case '(':
	    gid = (int)str_gnum(str);
#ifdef SETREGID
	    if (delaymagic) {
		delaymagic |= DM_REGID;
		break;				/* don't do magic till later */
	    }
#endif /* SETREGID */
#ifdef SETRGID
	    (void)setrgid((GIDTYPE)gid);
#else
#ifdef SETREGID
	    (void)setregid((GIDTYPE)gid, (GIDTYPE)-1);
#else
	    fatal("setrgid() not implemented");
#endif
#endif
	    break;
	case ')':
	    egid = (int)str_gnum(str);
#ifdef SETREGID
	    if (delaymagic) {
		delaymagic |= DM_REGID;
		break;				/* don't do magic till later */
	    }
#endif /* SETREGID */
#ifdef SETEGID
	    (void)setegid((GIDTYPE)egid);
#else
#ifdef SETREGID
	    (void)setregid((GIDTYPE)-1, (GIDTYPE)egid);
#else
	    fatal("setegid() not implemented");
#endif
#endif
	    break;
	case ':':
	    chopset = str_get(str);
	    break;
	default:
	    {
		struct ufuncs *uf = (struct ufuncs *)str->str_magic->str_ptr;

		if (uf && uf->uf_set)
		    (*uf->uf_set)(uf->uf_index, str);
	    }
	    break;
	}
	break;
    }
}

whichsig(sig)
char *sig;
{
    register char **sigv;

    for (sigv = sig_name+1; *sigv; sigv++)
	if (strEQ(sig,*sigv))
	    return sigv - sig_name;
#ifdef SIGCLD
    if (strEQ(sig,"CHLD"))
	return SIGCLD;
#endif
#ifdef SIGCHLD
    if (strEQ(sig,"CLD"))
	return SIGCHLD;
#endif
    return 0;
}

static handlertype
sighandler(sig)
int sig;
{
    STAB *stab;
    ARRAY *savearray;
    STR *str;
    CMD *oldcurcmd = curcmd;
    int oldsave = savestack->ary_fill;
    ARRAY *oldstack = stack;
    CSV *oldcurcsv = curcsv;
    SUBR *sub;

#ifdef OS2		/* or anybody else who requires SIG_ACK */
    signal(sig, SIG_ACK);
#endif
    curcsv = Nullcsv;
    stab = stabent(
	str_get(hfetch(stab_hash(sigstab),sig_name[sig],strlen(sig_name[sig]),
	  TRUE)), TRUE);
    sub = stab_sub(stab);
    if (!sub && *sig_name[sig] == 'C' && instr(sig_name[sig],"LD")) {
	if (sig_name[sig][1] == 'H')
	    stab = stabent(str_get(hfetch(stab_hash(sigstab),"CLD",3,TRUE)),
	      TRUE);
	else
	    stab = stabent(str_get(hfetch(stab_hash(sigstab),"CHLD",4,TRUE)),
	      TRUE);
	sub = stab_sub(stab);	/* gag */
    }
    if (!sub) {
	if (dowarn)
	    warn("SIG%s handler \"%s\" not defined.\n",
		sig_name[sig], stab_name(stab) );
	return;
    }
    savearray = stab_xarray(defstab);
    stab_xarray(defstab) = stack = anew(defstab);
    stack->ary_flags = 0;
    str = Str_new(71,0);
    str_set(str,sig_name[sig]);
    (void)apush(stab_xarray(defstab),str);
    sub->depth++;
    if (sub->depth >= 2) {	/* save temporaries on recursion? */
	if (sub->depth == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",stab_name(stab));
	savelist(sub->tosave->ary_array,sub->tosave->ary_fill);
    }

    (void)cmd_exec(sub->cmd,G_SCALAR,1);		/* so do it already */

    sub->depth--;	/* assuming no longjumps out of here */
    str_free(stack->ary_array[0]);	/* free the one real string */
    afree(stab_xarray(defstab));  /* put back old $_[] */
    stab_xarray(defstab) = savearray;
    stack = oldstack;
    if (savestack->ary_fill > oldsave)
	restorelist(oldsave);
    curcmd = oldcurcmd;
    curcsv = oldcurcsv;
}

STAB *
aadd(stab)
register STAB *stab;
{
    if (!stab_xarray(stab))
	stab_xarray(stab) = anew(stab);
    return stab;
}

STAB *
hadd(stab)
register STAB *stab;
{
    if (!stab_xhash(stab))
	stab_xhash(stab) = hnew(COEFFSIZE);
    return stab;
}

STAB *
fstab(name)
char *name;
{
    char tmpbuf[1200];
    STAB *stab;

    sprintf(tmpbuf,"'_<%s", name);
    stab = stabent(tmpbuf, TRUE);
    str_set(stab_val(stab), name);
    if (perldb)
	(void)hadd(aadd(stab));
    return stab;
}

STAB *
stabent(name,add)
register char *name;
int add;
{
    register STAB *stab;
    register STBP *stbp;
    int len;
    register char *namend;
    HASH *stash;
    char *sawquote = Nullch;
    char *prevquote = Nullch;
    bool global = FALSE;

    if (isascii(*name) && isupper(*name)) {
	if (*name > 'I') {
	    if (*name == 'S' && (
	      strEQ(name, "SIG") ||
	      strEQ(name, "STDIN") ||
	      strEQ(name, "STDOUT") ||
	      strEQ(name, "STDERR") ))
		global = TRUE;
	}
	else if (*name > 'E') {
	    if (*name == 'I' && strEQ(name, "INC"))
		global = TRUE;
	}
	else if (*name > 'A') {
	    if (*name == 'E' && strEQ(name, "ENV"))
		global = TRUE;
	}
	else if (*name == 'A' && (
	  strEQ(name, "ARGV") ||
	  strEQ(name, "ARGVOUT") ))
	    global = TRUE;
    }
    for (namend = name; *namend; namend++) {
	if (*namend == '\'' && namend[1])
	    prevquote = sawquote, sawquote = namend;
    }
    if (sawquote == name && name[1]) {
	stash = defstash;
	sawquote = Nullch;
	name++;
    }
    else if (!isalpha(*name) || global)
	stash = defstash;
    else if (curcmd == &compiling)
	stash = curstash;
    else
	stash = curcmd->c_stash;
    if (sawquote) {
	char tmpbuf[256];
	char *s, *d;

	*sawquote = '\0';
	if (s = prevquote) {
	    strncpy(tmpbuf,name,s-name+1);
	    d = tmpbuf+(s-name+1);
	    *d++ = '_';
	    strcpy(d,s+1);
	}
	else {
	    *tmpbuf = '_';
	    strcpy(tmpbuf+1,name);
	}
	stab = stabent(tmpbuf,TRUE);
	if (!(stash = stab_xhash(stab)))
	    stash = stab_xhash(stab) = hnew(0);
	if (!stash->tbl_name)
	    stash->tbl_name = savestr(name);
	name = sawquote+1;
	*sawquote = '\'';
    }
    len = namend - name;
    stab = (STAB*)hfetch(stash,name,len,add);
    if (stab == (STAB*)&str_undef)
	return Nullstab;
    if (stab->str_pok) {
	stab->str_pok |= SP_MULTI;
	return stab;
    }
    else {
	if (stab->str_len)
	    Safefree(stab->str_ptr);
	Newz(602,stbp, 1, STBP);
	stab->str_ptr = stbp;
	stab->str_len = stab->str_cur = sizeof(STBP);
	stab->str_pok = 1;
	strcpy(stab_magic(stab),"StB");
	stab_val(stab) = Str_new(72,0);
	stab_line(stab) = curcmd->c_line;
	str_magic(stab,stab,'*',name,len);
	stab_stash(stab) = stash;
	return stab;
    }
}

stab_fullname(str,stab)
STR *str;
STAB *stab;
{
    str_set(str,stab_stash(stab)->tbl_name);
    str_ncat(str,"'", 1);
    str_scat(str,stab->str_magic);
}

STIO *
stio_new()
{
    STIO *stio;

    Newz(603,stio,1,STIO);
    stio->page_len = 60;
    return stio;
}

stab_check(min,max)
int min;
register int max;
{
    register HENT *entry;
    register int i;
    register STAB *stab;

    for (i = min; i <= max; i++) {
	for (entry = defstash->tbl_array[i]; entry; entry = entry->hent_next) {
	    stab = (STAB*)entry->hent_val;
	    if (stab->str_pok & SP_MULTI)
		continue;
	    curcmd->c_line = stab_line(stab);
	    warn("Possible typo: \"%s\"", stab_name(stab));
	}
    }
}

static int gensym = 0;

STAB *
genstab()
{
    (void)sprintf(tokenbuf,"_GEN_%d",gensym++);
    return stabent(tokenbuf,TRUE);
}

/* hopefully this is only called on local symbol table entries */

void
stab_clear(stab)
register STAB *stab;
{
    STIO *stio;
    SUBR *sub;

    afree(stab_xarray(stab));
    (void)hfree(stab_xhash(stab), FALSE);
    str_free(stab_val(stab));
    if (stio = stab_io(stab)) {
	do_close(stab,FALSE);
	Safefree(stio->top_name);
	Safefree(stio->fmt_name);
    }
    if (sub = stab_sub(stab)) {
	afree(sub->tosave);
	cmd_free(sub->cmd);
    }
    Safefree(stab->str_ptr);
    stab->str_ptr = Null(STBP*);
    stab->str_len = 0;
    stab->str_cur = 0;
}

#if defined(CRIPPLED_CC) && (defined(iAPX286) || defined(M_I286) || defined(I80286))
#define MICROPORT
#endif

#ifdef	MICROPORT	/* Microport 2.4 hack */
ARRAY *stab_array(stab)
register STAB *stab;
{
    if (((STBP*)(stab->str_ptr))->stbp_array) 
	return ((STBP*)(stab->str_ptr))->stbp_array;
    else
	return ((STBP*)(aadd(stab)->str_ptr))->stbp_array;
}

HASH *stab_hash(stab)
register STAB *stab;
{
    if (((STBP*)(stab->str_ptr))->stbp_hash)
	return ((STBP*)(stab->str_ptr))->stbp_hash;
    else
	return ((STBP*)(hadd(stab)->str_ptr))->stbp_hash;
}
#endif			/* Microport 2.4 hack */
