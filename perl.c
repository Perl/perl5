/*
 *    Copyright (c) 1991, 1992, 1993, 1994 Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	perl.c,v $
 * Revision 4.1  92/08/07  18:25:50  lwall
 * 
 * Revision 4.0.1.7  92/06/08  14:50:39  lwall
 * patch20: PERLLIB now supports multiple directories
 * patch20: running taintperl explicitly now does checks even if $< == $>
 * patch20: -e 'cmd' no longer fails silently if /tmp runs out of space
 * patch20: perl -P now uses location of sed determined by Configure
 * patch20: form feed for formats is now specifiable via $^L
 * patch20: paragraph mode now skips extra newlines automatically
 * patch20: oldeval "1 #comment" didn't work
 * patch20: couldn't require . files
 * patch20: semantic compilation errors didn't abort execution
 * 
 * Revision 4.0.1.6  91/11/11  16:38:45  lwall
 * patch19: default arg for shift was wrong after first subroutine definition
 * patch19: op/regexp.t failed from missing arg to bcmp()
 * 
 * Revision 4.0.1.5  91/11/05  18:03:32  lwall
 * patch11: random cleanup
 * patch11: $0 was being truncated at times
 * patch11: cppstdin now installed outside of source directory
 * patch11: -P didn't allow use of #elif or #undef
 * patch11: prepared for ctype implementations that don't define isascii()
 * patch11: added oldeval {}
 * patch11: oldeval confused by string containing null
 * 
 * Revision 4.0.1.4  91/06/10  01:23:07  lwall
 * patch10: perl -v printed incorrect copyright notice
 * 
 * Revision 4.0.1.3  91/06/07  11:40:18  lwall
 * patch4: changed old $^P to $^X
 * 
 * Revision 4.0.1.2  91/06/07  11:26:16  lwall
 * patch4: new copyright notice
 * patch4: added $^P variable to control calling of perldb routines
 * patch4: added $^F variable to specify maximum system fd, default 2
 * patch4: debugger lost track of lines in oldeval
 * 
 * Revision 4.0.1.1  91/04/11  17:49:05  lwall
 * patch1: fixed undefined environ problem
 * 
 * Revision 4.0  91/03/20  01:37:44  lwall
 * 4.0 baseline.
 * 
 */

/*SUPPRESS 560*/

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"
#include "patchlevel.h"

char rcsid[] = "$RCSfile: perl.c,v $$Revision: 5.0 $$Date: 92/08/07 18:25:50 $\nPatch level: ###\n";

#ifdef IAMSUID
#ifndef DOSUID
#define DOSUID
#endif
#endif

#ifdef SETUID_SCRIPTS_ARE_SECURE_NOW
#ifdef DOSUID
#undef DOSUID
#endif
#endif

static void incpush();
static void validate_suid();
static void find_beginning();
static void init_main_stash();
static void open_script();
static void init_debugger();
static void init_stacks();
static void init_lexer();
static void init_predump_symbols();
static void init_postdump_symbols();
static void init_perllib();

PerlInterpreter *
perl_alloc()
{
    PerlInterpreter *sv_interp;
    PerlInterpreter junk;

    curinterp = 0;
/*    Zero(&junk, 1, PerlInterpreter); */
    New(53, sv_interp, 1, PerlInterpreter);
    return sv_interp;
}

void
perl_construct( sv_interp )
register PerlInterpreter *sv_interp;
{
    char* s;

    if (!(curinterp = sv_interp))
	return;

#ifdef MULTIPLICITY
    Zero(sv_interp, 1, PerlInterpreter);
#endif

    /* Init the real globals? */
    if (!linestr) {
	linestr = NEWSV(65,80);
	sv_upgrade(linestr,SVt_PVIV);

	SvREADONLY_on(&sv_undef);

	sv_setpv(&sv_no,No);
	SvNV(&sv_no);
	SvREADONLY_on(&sv_no);

	sv_setpv(&sv_yes,Yes);
	SvNV(&sv_yes);
	SvREADONLY_on(&sv_yes);

#ifdef MSDOS
	/*
	 * There is no way we can refer to them from Perl so close them to save
	 * space.  The other alternative would be to provide STDAUX and STDPRN
	 * filehandles.
	 */
	(void)fclose(stdaux);
	(void)fclose(stdprn);
#endif
    }

#ifdef MULTIPLICITY
    chopset	= " \n-";
    copline	= NOLINE;
    curcop	= &compiling;
    dlmax	= 128;
    laststatval	= -1;
    laststype	= OP_STAT;
    maxscream	= -1;
    maxsysfd	= MAXSYSFD;
    nrs		= "\n";
    nrschar	= '\n';
    nrslen	= 1;
    rs		= "\n";
    rschar	= '\n';
    rsfp	= Nullfp;
    rslen	= 1;
    statname	= Nullsv;
    tmps_floor	= -1;
#endif

    uid = (int)getuid();
    euid = (int)geteuid();
    gid = (int)getgid();
    egid = (int)getegid();
    tainting = (euid != uid || egid != gid);
    if (s = strchr(rcsid,'#')) {
	(void)sprintf(s, "%d\n", PATCHLEVEL);
	sprintf(patchlevel,"%3.3s%2.2d", strchr(rcsid,'5'), PATCHLEVEL);
    }

    fdpid = newAV();	/* for remembering popen pids by fd */
    pidstatus = newHV();/* for remembering status of dead pids */

    init_stacks();
    ENTER;
}

void
perl_destruct(sv_interp)
register PerlInterpreter *sv_interp;
{
    I32 last_sv_count;

    if (!(curinterp = sv_interp))
	return;
    LEAVE;
    FREE_TMPS();

#ifndef EMBED
    /* The exit() function may do everything that needs doing. */
    if (!sv_rvcount)
	return;
#endif

    /* Not so lucky.  We must account for everything.  First the syntax tree. */
    if (main_root) {
	curpad = AvARRAY(comppad);
	op_free(main_root);
	main_root = 0;
    }

    /*
     * Try to destruct global references.  We do this first so that the
     * destructors and destructees still exist.  This code currently
     * will break simple reference loops but may fail on more complicated
     * ones.  If so, the code below will clean up, but any destructors
     * may fail to find what they're looking for.
     */
    dirty = TRUE;
    if (sv_count != 0)
	sv_clean_refs();

    /* Delete self-reference from main symbol table */
    GvHV(gv_fetchpv("::_main",TRUE)) = 0;
    --SvREFCNT(defstash);

    /* Try to destruct main symbol table.  May fail on reference loops. */
    SvREFCNT_dec(defstash);

    FREE_TMPS();
#ifdef DEBUGGING
    if (scopestack_ix != 0)
	warn("Unbalanced scopes: %d more ENTERs than LEAVEs\n", scopestack_ix);
    if (savestack_ix != 0)
	warn("Unbalanced saves: %d more saves than restores\n", savestack_ix);
    if (tmps_floor != -1)
	warn("Unbalanced tmps: %d more allocs than frees\n", tmps_floor + 1);
    if (cxstack_ix != -1)
	warn("Unbalanced context: %d more PUSHes than POPs\n", cxstack_ix + 1);
#endif

    /* Now absolutely destruct everything, somehow or other, loops or no. */
    last_sv_count = 0;
    while (sv_count != 0 && sv_count != last_sv_count) {
	last_sv_count = sv_count;
	sv_clean_all();
    }
    if (sv_count != 0)
	warn("Scalars leaked: %d\n", sv_count);
}

void
perl_free(sv_interp)
PerlInterpreter *sv_interp;
{
    if (!(curinterp = sv_interp))
	return;
    Safefree(sv_interp);
}

int
perl_parse(sv_interp, argc, argv, env)
PerlInterpreter *sv_interp;
register int argc;
register char **argv;
char **env;
{
    register SV *sv;
    register char *s;
    char *scriptname;
    char *getenv();
    bool dosearch = FALSE;
    char *validarg = "";

#ifdef SETUID_SCRIPTS_ARE_SECURE_NOW
#ifdef IAMSUID
#undef IAMSUID
    croak("suidperl is no longer needed since the kernel can now execute\n\
setuid perl scripts securely.\n");
#endif
#endif

    if (!(curinterp = sv_interp))
	return 255;

    if (main_root)
	op_free(main_root);
    main_root = 0;

    origargv = argv;
    origargc = argc;
    origenviron = environ;

    switch (setjmp(top_env)) {
    case 1:
	statusvalue = 255;
    case 2:
	curstash = defstash;
	if (endav)
	    calllist(endav);
	return(statusvalue);	/* my_exit() was called */
    case 3:
	fprintf(stderr, "panic: top_env\n");
	return 1;
    }

    if (do_undump) {

	/* Come here if running an undumped a.out. */

	origfilename = savestr(argv[0]);
	do_undump = FALSE;
	cxstack_ix = -1;		/* start label stack again */
	init_postdump_symbols(argc,argv,env);
	return 0;
    }

    sv_setpvn(linestr,"",0);
    sv = newSVpv("",0);		/* first used for -I flags */
    SAVEFREESV(sv);
    init_main_stash();
    for (argc--,argv++; argc > 0; argc--,argv++) {
	if (argv[0][0] != '-' || !argv[0][1])
	    break;
#ifdef DOSUID
    if (*validarg)
	validarg = " PHOOEY ";
    else
	validarg = argv[0];
#endif
	s = argv[0]+1;
      reswitch:
	switch (*s) {
	case '0':
	case 'F':
	case 'a':
	case 'c':
	case 'd':
	case 'D':
	case 'i':
	case 'l':
	case 'n':
	case 'p':
	case 's':
	case 'T':
	case 'u':
	case 'U':
	case 'v':
	case 'w':
	    if (s = moreswitches(s))
		goto reswitch;
	    break;

	case 'e':
	    if (euid != uid || egid != gid)
		croak("No -e allowed in setuid scripts");
	    if (!e_fp) {
	        e_tmpname = savestr(TMPPATH);
		(void)mktemp(e_tmpname);
		if (!*e_tmpname)
		    croak("Can't mktemp()");
		e_fp = fopen(e_tmpname,"w");
		if (!e_fp)
		    croak("Cannot open temporary file");
	    }
	    if (argv[1]) {
		fputs(argv[1],e_fp);
		argc--,argv++;
	    }
	    (void)putc('\n', e_fp);
	    break;
	case 'I':
	    taint_not("-I");
	    sv_catpv(sv,"-");
	    sv_catpv(sv,s);
	    sv_catpv(sv," ");
	    if (*++s) {
		(void)av_push(GvAVn(incgv),newSVpv(s,0));
	    }
	    else if (argv[1]) {
		(void)av_push(GvAVn(incgv),newSVpv(argv[1],0));
		sv_catpv(sv,argv[1]);
		argc--,argv++;
		sv_catpv(sv," ");
	    }
	    break;
	case 'P':
	    taint_not("-P");
	    preprocess = TRUE;
	    s++;
	    goto reswitch;
	case 'S':
	    taint_not("-S");
	    dosearch = TRUE;
	    s++;
	    goto reswitch;
	case 'x':
	    doextract = TRUE;
	    s++;
	    if (*s)
		cddir = savestr(s);
	    break;
	case '-':
	    argc--,argv++;
	    goto switch_end;
	case 0:
	    break;
	default:
	    croak("Unrecognized switch: -%s",s);
	}
    }
  switch_end:
    scriptname = argv[0];
    if (e_fp) {
	if (fflush(e_fp) || ferror(e_fp) || fclose(e_fp))
	    croak("Can't write to temp file for -e: %s", Strerror(errno));
	argc++,argv--;
	scriptname = e_tmpname;
    }
    else if (scriptname == Nullch) {
#ifdef MSDOS
	if ( isatty(fileno(stdin)) )
	    moreswitches("v");
#endif
	scriptname = "-";
    }

    init_perllib();

    open_script(scriptname,dosearch,sv);

    validate_suid(validarg);

    if (doextract)
	find_beginning();

    if (perldb)
	init_debugger();

    pad = newAV();
    comppad = pad;
    av_push(comppad, Nullsv);
    curpad = AvARRAY(comppad);
    padname = newAV();
    comppad_name = padname;
    comppad_name_fill = 0;
    min_intro_pending = 0;
    padix = 0;

    perl_init_ext();	/* in case linked C routines want magical variables */

    init_predump_symbols();
    if (!do_undump)
	init_postdump_symbols(argc,argv,env);

    init_lexer();

    /* now parse the script */

    error_count = 0;
    if (yyparse() || error_count) {
	if (minus_c)
	    croak("%s had compilation errors.\n", origfilename);
	else {
	    croak("Execution of %s aborted due to compilation errors.\n",
		origfilename);
	}
    }
    curcop->cop_line = 0;
    curstash = defstash;
    preprocess = FALSE;
    if (e_fp) {
	e_fp = Nullfp;
	(void)UNLINK(e_tmpname);
    }

    /* now that script is parsed, we can modify record separator */

    rs = nrs;
    rslen = nrslen;
    rschar = nrschar;
    rspara = (nrslen == 2);
    sv_setpvn(GvSV(gv_fetchpv("/", TRUE)), rs, rslen);

    if (do_undump)
	my_unexec();

    if (dowarn)
	gv_check(defstash);

    return 0;
}

int
perl_run(sv_interp)
PerlInterpreter *sv_interp;
{
    if (!(curinterp = sv_interp))
	return 255;
    switch (setjmp(top_env)) {
    case 1:
	cxstack_ix = -1;		/* start context stack again */
	break;
    case 2:
	curstash = defstash;
	if (endav)
	    calllist(endav);
	FREE_TMPS();
	return(statusvalue);		/* my_exit() was called */
    case 3:
	if (!restartop) {
	    fprintf(stderr, "panic: restartop\n");
	    FREE_TMPS();
	    return 1;
	}
	if (stack != mainstack) {
	    dSP;
	    SWITCHSTACK(stack, mainstack);
	}
	break;
    }

    if (!restartop) {
	DEBUG_x(dump_all());
	DEBUG(fprintf(stderr,"\nEXECUTING...\n\n"));

	if (minus_c) {
	    fprintf(stderr,"%s syntax OK\n", origfilename);
	    my_exit(0);
	}
    }

    /* do it */

    if (restartop) {
	op = restartop;
	restartop = 0;
	run();
    }
    else if (main_start) {
	op = main_start;
	run();
    }

    my_exit(0);
}

void
my_exit(status)
int status;
{
    statusvalue = (unsigned short)(status & 0xffff);
    longjmp(top_env, 2);
}

/* Be sure to refetch the stack pointer after calling these routines. */

int
perl_callargv(subname, sp, gimme, argv)
char *subname;
register I32 sp;	/* current stack pointer */
I32 gimme;		/* TRUE if called in list context */
register char **argv;	/* null terminated arg list, NULL for no arglist */
{
    register I32 items = 0;
    I32 hasargs = (argv != 0);

    av_store(stack, ++sp, Nullsv);	/* reserve spot for sub reference */
    if (hasargs) {
	while (*argv) {
	    av_store(stack, ++sp, sv_2mortal(newSVpv(*argv,0)));
	    items++;
	    argv++;
	}
    }
    return perl_callpv(subname, sp, gimme, hasargs, items);
}

int
perl_callpv(subname, sp, gimme, hasargs, numargs)
char *subname;
I32 sp;			/* stack pointer after args are pushed */
I32 gimme;		/* TRUE if called in list context */
I32 hasargs;		/* whether to create a @_ array for routine */
I32 numargs;		/* how many args are pushed on the stack */
{
    return perl_callsv((SV*)gv_fetchpv(subname, TRUE),
			sp, gimme, hasargs, numargs);
}

/* May be called with any of a CV, a GV, or an SV containing the name. */
int
perl_callsv(sv, sp, gimme, hasargs, numargs)
SV* sv;
I32 sp;			/* stack pointer after args are pushed */
I32 gimme;		/* TRUE if called in list context */
I32 hasargs;		/* whether to create a @_ array for routine */
I32 numargs;		/* how many args are pushed on the stack */
{
    BINOP myop;		/* fake syntax tree node */
    
    ENTER;
    SAVETMPS;
    SAVESPTR(op);
    stack_base = AvARRAY(stack);
    stack_sp = stack_base + sp - numargs - 1;
    op = (OP*)&myop;
    Zero(op, 1, BINOP);
    pp_pushmark();	/* doesn't look at op, actually, except to return */
    *++stack_sp = sv;
    stack_sp += numargs;

    if (hasargs) {
	myop.op_flags = OPf_STACKED;
	myop.op_last = (OP*)&myop;
    }
    myop.op_next = Nullop;

    if (op = pp_entersubr())
	run();
    FREE_TMPS();
    LEAVE;
    return stack_sp - stack_base;
}

void
magicname(sym,name,namlen)
char *sym;
char *name;
I32 namlen;
{
    register GV *gv;

    if (gv = gv_fetchpv(sym,TRUE))
	sv_magic(GvSV(gv), (SV*)gv, 0, name, namlen);
}

#ifdef DOSISH
#define PERLLIB_SEP ';'
#else
#define PERLLIB_SEP ':'
#endif

static void
incpush(p)
char *p;
{
    char *s;

    if (!p)
	return;

    /* Break at all separators */
    while (*p) {
	/* First, skip any consecutive separators */
	while ( *p == PERLLIB_SEP ) {
	    /* Uncomment the next line for PATH semantics */
	    /* (void)av_push(GvAVn(incgv), newSVpv(".", 1)); */
	    p++;
	}
	if ( (s = strchr(p, PERLLIB_SEP)) != Nullch ) {
	    (void)av_push(GvAVn(incgv), newSVpv(p, (I32)(s - p)));
	    p = s + 1;
	} else {
	    (void)av_push(GvAVn(incgv), newSVpv(p, 0));
	    break;
	}
    }
}

/* This routine handles any switches that can be given during run */

char *
moreswitches(s)
char *s;
{
    I32 numlen;

    switch (*s) {
    case '0':
	nrschar = scan_oct(s, 4, &numlen);
	nrs = nsavestr("\n",1);
	*nrs = nrschar;
	if (nrschar > 0377) {
	    nrslen = 0;
	    nrs = "";
	}
	else if (!nrschar && numlen >= 2) {
	    nrslen = 2;
	    nrs = "\n\n";
	    nrschar = '\n';
	}
	return s + numlen;
    case 'F':
	minus_F = TRUE;
	splitstr = savestr(s + 1);
	s += strlen(s);
	return s;
    case 'a':
	minus_a = TRUE;
	s++;
	return s;
    case 'c':
	minus_c = TRUE;
	s++;
	return s;
    case 'd':
	taint_not("-d");
	perldb = TRUE;
	s++;
	return s;
    case 'D':
#ifdef DEBUGGING
	taint_not("-D");
	if (isALPHA(s[1])) {
	    static char debopts[] = "psltocPmfrxuLHXD";
	    char *d;

	    for (s++; *s && (d = strchr(debopts,*s)); s++)
		debug |= 1 << (d - debopts);
	}
	else {
	    debug = atoi(s+1);
	    for (s++; isDIGIT(*s); s++) ;
	}
	debug |= 0x80000000;
#else
	warn("Recompile perl with -DDEBUGGING to use -D switch\n");
	for (s++; isDIGIT(*s); s++) ;
#endif
	/*SUPPRESS 530*/
	return s;
    case 'i':
	if (inplace)
	    Safefree(inplace);
	inplace = savestr(s+1);
	/*SUPPRESS 530*/
	for (s = inplace; *s && !isSPACE(*s); s++) ;
	*s = '\0';
	break;
    case 'I':
	taint_not("-I");
	if (*++s) {
	    (void)av_push(GvAVn(incgv),newSVpv(s,0));
	}
	else
	    croak("No space allowed after -I");
	break;
    case 'l':
	minus_l = TRUE;
	s++;
	if (isDIGIT(*s)) {
	    ors = savestr("\n");
	    orslen = 1;
	    *ors = scan_oct(s, 3 + (*s == '0'), &numlen);
	    s += numlen;
	}
	else {
	    ors = nsavestr(nrs,nrslen);
	    orslen = nrslen;
	}
	return s;
    case 'n':
	minus_n = TRUE;
	s++;
	return s;
    case 'p':
	minus_p = TRUE;
	s++;
	return s;
    case 's':
	taint_not("-s");
	doswitches = TRUE;
	s++;
	return s;
    case 'T':
	tainting = TRUE;
	s++;
	return s;
    case 'u':
	do_undump = TRUE;
	s++;
	return s;
    case 'U':
	unsafe = TRUE;
	s++;
	return s;
    case 'v':
	fputs("\nThis is perl, version 5.0, Alpha 8 (unsupported)\n\n",stdout);
	fputs(rcsid,stdout);
	fputs("\nCopyright (c) 1989, 1990, 1991, 1992, 1993, 1994 Larry Wall\n",stdout);
#ifdef MSDOS
	fputs("MS-DOS port Copyright (c) 1989, 1990, Diomidis Spinellis\n",
	stdout);
#ifdef OS2
        fputs("OS/2 port Copyright (c) 1990, 1991, Raymond Chen, Kai Uwe Rommel\n",
        stdout);
#endif
#endif
#ifdef atarist
        fputs("atariST series port, ++jrb  bammi@cadence.com\n", stdout);
#endif
	fputs("\n\
Perl may be copied only under the terms of either the Artistic License or the\n\
GNU General Public License, which may be found in the Perl 5.0 source kit.\n",stdout);
#ifdef MSDOS
        usage(origargv[0]);
#endif
	exit(0);
    case 'w':
	dowarn = TRUE;
	s++;
	return s;
    case ' ':
	if (s[1] == '-')	/* Additional switches on #! line. */
	    return s+2;
	break;
    case 0:
    case '\n':
    case '\t':
	break;
    default:
	croak("Switch meaningless after -x: -%s",s);
    }
    return Nullch;
}

/* compliments of Tom Christiansen */

/* unexec() can be found in the Gnu emacs distribution */

void
my_unexec()
{
#ifdef UNEXEC
    int    status;
    extern int etext;

    sprintf (buf, "%s.perldump", origfilename);
    sprintf (tokenbuf, "%s/perl", BIN);

    status = unexec(buf, tokenbuf, &etext, sbrk(0), 0);
    if (status)
	fprintf(stderr, "unexec of %s into %s failed!\n", tokenbuf, buf);
    my_exit(status);
#else
    ABORT();		/* for use with undump */
#endif
}

static void
init_main_stash()
{
    GV *gv;
    curstash = defstash = newHV();
    curstname = newSVpv("main",4);
    GvHV(gv = gv_fetchpv("_main",TRUE)) = (HV*)SvREFCNT_inc(defstash);
    SvREADONLY_on(gv);
    HvNAME(defstash) = "main";
    incgv = gv_HVadd(gv_AVadd(gv_fetchpv("INC",TRUE)));
    SvMULTI_on(incgv);
    defgv = gv_fetchpv("_",TRUE);
    curstash = defstash;
    compiling.cop_stash = defstash;
}

static void
open_script(scriptname,dosearch,sv)
char *scriptname;
bool dosearch;
SV *sv;
{
    char *xfound = Nullch;
    char *xfailed = Nullch;
    register char *s;
    I32 len;

    if (dosearch && !strchr(scriptname, '/') && (s = getenv("PATH"))) {

	bufend = s + strlen(s);
	while (*s) {
#ifndef DOSISH
	    s = cpytill(tokenbuf,s,bufend,':',&len);
#else
#ifdef atarist
	    for (len = 0; *s && *s != ',' && *s != ';'; tokenbuf[len++] = *s++);
	    tokenbuf[len] = '\0';
#else
	    for (len = 0; *s && *s != ';'; tokenbuf[len++] = *s++);
	    tokenbuf[len] = '\0';
#endif
#endif
	    if (*s)
		s++;
#ifndef DOSISH
	    if (len && tokenbuf[len-1] != '/')
#else
#ifdef atarist
	    if (len && ((tokenbuf[len-1] != '\\') && (tokenbuf[len-1] != '/')))
#else
	    if (len && tokenbuf[len-1] != '\\')
#endif
#endif
		(void)strcat(tokenbuf+len,"/");
	    (void)strcat(tokenbuf+len,scriptname);
	    DEBUG_p(fprintf(stderr,"Looking for %s\n",tokenbuf));
	    if (stat(tokenbuf,&statbuf) < 0)		/* not there? */
		continue;
	    if (S_ISREG(statbuf.st_mode)
	     && cando(S_IRUSR,TRUE,&statbuf) && cando(S_IXUSR,TRUE,&statbuf)) {
		xfound = tokenbuf;              /* bingo! */
		break;
	    }
	    if (!xfailed)
		xfailed = savestr(tokenbuf);
	}
	if (!xfound)
	    croak("Can't execute %s", xfailed ? xfailed : scriptname );
	if (xfailed)
	    Safefree(xfailed);
	scriptname = xfound;
    }

    origfilename = savestr(e_fp ? "-e" : scriptname);
    curcop->cop_filegv = gv_fetchfile(origfilename);
    if (strEQ(origfilename,"-"))
	scriptname = "";
    if (preprocess) {
	char *cpp = CPPSTDIN;

	if (strEQ(cpp,"cppstdin"))
	    sprintf(tokenbuf, "%s/%s", SCRIPTDIR, cpp);
	else
	    sprintf(tokenbuf, "%s", cpp);
	sv_catpv(sv,"-I");
	sv_catpv(sv,PRIVLIB);
#ifdef MSDOS
	(void)sprintf(buf, "\
sed %s -e \"/^[^#]/b\" \
 -e \"/^#[ 	]*include[ 	]/b\" \
 -e \"/^#[ 	]*define[ 	]/b\" \
 -e \"/^#[ 	]*if[ 	]/b\" \
 -e \"/^#[ 	]*ifdef[ 	]/b\" \
 -e \"/^#[ 	]*ifndef[ 	]/b\" \
 -e \"/^#[ 	]*else/b\" \
 -e \"/^#[ 	]*elif[ 	]/b\" \
 -e \"/^#[ 	]*undef[ 	]/b\" \
 -e \"/^#[ 	]*endif/b\" \
 -e \"s/^#.*//\" \
 %s | %s -C %s %s",
	  (doextract ? "-e \"1,/^#/d\n\"" : ""),
#else
	(void)sprintf(buf, "\
%s %s -e '/^[^#]/b' \
 -e '/^#[ 	]*include[ 	]/b' \
 -e '/^#[ 	]*define[ 	]/b' \
 -e '/^#[ 	]*if[ 	]/b' \
 -e '/^#[ 	]*ifdef[ 	]/b' \
 -e '/^#[ 	]*ifndef[ 	]/b' \
 -e '/^#[ 	]*else/b' \
 -e '/^#[ 	]*elif[ 	]/b' \
 -e '/^#[ 	]*undef[ 	]/b' \
 -e '/^#[ 	]*endif/b' \
 -e 's/^[ 	]*#.*//' \
 %s | %s -C %s %s",
#ifdef LOC_SED
	  LOC_SED,
#else
	  "sed",
#endif
	  (doextract ? "-e '1,/^#/d\n'" : ""),
#endif
	  scriptname, tokenbuf, SvPV(sv, na), CPPMINUS);
	DEBUG_P(fprintf(stderr, "%s\n", buf));
	doextract = FALSE;
#ifdef IAMSUID				/* actually, this is caught earlier */
	if (euid != uid && !euid) {	/* if running suidperl */
#ifdef HAS_SETEUID
	    (void)seteuid(uid);		/* musn't stay setuid root */
#else
#ifdef HAS_SETREUID
	    (void)setreuid(-1, uid);
#else
	    setuid(uid);
#endif
#endif
	    if (geteuid() != uid)
		croak("Can't do seteuid!\n");
	}
#endif /* IAMSUID */
	rsfp = my_popen(buf,"r");
    }
    else if (!*scriptname) {
	taint_not("program input from stdin");
	rsfp = stdin;
    }
    else
	rsfp = fopen(scriptname,"r");
    if ((FILE*)rsfp == Nullfp) {
#ifdef DOSUID
#ifndef IAMSUID		/* in case script is not readable before setuid */
	if (euid && stat(SvPVX(GvSV(curcop->cop_filegv)),&statbuf) >= 0 &&
	  statbuf.st_mode & (S_ISUID|S_ISGID)) {
	    (void)sprintf(buf, "%s/sperl%s", BIN, patchlevel);
	    execv(buf, origargv);	/* try again */
	    croak("Can't do setuid\n");
	}
#endif
#endif
	croak("Can't open perl script \"%s\": %s\n",
	  SvPVX(GvSV(curcop->cop_filegv)), Strerror(errno));
    }
}

static void
validate_suid(validarg)
char *validarg;
{
    char *s;
    /* do we need to emulate setuid on scripts? */

    /* This code is for those BSD systems that have setuid #! scripts disabled
     * in the kernel because of a security problem.  Merely defining DOSUID
     * in perl will not fix that problem, but if you have disabled setuid
     * scripts in the kernel, this will attempt to emulate setuid and setgid
     * on scripts that have those now-otherwise-useless bits set.  The setuid
     * root version must be called suidperl or sperlN.NNN.  If regular perl
     * discovers that it has opened a setuid script, it calls suidperl with
     * the same argv that it had.  If suidperl finds that the script it has
     * just opened is NOT setuid root, it sets the effective uid back to the
     * uid.  We don't just make perl setuid root because that loses the
     * effective uid we had before invoking perl, if it was different from the
     * uid.
     *
     * DOSUID must be defined in both perl and suidperl, and IAMSUID must
     * be defined in suidperl only.  suidperl must be setuid root.  The
     * Configure script will set this up for you if you want it.
     */

#ifdef DOSUID
    if (fstat(fileno(rsfp),&statbuf) < 0)	/* normal stat is insecure */
	croak("Can't stat script \"%s\"",origfilename);
    if (statbuf.st_mode & (S_ISUID|S_ISGID)) {
	I32 len;

#ifdef IAMSUID
#ifndef HAS_SETREUID
	/* On this access check to make sure the directories are readable,
	 * there is actually a small window that the user could use to make
	 * filename point to an accessible directory.  So there is a faint
	 * chance that someone could execute a setuid script down in a
	 * non-accessible directory.  I don't know what to do about that.
	 * But I don't think it's too important.  The manual lies when
	 * it says access() is useful in setuid programs.
	 */
	if (access(SvPVX(GvSV(curcop->cop_filegv)),1))	/*double check*/
	    croak("Permission denied");
#else
	/* If we can swap euid and uid, then we can determine access rights
	 * with a simple stat of the file, and then compare device and
	 * inode to make sure we did stat() on the same file we opened.
	 * Then we just have to make sure he or she can execute it.
	 */
	{
	    struct stat tmpstatbuf;

	    if (setreuid(euid,uid) < 0 || getuid() != euid || geteuid() != uid)
		croak("Can't swap uid and euid");	/* really paranoid */
	    if (stat(SvPVX(GvSV(curcop->cop_filegv)),&tmpstatbuf) < 0)
		croak("Permission denied");	/* testing full pathname here */
	    if (tmpstatbuf.st_dev != statbuf.st_dev ||
		tmpstatbuf.st_ino != statbuf.st_ino) {
		(void)fclose(rsfp);
		if (rsfp = my_popen("/bin/mail root","w")) {	/* heh, heh */
		    fprintf(rsfp,
"User %d tried to run dev %d ino %d in place of dev %d ino %d!\n\
(Filename of set-id script was %s, uid %d gid %d.)\n\nSincerely,\nperl\n",
			uid,tmpstatbuf.st_dev, tmpstatbuf.st_ino,
			statbuf.st_dev, statbuf.st_ino,
			SvPVX(GvSV(curcop->cop_filegv)),
			statbuf.st_uid, statbuf.st_gid);
		    (void)my_pclose(rsfp);
		}
		croak("Permission denied\n");
	    }
	    if (setreuid(uid,euid) < 0 || getuid() != uid || geteuid() != euid)
		croak("Can't reswap uid and euid");
	    if (!cando(S_IXUSR,FALSE,&statbuf))		/* can real uid exec? */
		croak("Permission denied\n");
	}
#endif /* HAS_SETREUID */
#endif /* IAMSUID */

	if (!S_ISREG(statbuf.st_mode))
	    croak("Permission denied");
	if (statbuf.st_mode & S_IWOTH)
	    croak("Setuid/gid script is writable by world");
	doswitches = FALSE;		/* -s is insecure in suid */
	curcop->cop_line++;
	if (fgets(tokenbuf,sizeof tokenbuf, rsfp) == Nullch ||
	  strnNE(tokenbuf,"#!",2) )	/* required even on Sys V */
	    croak("No #! line");
	s = tokenbuf+2;
	if (*s == ' ') s++;
	while (!isSPACE(*s)) s++;
	if (strnNE(s-4,"perl",4) && strnNE(s-9,"perl",4))  /* sanity check */
	    croak("Not a perl script");
	while (*s == ' ' || *s == '\t') s++;
	/*
	 * #! arg must be what we saw above.  They can invoke it by
	 * mentioning suidperl explicitly, but they may not add any strange
	 * arguments beyond what #! says if they do invoke suidperl that way.
	 */
	len = strlen(validarg);
	if (strEQ(validarg," PHOOEY ") ||
	    strnNE(s,validarg,len) || !isSPACE(s[len]))
	    croak("Args must match #! line");

#ifndef IAMSUID
	if (euid != uid && (statbuf.st_mode & S_ISUID) &&
	    euid == statbuf.st_uid)
	    if (!do_undump)
		croak("YOU HAVEN'T DISABLED SET-ID SCRIPTS IN THE KERNEL YET!\n\
FIX YOUR KERNEL, PUT A C WRAPPER AROUND THIS SCRIPT, OR USE -u AND UNDUMP!\n");
#endif /* IAMSUID */

	if (euid) {	/* oops, we're not the setuid root perl */
	    (void)fclose(rsfp);
#ifndef IAMSUID
	    (void)sprintf(buf, "%s/sperl%s", BIN, patchlevel);
	    execv(buf, origargv);	/* try again */
#endif
	    croak("Can't do setuid\n");
	}

	if (statbuf.st_mode & S_ISGID && statbuf.st_gid != egid) {
#ifdef HAS_SETEGID
	    (void)setegid(statbuf.st_gid);
#else
#ifdef HAS_SETREGID
	    (void)setregid((GIDTYPE)-1,statbuf.st_gid);
#else
	    setgid(statbuf.st_gid);
#endif
#endif
	    if (getegid() != statbuf.st_gid)
		croak("Can't do setegid!\n");
	}
	if (statbuf.st_mode & S_ISUID) {
	    if (statbuf.st_uid != euid)
#ifdef HAS_SETEUID
		(void)seteuid(statbuf.st_uid);	/* all that for this */
#else
#ifdef HAS_SETREUID
		(void)setreuid((UIDTYPE)-1,statbuf.st_uid);
#else
		setuid(statbuf.st_uid);
#endif
#endif
	    if (geteuid() != statbuf.st_uid)
		croak("Can't do seteuid!\n");
	}
	else if (uid) {			/* oops, mustn't run as root */
#ifdef HAS_SETEUID
	    (void)seteuid((UIDTYPE)uid);
#else
#ifdef HAS_SETREUID
	    (void)setreuid((UIDTYPE)-1,(UIDTYPE)uid);
#else
	    setuid((UIDTYPE)uid);
#endif
#endif
	    if (geteuid() != uid)
		croak("Can't do seteuid!\n");
	}
	uid = (int)getuid();
	euid = (int)geteuid();
	gid = (int)getgid();
	egid = (int)getegid();
	tainting |= (euid != uid || egid != gid);
	if (!cando(S_IXUSR,TRUE,&statbuf))
	    croak("Permission denied\n");	/* they can't do this */
    }
#ifdef IAMSUID
    else if (preprocess)
	croak("-P not allowed for setuid/setgid script\n");
    else
	croak("Script is not setuid/setgid in suidperl\n");
#endif /* IAMSUID */
#else /* !DOSUID */
    if (euid != uid || egid != gid) {	/* (suidperl doesn't exist, in fact) */
#ifndef SETUID_SCRIPTS_ARE_SECURE_NOW
	fstat(fileno(rsfp),&statbuf);	/* may be either wrapped or real suid */
	if ((euid != uid && euid == statbuf.st_uid && statbuf.st_mode & S_ISUID)
	    ||
	    (egid != gid && egid == statbuf.st_gid && statbuf.st_mode & S_ISGID)
	   )
	    if (!do_undump)
		croak("YOU HAVEN'T DISABLED SET-ID SCRIPTS IN THE KERNEL YET!\n\
FIX YOUR KERNEL, PUT A C WRAPPER AROUND THIS SCRIPT, OR USE -u AND UNDUMP!\n");
#endif /* SETUID_SCRIPTS_ARE_SECURE_NOW */
	/* not set-id, must be wrapped */
    }
#endif /* DOSUID */
}

static void
find_beginning()
{
    register char *s;

    /* skip forward in input to the real script? */

    taint_not("-x");
    while (doextract) {
	if ((s = sv_gets(linestr, rsfp, 0)) == Nullch)
	    croak("No Perl script found in input\n");
	if (*s == '#' && s[1] == '!' && instr(s,"perl")) {
	    ungetc('\n',rsfp);		/* to keep line count right */
	    doextract = FALSE;
	    if (s = instr(s,"perl -")) {
		s += 6;
		/*SUPPRESS 530*/
		while (s = moreswitches(s)) ;
	    }
	    if (cddir && chdir(cddir) < 0)
		croak("Can't chdir to %s",cddir);
	}
    }
}

static void
init_debugger()
{
    GV* tmpgv;

    debstash = newHV();
    GvHV(gv_fetchpv("::_DB",TRUE)) = debstash;
    curstash = debstash;
    dbargs = GvAV(gv_AVadd((tmpgv = gv_fetchpv("args",TRUE))));
    SvMULTI_on(tmpgv);
    AvREAL_off(dbargs);
    DBgv = gv_fetchpv("DB",TRUE);
    SvMULTI_on(DBgv);
    DBline = gv_fetchpv("dbline",TRUE);
    SvMULTI_on(DBline);
    DBsub = gv_HVadd(tmpgv = gv_fetchpv("sub",TRUE));
    SvMULTI_on(tmpgv);
    DBsingle = GvSV((tmpgv = gv_fetchpv("single",TRUE)));
    SvMULTI_on(tmpgv);
    DBtrace = GvSV((tmpgv = gv_fetchpv("trace",TRUE)));
    SvMULTI_on(tmpgv);
    DBsignal = GvSV((tmpgv = gv_fetchpv("signal",TRUE)));
    SvMULTI_on(tmpgv);
    curstash = defstash;
}

static void
init_stacks()
{
    stack = newAV();
    mainstack = stack;			/* remember in case we switch stacks */
    AvREAL_off(stack);			/* not a real array */
    av_fill(stack,127); av_fill(stack,-1);	/* preextend stack */

    stack_base = AvARRAY(stack);
    stack_sp = stack_base;
    stack_max = stack_base + 127;

    New(54,markstack,64,int);
    markstack_ptr = markstack;
    markstack_max = markstack + 64;

    New(54,scopestack,32,int);
    scopestack_ix = 0;
    scopestack_max = 32;

    New(54,savestack,128,ANY);
    savestack_ix = 0;
    savestack_max = 128;

    New(54,retstack,16,OP*);
    retstack_ix = 0;
    retstack_max = 16;

    New(50,cxstack,128,CONTEXT);
    cxstack_ix	= -1;
    cxstack_max	= 128;

    New(50,tmps_stack,128,SV*);
    tmps_ix = -1;
    tmps_max = 128;

    DEBUG( {
	New(51,debname,128,char);
	New(52,debdelim,128,char);
    } )
}

static void
init_lexer()
{
    FILE* tmpfp = rsfp;

    lex_start(linestr);
    rsfp = tmpfp;
    subname = newSVpv("main",4);
}

static void
init_predump_symbols()
{
    GV *tmpgv;

    sv_setpvn(GvSV(gv_fetchpv("\"", TRUE)), " ", 1);

    stdingv = gv_fetchpv("STDIN",TRUE);
    SvMULTI_on(stdingv);
    if (!GvIO(stdingv))
	GvIO(stdingv) = newIO();
    IoIFP(GvIO(stdingv)) = stdin;
    tmpgv = gv_fetchpv("stdin",TRUE);
    GvIO(tmpgv) = (IO*)SvREFCNT_inc(GvIO(stdingv));
    SvMULTI_on(tmpgv);

    tmpgv = gv_fetchpv("STDOUT",TRUE);
    SvMULTI_on(tmpgv);
    if (!GvIO(tmpgv))
	GvIO(tmpgv) = newIO();
    IoOFP(GvIO(tmpgv)) = IoIFP(GvIO(tmpgv)) = stdout;
    defoutgv = tmpgv;
    tmpgv = gv_fetchpv("stdout",TRUE);
    GvIO(tmpgv) = (IO*)SvREFCNT_inc(GvIO(defoutgv));
    SvMULTI_on(tmpgv);

    curoutgv = gv_fetchpv("STDERR",TRUE);
    SvMULTI_on(curoutgv);
    if (!GvIO(curoutgv))
	GvIO(curoutgv) = newIO();
    IoOFP(GvIO(curoutgv)) = IoIFP(GvIO(curoutgv)) = stderr;
    tmpgv = gv_fetchpv("stderr",TRUE);
    GvIO(tmpgv) = (IO*)SvREFCNT_inc(GvIO(curoutgv));
    SvMULTI_on(tmpgv);
    curoutgv = defoutgv;		/* switch back to STDOUT */

    statname = NEWSV(66,0);		/* last filename we did stat on */
}

static void
init_postdump_symbols(argc,argv,env)
register int argc;
register char **argv;
register char **env;
{
    char *s;
    SV *sv;
    GV* tmpgv;

    argc--,argv++;	/* skip name of script */
    if (doswitches) {
	for (; argc > 0 && **argv == '-'; argc--,argv++) {
	    if (!argv[0][1])
		break;
	    if (argv[0][1] == '-') {
		argc--,argv++;
		break;
	    }
	    if (s = strchr(argv[0], '=')) {
		*s++ = '\0';
		sv_setpv(GvSV(gv_fetchpv(argv[0]+1,TRUE)),s);
	    }
	    else
		sv_setiv(GvSV(gv_fetchpv(argv[0]+1,TRUE)),1);
	}
    }
    toptarget = NEWSV(0,0);
    sv_upgrade(toptarget, SVt_PVFM);
    sv_setpvn(toptarget, "", 0);
    bodytarget = NEWSV(0,0);
    sv_upgrade(bodytarget, SVt_PVFM);
    sv_setpvn(bodytarget, "", 0);
    formtarget = bodytarget;

    tainted = 1;
    if (tmpgv = gv_fetchpv("0",TRUE)) {
	sv_setpv(GvSV(tmpgv),origfilename);
	magicname("0", "0", 1);
    }
    if (tmpgv = gv_fetchpv("\024",TRUE))
	time(&basetime);
    if (tmpgv = gv_fetchpv("\030",TRUE))
	sv_setpv(GvSV(tmpgv),origargv[0]);
    if (argvgv = gv_fetchpv("ARGV",TRUE)) {
	SvMULTI_on(argvgv);
	(void)gv_AVadd(argvgv);
	av_clear(GvAVn(argvgv));
	for (; argc > 0; argc--,argv++) {
	    (void)av_push(GvAVn(argvgv),newSVpv(argv[0],0));
	}
    }
    if (envgv = gv_fetchpv("ENV",TRUE)) {
	HV *hv;
	SvMULTI_on(envgv);
	hv = GvHVn(envgv);
	hv_clear(hv);
	if (env != environ) {
	    environ[0] = Nullch;
	    hv_magic(hv, envgv, 'E');
	}
	for (; *env; env++) {
	    if (!(s = strchr(*env,'=')))
		continue;
	    *s++ = '\0';
	    sv = newSVpv(s--,0);
	    (void)hv_store(hv, *env, s - *env, sv, 0);
	    *s = '=';
	}
	hv_magic(hv, envgv, 'E');
    }
    tainted = 0;
    if (tmpgv = gv_fetchpv("$",TRUE))
	sv_setiv(GvSV(tmpgv),(I32)getpid());

}

static void
init_perllib()
{
    if (!tainting)
	incpush(getenv("PERLLIB"));

#ifndef PRIVLIB
#define PRIVLIB "/usr/local/lib/perl"
#endif
    incpush(PRIVLIB);
    (void)av_push(GvAVn(incgv),newSVpv(".",1));
}

void
calllist(list)
AV* list;
{
    jmp_buf oldtop;
    I32 sp = stack_sp - stack_base;

    av_store(stack, ++sp, Nullsv);	/* reserve spot for sub reference */
    Copy(top_env, oldtop, 1, jmp_buf);

    while (AvFILL(list) >= 0) {
	CV *cv = (CV*)av_shift(list);

	SAVEFREESV(cv);
	if (setjmp(top_env)) {
	    if (list == beginav) {
		warn("BEGIN failed--execution aborted");
		Copy(oldtop, top_env, 1, jmp_buf);
		my_exit(1);
	    }
	}
	else {
	    perl_callsv((SV*)cv, sp, G_SCALAR, 0, 0);
	}
    }

    Copy(oldtop, top_env, 1, jmp_buf);
}

