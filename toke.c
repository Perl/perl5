/* $Header: toke.c,v 2.0 88/06/05 00:11:16 root Exp $
 *
 * $Log:	toke.c,v $
 * Revision 2.0  88/06/05  00:11:16  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"

#define CLINE (cmdline = (line < cmdline ? line : cmdline))

#define RETURN(retval) return (bufptr = s,(int)retval)
#define OPERATOR(retval) return (expectterm = TRUE,bufptr = s,(int)retval)
#define TERM(retval) return (CLINE, expectterm = FALSE,bufptr = s,(int)retval)
#define LOOPX(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)LOOPEX)
#define UNI(f) return(yylval.ival = f,expectterm = TRUE,bufptr = s,(int)UNIOP)
#define FTST(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)FILETEST)
#define FUN0(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC0)
#define FUN1(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC1)
#define FUN2(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC2)
#define FUN3(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC3)
#define SFUN(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)STABFUN)
#define LFUN(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)LVALFUN)

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
	    "Unrecognized character %c in file %s line %ld--ignoring.\n",
	     *s++,filename,(long)line);
	goto retry;
    case 0:
	s = str_get(linestr);
	*s = '\0';
	if (firstline && (minus_n || minus_p)) {
	    firstline = FALSE;
	    str_set(linestr,"line: while (<>) {");
	    if (minus_a)
		str_cat(linestr,"@F=split(' ');");
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
	    if (minus_n || minus_p) {
		str_set(linestr,minus_p ? "}continue{print;" : "");
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
    case ' ': case '\t': case '\f':
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
	    if (*s == '"') {
		s++;
		s[strlen(s)-1] = '\0';	/* wipe out trailing quote */
	    }
	    if (*s)
		filename = savestr(s);
	    else
		filename = savestr(origfilename);
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
    case '-':
	if (s[1] && isalpha(s[1]) && !isalpha(s[2])) {
	    s++;
	    switch (*s++) {
	    case 'r': FTST(O_FTEREAD);
	    case 'w': FTST(O_FTEWRITE);
	    case 'x': FTST(O_FTEEXEC);
	    case 'o': FTST(O_FTEOWNED);
	    case 'R': FTST(O_FTRREAD);
	    case 'W': FTST(O_FTRWRITE);
	    case 'X': FTST(O_FTREXEC);
	    case 'O': FTST(O_FTROWNED);
	    case 'e': FTST(O_FTIS);
	    case 'z': FTST(O_FTZERO);
	    case 's': FTST(O_FTSIZE);
	    case 'f': FTST(O_FTFILE);
	    case 'd': FTST(O_FTDIR);
	    case 'l': FTST(O_FTLINK);
	    case 'p': FTST(O_FTPIPE);
	    case 'S': FTST(O_FTSOCK);
	    case 'u': FTST(O_FTSUID);
	    case 'g': FTST(O_FTSGID);
	    case 'k': FTST(O_FTSVTX);
	    case 'b': FTST(O_FTBLK);
	    case 'c': FTST(O_FTCHR);
	    case 't': FTST(O_FTTTY);
	    case 'T': FTST(O_FTTEXT);
	    case 'B': FTST(O_FTBINARY);
	    default:
		s -= 2;
		break;
	    }
	}
	/*FALL THROUGH*/
    case '+':
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
    case '[':
	tmp = *s++;
	OPERATOR(tmp);
    case '{':
	tmp = *s++;
	if (isspace(*s) || *s == '#')
	    cmdline = NOLINE;   /* invalidate current command line number */
	OPERATOR(tmp);
    case ';':
	if (line < cmdline)
	    cmdline = line;
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
	    LFUN(O_CHOP);
	if (strEQ(d,"chmod")) {
	    yylval.ival = O_CHMOD;
	    OPERATOR(LISTOP);
	}
	if (strEQ(d,"chown")) {
	    yylval.ival = O_CHOWN;
	    OPERATOR(LISTOP);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'd': case 'D':
	SNARFWORD;
	if (strEQ(d,"do"))
	    OPERATOR(DO);
	if (strEQ(d,"die"))
	    UNI(O_DIE);
	if (strEQ(d,"delete"))
	    OPERATOR(DELETE);
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'e': case 'E':
	SNARFWORD;
	if (strEQ(d,"else"))
	    OPERATOR(ELSE);
	if (strEQ(d,"elsif")) {
	    yylval.ival = line;
	    OPERATOR(ELSIF);
	}
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
	    OPERATOR(LISTOP);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'f': case 'F':
	SNARFWORD;
	if (strEQ(d,"for"))
	    OPERATOR(FOR);
	if (strEQ(d,"foreach"))
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
	if (strEQ(d,"if")) {
	    yylval.ival = line;
	    OPERATOR(IF);
	}
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
	    OPERATOR(LISTOP);
	}
	yylval.cval = savestr(d);
	OPERATOR(WORD);
    case 'l': case 'L':
	SNARFWORD;
	if (strEQ(d,"last"))
	    LOOPX(O_LAST);
	if (strEQ(d,"local"))
	    OPERATOR(LOCAL);
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
	    OPERATOR(LISTOP);
	}
	if (strEQ(d,"printf")) {
	    yylval.ival = O_PRTF;
	    OPERATOR(LISTOP);
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
	if (strEQ(d,"study")) {
	    sawstudy++;
	    LFUN(O_STUDY);
	}
	if (strEQ(d,"sqrt"))
	    FUN1(O_SQRT);
	if (strEQ(d,"sleep"))
	    UNI(O_SLEEP);
	if (strEQ(d,"system")) {
	    yylval.ival = O_SYSTEM;
	    OPERATOR(LISTOP);
	}
	if (strEQ(d,"symlink"))
	    FUN2(O_SYMLINK);
	if (strEQ(d,"sort")) {
	    yylval.ival = O_SORT;
	    OPERATOR(LISTOP);
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
	if (strEQ(d,"until")) {
	    yylval.ival = line;
	    OPERATOR(UNTIL);
	}
	if (strEQ(d,"unless")) {
	    yylval.ival = line;
	    OPERATOR(UNLESS);
	}
	if (strEQ(d,"umask"))
	    FUN1(O_UMASK);
	if (strEQ(d,"unshift")) {
	    yylval.ival = O_UNSHIFT;
	    OPERATOR(PUSH);
	}
	if (strEQ(d,"unlink")) {
	    yylval.ival = O_UNLINK;
	    OPERATOR(LISTOP);
	}
	if (strEQ(d,"utime")) {
	    yylval.ival = O_UTIME;
	    OPERATOR(LISTOP);
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
	if (strEQ(d,"while")) {
	    yylval.ival = line;
	    OPERATOR(WHILE);
	}
	if (strEQ(d,"wait"))
	    FUN0(O_WAIT);
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

char *
scanreg(s,dest)
register char *s;
char *dest;
{
    register char *d;

    s++;
    d = dest;
    if (isdigit(*s)) {
	while (isdigit(*s) || *s == '_')
	    *d++ = *s++;
    }
    else {
	while (isalpha(*s) || isdigit(*s) || *s == '_')
	    *d++ = *s++;
    }
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
    *(long*)&retstr->str_nval = 100;
    for (d=t; *d; ) {
	switch (*d) {
	case '.': case '[': case '$': case '(': case ')': case '|':
	    *d = '\0';
	    break;
	case '\\':
	    if (index("wWbB0123456789sSdD",d[1])) {
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
    retstr->str_cur = strlen(retstr->str_ptr);
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

    switch (*s++) {
    case 'm':
	s++;
	break;
    case '/':
	break;
    case '?':
	spat->spat_flags |= SPAT_ONCE;
	break;
    default:
	fatal("panic: scanpat");
    }
    s = cpytill(tokenbuf,s,s[-1]);
    if (!*s)
	fatal("Search pattern not terminated");
    s++;
    if (*s == 'i') {
	s++;
	spat->spat_flags |= SPAT_FOLD;
    }
    for (d=tokenbuf; *d; d++) {
	if (*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') {
	    register ARG *arg;

	    spat->spat_runtime = arg = op_new(1);
	    arg->arg_type = O_ITEM;
	    arg[1].arg_type = A_DOUBLE;
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	    goto got_pat;		/* skip compiling for now */
	}
    }
    if (!(spat->spat_flags & SPAT_FOLD)) {
	if (*tokenbuf == '^') {
	    spat->spat_short = scanconst(tokenbuf+1);
	    if (spat->spat_short) {
		spat->spat_slen = strlen(spat->spat_short->str_ptr);
		if (spat->spat_slen == strlen(tokenbuf+1))
		    spat->spat_flags |= SPAT_ALL;
	    }
	}
	else {
	    spat->spat_flags |= SPAT_SCANFIRST;
	    spat->spat_short = scanconst(tokenbuf);
	    if (spat->spat_short) {
		spat->spat_slen = strlen(spat->spat_short->str_ptr);
		if (spat->spat_slen == strlen(tokenbuf))
		    spat->spat_flags |= SPAT_ALL;
	    }
	}	
    }
    spat->spat_regexp = regcomp(tokenbuf,spat->spat_flags & SPAT_FOLD,1);
    hoistmust(spat);
  got_pat:
    yylval.arg = make_match(O_MATCH,stab2arg(A_STAB,defstab),spat);
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

    s = cpytill(tokenbuf,s+1,*s);
    if (!*s)
	fatal("Substitution pattern not terminated");
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
	spat->spat_short = scanconst(tokenbuf+1);
	if (spat->spat_short)
	    spat->spat_slen = strlen(spat->spat_short->str_ptr);
    }
    else {
	spat->spat_flags |= SPAT_SCANFIRST;
	spat->spat_short = scanconst(tokenbuf);
	if (spat->spat_short)
	    spat->spat_slen = strlen(spat->spat_short->str_ptr);
    }	
    d = savestr(tokenbuf);
get_repl:
    s = scanstr(s);
    if (!*s)
	fatal("Substitution replacement not terminated");
    spat->spat_repl = yylval.arg;
    spat->spat_flags |= SPAT_ONCE;
    while (*s == 'g' || *s == 'i') {
	if (*s == 'g') {
	    s++;
	    spat->spat_flags &= ~SPAT_ONCE;
	}
	if (*s == 'i') {
	    s++;
	    spat->spat_flags |= SPAT_FOLD;
	}
    }
    if (!spat->spat_runtime) {
	spat->spat_regexp = regcomp(d, spat->spat_flags & SPAT_FOLD,1);
	hoistmust(spat);
	safefree(d);
    }
    if (spat->spat_flags & SPAT_FOLD) {		/* Oops, disable optimization */
	str_free(spat->spat_short);
	spat->spat_short = Nullstr;
	spat->spat_slen = 0;
    }
    yylval.arg = make_match(O_SUBST,stab2arg(A_STAB,defstab),spat);
    return s;
}

hoistmust(spat)
register SPAT *spat;
{
    if (spat->spat_regexp->regmust) {	/* is there a better short-circuit? */
	if (spat->spat_short &&
	  strEQ(spat->spat_short->str_ptr,spat->spat_regexp->regmust->str_ptr)){
	    if (spat->spat_flags & SPAT_SCANFIRST) {
		str_free(spat->spat_short);
		spat->spat_short = Nullstr;
	    }
	    else {
		str_free(spat->spat_regexp->regmust);
		spat->spat_regexp->regmust = Nullstr;
		return;
	    }
	}
	if (!spat->spat_short ||	/* promote the better string */
	  ((spat->spat_flags & SPAT_SCANFIRST) &&
	   (spat->spat_short->str_cur < spat->spat_regexp->regmust->str_cur) )){
	    str_free(spat->spat_short);		/* ok if null */
	    spat->spat_short = spat->spat_regexp->regmust;
	    spat->spat_regexp->regmust = Nullstr;
	    spat->spat_flags |= SPAT_SCANFIRST;
	}
    }
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
	l(make_op(O_TRANS,2,stab2arg(A_STAB,defstab),Nullarg,Nullarg,0));
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
	fatal("Translation pattern not terminated");
    t = expand_charset(str_get(yylval.arg[1].arg_ptr.arg_str));
    free_arg(yylval.arg);
    s = scanstr(s-1);
    if (!*s)
	fatal("Translation replacement not terminated");
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

char *
scanstr(s)
register char *s;
{
    register char term;
    register char *d;
    register ARG *arg;
    register bool makesingle = FALSE;
    register STAB *stab;
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
			fatal("Illegal octal digit");
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
	    sprintf(tokenbuf,"%ld",i);
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	}
	break;
    case '1': case '2': case '3': case '4': case '5':
    case '6': case '7': case '8': case '9': case '.':
      decimal:
	arg[1].arg_type = A_SINGLE;
	d = tokenbuf;
	while (isdigit(*s) || *s == '_') {
	    if (*s == '_')
		s++;
	    else
		*d++ = *s++;
	}
	if (*s == '.' && index("0123456789eE",s[1])) {
	    *d++ = *s++;
	    while (isdigit(*s) || *s == '_') {
		if (*s == '_')
		    s++;
		else
		    *d++ = *s++;
	    }
	}
	if (index("eE",*s) && index("+-0123456789",s[1])) {
	    *d++ = *s++;
	    if (*s == '+' || *s == '-')
		*d++ = *s++;
	    while (isdigit(*s))
		*d++ = *s++;
	}
	*d = '\0';
	arg[1].arg_ptr.arg_str = str_make(tokenbuf);
	break;
    case '\'':
	arg[1].arg_type = A_SINGLE;
	term = *s;
	leave = Nullch;
	goto snarf_it;

    case '<':
	d = tokenbuf;
	s = cpytill(d,s+1,'>');
	if (*s)
	    s++;
	if (*d == '$') d++;
	while (*d && (isalpha(*d) || isdigit(*d) || *d == '_')) d++;
	if (*d) {
	    d = tokenbuf;
	    arg[1].arg_type = A_GLOB;
	    d = savestr(d);
	    arg[1].arg_ptr.arg_stab = stab = genstab();
	    stab->stab_io = stio_new();
	    stab->stab_val = str_make(d);
	}
	else {
	    d = tokenbuf;
	    if (!*d)
		strcpy(d,"ARGV");
	    if (*d == '$') {
		arg[1].arg_type = A_INDREAD;
		arg[1].arg_ptr.arg_stab = stabent(d+1,TRUE);
	    }
	    else {
		arg[1].arg_type = A_READ;
		if (rsfp == stdin && strEQ(d,"stdin"))
		    fatal("Can't get both program and data from <stdin>");
		arg[1].arg_ptr.arg_stab = stabent(d,TRUE);
		arg[1].arg_ptr.arg_stab->stab_io = stio_new();
		if (strEQ(d,"ARGV")) {
		    aadd(arg[1].arg_ptr.arg_stab);
		    arg[1].arg_ptr.arg_stab->stab_io->flags |=
		      IOF_ARGV|IOF_START;
		}
	    }
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
		if (!s) {
		    line = sqstart;
		    fatal("EOF in string");
		}
		line++;
		s = str_append_till(tmpstr,s,term,leave);
	    }
	    s++;
	    if (term == '\'') {
		arg[1].arg_ptr.arg_str = tmpstr;
		break;
	    }
	    tmps = s;
	    s = tmpstr->str_ptr;
	    while (*s) {		/* see if we can make SINGLE */
		if (*s == '\\' && s[1] && isdigit(s[1]) && !isdigit(s[2]) &&
		  !index("`\"",term) )
		    *s = '$';		/* grandfather \digit in subst */
		if (*s == '$' && s[1] && s[1] != ')' && s[1] != '|') {
		    makesingle = FALSE;	/* force interpretation */
		}
		else if (*s == '\\' && s[1]) {
		    s++;
		}
		s++;
	    }
	    s = d = tmpstr->str_ptr;	/* assuming shrinkage only */
	    while (*s) {
		if (*s == '$' && s[1] && s[1] != ')' && s[1] != '|') {
		    int len;

		    len = scanreg(s,tokenbuf) - s;
		    stabent(tokenbuf,TRUE);	/* make sure it's created */
		    while (len--)
			*d++ = *s++;
		    continue;
		}
		else if (*s == '\\' && s[1]) {
		    s++;
		    switch (*s) {
		    default:
			if (!makesingle && (!leave || index(leave,*s)))
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

	    if (arg[1].arg_type == A_DOUBLE && makesingle)
		arg[1].arg_type = A_SINGLE;	/* now we can optimize on it */

	    tmpstr->str_cur = d - tmpstr->str_ptr;	/* XXX cheat */
	    arg[1].arg_ptr.arg_str = tmpstr;
	    s = tmps;
	    break;
	}
    }
    return s;
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
		    yylval.arg = stab2arg(A_LVAL,yylval.stabval);
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
