char rcsid[] = "$Header: perly.c,v 2.0 88/06/05 00:09:56 root Exp $";
/*
 * $Log:	perly.c,v $
 * Revision 2.0  88/06/05  00:09:56  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"

extern char *tokename[];
extern int yychar;

static int cmd_tosave();
static int arg_tosave();
static int spat_tosave();

main(argc,argv,env)
register int argc;
register char **argv;
register char **env;
{
    register STR *str;
    register char *s;
    char *index(), *strcpy(), *getenv();
    bool dosearch = FALSE;

    uid = (int)getuid();
    euid = (int)geteuid();
    linestr = str_new(80);
    str_nset(linestr,"",0);
    str = str_make("");		/* first used for -I flags */
    incstab = aadd(stabent("INC",TRUE));
    for (argc--,argv++; argc; argc--,argv++) {
	if (argv[0][0] != '-' || !argv[0][1])
	    break;
      reswitch:
	switch (argv[0][1]) {
	case 'a':
	    minus_a = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
#ifdef DEBUGGING
	case 'D':
	    debug = atoi(argv[0]+2);
#ifdef YYDEBUG
	    yydebug = (debug & 1);
#endif
	    break;
#endif
	case 'e':
	    if (!e_fp) {
	        e_tmpname = strcpy(safemalloc(sizeof(TMPPATH)),TMPPATH);
		mktemp(e_tmpname);
		e_fp = fopen(e_tmpname,"w");
	    }
	    if (argv[1])
		fputs(argv[1],e_fp);
	    putc('\n', e_fp);
	    argc--,argv++;
	    break;
	case 'i':
	    inplace = savestr(argv[0]+2);
	    argvoutstab = stabent("ARGVOUT",TRUE);
	    break;
	case 'I':
	    str_cat(str,argv[0]);
	    str_cat(str," ");
	    if (argv[0][2]) {
		apush(incstab->stab_array,str_make(argv[0]+2));
	    }
	    else {
		apush(incstab->stab_array,str_make(argv[1]));
		str_cat(str,argv[1]);
		argc--,argv++;
		str_cat(str," ");
	    }
	    break;
	case 'n':
	    minus_n = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'p':
	    minus_p = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'P':
	    preprocess = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 's':
	    doswitches = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'S':
	    dosearch = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'U':
	    unsafe = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'v':
	    version();
	    exit(0);
	case 'w':
	    dowarn = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case '-':
	    argc--,argv++;
	    goto switch_end;
	case 0:
	    break;
	default:
	    fatal("Unrecognized switch: %s",argv[0]);
	}
    }
  switch_end:
    if (e_fp) {
	fclose(e_fp);
	argc++,argv--;
	argv[0] = e_tmpname;
    }
#ifndef PRIVLIB
#define PRIVLIB "/usr/local/lib/perl"
#endif
    apush(incstab->stab_array,str_make(PRIVLIB));

    str_set(&str_no,No);
    str_set(&str_yes,Yes);
    init_eval();

    /* open script */

    if (argv[0] == Nullch)
	argv[0] = "-";
    if (dosearch && argv[0][0] != '/' && (s = getenv("PATH"))) {
	char *xfound = Nullch, *xfailed = Nullch;

	while (*s) {
	    s = cpytill(tokenbuf,s,':');
	    if (*s)
		s++;
	    if (tokenbuf[0])
		strcat(tokenbuf,"/");
	    strcat(tokenbuf,argv[0]);
#ifdef DEBUGGING
	    if (debug & 1)
		fprintf(stderr,"Looking for %s\n",tokenbuf);
#endif
	    if (stat(tokenbuf,&statbuf) < 0)		/* not there? */
		continue;
	    if ((statbuf.st_mode & S_IFMT) == S_IFREG
	     && cando(S_IREAD,TRUE) && cando(S_IEXEC,TRUE)) {
		xfound = tokenbuf;              /* bingo! */
		break;
	    }
	    if (!xfailed)
		xfailed = savestr(tokenbuf);
	}
	if (!xfound)
	    fatal("Can't execute %s", xfailed);
	if (xfailed)
	    safefree(xfailed);
	argv[0] = savestr(xfound);
    }
    filename = savestr(argv[0]);
    origfilename = savestr(filename);
    if (strEQ(filename,"-"))
	argv[0] = "";
    if (preprocess) {
	str_cat(str,"-I");
	str_cat(str,PRIVLIB);
	sprintf(buf, "\
/bin/sed -e '/^[^#]/b' \
 -e '/^#[ 	]*include[ 	]/b' \
 -e '/^#[ 	]*define[ 	]/b' \
 -e '/^#[ 	]*if[ 	]/b' \
 -e '/^#[ 	]*ifdef[ 	]/b' \
 -e '/^#[ 	]*ifndef[ 	]/b' \
 -e '/^#[ 	]*else/b' \
 -e '/^#[ 	]*endif/b' \
 -e 's/^#.*//' \
 %s | %s -C %s %s",
	  argv[0], CPPSTDIN, str_get(str), CPPMINUS);
	rsfp = popen(buf,"r");
    }
    else if (!*argv[0])
	rsfp = stdin;
    else
	rsfp = fopen(argv[0],"r");
    if (rsfp == Nullfp)
	fatal("Perl script \"%s\" doesn't seem to exist",filename);
    str_free(str);		/* free -I directories */

    defstab = stabent("_",TRUE);

    /* init tokener */

    bufptr = str_get(linestr);

    /* now parse the report spec */

    if (yyparse())
	fatal("Execution aborted due to compilation errors.\n");

    if (dowarn) {
	stab_check('A','Z');
	stab_check('a','z');
    }

    preprocess = FALSE;
    if (e_fp) {
	e_fp = Nullfp;
	UNLINK(e_tmpname);
    }
    argc--,argv++;	/* skip name of script */
    if (doswitches) {
	for (; argc > 0 && **argv == '-'; argc--,argv++) {
	    if (argv[0][1] == '-') {
		argc--,argv++;
		break;
	    }
	    str_numset(stabent(argv[0]+1,TRUE)->stab_val,(double)1.0);
	}
    }
    if (argvstab = stabent("ARGV",allstabs)) {
	aadd(argvstab);
	for (; argc > 0; argc--,argv++) {
	    apush(argvstab->stab_array,str_make(argv[0]));
	}
    }
    if (envstab = stabent("ENV",allstabs)) {
	hadd(envstab);
	for (; *env; env++) {
	    if (!(s = index(*env,'=')))
		continue;
	    *s++ = '\0';
	    str = str_make(s);
	    str->str_link.str_magic = envstab;
	    hstore(envstab->stab_hash,*env,str);
	    *--s = '=';
	}
    }
    if (sigstab = stabent("SIG",allstabs))
	hadd(sigstab);

    magicalize("!#?^~=-%0123456789.+&*()<>,\\/[|");

    sawampersand = (stabent("&",FALSE) != Nullstab);
    if (tmpstab = stabent("0",allstabs))
	str_set(STAB_STR(tmpstab),origfilename);
    if (tmpstab = stabent("$",allstabs))
	str_numset(STAB_STR(tmpstab),(double)getpid());

    tmpstab = stabent("stdin",TRUE);
    tmpstab->stab_io = stio_new();
    tmpstab->stab_io->fp = stdin;

    tmpstab = stabent("stdout",TRUE);
    tmpstab->stab_io = stio_new();
    tmpstab->stab_io->fp = stdout;
    defoutstab = tmpstab;
    curoutstab = tmpstab;

    tmpstab = stabent("stderr",TRUE);
    tmpstab->stab_io = stio_new();
    tmpstab->stab_io->fp = stderr;

    savestack = anew(Nullstab);		/* for saving non-local values */

    setjmp(top_env);	/* sets goto_targ on longjump */

#ifdef DEBUGGING
    if (debug & 1024)
	dump_cmd(main_root,Nullcmd);
    if (debug)
	fprintf(stderr,"\nEXECUTING...\n\n");
#endif

    /* do it */

    (void) cmd_exec(main_root);

    if (goto_targ)
	fatal("Can't find label \"%s\"--aborting",goto_targ);
    exit(0);
    /* NOTREACHED */
}

magicalize(list)
register char *list;
{
    register STAB *stab;
    char sym[2];

    sym[1] = '\0';
    while (*sym = *list++) {
	if (stab = stabent(sym,allstabs)) {
	    stab->stab_flags = SF_VMAGIC;
	    stab->stab_val->str_link.str_magic = stab;
	}
    }
}

ARG *
make_split(stab,arg)
register STAB *stab;
register ARG *arg;
{
    register SPAT *spat = (SPAT *) safemalloc(sizeof (SPAT));

    if (arg->arg_type != O_MATCH) {
	spat = (SPAT *) safemalloc(sizeof (SPAT));
	bzero((char *)spat, sizeof(SPAT));
	spat->spat_next = spat_root;	/* link into spat list */
	spat_root = spat;

	spat->spat_runtime = arg;
	arg = make_match(O_MATCH,stab2arg(A_STAB,defstab),spat);
    }
    arg->arg_type = O_SPLIT;
    spat = arg[2].arg_ptr.arg_spat;
    spat->spat_repl = stab2arg(A_STAB,aadd(stab));
    if (spat->spat_short) {	/* exact match can bypass regexec() */
	if (!((spat->spat_flags & SPAT_SCANFIRST) &&
	    (spat->spat_flags & SPAT_ALL) )) {
	    str_free(spat->spat_short);
	    spat->spat_short = Nullstr;
	}
    }
    return arg;
}

SUBR *
make_sub(name,cmd)
char *name;
CMD *cmd;
{
    register SUBR *sub = (SUBR *) safemalloc(sizeof (SUBR));
    STAB *stab = stabent(name,TRUE);

    if (stab->stab_sub) {
	if (dowarn) {
	    line_t oldline = line;

	    if (cmd)
		line = cmd->c_line;
	    warn("Subroutine %s redefined",name);
	    line = oldline;
	}
	cmd_free(stab->stab_sub->cmd);
	afree(stab->stab_sub->tosave);
	safefree((char*)stab->stab_sub);
    }
    bzero((char *)sub, sizeof(SUBR));
    sub->cmd = cmd;
    sub->filename = filename;
    tosave = anew(Nullstab);
    tosave->ary_fill = 0;	/* make 1 based */
    cmd_tosave(cmd);		/* this builds the tosave array */
    sub->tosave = tosave;
    stab->stab_sub = sub;
}

CMD *
block_head(tail)
register CMD *tail;
{
    if (tail == Nullcmd) {
	return tail;
    }
    return tail->c_head;
}

CMD *
append_line(head,tail)
register CMD *head;
register CMD *tail;
{
    if (tail == Nullcmd)
	return head;
    if (!tail->c_head)			/* make sure tail is well formed */
	tail->c_head = tail;
    if (head != Nullcmd) {
	tail = tail->c_head;		/* get to start of tail list */
	if (!head->c_head)
	    head->c_head = head;	/* start a new head list */
	while (head->c_next) {
	    head->c_next->c_head = head->c_head;
	    head = head->c_next;	/* get to end of head list */
	}
	head->c_next = tail;		/* link to end of old list */
	tail->c_head = head->c_head;	/* propagate head pointer */
    }
    while (tail->c_next) {
	tail->c_next->c_head = tail->c_head;
	tail = tail->c_next;
    }
    return tail;
}

CMD *
make_acmd(type,stab,cond,arg)
int type;
STAB *stab;
ARG *cond;
ARG *arg;
{
    register CMD *cmd = (CMD *) safemalloc(sizeof (CMD));

    bzero((char *)cmd, sizeof(CMD));
    cmd->c_type = type;
    cmd->ucmd.acmd.ac_stab = stab;
    cmd->ucmd.acmd.ac_expr = arg;
    cmd->c_expr = cond;
    if (cond) {
	opt_arg(cmd,1,1);
	cmd->c_flags |= CF_COND;
    }
    if (cmdline != NOLINE) {
	cmd->c_line = cmdline;
	cmdline = NOLINE;
    }
    cmd->c_file = filename;
    return cmd;
}

CMD *
make_ccmd(type,arg,cblock)
int type;
register ARG *arg;
struct compcmd cblock;
{
    register CMD *cmd = (CMD *) safemalloc(sizeof (CMD));

    bzero((char *)cmd, sizeof(CMD));
    cmd->c_type = type;
    cmd->c_expr = arg;
    cmd->ucmd.ccmd.cc_true = cblock.comp_true;
    cmd->ucmd.ccmd.cc_alt = cblock.comp_alt;
    if (arg) {
	opt_arg(cmd,1,0);
	cmd->c_flags |= CF_COND;
    }
    if (cmdline != NOLINE) {
	cmd->c_line = cmdline;
	cmdline = NOLINE;
    }
    return cmd;
}

void
opt_arg(cmd,fliporflop,acmd)
register CMD *cmd;
int fliporflop;
int acmd;
{
    register ARG *arg;
    int opt = CFT_EVAL;
    int sure = 0;
    ARG *arg2;
    char *tmps;	/* for True macro */
    int context = 0;	/* 0 = normal, 1 = before &&, 2 = before || */
    int flp = fliporflop;

    if (!cmd)
	return;
    arg = cmd->c_expr;

    /* Can we turn && and || into if and unless? */

    if (acmd && !cmd->ucmd.acmd.ac_expr && 
      (arg->arg_type == O_AND || arg->arg_type == O_OR) ) {
	dehoist(arg,1);
	dehoist(arg,2);
	cmd->ucmd.acmd.ac_expr = arg[2].arg_ptr.arg_arg;
	cmd->c_expr = arg[1].arg_ptr.arg_arg;
	if (arg->arg_type == O_OR)
	    cmd->c_flags ^= CF_INVERT;		/* || is like unless */
	arg->arg_len = 0;
	arg_free(arg);
	arg = cmd->c_expr;
    }

    /* Turn "if (!expr)" into "unless (expr)" */

    while (arg->arg_type == O_NOT) {
	dehoist(arg,1);
	cmd->c_flags ^= CF_INVERT;		/* flip sense of cmd */
	cmd->c_expr = arg[1].arg_ptr.arg_arg;	/* hoist the rest of expr */
	free_arg(arg);
	arg = cmd->c_expr;			/* here we go again */
    }

    if (!arg->arg_len) {		/* sanity check */
	cmd->c_flags |= opt;
	return;
    }

    /* for "cond .. cond" we set up for the initial check */

    if (arg->arg_type == O_FLIP)
	context |= 4;

    /* for "cond && expr" and "cond || expr" we can ignore expr, sort of */

    if (arg->arg_type == O_AND)
	context |= 1;
    else if (arg->arg_type == O_OR)
	context |= 2;
    if (context && arg[flp].arg_type == A_EXPR) {
	arg = arg[flp].arg_ptr.arg_arg;
	flp = 1;
    }

    if (arg[flp].arg_flags & (AF_PRE|AF_POST)) {
	cmd->c_flags |= opt;
	return;				/* side effect, can't optimize */
    }

    if (arg->arg_type == O_ITEM || arg->arg_type == O_FLIP ||
      arg->arg_type == O_AND || arg->arg_type == O_OR) {
	if (arg[flp].arg_type == A_SINGLE) {
	    opt = (str_true(arg[flp].arg_ptr.arg_str) ? CFT_TRUE : CFT_FALSE);
	    cmd->c_short = arg[flp].arg_ptr.arg_str;
	    goto literal;
	}
	else if (arg[flp].arg_type == A_STAB || arg[flp].arg_type == A_LVAL) {
	    cmd->c_stab  = arg[flp].arg_ptr.arg_stab;
	    opt = CFT_REG;
	  literal:
	    if (!context) {	/* no && or ||? */
		free_arg(arg);
		cmd->c_expr = Nullarg;
	    }
	    if (!(context & 1))
		cmd->c_flags |= CF_EQSURE;
	    if (!(context & 2))
		cmd->c_flags |= CF_NESURE;
	}
    }
    else if (arg->arg_type == O_MATCH || arg->arg_type == O_SUBST ||
	     arg->arg_type == O_NMATCH || arg->arg_type == O_NSUBST) {
	if ((arg[1].arg_type == A_STAB || arg[1].arg_type == A_LVAL) &&
		arg[2].arg_type == A_SPAT &&
		arg[2].arg_ptr.arg_spat->spat_short ) {
	    cmd->c_stab  = arg[1].arg_ptr.arg_stab;
	    cmd->c_short = arg[2].arg_ptr.arg_spat->spat_short;
	    cmd->c_slen  = arg[2].arg_ptr.arg_spat->spat_slen;
	    if (arg[2].arg_ptr.arg_spat->spat_flags & SPAT_ALL &&
		!(arg[2].arg_ptr.arg_spat->spat_flags & SPAT_ONCE) &&
		(arg->arg_type == O_MATCH || arg->arg_type == O_NMATCH) )
		sure |= CF_EQSURE;		/* (SUBST must be forced even */
						/* if we know it will work.) */
	    arg[2].arg_ptr.arg_spat->spat_short = Nullstr;
	    arg[2].arg_ptr.arg_spat->spat_slen = 0; /* only one chk */
	    sure |= CF_NESURE;		/* normally only sure if it fails */
	    if (arg->arg_type == O_NMATCH || arg->arg_type == O_NSUBST)
		cmd->c_flags |= CF_FIRSTNEG;
	    if (context & 1) {		/* only sure if thing is false */
		if (cmd->c_flags & CF_FIRSTNEG)
		    sure &= ~CF_NESURE;
		else
		    sure &= ~CF_EQSURE;
	    }
	    else if (context & 2) {	/* only sure if thing is true */
		if (cmd->c_flags & CF_FIRSTNEG)
		    sure &= ~CF_EQSURE;
		else
		    sure &= ~CF_NESURE;
	    }
	    if (sure & (CF_EQSURE|CF_NESURE)) {	/* if we know anything*/
		if (arg[2].arg_ptr.arg_spat->spat_flags & SPAT_SCANFIRST)
		    opt = CFT_SCAN;
		else
		    opt = CFT_ANCHOR;
		if (sure == (CF_EQSURE|CF_NESURE)	/* really sure? */
		    && arg->arg_type == O_MATCH
		    && context & 4
		    && fliporflop == 1) {
		    spat_free(arg[2].arg_ptr.arg_spat);
		    arg[2].arg_ptr.arg_spat = Nullspat;	/* don't do twice */
		}
		cmd->c_flags |= sure;
	    }
	}
    }
    else if (arg->arg_type == O_SEQ || arg->arg_type == O_SNE ||
	     arg->arg_type == O_SLT || arg->arg_type == O_SGT) {
	if (arg[1].arg_type == A_STAB || arg[1].arg_type == A_LVAL) {
	    if (arg[2].arg_type == A_SINGLE) {
		cmd->c_stab  = arg[1].arg_ptr.arg_stab;
		cmd->c_short = arg[2].arg_ptr.arg_str;
		cmd->c_slen  = 30000;
		switch (arg->arg_type) {
		case O_SLT: case O_SGT:
		    sure |= CF_EQSURE;
		    cmd->c_flags |= CF_FIRSTNEG;
		    break;
		case O_SNE:
		    cmd->c_flags |= CF_FIRSTNEG;
		    /* FALL THROUGH */
		case O_SEQ:
		    sure |= CF_NESURE|CF_EQSURE;
		    break;
		}
		if (context & 1) {	/* only sure if thing is false */
		    if (cmd->c_flags & CF_FIRSTNEG)
			sure &= ~CF_NESURE;
		    else
			sure &= ~CF_EQSURE;
		}
		else if (context & 2) { /* only sure if thing is true */
		    if (cmd->c_flags & CF_FIRSTNEG)
			sure &= ~CF_EQSURE;
		    else
			sure &= ~CF_NESURE;
		}
		if (sure & (CF_EQSURE|CF_NESURE)) {
		    opt = CFT_STROP;
		    cmd->c_flags |= sure;
		}
	    }
	}
    }
    else if (arg->arg_type == O_EQ || arg->arg_type == O_NE ||
	     arg->arg_type == O_LE || arg->arg_type == O_GE ||
	     arg->arg_type == O_LT || arg->arg_type == O_GT) {
	if (arg[1].arg_type == A_STAB || arg[1].arg_type == A_LVAL) {
	    if (arg[2].arg_type == A_SINGLE) {
		cmd->c_stab  = arg[1].arg_ptr.arg_stab;
		cmd->c_short = str_nmake(str_gnum(arg[2].arg_ptr.arg_str));
		cmd->c_slen = arg->arg_type;
		sure |= CF_NESURE|CF_EQSURE;
		if (context & 1) {	/* only sure if thing is false */
		    sure &= ~CF_EQSURE;
		}
		else if (context & 2) { /* only sure if thing is true */
		    sure &= ~CF_NESURE;
		}
		if (sure & (CF_EQSURE|CF_NESURE)) {
		    opt = CFT_NUMOP;
		    cmd->c_flags |= sure;
		}
	    }
	}
    }
    else if (arg->arg_type == O_ASSIGN &&
	     (arg[1].arg_type == A_STAB || arg[1].arg_type == A_LVAL) &&
	     arg[1].arg_ptr.arg_stab == defstab &&
	     arg[2].arg_type == A_EXPR ) {
	arg2 = arg[2].arg_ptr.arg_arg;
	if (arg2->arg_type == O_ITEM && arg2[1].arg_type == A_READ) {
	    opt = CFT_GETS;
	    cmd->c_stab = arg2[1].arg_ptr.arg_stab;
	    if (!(arg2[1].arg_ptr.arg_stab->stab_io->flags & IOF_ARGV)) {
		free_arg(arg2);
		free_arg(arg);
		cmd->c_expr = Nullarg;
	    }
	}
    }
    else if (arg->arg_type == O_CHOP &&
	     (arg[1].arg_type == A_STAB || arg[1].arg_type == A_LVAL) ) {
	opt = CFT_CHOP;
	cmd->c_stab = arg[1].arg_ptr.arg_stab;
	free_arg(arg);
	cmd->c_expr = Nullarg;
    }
    if (context & 4)
	opt |= CF_FLIP;
    cmd->c_flags |= opt;

    if (cmd->c_flags & CF_FLIP) {
	if (fliporflop == 1) {
	    arg = cmd->c_expr;	/* get back to O_FLIP arg */
	    arg[3].arg_ptr.arg_cmd = (CMD*)safemalloc(sizeof(CMD));
	    bcopy((char *)cmd, (char *)arg[3].arg_ptr.arg_cmd, sizeof(CMD));
	    arg[4].arg_ptr.arg_cmd = (CMD*)safemalloc(sizeof(CMD));
	    bcopy((char *)cmd, (char *)arg[4].arg_ptr.arg_cmd, sizeof(CMD));
	    opt_arg(arg[4].arg_ptr.arg_cmd,2,acmd);
	    arg->arg_len = 2;		/* this is a lie */
	}
	else {
	    if ((opt & CF_OPTIMIZE) == CFT_EVAL)
		cmd->c_flags = (cmd->c_flags & ~CF_OPTIMIZE) | CFT_UNFLIP;
	}
    }
}

ARG *
mod_match(type,left,pat)
register ARG *left;
register ARG *pat;
{

    register SPAT *spat;
    register ARG *newarg;

    if ((pat->arg_type == O_MATCH ||
	 pat->arg_type == O_SUBST ||
	 pat->arg_type == O_TRANS ||
	 pat->arg_type == O_SPLIT
	) &&
	pat[1].arg_ptr.arg_stab == defstab ) {
	switch (pat->arg_type) {
	case O_MATCH:
	    newarg = make_op(type == O_MATCH ? O_MATCH : O_NMATCH,
		pat->arg_len,
		left,Nullarg,Nullarg,0);
	    break;
	case O_SUBST:
	    newarg = l(make_op(type == O_MATCH ? O_SUBST : O_NSUBST,
		pat->arg_len,
		left,Nullarg,Nullarg,0));
	    break;
	case O_TRANS:
	    newarg = l(make_op(type == O_MATCH ? O_TRANS : O_NTRANS,
		pat->arg_len,
		left,Nullarg,Nullarg,0));
	    break;
	case O_SPLIT:
	    newarg = make_op(type == O_MATCH ? O_SPLIT : O_SPLIT,
		pat->arg_len,
		left,Nullarg,Nullarg,0);
	    break;
	}
	if (pat->arg_len >= 2) {
	    newarg[2].arg_type = pat[2].arg_type;
	    newarg[2].arg_ptr = pat[2].arg_ptr;
	    newarg[2].arg_flags = pat[2].arg_flags;
	    if (pat->arg_len >= 3) {
		newarg[3].arg_type = pat[3].arg_type;
		newarg[3].arg_ptr = pat[3].arg_ptr;
		newarg[3].arg_flags = pat[3].arg_flags;
	    }
	}
	safefree((char*)pat);
    }
    else {
	spat = (SPAT *) safemalloc(sizeof (SPAT));
	bzero((char *)spat, sizeof(SPAT));
	spat->spat_next = spat_root;	/* link into spat list */
	spat_root = spat;

	spat->spat_runtime = pat;
	newarg = make_op(type,2,left,Nullarg,Nullarg,0);
	newarg[2].arg_type = A_SPAT;
	newarg[2].arg_ptr.arg_spat = spat;
	newarg[2].arg_flags = AF_SPECIAL;
    }

    return newarg;
}

CMD *
add_label(lbl,cmd)
char *lbl;
register CMD *cmd;
{
    if (cmd)
	cmd->c_label = lbl;
    return cmd;
}

CMD *
addcond(cmd, arg)
register CMD *cmd;
register ARG *arg;
{
    cmd->c_expr = arg;
    opt_arg(cmd,1,0);
    cmd->c_flags |= CF_COND;
    return cmd;
}

CMD *
addloop(cmd, arg)
register CMD *cmd;
register ARG *arg;
{
    cmd->c_expr = arg;
    opt_arg(cmd,1,0);
    cmd->c_flags |= CF_COND|CF_LOOP;
    if (cmd->c_type == C_BLOCK)
	cmd->c_flags &= ~CF_COND;
    else {
	arg = cmd->ucmd.acmd.ac_expr;
	if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_CMD)
	    cmd->c_flags &= ~CF_COND;  /* "do {} while" happens at least once */
	if (arg && arg->arg_type == O_SUBR)
	    cmd->c_flags &= ~CF_COND;  /* likewise for "do subr() while" */
    }
    return cmd;
}

CMD *
invert(cmd)
register CMD *cmd;
{
    cmd->c_flags ^= CF_INVERT;
    return cmd;
}

yyerror(s)
char *s;
{
    char tmpbuf[128];
    char *tname = tmpbuf;

    if (yychar > 256) {
	tname = tokename[yychar-256];
	if (strEQ(tname,"word"))
	    strcpy(tname,tokenbuf);
	else if (strEQ(tname,"register"))
	    sprintf(tname,"$%s",tokenbuf);
	else if (strEQ(tname,"array_length"))
	    sprintf(tname,"$#%s",tokenbuf);
    }
    else if (!yychar)
	strcpy(tname,"EOF");
    else if (yychar < 32)
	sprintf(tname,"^%c",yychar+64);
    else if (yychar == 127)
	strcpy(tname,"^?");
    else
	sprintf(tname,"%c",yychar);
    sprintf(tokenbuf, "%s in file %s at line %d, next token \"%s\"\n",
      s,filename,line,tname);
    if (in_eval)
	str_set(stabent("@",TRUE)->stab_val,tokenbuf);
    else
	fputs(tokenbuf,stderr);
}

ARG *
make_op(type,newlen,arg1,arg2,arg3,dolist)
int type;
int newlen;
ARG *arg1;
ARG *arg2;
ARG *arg3;
int dolist;
{
    register ARG *arg;
    register ARG *chld;
    register int doarg;

    arg = op_new(newlen);
    arg->arg_type = type;
    doarg = opargs[type];
    if (chld = arg1) {
	if (!(doarg & 1))
	    arg[1].arg_flags |= AF_SPECIAL;
	if (doarg & 16)
	    arg[1].arg_flags |= AF_NUMERIC;
	if (chld->arg_type == O_ITEM &&
	    (hoistable[chld[1].arg_type] || chld[1].arg_type == A_LVAL) ) {
	    arg[1].arg_type = chld[1].arg_type;
	    arg[1].arg_ptr = chld[1].arg_ptr;
	    arg[1].arg_flags |= chld[1].arg_flags;
	    free_arg(chld);
	}
	else {
	    arg[1].arg_type = A_EXPR;
	    arg[1].arg_ptr.arg_arg = chld;
	    if (dolist & 1) {
		if (chld->arg_type == O_LIST) {
		    if (newlen == 1) {	/* we can hoist entire list */
			chld->arg_type = type;
			free_arg(arg);
			arg = chld;
		    }
		    else {
			arg[1].arg_flags |= AF_SPECIAL;
		    }
		}
		else {
		    switch (chld->arg_type) {
		    case O_ARRAY:
			if (chld->arg_len == 1)
			    arg[1].arg_flags |= AF_SPECIAL;
			break;
		    case O_ITEM:
			if (chld[1].arg_type == A_READ ||
			    chld[1].arg_type == A_INDREAD ||
			    chld[1].arg_type == A_GLOB)
			    arg[1].arg_flags |= AF_SPECIAL;
			break;
		    case O_SPLIT:
		    case O_TMS:
		    case O_EACH:
		    case O_VALUES:
		    case O_KEYS:
		    case O_SORT:
			arg[1].arg_flags |= AF_SPECIAL;
			break;
		    }
		}
	    }
	}
    }
    if (chld = arg2) {
	if (!(doarg & 2))
	    arg[2].arg_flags |= AF_SPECIAL;
	if (doarg & 32)
	    arg[2].arg_flags |= AF_NUMERIC;
	if (chld->arg_type == O_ITEM && 
	    (hoistable[chld[1].arg_type] || 
	     (type == O_ASSIGN && 
	      ((chld[1].arg_type == A_READ && !(arg[1].arg_flags & AF_SPECIAL))
		||
	       (chld[1].arg_type == A_INDREAD && !(arg[1].arg_flags & AF_SPECIAL))
		||
	       (chld[1].arg_type == A_GLOB && !(arg[1].arg_flags & AF_SPECIAL))
		||
	       chld[1].arg_type == A_BACKTICK ) ) ) ) {
	    arg[2].arg_type = chld[1].arg_type;
	    arg[2].arg_ptr = chld[1].arg_ptr;
	    free_arg(chld);
	}
	else {
	    arg[2].arg_type = A_EXPR;
	    arg[2].arg_ptr.arg_arg = chld;
	    if ((dolist & 2) &&
	      (chld->arg_type == O_LIST ||
	       (chld->arg_type == O_ARRAY && chld->arg_len == 1) ))
		arg[2].arg_flags |= AF_SPECIAL;
	}
    }
    if (chld = arg3) {
	if (!(doarg & 4))
	    arg[3].arg_flags |= AF_SPECIAL;
	if (doarg & 64)
	    arg[3].arg_flags |= AF_NUMERIC;
	if (chld->arg_type == O_ITEM && hoistable[chld[1].arg_type]) {
	    arg[3].arg_type = chld[1].arg_type;
	    arg[3].arg_ptr = chld[1].arg_ptr;
	    free_arg(chld);
	}
	else {
	    arg[3].arg_type = A_EXPR;
	    arg[3].arg_ptr.arg_arg = chld;
	    if ((dolist & 4) &&
	      (chld->arg_type == O_LIST ||
	       (chld->arg_type == O_ARRAY && chld->arg_len == 1) ))
		arg[3].arg_flags |= AF_SPECIAL;
	}
    }
#ifdef DEBUGGING
    if (debug & 16) {
	fprintf(stderr,"%lx <= make_op(%s",arg,opname[arg->arg_type]);
	if (arg1)
	    fprintf(stderr,",%s=%lx",
		argname[arg[1].arg_type],arg[1].arg_ptr.arg_arg);
	if (arg2)
	    fprintf(stderr,",%s=%lx",
		argname[arg[2].arg_type],arg[2].arg_ptr.arg_arg);
	if (arg3)
	    fprintf(stderr,",%s=%lx",
		argname[arg[3].arg_type],arg[3].arg_ptr.arg_arg);
	fprintf(stderr,")\n");
    }
#endif
    evalstatic(arg);		/* see if we can consolidate anything */
    return arg;
}

/* turn 123 into 123 == $. */

ARG *
flipflip(arg)
register ARG *arg;
{
    if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_SINGLE) {
	arg = (ARG*)saferealloc((char*)arg,3*sizeof(ARG));
	arg->arg_type = O_EQ;
	arg->arg_len = 2;
	arg[2].arg_type = A_STAB;
	arg[2].arg_flags = 0;
	arg[2].arg_ptr.arg_stab = stabent(".",TRUE);
    }
    return arg;
}

void
evalstatic(arg)
register ARG *arg;
{
    register STR *str;
    register STR *s1;
    register STR *s2;
    double value;		/* must not be register */
    register char *tmps;
    int i;
    unsigned long tmplong;
    double exp(), log(), sqrt(), modf();
    char *crypt();

    if (!arg || !arg->arg_len)
	return;

    if (arg[1].arg_type == A_SINGLE &&
        (arg->arg_len == 1 || arg[2].arg_type == A_SINGLE) ) {
	str = str_new(0);
	s1 = arg[1].arg_ptr.arg_str;
	if (arg->arg_len > 1)
	    s2 = arg[2].arg_ptr.arg_str;
	else
	    s2 = Nullstr;
	switch (arg->arg_type) {
	default:
	    str_free(str);
	    str = Nullstr;		/* can't be evaluated yet */
	    break;
	case O_CONCAT:
	    str_sset(str,s1);
	    str_scat(str,s2);
	    break;
	case O_REPEAT:
	    i = (int)str_gnum(s2);
	    while (i-- > 0)
		str_scat(str,s1);
	    break;
	case O_MULTIPLY:
	    value = str_gnum(s1);
	    str_numset(str,value * str_gnum(s2));
	    break;
	case O_DIVIDE:
	    value = str_gnum(s2);
	    if (value == 0.0)
		fatal("Illegal division by constant zero");
	    str_numset(str,str_gnum(s1) / value);
	    break;
	case O_MODULO:
	    tmplong = (unsigned long)str_gnum(s2);
	    if (tmplong == 0L)
		fatal("Illegal modulus of constant zero");
	    str_numset(str,(double)(((unsigned long)str_gnum(s1)) % tmplong));
	    break;
	case O_ADD:
	    value = str_gnum(s1);
	    str_numset(str,value + str_gnum(s2));
	    break;
	case O_SUBTRACT:
	    value = str_gnum(s1);
	    str_numset(str,value - str_gnum(s2));
	    break;
	case O_LEFT_SHIFT:
	    value = str_gnum(s1);
	    i = (int)str_gnum(s2);
	    str_numset(str,(double)(((unsigned long)value) << i));
	    break;
	case O_RIGHT_SHIFT:
	    value = str_gnum(s1);
	    i = (int)str_gnum(s2);
	    str_numset(str,(double)(((unsigned long)value) >> i));
	    break;
	case O_LT:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value < str_gnum(s2)));
	    break;
	case O_GT:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value > str_gnum(s2)));
	    break;
	case O_LE:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value <= str_gnum(s2)));
	    break;
	case O_GE:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value >= str_gnum(s2)));
	    break;
	case O_EQ:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value == str_gnum(s2)));
	    break;
	case O_NE:
	    value = str_gnum(s1);
	    str_numset(str,(double)(value != str_gnum(s2)));
	    break;
	case O_BIT_AND:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((unsigned long)value) &
		((unsigned long)str_gnum(s2))));
	    break;
	case O_XOR:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((unsigned long)value) ^
		((unsigned long)str_gnum(s2))));
	    break;
	case O_BIT_OR:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((unsigned long)value) |
		((unsigned long)str_gnum(s2))));
	    break;
	case O_AND:
	    if (str_true(s1))
		str = str_make(str_get(s2));
	    else
		str = str_make(str_get(s1));
	    break;
	case O_OR:
	    if (str_true(s1))
		str = str_make(str_get(s1));
	    else
		str = str_make(str_get(s2));
	    break;
	case O_COND_EXPR:
	    if (arg[3].arg_type != A_SINGLE) {
		str_free(str);
		str = Nullstr;
	    }
	    else {
		str = str_make(str_get(str_true(s1) ? s2 : arg[3].arg_ptr.arg_str));
		str_free(arg[3].arg_ptr.arg_str);
	    }
	    break;
	case O_NEGATE:
	    str_numset(str,(double)(-str_gnum(s1)));
	    break;
	case O_NOT:
	    str_numset(str,(double)(!str_true(s1)));
	    break;
	case O_COMPLEMENT:
	    str_numset(str,(double)(~(long)str_gnum(s1)));
	    break;
	case O_LENGTH:
	    str_numset(str, (double)str_len(s1));
	    break;
	case O_SUBSTR:
	    if (arg[3].arg_type != A_SINGLE || stabent("[",allstabs)) {
		str_free(str);		/* making the fallacious assumption */
		str = Nullstr;		/* that any $[ occurs before substr()*/
	    }
	    else {
		char *beg;
		int len = (int)str_gnum(s2);
		int tmp;

		for (beg = str_get(s1); *beg && len > 0; beg++,len--) ;
		len = (int)str_gnum(arg[3].arg_ptr.arg_str);
		str_free(arg[3].arg_ptr.arg_str);
		if (len > (tmp = strlen(beg)))
		    len = tmp;
		str_nset(str,beg,len);
	    }
	    break;
	case O_SLT:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strLT(tmps,str_get(s2))));
	    break;
	case O_SGT:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strGT(tmps,str_get(s2))));
	    break;
	case O_SLE:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strLE(tmps,str_get(s2))));
	    break;
	case O_SGE:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strGE(tmps,str_get(s2))));
	    break;
	case O_SEQ:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strEQ(tmps,str_get(s2))));
	    break;
	case O_SNE:
	    tmps = str_get(s1);
	    str_numset(str,(double)(strNE(tmps,str_get(s2))));
	    break;
	case O_CRYPT:
#ifdef CRYPT
	    tmps = str_get(s1);
	    str_set(str,crypt(tmps,str_get(s2)));
#else
	    fatal(
	    "The crypt() function is unimplemented due to excessive paranoia.");
#endif
	    break;
	case O_EXP:
	    str_numset(str,exp(str_gnum(s1)));
	    break;
	case O_LOG:
	    str_numset(str,log(str_gnum(s1)));
	    break;
	case O_SQRT:
	    str_numset(str,sqrt(str_gnum(s1)));
	    break;
	case O_INT:
	    value = str_gnum(s1);
	    if (value >= 0.0)
		modf(value,&value);
	    else {
		modf(-value,&value);
		value = -value;
	    }
	    str_numset(str,value);
	    break;
	case O_ORD:
	    str_numset(str,(double)(*str_get(s1)));
	    break;
	}
	if (str) {
	    arg->arg_type = O_ITEM;	/* note arg1 type is already SINGLE */
	    str_free(s1);
	    str_free(s2);
	    arg[1].arg_ptr.arg_str = str;
	}
    }
}

ARG *
l(arg)
register ARG *arg;
{
    register int i;
    register ARG *arg1;
    ARG *tmparg;

    arg->arg_flags |= AF_COMMON;	/* XXX should cross-match */
					/* this does unnecessary copying */

    if (arg[1].arg_type == A_ARYLEN) {
	arg[1].arg_type = A_LARYLEN;
	return arg;
    }

    /* see if it's an array reference */

    if (arg[1].arg_type == A_EXPR) {
	arg1 = arg[1].arg_ptr.arg_arg;

	if (arg1->arg_type == O_LIST && arg->arg_type != O_ITEM) {
						/* assign to list */
	    arg[1].arg_flags |= AF_SPECIAL;
	    dehoist(arg,2);
	    arg[2].arg_flags |= AF_SPECIAL;
	    for (i = arg1->arg_len; i >= 1; i--) {
		switch (arg1[i].arg_type) {
		case A_STAB: case A_LVAL:
		    arg1[i].arg_type = A_LVAL;
		    break;
		case A_EXPR: case A_LEXPR:
		    arg1[i].arg_type = A_LEXPR;
		    if (arg1[i].arg_ptr.arg_arg->arg_type == O_ARRAY)
			arg1[i].arg_ptr.arg_arg->arg_type = O_LARRAY;
		    else if (arg1[i].arg_ptr.arg_arg->arg_type == O_HASH)
			arg1[i].arg_ptr.arg_arg->arg_type = O_LHASH;
		    if (arg1[i].arg_ptr.arg_arg->arg_type == O_LARRAY)
			break;
		    if (arg1[i].arg_ptr.arg_arg->arg_type == O_LHASH)
			break;
		    /* FALL THROUGH */
		default:
		    sprintf(tokenbuf,
		      "Illegal item (%s) as lvalue",argname[arg1[i].arg_type]);
		    yyerror(tokenbuf);
		}
	    }
	}
	else if (arg1->arg_type == O_ARRAY) {
	    if (arg1->arg_len == 1 && arg->arg_type != O_ITEM) {
						/* assign to array */
		arg[1].arg_flags |= AF_SPECIAL;
		dehoist(arg,2);
		arg[2].arg_flags |= AF_SPECIAL;
	    }
	    else
		arg1->arg_type = O_LARRAY;	/* assign to array elem */
	}
	else if (arg1->arg_type == O_HASH)
	    arg1->arg_type = O_LHASH;
	else if (arg1->arg_type != O_ASSIGN) {
	    sprintf(tokenbuf,
	      "Illegal expression (%s) as lvalue",opname[arg1->arg_type]);
	    yyerror(tokenbuf);
	}
	arg[1].arg_type = A_LEXPR;
#ifdef DEBUGGING
	if (debug & 16)
	    fprintf(stderr,"lval LEXPR\n");
#endif
	return arg;
    }

    /* not an array reference, should be a register name */

    if (arg[1].arg_type != A_STAB && arg[1].arg_type != A_LVAL) {
	sprintf(tokenbuf,
	  "Illegal item (%s) as lvalue",argname[arg[1].arg_type]);
	yyerror(tokenbuf);
    }
    arg[1].arg_type = A_LVAL;
#ifdef DEBUGGING
    if (debug & 16)
	fprintf(stderr,"lval LVAL\n");
#endif
    return arg;
}

dehoist(arg,i)
ARG *arg;
{
    ARG *tmparg;

    if (arg[i].arg_type != A_EXPR) {	/* dehoist */
	tmparg = make_op(O_ITEM,1,Nullarg,Nullarg,Nullarg,0);
	tmparg[1] = arg[i];
	arg[i].arg_ptr.arg_arg = tmparg;
	arg[i].arg_type = A_EXPR;
    }
}

ARG *
addflags(i,flags,arg)
register ARG *arg;
{
    arg[i].arg_flags |= flags;
    return arg;
}

ARG *
hide_ary(arg)
ARG *arg;
{
    if (arg->arg_type == O_ARRAY)
	return make_op(O_ITEM,1,arg,Nullarg,Nullarg,0);
    return arg;
}

ARG *
make_list(arg)
register ARG *arg;
{
    register int i;
    register ARG *node;
    register ARG *nxtnode;
    register int j;
    STR *tmpstr;

    if (!arg) {
	arg = op_new(0);
	arg->arg_type = O_LIST;
    }
    if (arg->arg_type != O_COMMA) {
	arg->arg_flags |= AF_LISTISH;	/* see listish() below */
	return arg;
    }
    for (i = 2, node = arg; ; i++) {
	if (node->arg_len < 2)
	    break;
        if (node[2].arg_type != A_EXPR)
	    break;
	node = node[2].arg_ptr.arg_arg;
	if (node->arg_type != O_COMMA)
	    break;
    }
    if (i > 2) {
	node = arg;
	arg = op_new(i);
	tmpstr = arg->arg_ptr.arg_str;
	*arg = *node;		/* copy everything except the STR */
	arg->arg_ptr.arg_str = tmpstr;
	for (j = 1; ; ) {
	    arg[j] = node[1];
	    ++j;		/* Bug in Xenix compiler */
	    if (j >= i) {
		arg[j] = node[2];
		free_arg(node);
		break;
	    }
	    nxtnode = node[2].arg_ptr.arg_arg;
	    free_arg(node);
	    node = nxtnode;
	}
    }
    arg->arg_type = O_LIST;
    arg->arg_len = i;
    return arg;
}

/* turn a single item into a list */

ARG *
listish(arg)
ARG *arg;
{
    if (arg->arg_flags & AF_LISTISH) {
	arg = make_op(O_LIST,1,arg,Nullarg,Nullarg,0);
	arg[1].arg_flags &= ~AF_SPECIAL;
    }
    return arg;
}

/* mark list of local variables */

ARG *
localize(arg)
ARG *arg;
{
    arg->arg_flags |= AF_LOCAL;
    return arg;
}

ARG *
stab2arg(atype,stab)
int atype;
register STAB *stab;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = atype;
    arg[1].arg_ptr.arg_stab = stab;
    return arg;
}

ARG *
cval_to_arg(cval)
register char *cval;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = A_SINGLE;
    arg[1].arg_ptr.arg_str = str_make(cval);
    safefree(cval);
    return arg;
}

ARG *
op_new(numargs)
int numargs;
{
    register ARG *arg;

    arg = (ARG*)safemalloc((numargs + 1) * sizeof (ARG));
    bzero((char *)arg, (numargs + 1) * sizeof (ARG));
    arg->arg_ptr.arg_str = str_new(0);
    arg->arg_len = numargs;
    return arg;
}

void
free_arg(arg)
ARG *arg;
{
    str_free(arg->arg_ptr.arg_str);
    safefree((char*)arg);
}

ARG *
make_match(type,expr,spat)
int type;
ARG *expr;
SPAT *spat;
{
    register ARG *arg;

    arg = make_op(type,2,expr,Nullarg,Nullarg,0);

    arg[2].arg_type = A_SPAT;
    arg[2].arg_ptr.arg_spat = spat;
#ifdef DEBUGGING
    if (debug & 16)
	fprintf(stderr,"make_match SPAT=%lx\n",(long)spat);
#endif

    if (type == O_SUBST || type == O_NSUBST) {
	if (arg[1].arg_type != A_STAB)
	    yyerror("Illegal lvalue");
	arg[1].arg_type = A_LVAL;
    }
    return arg;
}

ARG *
cmd_to_arg(cmd)
CMD *cmd;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = A_CMD;
    arg[1].arg_ptr.arg_cmd = cmd;
    return arg;
}

CMD *
wopt(cmd)
register CMD *cmd;
{
    register CMD *tail;
    register ARG *arg = cmd->c_expr;
    STAB *asgnstab;

    /* hoist "while (<channel>)" up into command block */

    if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_READ) {
	cmd->c_flags &= ~CF_OPTIMIZE;	/* clear optimization type */
	cmd->c_flags |= CFT_GETS;	/* and set it to do the input */
	cmd->c_stab = arg[1].arg_ptr.arg_stab;
	if (arg[1].arg_ptr.arg_stab->stab_io->flags & IOF_ARGV) {
	    cmd->c_expr = l(make_op(O_ASSIGN, 2,	/* fake up "$_ =" */
	       stab2arg(A_LVAL,defstab), arg, Nullarg,1 ));
	}
	else {
	    free_arg(arg);
	    cmd->c_expr = Nullarg;
	}
    }
    else if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_INDREAD) {
	cmd->c_flags &= ~CF_OPTIMIZE;	/* clear optimization type */
	cmd->c_flags |= CFT_INDGETS;	/* and set it to do the input */
	cmd->c_stab = arg[1].arg_ptr.arg_stab;
	free_arg(arg);
	cmd->c_expr = Nullarg;
    }
    else if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_GLOB) {
	if ((cmd->c_flags & CF_OPTIMIZE) == CFT_ARRAY)
	    asgnstab = cmd->c_stab;
	else
	    asgnstab = defstab;
	cmd->c_expr = l(make_op(O_ASSIGN, 2,	/* fake up "$foo =" */
	   stab2arg(A_LVAL,asgnstab), arg, Nullarg,1 ));
	cmd->c_flags &= ~CF_OPTIMIZE;	/* clear optimization type */
    }

    /* First find the end of the true list */

    if (cmd->ucmd.ccmd.cc_true == Nullcmd)
	return cmd;
    for (tail = cmd->ucmd.ccmd.cc_true; tail->c_next; tail = tail->c_next) ;

    /* if there's a continue block, link it to true block and find end */

    if (cmd->ucmd.ccmd.cc_alt != Nullcmd) {
	tail->c_next = cmd->ucmd.ccmd.cc_alt;
	for ( ; tail->c_next; tail = tail->c_next) ;
    }

    /* Here's the real trick: link the end of the list back to the beginning,
     * inserting a "last" block to break out of the loop.  This saves one or
     * two procedure calls every time through the loop, because of how cmd_exec
     * does tail recursion.
     */

    tail->c_next = (CMD *) safemalloc(sizeof (CMD));
    tail = tail->c_next;
    if (!cmd->ucmd.ccmd.cc_alt)
	cmd->ucmd.ccmd.cc_alt = tail;	/* every loop has a continue now */

    bcopy((char *)cmd, (char *)tail, sizeof(CMD));
    tail->c_type = C_EXPR;
    tail->c_flags ^= CF_INVERT;		/* turn into "last unless" */
    tail->c_next = tail->ucmd.ccmd.cc_true;	/* loop directly back to top */
    tail->ucmd.acmd.ac_expr = make_op(O_LAST,0,Nullarg,Nullarg,Nullarg,0);
    tail->ucmd.acmd.ac_stab = Nullstab;
    return cmd;
}

CMD *
over(eachstab,cmd)
STAB *eachstab;
register CMD *cmd;
{
    /* hoist "for $foo (@bar)" up into command block */

    cmd->c_flags &= ~CF_OPTIMIZE;	/* clear optimization type */
    cmd->c_flags |= CFT_ARRAY;		/* and set it to do the iteration */
    cmd->c_stab = eachstab;

    return cmd;
}

static int gensym = 0;

STAB *
genstab()
{
    sprintf(tokenbuf,"_GEN_%d",gensym++);
    return stabent(tokenbuf,TRUE);
}

/* this routine is in perly.c by virtue of being sort of an alternate main() */

STR *
do_eval(str,optype)
STR *str;
int optype;
{
    int retval;
    CMD *myroot;
    ARRAY *ar;
    int i;
    char *oldfile = filename;
    line_t oldline = line;
    int oldtmps_base = tmps_base;
    int oldsave = savestack->ary_fill;

    tmps_base = tmps_max;
    str_set(stabent("@",TRUE)->stab_val,"");
    if (optype != O_DOFILE) {	/* normal eval */
	filename = "(eval)";
	line = 1;
	str_sset(linestr,str);
    }
    else {
	filename = savestr(str_get(str));	/* can't free this easily */
	str_set(linestr,"");
	rsfp = fopen(filename,"r");
	ar = incstab->stab_array;
	if (!rsfp && *filename != '/') {
	    for (i = 0; i <= ar->ary_fill; i++) {
		sprintf(tokenbuf,"%s/%s",str_get(afetch(ar,i)),filename);
		rsfp = fopen(tokenbuf,"r");
		if (rsfp) {
		    free(filename);
		    filename = savestr(tokenbuf);
		    break;
		}
	    }
	}
	if (!rsfp) {
	    filename = oldfile;
	    tmps_base = oldtmps_base;
	    return &str_no;
	}
	line = 0;
    }
    in_eval++;
    bufptr = str_get(linestr);
    if (setjmp(eval_env))
	retval = 1;
    else
	retval = yyparse();
    myroot = eval_root;		/* in case cmd_exec does another eval! */
    if (retval)
	str = &str_no;
    else {
	str = str_static(cmd_exec(eval_root));
				/* if we don't save str, free zaps it */
	cmd_free(myroot);	/* can't free on error, for some reason */
    }
    in_eval--;
    filename = oldfile;
    line = oldline;
    tmps_base = oldtmps_base;
    if (savestack->ary_fill > oldsave)	/* let them use local() */
	restorelist(oldsave);
    return str;
}

cmd_free(cmd)
register CMD *cmd;
{
    register CMD *tofree;
    register CMD *head = cmd;

    while (cmd) {
	if (cmd->c_type != C_WHILE) {	/* WHILE block is duplicated */
	    if (cmd->c_label)
		safefree(cmd->c_label);
	    if (cmd->c_short)
		str_free(cmd->c_short);
	    if (cmd->c_spat)
		spat_free(cmd->c_spat);
	    if (cmd->c_expr)
		arg_free(cmd->c_expr);
	}
	switch (cmd->c_type) {
	case C_WHILE:
	case C_BLOCK:
	case C_IF:
	    if (cmd->ucmd.ccmd.cc_true)
		cmd_free(cmd->ucmd.ccmd.cc_true);
	    if (cmd->c_type == C_IF && cmd->ucmd.ccmd.cc_alt)
		cmd_free(cmd->ucmd.ccmd.cc_alt);
	    break;
	case C_EXPR:
	    if (cmd->ucmd.acmd.ac_expr)
		arg_free(cmd->ucmd.acmd.ac_expr);
	    break;
	}
	tofree = cmd;
	cmd = cmd->c_next;
	safefree((char*)tofree);
	if (cmd && cmd == head)		/* reached end of while loop */
	    break;
    }
}

arg_free(arg)
register ARG *arg;
{
    register int i;

    for (i = 1; i <= arg->arg_len; i++) {
	switch (arg[i].arg_type) {
	case A_NULL:
	    break;
	case A_LEXPR:
	case A_EXPR:
	    arg_free(arg[i].arg_ptr.arg_arg);
	    break;
	case A_CMD:
	    cmd_free(arg[i].arg_ptr.arg_cmd);
	    break;
	case A_WORD:
	case A_STAB:
	case A_LVAL:
	case A_READ:
	case A_GLOB:
	case A_ARYLEN:
	    break;
	case A_SINGLE:
	case A_DOUBLE:
	case A_BACKTICK:
	    str_free(arg[i].arg_ptr.arg_str);
	    break;
	case A_SPAT:
	    spat_free(arg[i].arg_ptr.arg_spat);
	    break;
	case A_NUMBER:
	    break;
	}
    }
    free_arg(arg);
}

spat_free(spat)
register SPAT *spat;
{
    register SPAT *sp;

    if (spat->spat_runtime)
	arg_free(spat->spat_runtime);
    if (spat->spat_repl) {
	arg_free(spat->spat_repl);
    }
    if (spat->spat_short) {
	str_free(spat->spat_short);
    }
    if (spat->spat_regexp) {
	regfree(spat->spat_regexp);
    }

    /* now unlink from spat list */
    if (spat_root == spat)
	spat_root = spat->spat_next;
    else {
	for (sp = spat_root; sp->spat_next != spat; sp = sp->spat_next) ;
	sp->spat_next = spat->spat_next;
    }

    safefree((char*)spat);
}

/* Recursively descend a command sequence and push the address of any string
 * that needs saving on recursion onto the tosave array.
 */

static int
cmd_tosave(cmd)
register CMD *cmd;
{
    register CMD *head = cmd;

    while (cmd) {
	if (cmd->c_spat)
	    spat_tosave(cmd->c_spat);
	if (cmd->c_expr)
	    arg_tosave(cmd->c_expr);
	switch (cmd->c_type) {
	case C_WHILE:
	case C_BLOCK:
	case C_IF:
	    if (cmd->ucmd.ccmd.cc_true)
		cmd_tosave(cmd->ucmd.ccmd.cc_true);
	    if (cmd->c_type == C_IF && cmd->ucmd.ccmd.cc_alt)
		cmd_tosave(cmd->ucmd.ccmd.cc_alt);
	    break;
	case C_EXPR:
	    if (cmd->ucmd.acmd.ac_expr)
		arg_tosave(cmd->ucmd.acmd.ac_expr);
	    break;
	}
	cmd = cmd->c_next;
	if (cmd && cmd == head)		/* reached end of while loop */
	    break;
    }
}

static int
arg_tosave(arg)
register ARG *arg;
{
    register int i;
    int saving = FALSE;

    for (i = 1; i <= arg->arg_len; i++) {
	switch (arg[i].arg_type) {
	case A_NULL:
	    break;
	case A_LEXPR:
	case A_EXPR:
	    saving |= arg_tosave(arg[i].arg_ptr.arg_arg);
	    break;
	case A_CMD:
	    cmd_tosave(arg[i].arg_ptr.arg_cmd);
	    saving = TRUE;	/* assume hanky panky */
	    break;
	case A_WORD:
	case A_STAB:
	case A_LVAL:
	case A_READ:
	case A_GLOB:
	case A_ARYLEN:
	case A_SINGLE:
	case A_DOUBLE:
	case A_BACKTICK:
	    break;
	case A_SPAT:
	    saving |= spat_tosave(arg[i].arg_ptr.arg_spat);
	    break;
	case A_NUMBER:
	    break;
	}
    }
    switch (arg->arg_type) {
    case O_EVAL:
    case O_SUBR:
	saving = TRUE;
    }
    if (saving)
	apush(tosave,arg->arg_ptr.arg_str);
    return saving;
}

static int
spat_tosave(spat)
register SPAT *spat;
{
    int saving = FALSE;

    if (spat->spat_runtime)
	saving |= arg_tosave(spat->spat_runtime);
    if (spat->spat_repl) {
	saving |= arg_tosave(spat->spat_repl);
    }

    return saving;
}
