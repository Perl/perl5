char rcsid[] = "$Header: perly.c,v 1.0.1.3 88/01/28 10:28:31 root Exp $";
/*
 * $Log:	perly.c,v $
 * Revision 1.0.1.3  88/01/28  10:28:31  root
 * patch8: added eval operator.  Also fixed expectterm following right curly.
 * 
 * Revision 1.0.1.2  88/01/24  00:06:03  root
 * patch 2: s/(abc)/\1/ grandfathering didn't work right.
 * 
 * Revision 1.0.1.1  88/01/21  21:25:57  root
 * Now uses CPP and CPPMINUS symbols from config.h.
 * 
 * Revision 1.0  87/12/18  15:53:31  root
 * Initial revision
 * 
 */

bool preprocess = FALSE;
bool assume_n = FALSE;
bool assume_p = FALSE;
bool doswitches = FALSE;
bool allstabs = FALSE;		/* init all customary symbols in symbol table?*/
char *filename;
char *e_tmpname = "/tmp/perl-eXXXXXX";
FILE *e_fp = Nullfp;
ARG *l();

main(argc,argv,env)
register int argc;
register char **argv;
register char **env;
{
    register STR *str;
    register char *s;
    char *index();

    linestr = str_new(80);
    str = str_make("-I/usr/lib/perl ");	/* first used for -I flags */
    for (argc--,argv++; argc; argc--,argv++) {
	if (argv[0][0] != '-' || !argv[0][1])
	    break;
      reswitch:
	switch (argv[0][1]) {
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
		e_tmpname = (char*) strdup(e_tmpname);
		mkstemp(e_tmpname);
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
	    if (!argv[0][2]) {
		str_cat(str,argv[1]);
		argc--,argv++;
		str_cat(str," ");
	    }
	    break;
	case 'n':
	    assume_n = TRUE;
	    strcpy(argv[0], argv[0]+1);
	    goto reswitch;
	case 'p':
	    assume_p = TRUE;
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
	case 'v':
	    version();
	    exit(0);
	case '-':
	    argc--,argv++;
	    goto switch_end;
	case 0:
	    break;
	default:
	    fatal("Unrecognized switch: %s\n",argv[0]);
	}
    }
  switch_end:
    if (e_fp) {
	fclose(e_fp);
	argc++,argv--;
	argv[0] = e_tmpname;
    }

    str_set(&str_no,No);
    str_set(&str_yes,Yes);
    init_eval();

    /* open script */

    if (argv[0] == Nullch)
	argv[0] = "-";
    filename = savestr(argv[0]);
    if (strEQ(filename,"-"))
	argv[0] = "";
    if (preprocess) {
	sprintf(buf, "\
%s -e '/^[^#]/b' \
 -e '/^#[ 	]*include[ 	]/b' \
 -e '/^#[ 	]*define[ 	]/b' \
 -e '/^#[ 	]*if[ 	]/b' \
 -e '/^#[ 	]*ifdef[ 	]/b' \
 -e '/^#[ 	]*else/b' \
 -e '/^#[ 	]*endif/b' \
 -e 's/^#.*//' \
 %s | %s -C %s%s",
	  SED, argv[0], CPP, str_get(str), CPPMINUS);
	rsfp = popen(buf,"r");
    }
    else if (!*argv[0])
	rsfp = stdin;
    else
	rsfp = fopen(argv[0],"r");
    if (rsfp == Nullfp)
	fatal("Perl script \"%s\" doesn't seem to exist.\n",filename);
    str_free(str);		/* free -I directories */

    defstab = stabent("_",TRUE);

    /* init tokener */

    bufptr = str_get(linestr);

    /* now parse the report spec */

    if (yyparse())
	fatal("Execution aborted due to compilation errors.\n");

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
	for (; argc > 0; argc--,argv++) {
	    apush(argvstab->stab_array,str_make(argv[0]));
	}
    }
    if (envstab = stabent("ENV",allstabs)) {
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
    sigstab = stabent("SIG",allstabs);

    magicalize("!#?^~=-%0123456789.+&*(),\\/[|");

    (tmpstab = stabent("0",allstabs)) && str_set(STAB_STR(tmpstab),filename);
    (tmpstab = stabent("$",allstabs)) &&
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
    safefree(filename);
    filename = "(eval)";

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
	fatal("Can't find label \"%s\"--aborting.\n",goto_targ);
    exit(0);
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

#define RETURN(retval) return (bufptr = s,retval)
#define OPERATOR(retval) return (expectterm = TRUE,bufptr = s,retval)
#define TERM(retval) return (expectterm = FALSE,bufptr = s,retval)
#define LOOPX(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,LOOPEX)
#define UNI(f) return (yylval.ival = f,expectterm = TRUE,bufptr = s,UNIOP)
#define FUN0(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,FUNC0)
#define FUN1(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,FUNC1)
#define FUN2(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,FUNC2)
#define FUN3(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,FUNC3)
#define SFUN(f) return (yylval.ival = f,expectterm = FALSE,bufptr = s,STABFUN)

yylex()
{
    register char *s = bufptr;
    register char *d;
    register int tmp;
    static bool in_format = FALSE;
    static bool firstline = TRUE;

  retry:
#ifdef YYDEBUG
    if (yydebug)
	if (index(s,'\n'))
	    fprintf(stderr,"Tokener at %s",s);
	else
	    fprintf(stderr,"Tokener at %s\n",s);
#endif
    switch (*s) {
    default:
	fprintf(stderr,
	    "Unrecognized character %c in file %s line %d--ignoring.\n",
	     *s++,filename,line);
	goto retry;
    case 0:
	s = str_get(linestr);
	*s = '\0';
	if (firstline && (assume_n || assume_p)) {
	    firstline = FALSE;
	    str_set(linestr,"while (<>) {");
	    s = str_get(linestr);
	    goto retry;
	}
	if (!rsfp)
	    RETURN(0);
	if (in_format) {
	    yylval.formval = load_format();	/* leaves . in buffer */
	    in_format = FALSE;
	    s = str_get(linestr);
	    TERM(FORMLIST);
	}
	line++;
	if ((s = str_gets(linestr, rsfp)) == Nullch) {
	    if (preprocess)
		pclose(rsfp);
	    else if (rsfp != stdin)
		fclose(rsfp);
	    rsfp = Nullfp;
	    if (assume_n || assume_p) {
		str_set(linestr,assume_p ? "}continue{print;" : "");
		str_cat(linestr,"}");
		s = str_get(linestr);
		goto retry;
	    }
	    s = str_get(linestr);
	    RETURN(0);
	}
#ifdef DEBUG
	else if (firstline) {
	    char *showinput();
	    s = showinput();
	}
#endif
	firstline = FALSE;
	goto retry;
    case ' ': case '\t':
	s++;
	goto retry;
    case '\n':
    case '#':
	if (preprocess && s == str_get(linestr) &&
	       s[1] == ' ' && isdigit(s[2])) {
	    line = atoi(s+2)-1;
	    for (s += 2; isdigit(*s); s++) ;
	    while (*s && isspace(*s)) s++;
	    if (filename)
		safefree(filename);
	    s[strlen(s)-1] = '\0';	/* wipe out newline */
	    filename = savestr(s);
	    s = str_get(linestr);
	}
	if (in_eval) {
	    while (*s && *s != '\n')
		s++;
	    if (*s)
		s++;
	    line++;
	}
	else
	    *s = '\0';
	if (lex_newlines)
	    RETURN('\n');
	goto retry;
    case '+':
    case '-':
	if (s[1] == *s) {
	    s++;
	    if (*s++ == '+')
		RETURN(INC);
	    else
		RETURN(DEC);
	}
	/* FALL THROUGH */
    case '*':
    case '%':
    case '^':
    case '~':
    case '(':
    case ',':
    case ':':
    case ';':
    case '{':
    case '[':
	tmp = *s++;
	OPERATOR(tmp);
    case ')':
    case ']':
	tmp = *s++;
	TERM(tmp);
    case '}':
	tmp = *s++;
	for (d = s; *d == ' ' || *d == '\t'; d++) ;
	if (*d == '\n' || *d == '#')
	    OPERATOR(tmp);		/* block end */
	else
	    TERM(tmp);			/* associative array end */
    case '&':
	s++;
	tmp = *s++;
	if (tmp == '&')
	    OPERATOR(ANDAND);
	s--;
	OPERATOR('&');
    case '|':
	s++;
	tmp = *s++;
	if (tmp == '|')
	    OPERATOR(OROR);
	s--;
	OPERATOR('|');
    case '=':
	s++;
	tmp = *s++;
	if (tmp == '=')
	    OPERATOR(EQ);
	if (tmp == '~')
	    OPERATOR(MATCH);
	s--;
	OPERATOR('=');
    case '!':
	s++;
	tmp = *s++;
	if (tmp == '=')
	    OPERATOR(NE);
	if (tmp == '~')
	    OPERATOR(NMATCH);
	s--;
	OPERATOR('!');
    case '<':
	if (expectterm) {
	    s = scanstr(s);
	    TERM(RSTRING);
	}
	s++;
	tmp = *s++;
	if (tmp == '<')
	    OPERATOR(LS);
	if (tmp == '=')
	    OPERATOR(LE);
	s--;
	OPERATOR('<');
    case '>':
	s++;
	tmp = *s++;
	if (tmp == '>')
	    OPERATOR(RS);
	if (tmp == '=')
	    OPERATOR(GE);
	s--;
	OPERATOR('>');

#define SNARFWORD \
	d = tokenbuf; \
	while (isalpha(*s) || isdigit(*s) || *s == '_') \
	    *d++ = *s++; \
	*d = '\0'; \
	d = tokenbuf;

    case '$':
	if (s[1] == '#' && (isalpha(s[2]) || s[2] == '_')) {
	    s++;
	    s = scanreg(s,tokenbuf);
	    yylval.stabval = aadd(stabent(tokenbuf,TRUE));
	    TERM(ARYLEN);
	}
	s = scanreg(s,tokenbuf);
	yylval.stabval = stabent(tokenbuf,TRUE);
	TERM(REG);

    case '@':
	s = scanreg(s,tokenbuf);
	yylval.stabval = aadd(stabent(tokenbuf,TRUE));
	TERM(ARY);

    case '/':			/* may either be division or pattern */
    case '?':			/* may either be conditional or pattern */
	if (expectterm) {
	    s = scanpat(s);
	    TERM(PATTERN);
	}
	tmp = *s++;
	OPERATOR(tmp);

    case '.':
	if (!expectterm || !isdigit(s[1])) {
	    s++;
	    tmp = *s++;
	    if (tmp == '.')
		OPERATOR(DOTDOT);
	    s--;
	    OPERATOR('.');
	}
	/* FALL THROUGH */
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
    case '\'': case '"': case '`':
	s = scanstr(s);
	TERM(RSTRING);

    case '_':
	SNARFWORD;
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'a': case 'A':
	SNARFWORD;
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'b': case 'B':
	SNARFWORD;
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'c': case 'C':
	SNARFWORD;
	if (strEQ(d,"continue"))
	    OPERATOR(CONTINUE);
	if (strEQ(d,"chdir"))
	    UNI(O_CHDIR);
	if (strEQ(d,"close"))
	    OPERATOR(CLOSE);
	if (strEQ(d,"crypt"))
	    FUN2(O_CRYPT);
	if (strEQ(d,"chop"))
	    OPERATOR(CHOP);
	if (strEQ(d,"chmod")) {
	    yylval.ival = O_CHMOD;
	    OPERATOR(PRINT);
	}
	if (strEQ(d,"chown")) {
	    yylval.ival = O_CHOWN;
	    OPERATOR(PRINT);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'd': case 'D':
	SNARFWORD;
	if (strEQ(d,"do"))
	    OPERATOR(DO);
	if (strEQ(d,"die"))
	    UNI(O_DIE);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'e': case 'E':
	SNARFWORD;
	if (strEQ(d,"else"))
	    OPERATOR(ELSE);
	if (strEQ(d,"elsif"))
	    OPERATOR(ELSIF);
	if (strEQ(d,"eq") || strEQ(d,"EQ"))
	    OPERATOR(SEQ);
	if (strEQ(d,"exit"))
	    UNI(O_EXIT);
	if (strEQ(d,"eval")) {
	    allstabs = TRUE;		/* must initialize everything since */
	    UNI(O_EVAL);		/* we don't know what will be used */
	}
	if (strEQ(d,"eof"))
	    TERM(FEOF);
	if (strEQ(d,"exp"))
	    FUN1(O_EXP);
	if (strEQ(d,"each"))
	    SFUN(O_EACH);
	if (strEQ(d,"exec")) {
	    yylval.ival = O_EXEC;
	    OPERATOR(PRINT);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'f': case 'F':
	SNARFWORD;
	if (strEQ(d,"for"))
	    OPERATOR(FOR);
	if (strEQ(d,"format")) {
	    in_format = TRUE;
	    OPERATOR(FORMAT);
	}
	if (strEQ(d,"fork"))
	    FUN0(O_FORK);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'g': case 'G':
	SNARFWORD;
	if (strEQ(d,"gt") || strEQ(d,"GT"))
	    OPERATOR(SGT);
	if (strEQ(d,"ge") || strEQ(d,"GE"))
	    OPERATOR(SGE);
	if (strEQ(d,"goto"))
	    LOOPX(O_GOTO);
	if (strEQ(d,"gmtime"))
	    FUN1(O_GMTIME);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'h': case 'H':
	SNARFWORD;
	if (strEQ(d,"hex"))
	    FUN1(O_HEX);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'i': case 'I':
	SNARFWORD;
	if (strEQ(d,"if"))
	    OPERATOR(IF);
	if (strEQ(d,"index"))
	    FUN2(O_INDEX);
	if (strEQ(d,"int"))
	    FUN1(O_INT);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'j': case 'J':
	SNARFWORD;
	if (strEQ(d,"join"))
	    OPERATOR(JOIN);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'k': case 'K':
	SNARFWORD;
	if (strEQ(d,"keys"))
	    SFUN(O_KEYS);
	if (strEQ(d,"kill")) {
	    yylval.ival = O_KILL;
	    OPERATOR(PRINT);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'l': case 'L':
	SNARFWORD;
	if (strEQ(d,"last"))
	    LOOPX(O_LAST);
	if (strEQ(d,"length"))
	    FUN1(O_LENGTH);
	if (strEQ(d,"lt") || strEQ(d,"LT"))
	    OPERATOR(SLT);
	if (strEQ(d,"le") || strEQ(d,"LE"))
	    OPERATOR(SLE);
	if (strEQ(d,"localtime"))
	    FUN1(O_LOCALTIME);
	if (strEQ(d,"log"))
	    FUN1(O_LOG);
	if (strEQ(d,"link"))
	    FUN2(O_LINK);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'm': case 'M':
	SNARFWORD;
	if (strEQ(d,"m")) {
	    s = scanpat(s-1);
	    TERM(PATTERN);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'n': case 'N':
	SNARFWORD;
	if (strEQ(d,"next"))
	    LOOPX(O_NEXT);
	if (strEQ(d,"ne") || strEQ(d,"NE"))
	    OPERATOR(SNE);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'o': case 'O':
	SNARFWORD;
	if (strEQ(d,"open"))
	    OPERATOR(OPEN);
	if (strEQ(d,"ord"))
	    FUN1(O_ORD);
	if (strEQ(d,"oct"))
	    FUN1(O_OCT);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'p': case 'P':
	SNARFWORD;
	if (strEQ(d,"print")) {
	    yylval.ival = O_PRINT;
	    OPERATOR(PRINT);
	}
	if (strEQ(d,"printf")) {
	    yylval.ival = O_PRTF;
	    OPERATOR(PRINT);
	}
	if (strEQ(d,"push")) {
	    yylval.ival = O_PUSH;
	    OPERATOR(PUSH);
	}
	if (strEQ(d,"pop"))
	    OPERATOR(POP);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'q': case 'Q':
	SNARFWORD;
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'r': case 'R':
	SNARFWORD;
	if (strEQ(d,"reset"))
	    UNI(O_RESET);
	if (strEQ(d,"redo"))
	    LOOPX(O_REDO);
	if (strEQ(d,"rename"))
	    FUN2(O_RENAME);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 's': case 'S':
	SNARFWORD;
	if (strEQ(d,"s")) {
	    s = scansubst(s);
	    TERM(SUBST);
	}
	if (strEQ(d,"shift"))
	    TERM(SHIFT);
	if (strEQ(d,"split"))
	    TERM(SPLIT);
	if (strEQ(d,"substr"))
	    FUN3(O_SUBSTR);
	if (strEQ(d,"sprintf"))
	    OPERATOR(SPRINTF);
	if (strEQ(d,"sub"))
	    OPERATOR(SUB);
	if (strEQ(d,"select"))
	    OPERATOR(SELECT);
	if (strEQ(d,"seek"))
	    OPERATOR(SEEK);
	if (strEQ(d,"stat"))
	    OPERATOR(STAT);
	if (strEQ(d,"sqrt"))
	    FUN1(O_SQRT);
	if (strEQ(d,"sleep"))
	    UNI(O_SLEEP);
	if (strEQ(d,"system")) {
	    yylval.ival = O_SYSTEM;
	    OPERATOR(PRINT);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 't': case 'T':
	SNARFWORD;
	if (strEQ(d,"tr")) {
	    s = scantrans(s);
	    TERM(TRANS);
	}
	if (strEQ(d,"tell"))
	    TERM(TELL);
	if (strEQ(d,"time"))
	    FUN0(O_TIME);
	if (strEQ(d,"times"))
	    FUN0(O_TMS);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'u': case 'U':
	SNARFWORD;
	if (strEQ(d,"using"))
	    OPERATOR(USING);
	if (strEQ(d,"until"))
	    OPERATOR(UNTIL);
	if (strEQ(d,"unless"))
	    OPERATOR(UNLESS);
	if (strEQ(d,"umask"))
	    FUN1(O_UMASK);
	if (strEQ(d,"unshift")) {
	    yylval.ival = O_UNSHIFT;
	    OPERATOR(PUSH);
	}
	if (strEQ(d,"unlink")) {
	    yylval.ival = O_UNLINK;
	    OPERATOR(PRINT);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'v': case 'V':
	SNARFWORD;
	if (strEQ(d,"values"))
	    SFUN(O_VALUES);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'w': case 'W':
	SNARFWORD;
	if (strEQ(d,"write"))
	    TERM(WRITE);
	if (strEQ(d,"while"))
	    OPERATOR(WHILE);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'x': case 'X':
	SNARFWORD;
	if (!expectterm && strEQ(d,"x"))
	    OPERATOR('x');
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'y': case 'Y':
	SNARFWORD;
	if (strEQ(d,"y")) {
	    s = scantrans(s);
	    TERM(TRANS);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'z': case 'Z':
	SNARFWORD;
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    }
}

STAB *
stabent(name,add)
register char *name;
int add;
{
    register STAB *stab;

    for (stab = stab_index[*name]; stab; stab = stab->stab_next) {
	if (strEQ(name,stab->stab_name))
	    return stab;
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

char *
scanreg(s,dest)
register char *s;
char *dest;
{
    register char *d;

    s++;
    d = dest;
    while (isalpha(*s) || isdigit(*s) || *s == '_')
	*d++ = *s++;
    *d = '\0';
    d = dest;
    if (!*d) {
	*d = *s++;
	if (*d == '{') {
	    d = dest;
	    while (*s && *s != '}')
		*d++ = *s++;
	    *d = '\0';
	    d = dest;
	    if (*s)
		s++;
	}
	else
	    d[1] = '\0';
    }
    if (*d == '^' && !isspace(*s))
	*d = *s++ & 31;
    return s;
}

STR *
scanconst(string)
char *string;
{
    register STR *retstr;
    register char *t;
    register char *d;

    if (index(string,'|')) {
	return Nullstr;
    }
    retstr = str_make(string);
    t = str_get(retstr);
    for (d=t; *d; ) {
	switch (*d) {
	case '.': case '[': case '$': case '(': case ')': case '|':
	    *d = '\0';
	    break;
	case '\\':
	    if (index("wWbB0123456789",d[1])) {
		*d = '\0';
		break;
	    }
	    strcpy(d,d+1);
	    switch(*d) {
	    case 'n':
		*d = '\n';
		break;
	    case 't':
		*d = '\t';
		break;
	    case 'f':
		*d = '\f';
		break;
	    case 'r':
		*d = '\r';
		break;
	    }
	    /* FALL THROUGH */
	default:
	    if (d[1] == '*' || d[1] == '+' || d[1] == '?') {
		*d = '\0';
		break;
	    }
	    d++;
	}
    }
    if (!*t) {
	str_free(retstr);
	return Nullstr;
    }
    retstr->str_cur = strlen(retstr->str_ptr);	/* XXX cheating here */
    return retstr;
}

char *
scanpat(s)
register char *s;
{
    register SPAT *spat = (SPAT *) safemalloc(sizeof (SPAT));
    register char *d;

    bzero((char *)spat, sizeof(SPAT));
    spat->spat_next = spat_root;	/* link into spat list */
    spat_root = spat;
    init_compex(&spat->spat_compex);

    switch (*s++) {
    case 'm':
	s++;
	break;
    case '/':
	break;
    case '?':
	spat->spat_flags |= SPAT_USE_ONCE;
	break;
    default:
	fatal("Search pattern not found:\n%s",str_get(linestr));
    }
    s = cpytill(tokenbuf,s,s[-1]);
    if (!*s)
	fatal("Search pattern not terminated:\n%s",str_get(linestr));
    s++;
    if (*tokenbuf == '^') {
	spat->spat_first = scanconst(tokenbuf+1);
	if (spat->spat_first) {
	    spat->spat_flen = strlen(spat->spat_first->str_ptr);
	    if (spat->spat_flen == strlen(tokenbuf+1))
		spat->spat_flags |= SPAT_SCANALL;
	}
    }
    else {
	spat->spat_flags |= SPAT_SCANFIRST;
	spat->spat_first = scanconst(tokenbuf);
	if (spat->spat_first) {
	    spat->spat_flen = strlen(spat->spat_first->str_ptr);
	    if (spat->spat_flen == strlen(tokenbuf))
		spat->spat_flags |= SPAT_SCANALL;
	}
    }	
    if (d = compile(&spat->spat_compex,tokenbuf,TRUE,FALSE))
	fatal(d);
    yylval.arg = make_match(O_MATCH,stab_to_arg(A_STAB,defstab),spat);
    return s;
}

char *
scansubst(s)
register char *s;
{
    register SPAT *spat = (SPAT *) safemalloc(sizeof (SPAT));
    register char *d;

    bzero((char *)spat, sizeof(SPAT));
    spat->spat_next = spat_root;	/* link into spat list */
    spat_root = spat;
    init_compex(&spat->spat_compex);

    s = cpytill(tokenbuf,s+1,*s);
    if (!*s)
	fatal("Substitution pattern not terminated:\n%s",str_get(linestr));
    for (d=tokenbuf; *d; d++) {
	if (*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') {
	    register ARG *arg;

	    spat->spat_runtime = arg = op_new(1);
	    arg->arg_type = O_ITEM;
	    arg[1].arg_type = A_DOUBLE;
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	    goto get_repl;		/* skip compiling for now */
	}
    }
    if (*tokenbuf == '^') {
	spat->spat_first = scanconst(tokenbuf+1);
	if (spat->spat_first)
	    spat->spat_flen = strlen(spat->spat_first->str_ptr);
    }
    else {
	spat->spat_flags |= SPAT_SCANFIRST;
	spat->spat_first = scanconst(tokenbuf);
	if (spat->spat_first)
	    spat->spat_flen = strlen(spat->spat_first->str_ptr);
    }	
    if (d = compile(&spat->spat_compex,tokenbuf,TRUE,FALSE))
	fatal(d);
get_repl:
    s = scanstr(s);
    if (!*s)
	fatal("Substitution replacement not terminated:\n%s",str_get(linestr));
    spat->spat_repl = yylval.arg;
    if (*s == 'g') {
	s++;
	spat->spat_flags &= ~SPAT_USE_ONCE;
    }
    else
	spat->spat_flags |= SPAT_USE_ONCE;
    yylval.arg = make_match(O_SUBST,stab_to_arg(A_STAB,defstab),spat);
    return s;
}

ARG *
make_split(stab,arg)
register STAB *stab;
register ARG *arg;
{
    if (arg->arg_type != O_MATCH) {
	register SPAT *spat = (SPAT *) safemalloc(sizeof (SPAT));
	register char *d;

	bzero((char *)spat, sizeof(SPAT));
	spat->spat_next = spat_root;	/* link into spat list */
	spat_root = spat;
	init_compex(&spat->spat_compex);

	spat->spat_runtime = arg;
	arg = make_match(O_MATCH,stab_to_arg(A_STAB,defstab),spat);
    }
    arg->arg_type = O_SPLIT;
    arg[2].arg_ptr.arg_spat->spat_repl = stab_to_arg(A_STAB,aadd(stab));
    return arg;
}

char *
expand_charset(s)
register char *s;
{
    char t[512];
    register char *d = t;
    register int i;

    while (*s) {
	if (s[1] == '-' && s[2]) {
	    for (i = s[0]; i <= s[2]; i++)
		*d++ = i;
	    s += 3;
	}
	else
	    *d++ = *s++;
    }
    *d = '\0';
    return savestr(t);
}

char *
scantrans(s)
register char *s;
{
    ARG *arg =
	l(make_op(O_TRANS,2,stab_to_arg(A_STAB,defstab),Nullarg,Nullarg,0));
    register char *t;
    register char *r;
    register char *tbl = safemalloc(256);
    register int i;

    arg[2].arg_type = A_NULL;
    arg[2].arg_ptr.arg_cval = tbl;
    for (i=0; i<256; i++)
	tbl[i] = 0;
    s = scanstr(s);
    if (!*s)
	fatal("Translation pattern not terminated:\n%s",str_get(linestr));
    t = expand_charset(str_get(yylval.arg[1].arg_ptr.arg_str));
    free_arg(yylval.arg);
    s = scanstr(s-1);
    if (!*s)
	fatal("Translation replacement not terminated:\n%s",str_get(linestr));
    r = expand_charset(str_get(yylval.arg[1].arg_ptr.arg_str));
    free_arg(yylval.arg);
    yylval.arg = arg;
    if (!*r) {
	safefree(r);
	r = t;
    }
    for (i = 0; t[i]; i++) {
	if (!r[i])
	    r[i] = r[i-1];
	tbl[t[i] & 0377] = r[i];
    }
    if (r != t)
	safefree(r);
    safefree(t);
    return s;
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
	opt_arg(cmd,1);
	cmd->c_flags |= CF_COND;
    }
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
	opt_arg(cmd,1);
	cmd->c_flags |= CF_COND;
    }
    return cmd;
}

void
opt_arg(cmd,fliporflop)
register CMD *cmd;
int fliporflop;
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

    /* Turn "if (!expr)" into "unless (expr)" */

    while (arg->arg_type == O_NOT && arg[1].arg_type == A_EXPR) {
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
	    cmd->c_first = arg[flp].arg_ptr.arg_str;
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
		arg[2].arg_ptr.arg_spat->spat_first ) {
	    cmd->c_stab  = arg[1].arg_ptr.arg_stab;
	    cmd->c_first = arg[2].arg_ptr.arg_spat->spat_first;
	    cmd->c_flen  = arg[2].arg_ptr.arg_spat->spat_flen;
	    if (arg[2].arg_ptr.arg_spat->spat_flags & SPAT_SCANALL &&
		(arg->arg_type == O_MATCH || arg->arg_type == O_NMATCH) )
		sure |= CF_EQSURE;		/* (SUBST must be forced even */
						/* if we know it will work.) */
	    arg[2].arg_ptr.arg_spat->spat_first = Nullstr;
	    arg[2].arg_ptr.arg_spat->spat_flen = 0; /* only one chk */
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
		    arg[2].arg_type = A_SINGLE;		/* don't do twice */
		    arg[2].arg_ptr.arg_str = &str_yes;
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
		cmd->c_first = arg[2].arg_ptr.arg_str;
		cmd->c_flen  = 30000;
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
	    opt_arg(arg[4].arg_ptr.arg_cmd,2);
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
	init_compex(&spat->spat_compex);

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
    opt_arg(cmd,1);
    cmd->c_flags |= CF_COND;
    return cmd;
}

CMD *
addloop(cmd, arg)
register CMD *cmd;
register ARG *arg;
{
    cmd->c_expr = arg;
    opt_arg(cmd,1);
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

char *
scanstr(s)
register char *s;
{
    register char term;
    register char *d;
    register ARG *arg;
    register bool makesingle = FALSE;
    char *leave = "\\$nrtfb0123456789";	/* which backslash sequences to keep */

    arg = op_new(1);
    yylval.arg = arg;
    arg->arg_type = O_ITEM;

    switch (*s) {
    default:			/* a substitution replacement */
	arg[1].arg_type = A_DOUBLE;
	makesingle = TRUE;	/* maybe disable runtime scanning */
	term = *s;
	if (term == '\'')
	    leave = Nullch;
	goto snarf_it;
    case '0':
	{
	    long i;
	    int shift;

	    arg[1].arg_type = A_SINGLE;
	    if (s[1] == 'x') {
		shift = 4;
		s += 2;
	    }
	    else if (s[1] == '.')
		goto decimal;
	    else
		shift = 3;
	    i = 0;
	    for (;;) {
		switch (*s) {
		default:
		    goto out;
		case '8': case '9':
		    if (shift != 4)
			fatal("Illegal octal digit at line %d",line);
		    /* FALL THROUGH */
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7':
		    i <<= shift;
		    i += *s++ & 15;
		    break;
		case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
		case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
		    if (shift != 4)
			goto out;
		    i <<= 4;
		    i += (*s++ & 7) + 9;
		    break;
		}
	    }
	  out:
	    sprintf(tokenbuf,"%d",i);
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	}
	break;
    case '1': case '2': case '3': case '4': case '5':
    case '6': case '7': case '8': case '9': case '.':
      decimal:
	arg[1].arg_type = A_SINGLE;
	d = tokenbuf;
	while (isdigit(*s) || *s == '_')
	    *d++ = *s++;
	if (*s == '.' && index("0123456789eE",s[1]))
	    *d++ = *s++;
	while (isdigit(*s) || *s == '_')
	    *d++ = *s++;
	if (index("eE",*s) && index("+-0123456789",s[1]))
	    *d++ = *s++;
	if (*s == '+' || *s == '-')
	    *d++ = *s++;
	while (isdigit(*s))
	    *d++ = *s++;
	*d = '\0';
	arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	break;
    case '\'':
	arg[1].arg_type = A_SINGLE;
	term = *s;
	leave = Nullch;
	goto snarf_it;

    case '<':
	arg[1].arg_type = A_READ;
	s = cpytill(tokenbuf,s+1,'>');
	if (!*tokenbuf)
	    strcpy(tokenbuf,"ARGV");
	if (*s)
	    s++;
	if (rsfp == stdin && strEQ(tokenbuf,"stdin"))
	    fatal("Can't get both program and data from <stdin>\n");
	arg[1].arg_ptr.arg_stab = stabent(tokenbuf,TRUE);
	arg[1].arg_ptr.arg_stab->stab_io = stio_new();
	if (strEQ(tokenbuf,"ARGV")) {
	    aadd(arg[1].arg_ptr.arg_stab);
	    arg[1].arg_ptr.arg_stab->stab_io->flags |= IOF_ARGV|IOF_START;
	}
	break;
    case '"': 
	arg[1].arg_type = A_DOUBLE;
	makesingle = TRUE;	/* maybe disable runtime scanning */
	term = *s;
	goto snarf_it;
    case '`':
	arg[1].arg_type = A_BACKTICK;
	term = *s;
      snarf_it:
	{
	    STR *tmpstr;
	    int sqstart = line;
	    char *tmps;

	    tmpstr = str_new(strlen(s));
	    s = str_append_till(tmpstr,s+1,term,leave);
	    while (!*s) {	/* multiple line string? */
		s = str_gets(linestr, rsfp);
		if (!*s)
		    fatal("EOF in string at line %d\n",sqstart);
		line++;
		s = str_append_till(tmpstr,s,term,leave);
	    }
	    s++;
	    if (term == '\'') {
		arg[1].arg_ptr.arg_str = tmpstr;
		break;
	    }
	    tmps = s;
	    s = d = tmpstr->str_ptr;	/* assuming shrinkage only */
	    while (*s) {
		if (*s == '$' && s[1]) {
		    makesingle = FALSE;	/* force interpretation */
		    if (!isalpha(s[1])) {	/* an internal register? */
			int len;

			len = scanreg(s,tokenbuf) - s;
			stabent(tokenbuf,TRUE);	/* make sure it's created */
			while (len--)
			    *d++ = *s++;
			continue;
		    }
		}
		else if (*s == '\\' && s[1]) {
		    s++;
		    switch (*s) {
		    default:
		      defchar:
			if (!leave || index(leave,*s))
			    *d++ = '\\';
			*d++ = *s++;
			continue;
		    case '0': case '1': case '2': case '3':
		    case '4': case '5': case '6': case '7':
			*d = *s++ - '0';
			if (index("01234567",*s)) {
			    *d <<= 3;
			    *d += *s++ - '0';
			}
			else if (!index("`\"",term)) {	/* oops, a subpattern */
			    s--;
			    goto defchar;
			}
			if (index("01234567",*s)) {
			    *d <<= 3;
			    *d += *s++ - '0';
			}
			d++;
			continue;
		    case 'b':
			*d++ = '\b';
			break;
		    case 'n':
			*d++ = '\n';
			break;
		    case 'r':
			*d++ = '\r';
			break;
		    case 'f':
			*d++ = '\f';
			break;
		    case 't':
			*d++ = '\t';
			break;
		    }
		    s++;
		    continue;
		}
		*d++ = *s++;
	    }
	    *d = '\0';
	    if (arg[1].arg_type == A_DOUBLE) {
		if (makesingle)
		    arg[1].arg_type = A_SINGLE;	/* now we can optimize on it */
		else
		    leave = "\\";
		for (d = s = tmpstr->str_ptr; *s; *d++ = *s++) {
		    if (*s == '\\' && (!leave || index(leave,s[1])))
			s++;
		}
		*d = '\0';
	    }
	    tmpstr->str_cur = d - tmpstr->str_ptr;	/* XXX cheat */
	    arg[1].arg_ptr.arg_str = tmpstr;
	    s = tmps;
	    break;
	}
    }
    return s;
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
		else if (chld->arg_type == O_ARRAY && chld->arg_len == 1)
		    arg[1].arg_flags |= AF_SPECIAL;
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
	      (chld[1].arg_type == A_READ ||
	       chld[1].arg_type == A_DOUBLE ||
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
	    while (i--)
		str_scat(str,s1);
	    break;
	case O_MULTIPLY:
	    value = str_gnum(s1);
	    str_numset(str,value * str_gnum(s2));
	    break;
	case O_DIVIDE:
	    value = str_gnum(s1);
	    str_numset(str,value / str_gnum(s2));
	    break;
	case O_MODULO:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((long)value) % ((long)str_gnum(s2))));
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
	    str_numset(str,(double)(((long)value) << ((long)str_gnum(s2))));
	    break;
	case O_RIGHT_SHIFT:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((long)value) >> ((long)str_gnum(s2))));
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
	    str_numset(str,(double)(((long)value) & ((long)str_gnum(s2))));
	    break;
	case O_XOR:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((long)value) ^ ((long)str_gnum(s2))));
	    break;
	case O_BIT_OR:
	    value = str_gnum(s1);
	    str_numset(str,(double)(((long)value) | ((long)str_gnum(s2))));
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
	    tmps = str_get(s1);
	    str_set(str,crypt(tmps,str_get(s2)));
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
	    modf(str_gnum(s1),&value);
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

    arg->arg_flags |= AF_COMMON;	/* XXX should cross-match */

    /* see if it's an array reference */

    if (arg[1].arg_type == A_EXPR) {
	arg1 = arg[1].arg_ptr.arg_arg;

	if (arg1->arg_type == O_LIST && arg->arg_type != O_ITEM) {
						/* assign to list */
	    arg[1].arg_flags |= AF_SPECIAL;
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
		arg[2].arg_flags |= AF_SPECIAL;
	    }
	    else
		arg1->arg_type = O_LARRAY;	/* assign to array elem */
	}
	else if (arg1->arg_type == O_HASH)
	    arg1->arg_type = O_LHASH;
	else {
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
	    arg[j++] = node[1];
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
    if (arg->arg_flags & AF_LISTISH)
	arg = make_op(O_LIST,1,arg,Nullarg,Nullarg,0);
    return arg;
}

ARG *
stab_to_arg(atype,stab)
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
	fprintf(stderr,"make_match SPAT=%lx\n",spat);
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
    char *tmps;	/* used by True macro */

    /* hoist "while (<channel>)" up into command block */

    if (arg && arg->arg_type == O_ITEM && arg[1].arg_type == A_READ) {
	cmd->c_flags &= ~CF_OPTIMIZE;	/* clear optimization type */
	cmd->c_flags |= CFT_GETS;	/* and set it to do the input */
	cmd->c_stab = arg[1].arg_ptr.arg_stab;
	if (arg[1].arg_ptr.arg_stab->stab_io->flags & IOF_ARGV) {
	    cmd->c_expr = l(make_op(O_ASSIGN, 2,	/* fake up "$_ =" */
	       stab_to_arg(A_LVAL,defstab), arg, Nullarg,1 ));
	}
	else {
	    free_arg(arg);
	    cmd->c_expr = Nullarg;
	}
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

FCMD *
load_format()
{
    FCMD froot;
    FCMD *flinebeg;
    register FCMD *fprev = &froot;
    register FCMD *fcmd;
    register char *s;
    register char *t;
    register char tmpchar;
    bool noblank;

    while ((s = str_gets(linestr,rsfp)) != Nullch) {
	line++;
	if (strEQ(s,".\n")) {
	    bufptr = s;
	    return froot.f_next;
	}
	if (*s == '#')
	    continue;
	flinebeg = Nullfcmd;
	noblank = FALSE;
	while (*s) {
	    fcmd = (FCMD *)safemalloc(sizeof (FCMD));
	    bzero((char*)fcmd, sizeof (FCMD));
	    fprev->f_next = fcmd;
	    fprev = fcmd;
	    for (t=s; *t && *t != '@' && *t != '^'; t++) {
		if (*t == '~') {
		    noblank = TRUE;
		    *t = ' ';
		}
	    }
	    tmpchar = *t;
	    *t = '\0';
	    fcmd->f_pre = savestr(s);
	    fcmd->f_presize = strlen(s);
	    *t = tmpchar;
	    s = t;
	    if (!*s) {
		if (noblank)
		    fcmd->f_flags |= FC_NOBLANK;
		break;
	    }
	    if (!flinebeg)
		flinebeg = fcmd;		/* start values here */
	    if (*s++ == '^')
		fcmd->f_flags |= FC_CHOP;	/* for doing text filling */
	    switch (*s) {
	    case '*':
		fcmd->f_type = F_LINES;
		*s = '\0';
		break;
	    case '<':
		fcmd->f_type = F_LEFT;
		while (*s == '<')
		    s++;
		break;
	    case '>':
		fcmd->f_type = F_RIGHT;
		while (*s == '>')
		    s++;
		break;
	    case '|':
		fcmd->f_type = F_CENTER;
		while (*s == '|')
		    s++;
		break;
	    default:
		fcmd->f_type = F_LEFT;
		break;
	    }
	    if (fcmd->f_flags & FC_CHOP && *s == '.') {
		fcmd->f_flags |= FC_MORE;
		while (*s == '.')
		    s++;
	    }
	    fcmd->f_size = s-t;
	}
	if (flinebeg) {
	  again:
	    if ((bufptr = str_gets(linestr ,rsfp)) == Nullch)
		goto badform;
	    line++;
	    if (strEQ(bufptr,".\n")) {
		yyerror("Missing values line");
		return froot.f_next;
	    }
	    if (*bufptr == '#')
		goto again;
	    lex_newlines = TRUE;
	    while (flinebeg || *bufptr) {
		switch(yylex()) {
		default:
		    yyerror("Bad value in format");
		    *bufptr = '\0';
		    break;
		case '\n':
		    if (flinebeg)
			yyerror("Missing value in format");
		    *bufptr = '\0';
		    break;
		case REG:
		    yylval.arg = stab_to_arg(A_LVAL,yylval.stabval);
		    /* FALL THROUGH */
		case RSTRING:
		    if (!flinebeg)
			yyerror("Extra value in format");
		    else {
			flinebeg->f_expr = yylval.arg;
			do {
			    flinebeg = flinebeg->f_next;
			} while (flinebeg && flinebeg->f_size == 0);
		    }
		    break;
		case ',': case ';':
		    continue;
		}
	    }
	    lex_newlines = FALSE;
	}
    }
  badform:
    bufptr = str_get(linestr);
    yyerror("Format not terminated");
    return froot.f_next;
}

STR *
do_eval(str)
STR *str;
{
    int retval;
    CMD *myroot;

    in_eval++;
    str_set(stabent("@",TRUE)->stab_val,"");
    line = 1;
    str_sset(linestr,str);
    bufptr = str_get(linestr);
    if (setjmp(eval_env))
	retval = 1;
    else
	retval = yyparse();
    myroot = eval_root;		/* in case cmd_exec does another eval! */
    if (retval)
	str = &str_no;
    else {
	str = cmd_exec(eval_root);
	cmd_free(myroot);	/* can't free on error, for some reason */
    }
    in_eval--;
    return str;
}

cmd_free(cmd)
register CMD *cmd;
{
    register CMD *tofree;
    register CMD *head = cmd;

    while (cmd) {
	if (cmd->c_label)
	    safefree(cmd->c_label);
	if (cmd->c_first)
	    str_free(cmd->c_first);
	if (cmd->c_spat)
	    spat_free(cmd->c_spat);
	if (cmd->c_expr)
	    arg_free(cmd->c_expr);
	switch (cmd->c_type) {
	case C_WHILE:
	case C_BLOCK:
	case C_IF:
	    if (cmd->ucmd.ccmd.cc_true)
		cmd_free(cmd->ucmd.ccmd.cc_true);
	    if (cmd->c_type == C_IF && cmd->ucmd.ccmd.cc_alt)
		cmd_free(cmd->ucmd.ccmd.cc_alt,Nullcmd);
	    break;
	case C_EXPR:
	    if (cmd->ucmd.acmd.ac_stab)
		arg_free(cmd->ucmd.acmd.ac_stab);
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
	case A_STAB:
	case A_LVAL:
	case A_READ:
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
    free_compex(&spat->spat_compex);

    /* now unlink from spat list */
    if (spat_root == spat)
	spat_root = spat->spat_next;
    else {
	for (sp = spat_root; sp->spat_next != spat; sp = sp->spat_next) ;
	sp->spat_next = spat->spat_next;
    }

    safefree((char*)spat);
}
