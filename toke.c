/* $Header: toke.c,v 3.0.1.1 89/10/26 23:26:21 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	toke.c,v $
 * Revision 3.0.1.1  89/10/26  23:26:21  lwall
 * patch1: disambiguated word after "sort" better
 * 
 * Revision 3.0  89/10/18  15:32:33  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"

char *reparse;		/* if non-null, scanreg found ${foo[$bar]} */

#define CLINE (cmdline = (line < cmdline ? line : cmdline))

#define META(c) ((c) | 128)

#define RETURN(retval) return (bufptr = s,(int)retval)
#define OPERATOR(retval) return (expectterm = TRUE,bufptr = s,(int)retval)
#define TERM(retval) return (CLINE, expectterm = FALSE,bufptr = s,(int)retval)
#define LOOPX(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)LOOPEX)
#define FTST(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)FILETEST)
#define FUN0(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC0)
#define FUN1(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC1)
#define FUN2(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC2)
#define FUN3(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)FUNC3)
#define FL(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FLIST)
#define FL2(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FLIST2)
#define HFUN(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)HSHFUN)
#define HFUN3(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)HSHFUN3)
#define LFUN(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)LVALFUN)
#define LFUN4(f) return(yylval.ival = f,expectterm = FALSE,bufptr = s,(int)LFUNC4)
#define AOP(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)ADDOP)
#define MOP(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)MULOP)
#define EOP(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)EQOP)
#define ROP(f) return(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)RELOP)
#define FOP(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP)
#define FOP2(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP2)
#define FOP3(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP3)
#define FOP4(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP4)
#define FOP22(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP22)
#define FOP25(f) return(yylval.ival=f,expectterm = FALSE,bufptr = s,(int)FILOP25)

/* This bit of chicanery makes a unary function followed by
 * a parenthesis into a function with one argument, highest precedence.
 */
#define UNI(f) return(yylval.ival = f,expectterm = TRUE,bufptr = s, \
	(*s == '(' || (s = skipspace(s), *s == '(') ? (int)FUNC1 : (int)UNIOP) )

/* This does similarly for list operators, merely by pretending that the
 * paren came before the listop rather than after.
 */
#define LOP(f) return(*s == '(' || (s = skipspace(s), *s == '(') ? \
	(*s = META('('), bufptr = oldbufptr, '(') : \
	(yylval.ival=f,expectterm = TRUE,bufptr = s,(int)LISTOP))

char *
skipspace(s)
register char *s;
{
    while (s < bufend && isascii(*s) && isspace(*s))
	s++;
    return s;
}

yylex()
{
    register char *s = bufptr;
    register char *d;
    register int tmp;
    static bool in_format = FALSE;
    static bool firstline = TRUE;
    extern int yychar;		/* last token */

    oldoldbufptr = oldbufptr;
    oldbufptr = s;

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
	if ((*s & 127) == '(')
	    *s++ = '(';
	else
	    warn("Unrecognized character \\%03o ignored", *s++);
	goto retry;
    case 0:
	if (!rsfp)
	    RETURN(0);
	if (s++ < bufend)
	    goto retry;			/* ignore stray nulls */
	if (firstline) {
	    firstline = FALSE;
	    if (minus_n || minus_p || perldb) {
		str_set(linestr,"");
		if (perldb)
		    str_cat(linestr,"do 'perldb.pl'; print $@;");
		if (minus_n || minus_p) {
		    str_cat(linestr,"line: while (<>) {");
		    if (minus_a)
			str_cat(linestr,"@F=split(' ');");
		}
		oldoldbufptr = oldbufptr = s = str_get(linestr);
		bufend = linestr->str_ptr + linestr->str_cur;
		goto retry;
	    }
	}
	if (in_format) {
	    yylval.formval = load_format();
	    in_format = FALSE;
	    oldoldbufptr = oldbufptr = s = str_get(linestr) + 1;
	    bufend = linestr->str_ptr + linestr->str_cur;
	    TERM(FORMLIST);
	}
	line++;
	if ((s = str_gets(linestr, rsfp, 0)) == Nullch) {
	    if (preprocess)
		(void)mypclose(rsfp);
	    else if (rsfp != stdin)
		(void)fclose(rsfp);
	    rsfp = Nullfp;
	    if (minus_n || minus_p) {
		str_set(linestr,minus_p ? "}continue{print;" : "");
		str_cat(linestr,"}");
		oldoldbufptr = oldbufptr = s = str_get(linestr);
		bufend = linestr->str_ptr + linestr->str_cur;
		goto retry;
	    }
	    oldoldbufptr = oldbufptr = s = str_get(linestr);
	    str_set(linestr,"");
	    RETURN(0);
	}
	oldoldbufptr = oldbufptr = bufptr = s;
	if (perldb) {
	    STR *str = Str_new(85,0);

	    str_sset(str,linestr);
	    astore(lineary,(int)line,str);
	}
#ifdef DEBUG
	if (firstline) {
	    char *showinput();
	    s = showinput();
	}
#endif
	bufend = linestr->str_ptr + linestr->str_cur;
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
	    d = bufend;
	    while (s < d && isspace(*s)) s++;
	    if (filename)
		Safefree(filename);
	    s[strlen(s)-1] = '\0';	/* wipe out newline */
	    if (*s == '"') {
		s++;
		s[strlen(s)-1] = '\0';	/* wipe out trailing quote */
	    }
	    if (*s)
		filename = savestr(s);
	    else
		filename = savestr(origfilename);
	    oldoldbufptr = oldbufptr = s = str_get(linestr);
	}
	if (in_eval && !rsfp) {
	    d = bufend;
	    while (s < d && *s != '\n')
		s++;
	    if (s < d) {
		s++;
		line++;
	    }
	}
	else {
	    *s = '\0';
	    bufend = s;
	}
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
	tmp = *s++;
	if (*s == tmp) {
	    s++;
	    RETURN(DEC);
	}
	if (expectterm)
	    OPERATOR('-');
	else
	    AOP(O_SUBTRACT);
    case '+':
	tmp = *s++;
	if (*s == tmp) {
	    s++;
	    RETURN(INC);
	}
	if (expectterm)
	    OPERATOR('+');
	else
	    AOP(O_ADD);

    case '*':
	if (expectterm) {
	    s = scanreg(s,bufend,tokenbuf);
	    yylval.stabval = stabent(tokenbuf,TRUE);
	    TERM(STAR);
	}
	tmp = *s++;
	if (*s == tmp) {
	    s++;
	    OPERATOR(POW);
	}
	MOP(O_MULTIPLY);
    case '%':
	if (expectterm) {
	    s = scanreg(s,bufend,tokenbuf);
	    yylval.stabval = stabent(tokenbuf,TRUE);
	    TERM(HSH);
	}
	s++;
	MOP(O_MODULO);

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
	if (expectterm) {
	    d = bufend;
	    while (s < d && isspace(*s))
		s++;
	    if (isalpha(*s) || *s == '_' || *s == '\'')
		*(--s) = '\\';	/* force next ident to WORD */
	    OPERATOR(AMPER);
	}
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
	    EOP(O_EQ);
	if (tmp == '~')
	    OPERATOR(MATCH);
	s--;
	OPERATOR('=');
    case '!':
	s++;
	tmp = *s++;
	if (tmp == '=')
	    EOP(O_NE);
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
	    ROP(O_LE);
	s--;
	ROP(O_LT);
    case '>':
	s++;
	tmp = *s++;
	if (tmp == '>')
	    OPERATOR(RS);
	if (tmp == '=')
	    ROP(O_GE);
	s--;
	ROP(O_GT);

#define SNARFWORD \
	d = tokenbuf; \
	while (isascii(*s) && \
	  (isalpha(*s) || isdigit(*s) || *s == '_' || *s == '\'')) \
	    *d++ = *s++; \
	if (d[-1] == '\'') \
	    d--,s--; \
	*d = '\0'; \
	d = tokenbuf;

    case '$':
	if (s[1] == '#' && (isalpha(s[2]) || s[2] == '_')) {
	    s++;
	    s = scanreg(s,bufend,tokenbuf);
	    yylval.stabval = aadd(stabent(tokenbuf,TRUE));
	    TERM(ARYLEN);
	}
	d = s;
	s = scanreg(s,bufend,tokenbuf);
	if (reparse) {		/* turn ${foo[bar]} into ($foo[bar]) */
	  do_reparse:
	    s[-1] = ')';
	    s = d;
	    s[1] = s[0];
	    s[0] = '(';
	    goto retry;
	}
	yylval.stabval = stabent(tokenbuf,TRUE);
	TERM(REG);

    case '@':
	d = s;
	s = scanreg(s,bufend,tokenbuf);
	if (reparse)
	    goto do_reparse;
	yylval.stabval = stabent(tokenbuf,TRUE);
	TERM(ARY);

    case '/':			/* may either be division or pattern */
    case '?':			/* may either be conditional or pattern */
	if (expectterm) {
	    s = scanpat(s);
	    TERM(PATTERN);
	}
	tmp = *s++;
	if (tmp == '/')
	    MOP(O_DIVIDE);
	OPERATOR(tmp);

    case '.':
	if (!expectterm || !isdigit(s[1])) {
	    tmp = *s++;
	    if (*s == tmp) {
		s++;
		OPERATOR(DOTDOT);
	    }
	    AOP(O_CONCAT);
	}
	/* FALL THROUGH */
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
    case '\'': case '"': case '`':
	s = scanstr(s);
	TERM(RSTRING);

    case '\\':	/* some magic to force next word to be a WORD */
	s++;	/* used by do and sub to force a separate namespace */
	/* FALL THROUGH */
    case '_':
	SNARFWORD;
	break;
    case 'a': case 'A':
	SNARFWORD;
	if (strEQ(d,"accept"))
	    FOP22(O_ACCEPT);
	if (strEQ(d,"atan2"))
	    FUN2(O_ATAN2);
	break;
    case 'b': case 'B':
	SNARFWORD;
	if (strEQ(d,"bind"))
	    FOP2(O_BIND);
	break;
    case 'c': case 'C':
	SNARFWORD;
	if (strEQ(d,"chop"))
	    LFUN(O_CHOP);
	if (strEQ(d,"continue"))
	    OPERATOR(CONTINUE);
	if (strEQ(d,"chdir"))
	    UNI(O_CHDIR);
	if (strEQ(d,"close"))
	    FOP(O_CLOSE);
	if (strEQ(d,"closedir"))
	    FOP(O_CLOSEDIR);
	if (strEQ(d,"crypt")) {
#ifdef FCRYPT
	    init_des();
#endif
	    FUN2(O_CRYPT);
	}
	if (strEQ(d,"chmod"))
	    LOP(O_CHMOD);
	if (strEQ(d,"chown"))
	    LOP(O_CHOWN);
	if (strEQ(d,"connect"))
	    FOP2(O_CONNECT);
	if (strEQ(d,"cos"))
	    UNI(O_COS);
	if (strEQ(d,"chroot"))
	    UNI(O_CHROOT);
	break;
    case 'd': case 'D':
	SNARFWORD;
	if (strEQ(d,"do")) {
	    d = bufend;
	    while (s < d && isspace(*s))
		s++;
	    if (isalpha(*s) || *s == '_')
		*(--s) = '\\';	/* force next ident to WORD */
	    OPERATOR(DO);
	}
	if (strEQ(d,"die"))
	    LOP(O_DIE);
	if (strEQ(d,"defined"))
	    LFUN(O_DEFINED);
	if (strEQ(d,"delete"))
	    OPERATOR(DELETE);
	if (strEQ(d,"dbmopen"))
	    HFUN3(O_DBMOPEN);
	if (strEQ(d,"dbmclose"))
	    HFUN(O_DBMCLOSE);
	if (strEQ(d,"dump"))
	    LOOPX(O_DUMP);
	break;
    case 'e': case 'E':
	SNARFWORD;
	if (strEQ(d,"else"))
	    OPERATOR(ELSE);
	if (strEQ(d,"elsif")) {
	    yylval.ival = line;
	    OPERATOR(ELSIF);
	}
	if (strEQ(d,"eq") || strEQ(d,"EQ"))
	    EOP(O_SEQ);
	if (strEQ(d,"exit"))
	    UNI(O_EXIT);
	if (strEQ(d,"eval")) {
	    allstabs = TRUE;		/* must initialize everything since */
	    UNI(O_EVAL);		/* we don't know what will be used */
	}
	if (strEQ(d,"eof"))
	    FOP(O_EOF);
	if (strEQ(d,"exp"))
	    UNI(O_EXP);
	if (strEQ(d,"each"))
	    HFUN(O_EACH);
	if (strEQ(d,"exec")) {
	    set_csh();
	    LOP(O_EXEC);
	}
	if (strEQ(d,"endhostent"))
	    FUN0(O_EHOSTENT);
	if (strEQ(d,"endnetent"))
	    FUN0(O_ENETENT);
	if (strEQ(d,"endservent"))
	    FUN0(O_ESERVENT);
	if (strEQ(d,"endprotoent"))
	    FUN0(O_EPROTOENT);
	if (strEQ(d,"endpwent"))
	    FUN0(O_EPWENT);
	if (strEQ(d,"endgrent"))
	    FUN0(O_EGRENT);
	break;
    case 'f': case 'F':
	SNARFWORD;
	if (strEQ(d,"for"))
	    OPERATOR(FOR);
	if (strEQ(d,"foreach"))
	    OPERATOR(FOR);
	if (strEQ(d,"format")) {
	    d = bufend;
	    while (s < d && isspace(*s))
		s++;
	    if (isalpha(*s) || *s == '_')
		*(--s) = '\\';	/* force next ident to WORD */
	    in_format = TRUE;
	    allstabs = TRUE;		/* must initialize everything since */
	    OPERATOR(FORMAT);		/* we don't know what will be used */
	}
	if (strEQ(d,"fork"))
	    FUN0(O_FORK);
	if (strEQ(d,"fcntl"))
	    FOP3(O_FCNTL);
	if (strEQ(d,"fileno"))
	    FOP(O_FILENO);
	if (strEQ(d,"flock"))
	    FOP2(O_FLOCK);
	break;
    case 'g': case 'G':
	SNARFWORD;
	if (strEQ(d,"gt") || strEQ(d,"GT"))
	    ROP(O_SGT);
	if (strEQ(d,"ge") || strEQ(d,"GE"))
	    ROP(O_SGE);
	if (strEQ(d,"grep"))
	    FL2(O_GREP);
	if (strEQ(d,"goto"))
	    LOOPX(O_GOTO);
	if (strEQ(d,"gmtime"))
	    UNI(O_GMTIME);
	if (strEQ(d,"getc"))
	    FOP(O_GETC);
	if (strnEQ(d,"get",3)) {
	    d += 3;
	    if (*d == 'p') {
		if (strEQ(d,"ppid"))
		    FUN0(O_GETPPID);
		if (strEQ(d,"pgrp"))
		    UNI(O_GETPGRP);
		if (strEQ(d,"priority"))
		    FUN2(O_GETPRIORITY);
		if (strEQ(d,"protobyname"))
		    UNI(O_GPBYNAME);
		if (strEQ(d,"protobynumber"))
		    FUN1(O_GPBYNUMBER);
		if (strEQ(d,"protoent"))
		    FUN0(O_GPROTOENT);
		if (strEQ(d,"pwent"))
		    FUN0(O_GPWENT);
		if (strEQ(d,"pwnam"))
		    FUN1(O_GPWNAM);
		if (strEQ(d,"pwuid"))
		    FUN1(O_GPWUID);
		if (strEQ(d,"peername"))
		    FOP(O_GETPEERNAME);
	    }
	    else if (*d == 'h') {
		if (strEQ(d,"hostbyname"))
		    UNI(O_GHBYNAME);
		if (strEQ(d,"hostbyaddr"))
		    FUN2(O_GHBYADDR);
		if (strEQ(d,"hostent"))
		    FUN0(O_GHOSTENT);
	    }
	    else if (*d == 'n') {
		if (strEQ(d,"netbyname"))
		    UNI(O_GNBYNAME);
		if (strEQ(d,"netbyaddr"))
		    FUN2(O_GNBYADDR);
		if (strEQ(d,"netent"))
		    FUN0(O_GNETENT);
	    }
	    else if (*d == 's') {
		if (strEQ(d,"servbyname"))
		    FUN2(O_GSBYNAME);
		if (strEQ(d,"servbyport"))
		    FUN2(O_GSBYPORT);
		if (strEQ(d,"servent"))
		    FUN0(O_GSERVENT);
		if (strEQ(d,"sockname"))
		    FOP(O_GETSOCKNAME);
		if (strEQ(d,"sockopt"))
		    FOP3(O_GSOCKOPT);
	    }
	    else if (*d == 'g') {
		if (strEQ(d,"grent"))
		    FUN0(O_GGRENT);
		if (strEQ(d,"grnam"))
		    FUN1(O_GGRNAM);
		if (strEQ(d,"grgid"))
		    FUN1(O_GGRGID);
	    }
	    else if (*d == 'l') {
		if (strEQ(d,"login"))
		    FUN0(O_GETLOGIN);
	    }
	    d -= 3;
	}
	break;
    case 'h': case 'H':
	SNARFWORD;
	if (strEQ(d,"hex"))
	    UNI(O_HEX);
	break;
    case 'i': case 'I':
	SNARFWORD;
	if (strEQ(d,"if")) {
	    yylval.ival = line;
	    OPERATOR(IF);
	}
	if (strEQ(d,"index"))
	    FUN2(O_INDEX);
	if (strEQ(d,"int"))
	    UNI(O_INT);
	if (strEQ(d,"ioctl"))
	    FOP3(O_IOCTL);
	break;
    case 'j': case 'J':
	SNARFWORD;
	if (strEQ(d,"join"))
	    FL2(O_JOIN);
	break;
    case 'k': case 'K':
	SNARFWORD;
	if (strEQ(d,"keys"))
	    HFUN(O_KEYS);
	if (strEQ(d,"kill"))
	    LOP(O_KILL);
	break;
    case 'l': case 'L':
	SNARFWORD;
	if (strEQ(d,"last"))
	    LOOPX(O_LAST);
	if (strEQ(d,"local"))
	    OPERATOR(LOCAL);
	if (strEQ(d,"length"))
	    UNI(O_LENGTH);
	if (strEQ(d,"lt") || strEQ(d,"LT"))
	    ROP(O_SLT);
	if (strEQ(d,"le") || strEQ(d,"LE"))
	    ROP(O_SLE);
	if (strEQ(d,"localtime"))
	    UNI(O_LOCALTIME);
	if (strEQ(d,"log"))
	    UNI(O_LOG);
	if (strEQ(d,"link"))
	    FUN2(O_LINK);
	if (strEQ(d,"listen"))
	    FOP2(O_LISTEN);
	if (strEQ(d,"lstat"))
	    FOP(O_LSTAT);
	break;
    case 'm': case 'M':
	SNARFWORD;
	if (strEQ(d,"m")) {
	    s = scanpat(s-1);
	    if (yylval.arg)
		TERM(PATTERN);
	    else
		RETURN(1);	/* force error */
	}
	if (strEQ(d,"mkdir"))
	    FUN2(O_MKDIR);
	break;
    case 'n': case 'N':
	SNARFWORD;
	if (strEQ(d,"next"))
	    LOOPX(O_NEXT);
	if (strEQ(d,"ne") || strEQ(d,"NE"))
	    EOP(O_SNE);
	break;
    case 'o': case 'O':
	SNARFWORD;
	if (strEQ(d,"open"))
	    OPERATOR(OPEN);
	if (strEQ(d,"ord"))
	    UNI(O_ORD);
	if (strEQ(d,"oct"))
	    UNI(O_OCT);
	if (strEQ(d,"opendir"))
	    FOP2(O_OPENDIR);
	break;
    case 'p': case 'P':
	SNARFWORD;
	if (strEQ(d,"print")) {
	    checkcomma(s,"filehandle");
	    LOP(O_PRINT);
	}
	if (strEQ(d,"printf")) {
	    checkcomma(s,"filehandle");
	    LOP(O_PRTF);
	}
	if (strEQ(d,"push")) {
	    yylval.ival = O_PUSH;
	    OPERATOR(PUSH);
	}
	if (strEQ(d,"pop"))
	    OPERATOR(POP);
	if (strEQ(d,"pack"))
	    FL2(O_PACK);
	if (strEQ(d,"package"))
	    OPERATOR(PACKAGE);
	break;
    case 'q': case 'Q':
	SNARFWORD;
	if (strEQ(d,"q")) {
	    s = scanstr(s-1);
	    TERM(RSTRING);
	}
	if (strEQ(d,"qq")) {
	    s = scanstr(s-2);
	    TERM(RSTRING);
	}
	break;
    case 'r': case 'R':
	SNARFWORD;
	if (strEQ(d,"return"))
	    LOP(O_RETURN);
	if (strEQ(d,"reset"))
	    UNI(O_RESET);
	if (strEQ(d,"redo"))
	    LOOPX(O_REDO);
	if (strEQ(d,"rename"))
	    FUN2(O_RENAME);
	if (strEQ(d,"rand"))
	    UNI(O_RAND);
	if (strEQ(d,"rmdir"))
	    UNI(O_RMDIR);
	if (strEQ(d,"rindex"))
	    FUN2(O_RINDEX);
	if (strEQ(d,"read"))
	    FOP3(O_READ);
	if (strEQ(d,"readdir"))
	    FOP(O_READDIR);
	if (strEQ(d,"rewinddir"))
	    FOP(O_REWINDDIR);
	if (strEQ(d,"recv"))
	    FOP4(O_RECV);
	if (strEQ(d,"reverse"))
	    LOP(O_REVERSE);
	if (strEQ(d,"readlink"))
	    UNI(O_READLINK);
	break;
    case 's': case 'S':
	SNARFWORD;
	if (strEQ(d,"s")) {
	    s = scansubst(s);
	    if (yylval.arg)
		TERM(SUBST);
	    else
		RETURN(1);	/* force error */
	}
	switch (d[1]) {
	case 'a':
	case 'b':
	case 'c':
	case 'd':
	    break;
	case 'e':
	    if (strEQ(d,"select"))
		OPERATOR(SELECT);
	    if (strEQ(d,"seek"))
		FOP3(O_SEEK);
	    if (strEQ(d,"send"))
		FOP3(O_SEND);
	    if (strEQ(d,"setpgrp"))
		FUN2(O_SETPGRP);
	    if (strEQ(d,"setpriority"))
		FUN3(O_SETPRIORITY);
	    if (strEQ(d,"sethostent"))
		FUN1(O_SHOSTENT);
	    if (strEQ(d,"setnetent"))
		FUN1(O_SNETENT);
	    if (strEQ(d,"setservent"))
		FUN1(O_SSERVENT);
	    if (strEQ(d,"setprotoent"))
		FUN1(O_SPROTOENT);
	    if (strEQ(d,"setpwent"))
		FUN0(O_SPWENT);
	    if (strEQ(d,"setgrent"))
		FUN0(O_SGRENT);
	    if (strEQ(d,"seekdir"))
		FOP2(O_SEEKDIR);
	    if (strEQ(d,"setsockopt"))
		FOP4(O_SSOCKOPT);
	    break;
	case 'f':
	case 'g':
	    break;
	case 'h':
	    if (strEQ(d,"shift"))
		TERM(SHIFT);
	    if (strEQ(d,"shutdown"))
		FOP2(O_SHUTDOWN);
	    break;
	case 'i':
	    if (strEQ(d,"sin"))
		UNI(O_SIN);
	    break;
	case 'j':
	case 'k':
	    break;
	case 'l':
	    if (strEQ(d,"sleep"))
		UNI(O_SLEEP);
	    break;
	case 'm':
	case 'n':
	    break;
	case 'o':
	    if (strEQ(d,"socket"))
		FOP4(O_SOCKET);
	    if (strEQ(d,"socketpair"))
		FOP25(O_SOCKETPAIR);
	    if (strEQ(d,"sort")) {
		checkcomma(s,"subroutine name");
		d = bufend;
		while (s < d && isascii(*s) && isspace(*s)) s++;
		if (*s == ';' || *s == ')')		/* probably a close */
		    fatal("sort is now a reserved word");
		if (isascii(*s) && (isalpha(*s) || *s == '_')) {
		    for (d = s; isalpha(*d) || isdigit(*d) || *d == '_'; d++) ;
		    strncpy(tokenbuf,s,d-s);
		    if (strNE(tokenbuf,"keys") &&
			strNE(tokenbuf,"values") &&
			strNE(tokenbuf,"split") &&
			strNE(tokenbuf,"grep") &&
			strNE(tokenbuf,"readdir") &&
			strNE(tokenbuf,"unpack") &&
			strNE(tokenbuf,"do") &&
			(d >= bufend || isspace(*d)) )
			*(--s) = '\\';	/* force next ident to WORD */
		}
		LOP(O_SORT);
	    }
	    break;
	case 'p':
	    if (strEQ(d,"split"))
		TERM(SPLIT);
	    if (strEQ(d,"sprintf"))
		FL(O_SPRINTF);
	    break;
	case 'q':
	    if (strEQ(d,"sqrt"))
		UNI(O_SQRT);
	    break;
	case 'r':
	    if (strEQ(d,"srand"))
		UNI(O_SRAND);
	    break;
	case 's':
	    break;
	case 't':
	    if (strEQ(d,"stat"))
		FOP(O_STAT);
	    if (strEQ(d,"study")) {
		sawstudy++;
		LFUN(O_STUDY);
	    }
	    break;
	case 'u':
	    if (strEQ(d,"substr"))
		FUN3(O_SUBSTR);
	    if (strEQ(d,"sub")) {
		subline = line;
		d = bufend;
		while (s < d && isspace(*s))
		    s++;
		if (isalpha(*s) || *s == '_' || *s == '\'') {
		    if (perldb) {
			str_sset(subname,curstname);
			str_ncat(subname,"'",1);
			for (d = s+1;
			  isalpha(*d) || isdigit(*d) || *d == '_' || *d == '\'';
			  d++);
			if (d[-1] == '\'')
			    d--;
			str_ncat(subname,s,d-s);
		    }
		    *(--s) = '\\';	/* force next ident to WORD */
		}
		else if (perldb)
		    str_set(subname,"?");
		OPERATOR(SUB);
	    }
	    break;
	case 'v':
	case 'w':
	case 'x':
	    break;
	case 'y':
	    if (strEQ(d,"system")) {
		set_csh();
		LOP(O_SYSTEM);
	    }
	    if (strEQ(d,"symlink"))
		FUN2(O_SYMLINK);
	    if (strEQ(d,"syscall"))
		LOP(O_SYSCALL);
	    break;
	case 'z':
	    break;
	}
	break;
    case 't': case 'T':
	SNARFWORD;
	if (strEQ(d,"tr")) {
	    s = scantrans(s);
	    if (yylval.arg)
		TERM(TRANS);
	    else
		RETURN(1);	/* force error */
	}
	if (strEQ(d,"tell"))
	    FOP(O_TELL);
	if (strEQ(d,"telldir"))
	    FOP(O_TELLDIR);
	if (strEQ(d,"time"))
	    FUN0(O_TIME);
	if (strEQ(d,"times"))
	    FUN0(O_TMS);
	break;
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
	if (strEQ(d,"unlink"))
	    LOP(O_UNLINK);
	if (strEQ(d,"undef"))
	    LFUN(O_UNDEF);
	if (strEQ(d,"unpack"))
	    FUN2(O_UNPACK);
	if (strEQ(d,"utime"))
	    LOP(O_UTIME);
	if (strEQ(d,"umask"))
	    UNI(O_UMASK);
	if (strEQ(d,"unshift")) {
	    yylval.ival = O_UNSHIFT;
	    OPERATOR(PUSH);
	}
	break;
    case 'v': case 'V':
	SNARFWORD;
	if (strEQ(d,"values"))
	    HFUN(O_VALUES);
	if (strEQ(d,"vec")) {
	    sawvec = TRUE;
	    FUN3(O_VEC);
	}
	break;
    case 'w': case 'W':
	SNARFWORD;
	if (strEQ(d,"while")) {
	    yylval.ival = line;
	    OPERATOR(WHILE);
	}
	if (strEQ(d,"warn"))
	    LOP(O_WARN);
	if (strEQ(d,"wait"))
	    FUN0(O_WAIT);
	if (strEQ(d,"wantarray")) {
	    yylval.arg = op_new(1);
	    yylval.arg->arg_type = O_ITEM;
	    yylval.arg[1].arg_type = A_WANTARRAY;
	    TERM(RSTRING);
	}
	if (strEQ(d,"write"))
	    FOP(O_WRITE);
	break;
    case 'x': case 'X':
	SNARFWORD;
	if (!expectterm && strEQ(d,"x"))
	    MOP(O_REPEAT);
	break;
    case 'y': case 'Y':
	SNARFWORD;
	if (strEQ(d,"y")) {
	    s = scantrans(s);
	    TERM(TRANS);
	}
	break;
    case 'z': case 'Z':
	SNARFWORD;
	break;
    }
    yylval.cval = savestr(d);
    expectterm = FALSE;
    if (oldoldbufptr && oldoldbufptr < bufptr) {
	while (isspace(*oldoldbufptr))
	    oldoldbufptr++;
	if (*oldoldbufptr == 'p' && strnEQ(oldoldbufptr,"print",5))
	    expectterm = TRUE;
	else if (*oldoldbufptr == 's' && strnEQ(oldoldbufptr,"sort",4))
	    expectterm = TRUE;
    }
    return (CLINE, bufptr = s, (int)WORD);
}

int
checkcomma(s,what)
register char *s;
char *what;
{
    if (*s == '(')
	s++;
    while (s < bufend && isascii(*s) && isspace(*s))
	s++;
    if (isascii(*s) && (isalpha(*s) || *s == '_')) {
	s++;
	while (isalpha(*s) || isdigit(*s) || *s == '_')
	    s++;
	while (s < bufend && isspace(*s))
	    s++;
	if (*s == ',')
	    fatal("No comma allowed after %s", what);
    }
}

char *
scanreg(s,send,dest)
register char *s;
register char *send;
char *dest;
{
    register char *d;
    int brackets = 0;

    reparse = Nullch;
    s++;
    d = dest;
    if (isdigit(*s)) {
	while (isdigit(*s))
	    *d++ = *s++;
    }
    else {
	while (isalpha(*s) || isdigit(*s) || *s == '_' || *s == '\'')
	    *d++ = *s++;
    }
    if (d > dest+1 && d[-1] == '\'')
	d--,s--;
    *d = '\0';
    d = dest;
    if (!*d) {
	*d = *s++;
	if (*d == '{' /* } */ ) {
	    d = dest;
	    brackets++;
	    while (s < send && brackets) {
		if (!reparse && (d == dest || (*s && isascii(*s) &&
		  (isalpha(*s) || isdigit(*s) || *s == '_') ))) {
		    *d++ = *s++;
		    continue;
		}
		else if (!reparse)
		    reparse = s;
		switch (*s++) {
		/* { */
		case '}':
		    brackets--;
		    if (reparse && reparse == s - 1)
			reparse = Nullch;
		    break;
		case '{':   /* } */
		    brackets++;
		    break;
		}
	    }
	    *d = '\0';
	    d = dest;
	}
	else
	    d[1] = '\0';
    }
    if (*d == '^' && !isspace(*s))
	*d = *s++ & 31;
    return s;
}

STR *
scanconst(string,len)
char *string;
int len;
{
    register STR *retstr;
    register char *t;
    register char *d;
    register char *e;

    if (index(string,'|')) {
	return Nullstr;
    }
    retstr = Str_new(86,len);
    str_nset(retstr,string,len);
    t = str_get(retstr);
    e = t + len;
    retstr->str_u.str_useful = 100;
    for (d=t; d < e; ) {
	switch (*d) {
	case '{':
	    if (isdigit(d[1]))
		e = d;
	    else
		goto defchar;
	    break;
	case '.': case '[': case '$': case '(': case ')': case '|': case '+':
	    e = d;
	    break;
	case '\\':
	    if (d[1] && index("wWbB0123456789sSdD",d[1])) {
		e = d;
		break;
	    }
	    (void)bcopy(d+1,d,e-d);
	    e--;
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
	  defchar:
	    if (d[1] == '*' || (d[1] == '{' && d[2] == '0') || d[1] == '?') {
		e = d;
		break;
	    }
	    d++;
	}
    }
    if (d == t) {
	str_free(retstr);
	return Nullstr;
    }
    *d = '\0';
    retstr->str_cur = d - t;
    return retstr;
}

char *
scanpat(s)
register char *s;
{
    register SPAT *spat;
    register char *d;
    register char *e;
    int len;
    SPAT savespat;

    Newz(801,spat,1,SPAT);
    spat->spat_next = curstash->tbl_spatroot;	/* link into spat list */
    curstash->tbl_spatroot = spat;

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
    s = cpytill(tokenbuf,s,bufend,s[-1],&len);
    if (s >= bufend) {
	yyerror("Search pattern not terminated");
	yylval.arg = Nullarg;
	return s;
    }
    s++;
    while (*s == 'i' || *s == 'o') {
	if (*s == 'i') {
	    s++;
	    sawi = TRUE;
	    spat->spat_flags |= SPAT_FOLD;
	}
	if (*s == 'o') {
	    s++;
	    spat->spat_flags |= SPAT_KEEP;
	}
    }
    e = tokenbuf + len;
    for (d=tokenbuf; d < e; d++) {
	if ((*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') ||
	    (*d == '@' && d[-1] != '\\')) {
	    register ARG *arg;

	    spat->spat_runtime = arg = op_new(1);
	    arg->arg_type = O_ITEM;
	    arg[1].arg_type = A_DOUBLE;
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf,len);
	    arg[1].arg_ptr.arg_str->str_u.str_hash = curstash;
	    d = scanreg(d,bufend,buf);
	    (void)stabent(buf,TRUE);		/* make sure it's created */
	    for (; d < e; d++) {
		if (*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') {
		    d = scanreg(d,bufend,buf);
		    (void)stabent(buf,TRUE);
		}
		else if (*d == '@' && d[-1] != '\\') {
		    d = scanreg(d,bufend,buf);
		    if (strEQ(buf,"ARGV") || strEQ(buf,"ENV") ||
		      strEQ(buf,"SIG") || strEQ(buf,"INC"))
			(void)stabent(buf,TRUE);
		}
	    }
	    goto got_pat;		/* skip compiling for now */
	}
    }
    if (spat->spat_flags & SPAT_FOLD)
#ifdef STRUCTCOPY
	savespat = *spat;
#else
	(void)bcopy((char *)spat, (char *)&savespat, sizeof(SPAT));
#endif
    if (*tokenbuf == '^') {
	spat->spat_short = scanconst(tokenbuf+1,len-1);
	if (spat->spat_short) {
	    spat->spat_slen = spat->spat_short->str_cur;
	    if (spat->spat_slen == len - 1)
		spat->spat_flags |= SPAT_ALL;
	}
    }
    else {
	spat->spat_flags |= SPAT_SCANFIRST;
	spat->spat_short = scanconst(tokenbuf,len);
	if (spat->spat_short) {
	    spat->spat_slen = spat->spat_short->str_cur;
	    if (spat->spat_slen == len)
		spat->spat_flags |= SPAT_ALL;
	}
    }	
    if ((spat->spat_flags & SPAT_ALL) && (spat->spat_flags & SPAT_SCANFIRST)) {
	fbmcompile(spat->spat_short, spat->spat_flags & SPAT_FOLD);
	spat->spat_regexp = regcomp(tokenbuf,tokenbuf+len,
	    spat->spat_flags & SPAT_FOLD,1);
		/* Note that this regexp can still be used if someone says
		 * something like /a/ && s//b/;  so we can't delete it.
		 */
    }
    else {
	if (spat->spat_flags & SPAT_FOLD)
#ifdef STRUCTCOPY
	    *spat = savespat;
#else
	    (void)bcopy((char *)&savespat, (char *)spat, sizeof(SPAT));
#endif
	if (spat->spat_short)
	    fbmcompile(spat->spat_short, spat->spat_flags & SPAT_FOLD);
	spat->spat_regexp = regcomp(tokenbuf,tokenbuf+len,
	    spat->spat_flags & SPAT_FOLD,1);
	hoistmust(spat);
    }
  got_pat:
    yylval.arg = make_match(O_MATCH,stab2arg(A_STAB,defstab),spat);
    return s;
}

char *
scansubst(s)
register char *s;
{
    register SPAT *spat;
    register char *d;
    register char *e;
    int len;

    Newz(802,spat,1,SPAT);
    spat->spat_next = curstash->tbl_spatroot;	/* link into spat list */
    curstash->tbl_spatroot = spat;

    s = cpytill(tokenbuf,s+1,bufend,*s,&len);
    if (s >= bufend) {
	yyerror("Substitution pattern not terminated");
	yylval.arg = Nullarg;
	return s;
    }
    e = tokenbuf + len;
    for (d=tokenbuf; d < e; d++) {
	if ((*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') ||
	    (*d == '@' && d[-1] != '\\')) {
	    register ARG *arg;

	    spat->spat_runtime = arg = op_new(1);
	    arg->arg_type = O_ITEM;
	    arg[1].arg_type = A_DOUBLE;
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf,len);
	    arg[1].arg_ptr.arg_str->str_u.str_hash = curstash;
	    d = scanreg(d,bufend,buf);
	    (void)stabent(buf,TRUE);		/* make sure it's created */
	    for (; *d; d++) {
		if (*d == '$' && d[1] && d[-1] != '\\' && d[1] != '|') {
		    d = scanreg(d,bufend,buf);
		    (void)stabent(buf,TRUE);
		}
		else if (*d == '@' && d[-1] != '\\') {
		    d = scanreg(d,bufend,buf);
		    if (strEQ(buf,"ARGV") || strEQ(buf,"ENV") ||
		      strEQ(buf,"SIG") || strEQ(buf,"INC"))
			(void)stabent(buf,TRUE);
		}
	    }
	    goto get_repl;		/* skip compiling for now */
	}
    }
    if (*tokenbuf == '^') {
	spat->spat_short = scanconst(tokenbuf+1,len-1);
	if (spat->spat_short)
	    spat->spat_slen = spat->spat_short->str_cur;
    }
    else {
	spat->spat_flags |= SPAT_SCANFIRST;
	spat->spat_short = scanconst(tokenbuf,len);
	if (spat->spat_short)
	    spat->spat_slen = spat->spat_short->str_cur;
    }
    d = nsavestr(tokenbuf,len);
get_repl:
    s = scanstr(s);
    if (s >= bufend) {
	yyerror("Substitution replacement not terminated");
	yylval.arg = Nullarg;
	return s;
    }
    spat->spat_repl = yylval.arg;
    spat->spat_flags |= SPAT_ONCE;
    if ((spat->spat_repl[1].arg_type & A_MASK) == A_SINGLE)
	spat->spat_flags |= SPAT_CONST;
    else if ((spat->spat_repl[1].arg_type & A_MASK) == A_DOUBLE) {
	STR *tmpstr;
	register char *t;

	spat->spat_flags |= SPAT_CONST;
	tmpstr = spat->spat_repl[1].arg_ptr.arg_str;
	e = tmpstr->str_ptr + tmpstr->str_cur;
	for (t = tmpstr->str_ptr; t < e; t++) {
	    if (*t == '$' && t[1] && index("`'&+0123456789",t[1]))
		spat->spat_flags &= ~SPAT_CONST;
	}
    }
    while (*s == 'g' || *s == 'i' || *s == 'e' || *s == 'o') {
	if (*s == 'e') {
	    s++;
	    if ((spat->spat_repl[1].arg_type & A_MASK) == A_DOUBLE)
		spat->spat_repl[1].arg_type = A_SINGLE;
	    spat->spat_repl = fixeval(make_op(O_EVAL,2,
		spat->spat_repl,
		Nullarg,
		Nullarg));
	    spat->spat_flags &= ~SPAT_CONST;
	}
	if (*s == 'g') {
	    s++;
	    spat->spat_flags &= ~SPAT_ONCE;
	}
	if (*s == 'i') {
	    s++;
	    sawi = TRUE;
	    spat->spat_flags |= SPAT_FOLD;
	    if (!(spat->spat_flags & SPAT_SCANFIRST)) {
		str_free(spat->spat_short);	/* anchored opt doesn't do */
		spat->spat_short = Nullstr;	/* case insensitive match */
		spat->spat_slen = 0;
	    }
	}
	if (*s == 'o') {
	    s++;
	    spat->spat_flags |= SPAT_KEEP;
	}
    }
    if (spat->spat_short && (spat->spat_flags & SPAT_SCANFIRST))
	fbmcompile(spat->spat_short, spat->spat_flags & SPAT_FOLD);
    if (!spat->spat_runtime) {
	spat->spat_regexp = regcomp(d,d+len,spat->spat_flags & SPAT_FOLD,1);
	hoistmust(spat);
	Safefree(d);
    }
    yylval.arg = make_match(O_SUBST,stab2arg(A_STAB,defstab),spat);
    return s;
}

hoistmust(spat)
register SPAT *spat;
{
    if (spat->spat_regexp->regmust) {	/* is there a better short-circuit? */
	if (spat->spat_short &&
	  str_eq(spat->spat_short,spat->spat_regexp->regmust))
	{
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
expand_charset(s,len,retlen)
register char *s;
int len;
int *retlen;
{
    char t[512];
    register char *d = t;
    register int i;
    register char *send = s + len;

    while (s < send) {
	if (s[1] == '-' && s+2 < send) {
	    for (i = s[0]; i <= s[2]; i++)
		*d++ = i;
	    s += 3;
	}
	else
	    *d++ = *s++;
    }
    *d = '\0';
    *retlen = d - t;
    return nsavestr(t,d-t);
}

char *
scantrans(s)
register char *s;
{
    ARG *arg =
	l(make_op(O_TRANS,2,stab2arg(A_STAB,defstab),Nullarg,Nullarg));
    register char *t;
    register char *r;
    register char *tbl;
    register int i;
    register int j;
    int tlen, rlen;

    Newz(803,tbl,256,char);
    arg[2].arg_type = A_NULL;
    arg[2].arg_ptr.arg_cval = tbl;
    s = scanstr(s);
    if (s >= bufend) {
	yyerror("Translation pattern not terminated");
	yylval.arg = Nullarg;
	return s;
    }
    t = expand_charset(yylval.arg[1].arg_ptr.arg_str->str_ptr,
	yylval.arg[1].arg_ptr.arg_str->str_cur,&tlen);
    free_arg(yylval.arg);
    s = scanstr(s-1);
    if (s >= bufend) {
	yyerror("Translation replacement not terminated");
	yylval.arg = Nullarg;
	return s;
    }
    r = expand_charset(yylval.arg[1].arg_ptr.arg_str->str_ptr,
	yylval.arg[1].arg_ptr.arg_str->str_cur,&rlen);
    free_arg(yylval.arg);
    yylval.arg = arg;
    if (!*r) {
	Safefree(r);
	r = t;
    }
    for (i = 0, j = 0; i < tlen; i++,j++) {
	if (j >= rlen)
	    --j;
	tbl[t[i] & 0377] = r[j];
    }
    if (r != t)
	Safefree(r);
    Safefree(t);
    return s;
}

char *
scanstr(s)
register char *s;
{
    register char term;
    register char *d;
    register ARG *arg;
    register char *send;
    register bool makesingle = FALSE;
    register STAB *stab;
    bool alwaysdollar = FALSE;
    bool hereis = FALSE;
    STR *herewas;
    char *leave = "\\$@nrtfb0123456789[{]}"; /* which backslash sequences to keep */
    int len;

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
			yyerror("Illegal octal digit");
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
	    (void)sprintf(tokenbuf,"%ld",i);
	    arg[1].arg_ptr.arg_str = str_make(tokenbuf,strlen(tokenbuf));
	    (void)str_2num(arg[1].arg_ptr.arg_str);
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
	if (*s == '.' && s[1] && index("0123456789eE ;",s[1])) {
	    *d++ = *s++;
	    while (isdigit(*s) || *s == '_') {
		if (*s == '_')
		    s++;
		else
		    *d++ = *s++;
	    }
	}
	if (*s && index("eE",*s) && index("+-0123456789",s[1])) {
	    *d++ = *s++;
	    if (*s == '+' || *s == '-')
		*d++ = *s++;
	    while (isdigit(*s))
		*d++ = *s++;
	}
	*d = '\0';
	arg[1].arg_ptr.arg_str = str_make(tokenbuf, d - tokenbuf);
	(void)str_2num(arg[1].arg_ptr.arg_str);
	break;
    case '<':
	if (*++s == '<') {
	    hereis = TRUE;
	    d = tokenbuf;
	    if (!rsfp)
		*d++ = '\n';
	    if (*++s && index("`'\"",*s)) {
		term = *s++;
		s = cpytill(d,s,bufend,term,&len);
		if (s < bufend)
		    s++;
		d += len;
	    }
	    else {
		if (*s == '\\')
		    s++, term = '\'';
		else
		    term = '"';
		while (isascii(*s) && (isalpha(*s) || isdigit(*s) || *s == '_'))
		    *d++ = *s++;
	    }				/* assuming tokenbuf won't clobber */
	    *d++ = '\n';
	    *d = '\0';
	    len = d - tokenbuf;
	    d = "\n";
	    if (rsfp || !(d=ninstr(s,bufend,d,d+1)))
		herewas = str_make(s,bufend-s);
	    else
		s--, herewas = str_make(s,d-s);
	    s += herewas->str_cur;
	    if (term == '\'')
		goto do_single;
	    if (term == '`')
		goto do_back;
	    goto do_double;
	}
	d = tokenbuf;
	s = cpytill(d,s,bufend,'>',&len);
	if (s < bufend)
	    s++;
	if (*d == '$') d++;
	while (*d &&
	  (isalpha(*d) || isdigit(*d) || *d == '_' || *d == '\''))
	    d++;
	if (d - tokenbuf != len) {
	    d = tokenbuf;
	    arg[1].arg_type = A_GLOB;
	    d = nsavestr(d,len);
	    arg[1].arg_ptr.arg_stab = stab = genstab();
	    stab_io(stab) = stio_new();
	    stab_val(stab) = str_make(d,len);
	    stab_val(stab)->str_u.str_hash = curstash;
	    Safefree(d);
	    set_csh();
	}
	else {
	    d = tokenbuf;
	    if (!len)
		(void)strcpy(d,"ARGV");
	    if (*d == '$') {
		arg[1].arg_type = A_INDREAD;
		arg[1].arg_ptr.arg_stab = stabent(d+1,TRUE);
	    }
	    else {
		arg[1].arg_type = A_READ;
		if (rsfp == stdin && (strEQ(d,"stdin") || strEQ(d,"STDIN")))
		    yyerror("Can't get both program and data from <STDIN>");
		arg[1].arg_ptr.arg_stab = stabent(d,TRUE);
		if (!stab_io(arg[1].arg_ptr.arg_stab))
		    stab_io(arg[1].arg_ptr.arg_stab) = stio_new();
		if (strEQ(d,"ARGV")) {
		    (void)aadd(arg[1].arg_ptr.arg_stab);
		    stab_io(arg[1].arg_ptr.arg_stab)->flags |=
		      IOF_ARGV|IOF_START;
		}
	    }
	}
	break;

    case 'q':
	s++;
	if (*s == 'q') {
	    s++;
	    goto do_double;
	}
	/* FALL THROUGH */
    case '\'':
      do_single:
	term = *s;
	arg[1].arg_type = A_SINGLE;
	leave = Nullch;
	goto snarf_it;

    case '"': 
      do_double:
	term = *s;
	arg[1].arg_type = A_DOUBLE;
	makesingle = TRUE;	/* maybe disable runtime scanning */
	alwaysdollar = TRUE;	/* treat $) and $| as variables */
	goto snarf_it;
    case '`':
      do_back:
	term = *s;
	arg[1].arg_type = A_BACKTICK;
	set_csh();
	alwaysdollar = TRUE;	/* treat $) and $| as variables */
      snarf_it:
	{
	    STR *tmpstr;
	    char *tmps;

	    multi_start = line;
	    if (hereis)
		multi_open = multi_close = '<';
	    else {
		multi_open = term;
		if (tmps = index("([{< )]}> )]}>",term))
		    term = tmps[5];
		multi_close = term;
	    }
	    tmpstr = Str_new(87,0);
	    if (hereis) {
		term = *tokenbuf;
		if (!rsfp) {
		    d = s;
		    while (s < bufend &&
		      (*s != term || bcmp(s,tokenbuf,len) != 0) ) {
			if (*s++ == '\n')
			    line++;
		    }
		    if (s >= bufend) {
			line = multi_start;
			fatal("EOF in string");
		    }
		    str_nset(tmpstr,d+1,s-d);
		    s += len - 1;
		    str_ncat(herewas,s,bufend-s);
		    str_replace(linestr,herewas);
		    oldoldbufptr = oldbufptr = bufptr = s = str_get(linestr);
		    bufend = linestr->str_ptr + linestr->str_cur;
		    hereis = FALSE;
		}
	    }
	    else
		s = str_append_till(tmpstr,s+1,bufend,term,leave);
	    while (s >= bufend) {	/* multiple line string? */
		if (!rsfp ||
		 !(oldoldbufptr = oldbufptr = s = str_gets(linestr, rsfp, 0))) {
		    line = multi_start;
		    fatal("EOF in string");
		}
		line++;
		if (perldb) {
		    STR *str = Str_new(88,0);

		    str_sset(str,linestr);
		    astore(lineary,(int)line,str);
		}
		bufend = linestr->str_ptr + linestr->str_cur;
		if (hereis) {
		    if (*s == term && bcmp(s,tokenbuf,len) == 0) {
			s = bufend - 1;
			*s = ' ';
			str_scat(linestr,herewas);
			bufend = linestr->str_ptr + linestr->str_cur;
		    }
		    else {
			s = bufend;
			str_scat(tmpstr,linestr);
		    }
		}
		else
		    s = str_append_till(tmpstr,s,bufend,term,leave);
	    }
	    multi_end = line;
	    s++;
	    if (tmpstr->str_cur + 5 < tmpstr->str_len) {
		tmpstr->str_len = tmpstr->str_cur + 1;
		Renew(tmpstr->str_ptr, tmpstr->str_len, char);
	    }
	    if ((arg[1].arg_type & A_MASK) == A_SINGLE) {
		arg[1].arg_ptr.arg_str = tmpstr;
		break;
	    }
	    tmps = s;
	    s = tmpstr->str_ptr;
	    send = s + tmpstr->str_cur;
	    while (s < send) {		/* see if we can make SINGLE */
		if (*s == '\\' && s[1] && isdigit(s[1]) && !isdigit(s[2]) &&
		  !alwaysdollar )
		    *s = '$';		/* grandfather \digit in subst */
		if ((*s == '$' || *s == '@') && s+1 < send &&
		  (alwaysdollar || (s[1] != ')' && s[1] != '|'))) {
		    makesingle = FALSE;	/* force interpretation */
		}
		else if (*s == '\\' && s+1 < send) {
		    s++;
		}
		s++;
	    }
	    s = d = tmpstr->str_ptr;	/* assuming shrinkage only */
	    while (s < send) {
		if ((*s == '$' && s+1 < send &&
		    (alwaysdollar || /*(*/ (s[1] != ')' && s[1] != '|')) ) ||
		    (*s == '@' && s+1 < send) ) {
		    len = scanreg(s,bufend,tokenbuf) - s;
		    if (*s == '$' || strEQ(tokenbuf,"ARGV")
		      || strEQ(tokenbuf,"ENV")
		      || strEQ(tokenbuf,"SIG")
		      || strEQ(tokenbuf,"INC") )
			(void)stabent(tokenbuf,TRUE); /* make sure it exists */
		    while (len--)
			*d++ = *s++;
		    continue;
		}
		else if (*s == '\\' && s+1 < send) {
		    s++;
		    switch (*s) {
		    default:
			if (!makesingle && (!leave || (*s && index(leave,*s))))
			    *d++ = '\\';
			*d++ = *s++;
			continue;
		    case '0': case '1': case '2': case '3':
		    case '4': case '5': case '6': case '7':
			*d = *s++ - '0';
			if (s < send && *s && index("01234567",*s)) {
			    *d <<= 3;
			    *d += *s++ - '0';
			}
			if (s < send && *s && index("01234567",*s)) {
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

	    if ((arg[1].arg_type & A_MASK) == A_DOUBLE && makesingle)
		    arg[1].arg_type = A_SINGLE;	/* now we can optimize on it */

	    tmpstr->str_u.str_hash = curstash;	/* so interp knows package */

	    tmpstr->str_cur = d - tmpstr->str_ptr;
	    arg[1].arg_ptr.arg_str = tmpstr;
	    s = tmps;
	    break;
	}
    }
    if (hereis)
	str_free(herewas);
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
    register STR *str;
    bool noblank;
    bool repeater;

    Zero(&froot, 1, FCMD);
    while ((s = str_gets(linestr,rsfp, 0)) != Nullch) {
	line++;
	if (perldb) {
	    STR *tmpstr = Str_new(89,0);

	    str_sset(tmpstr,linestr);
	    astore(lineary,(int)line,tmpstr);
	}
	bufend = linestr->str_ptr + linestr->str_cur;
	if (strEQ(s,".\n")) {
	    bufptr = s;
	    return froot.f_next;
	}
	if (*s == '#')
	    continue;
	flinebeg = Nullfcmd;
	noblank = FALSE;
	repeater = FALSE;
	while (s < bufend) {
	    Newz(804,fcmd,1,FCMD);
	    fprev->f_next = fcmd;
	    fprev = fcmd;
	    for (t=s; t < bufend && *t != '@' && *t != '^'; t++) {
		if (*t == '~') {
		    noblank = TRUE;
		    *t = ' ';
		    if (t[1] == '~') {
			repeater = TRUE;
			t[1] = ' ';
		    }
		}
	    }
	    fcmd->f_pre = nsavestr(s, t-s);
	    fcmd->f_presize = t-s;
	    s = t;
	    if (s >= bufend) {
		if (noblank)
		    fcmd->f_flags |= FC_NOBLANK;
		if (repeater)
		    fcmd->f_flags |= FC_REPEAT;
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
	    if ((s = str_gets(linestr, rsfp, 0)) == Nullch)
		goto badform;
	    line++;
	    if (perldb) {
		STR *tmpstr = Str_new(90,0);

		str_sset(tmpstr,linestr);
		astore(lineary,(int)line,tmpstr);
	    }
	    if (strEQ(s,".\n")) {
		bufptr = s;
		yyerror("Missing values line");
		return froot.f_next;
	    }
	    if (*s == '#')
		goto again;
	    bufend = linestr->str_ptr + linestr->str_cur;
	    str = flinebeg->f_unparsed = Str_new(91,bufend - bufptr);
	    str->str_u.str_hash = curstash;
	    str_nset(str,"(",1);
	    flinebeg->f_line = line;
	    if (!flinebeg->f_next->f_type || index(linestr->str_ptr, ',')) {
		str_scat(str,linestr);
		str_ncat(str,",$$);",5);
	    }
	    else {
		while (s < bufend && isspace(*s))
		    s++;
		t = s;
		while (s < bufend) {
		    switch (*s) {
		    case ' ': case '\t': case '\n': case ';':
			str_ncat(str, t, s - t);
			str_ncat(str, "," ,1);
			while (s < bufend && (isspace(*s) || *s == ';'))
			    s++;
			t = s;
			break;
		    case '$':
			str_ncat(str, t, s - t);
			t = s;
			s = scanreg(s,bufend,tokenbuf);
			str_ncat(str, t, s - t);
			t = s;
			if (s < bufend && *s && index("$'\"",*s))
			    str_ncat(str, ",", 1);
			break;
		    case '"': case '\'':
			str_ncat(str, t, s - t);
			t = s;
			s++;
			while (s < bufend && (*s != *t || s[-1] == '\\'))
			    s++;
			if (s < bufend)
			    s++;
			str_ncat(str, t, s - t);
			t = s;
			if (s < bufend && *s && index("$'\"",*s))
			    str_ncat(str, ",", 1);
			break;
		    default:
			yyerror("Please use commas to separate fields");
		    }
		}
		str_ncat(str,"$$);",4);
	    }
	}
    }
  badform:
    bufptr = str_get(linestr);
    yyerror("Format not terminated");
    return froot.f_next;
}

set_csh()
{
    if (!csh) {
	if (stat("/bin/csh",&statbuf) < 0)
	    csh = -1;
	else
	    csh = 1;
    }
}
