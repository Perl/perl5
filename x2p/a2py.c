/* $Header: a2py.c,v 1.0 87/12/18 17:50:33 root Exp $
 *
 * $Log:	a2py.c,v $
 * Revision 1.0  87/12/18  17:50:33  root
 * Initial revision
 * 
 */

#include "util.h"
char *index();

char *filename;

main(argc,argv,env)
register int argc;
register char **argv;
register char **env;
{
    register STR *str;
    register char *s;
    int i;
    STR *walk();
    STR *tmpstr;

    linestr = str_new(80);
    str = str_new(0);		/* first used for -I flags */
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
	case '0': case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	    maxfld = atoi(argv[0]+1);
	    absmaxfld = TRUE;
	    break;
	case 'F':
	    fswitch = argv[0][2];
	    break;
	case 'n':
	    namelist = savestr(argv[0]+2);
	    break;
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

    /* open script */

    if (argv[0] == Nullch)
	argv[0] = "-";
    filename = savestr(argv[0]);
    if (strEQ(filename,"-"))
	argv[0] = "";
    if (!*argv[0])
	rsfp = stdin;
    else
	rsfp = fopen(argv[0],"r");
    if (rsfp == Nullfp)
	fatal("Awk script \"%s\" doesn't seem to exist.\n",filename);

    /* init tokener */

    bufptr = str_get(linestr);
    symtab = hnew();

    /* now parse the report spec */

    if (yyparse())
	fatal("Translation aborted due to syntax errors.\n");

#ifdef DEBUGGING
    if (debug & 2) {
	int type, len;

	for (i=1; i<mop;) {
	    type = ops[i].ival;
	    len = type >> 8;
	    type &= 255;
	    printf("%d\t%d\t%d\t%-10s",i++,type,len,opname[type]);
	    if (type == OSTRING)
		printf("\t\"%s\"\n",ops[i].cval),i++;
	    else {
		while (len--) {
		    printf("\t%d",ops[i].ival),i++;
		}
		putchar('\n');
	    }
	}
    }
    if (debug & 8)
	dump(root);
#endif

    /* first pass to look for numeric variables */

    prewalk(0,0,root,&i);

    /* second pass to produce new program */

    tmpstr = walk(0,0,root,&i);
    str = str_make("#!/bin/perl\n\n");
    if (do_opens && opens) {
	str_scat(str,opens);
	str_free(opens);
	str_cat(str,"\n");
    }
    str_scat(str,tmpstr);
    str_free(tmpstr);
#ifdef DEBUGGING
    if (!(debug & 16))
#endif
    fixup(str);
    putlines(str);
    exit(0);
}

#define RETURN(retval) return (bufptr = s,retval)
#define XTERM(retval) return (expectterm = TRUE,bufptr = s,retval)
#define XOP(retval) return (expectterm = FALSE,bufptr = s,retval)
#define ID(x) return (yylval=string(x,0),expectterm = FALSE,bufptr = s,VAR)

yylex()
{
    register char *s = bufptr;
    register char *d;
    register int tmp;

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
    case '\\':
    case 0:
	s = str_get(linestr);
	*s = '\0';
	if (!rsfp)
	    RETURN(0);
	line++;
	if ((s = str_gets(linestr, rsfp)) == Nullch) {
	    if (rsfp != stdin)
		fclose(rsfp);
	    rsfp = Nullfp;
	    s = str_get(linestr);
	    RETURN(0);
	}
	goto retry;
    case ' ': case '\t':
	s++;
	goto retry;
    case '\n':
	*s = '\0';
	XTERM(NEWLINE);
    case '#':
	yylval = string(s,0);
	*s = '\0';
	XTERM(COMMENT);
    case ';':
	tmp = *s++;
	if (*s == '\n') {
	    s++;
	    XTERM(SEMINEW);
	}
	XTERM(tmp);
    case '(':
    case '{':
    case '[':
    case ')':
    case ']':
	tmp = *s++;
	XOP(tmp);
    case 127:
	s++;
	XTERM('}');
    case '}':
	for (d = s + 1; isspace(*d); d++) ;
	if (!*d)
	    s = d - 1;
	*s = 127;
	XTERM(';');
    case ',':
	tmp = *s++;
	XTERM(tmp);
    case '~':
	s++;
	XTERM(MATCHOP);
    case '+':
    case '-':
	if (s[1] == *s) {
	    s++;
	    if (*s++ == '+')
		XTERM(INCR);
	    else
		XTERM(DECR);
	}
	/* FALL THROUGH */
    case '*':
    case '%':
	tmp = *s++;
	if (*s == '=') {
	    yylval = string(s-1,2);
	    s++;
	    XTERM(ASGNOP);
	}
	XTERM(tmp);
    case '&':
	s++;
	tmp = *s++;
	if (tmp == '&')
	    XTERM(ANDAND);
	s--;
	XTERM('&');
    case '|':
	s++;
	tmp = *s++;
	if (tmp == '|')
	    XTERM(OROR);
	s--;
	XTERM('|');
    case '=':
	s++;
	tmp = *s++;
	if (tmp == '=') {
	    yylval = string("==",2);
	    XTERM(RELOP);
	}
	s--;
	yylval = string("=",1);
	XTERM(ASGNOP);
    case '!':
	s++;
	tmp = *s++;
	if (tmp == '=') {
	    yylval = string("!=",2);
	    XTERM(RELOP);
	}
	if (tmp == '~') {
	    yylval = string("!~",2);
	    XTERM(MATCHOP);
	}
	s--;
	XTERM(NOT);
    case '<':
	s++;
	tmp = *s++;
	if (tmp == '=') {
	    yylval = string("<=",2);
	    XTERM(RELOP);
	}
	s--;
	yylval = string("<",1);
	XTERM(RELOP);
    case '>':
	s++;
	tmp = *s++;
	if (tmp == '=') {
	    yylval = string(">=",2);
	    XTERM(RELOP);
	}
	s--;
	yylval = string(">",1);
	XTERM(RELOP);

#define SNARFWORD \
	d = tokenbuf; \
	while (isalpha(*s) || isdigit(*s) || *s == '_') \
	    *d++ = *s++; \
	*d = '\0'; \
	d = tokenbuf;

    case '$':
	s++;
	if (*s == '0') {
	    s++;
	    do_chop = TRUE;
	    need_entire = TRUE;
	    ID("0");
	}
	do_split = TRUE;
	if (isdigit(*s)) {
	    for (d = s; isdigit(*s); s++) ;
	    yylval = string(d,s-d);
	    tmp = atoi(d);
	    if (tmp > maxfld)
		maxfld = tmp;
	    XOP(FIELD);
	}
	split_to_array = set_array_base = TRUE;
	XOP(VFIELD);

    case '/':			/* may either be division or pattern */
	if (expectterm) {
	    s = scanpat(s);
	    XTERM(REGEX);
	}
	tmp = *s++;
	if (*s == '=') {
	    yylval = string("/=",2);
	    s++;
	    XTERM(ASGNOP);
	}
	XTERM(tmp);

    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
	s = scannum(s);
	XOP(NUMBER);
    case '"':
	s++;
	s = cpy2(tokenbuf,s,s[-1]);
	if (!*s)
	    fatal("String not terminated:\n%s",str_get(linestr));
	s++;
	yylval = string(tokenbuf,0);
	XOP(STRING);

    case 'a': case 'A':
	SNARFWORD;
	ID(d);
    case 'b': case 'B':
	SNARFWORD;
	if (strEQ(d,"break"))
	    XTERM(BREAK);
	if (strEQ(d,"BEGIN"))
	    XTERM(BEGIN);
	ID(d);
    case 'c': case 'C':
	SNARFWORD;
	if (strEQ(d,"continue"))
	    XTERM(CONTINUE);
	ID(d);
    case 'd': case 'D':
	SNARFWORD;
	ID(d);
    case 'e': case 'E':
	SNARFWORD;
	if (strEQ(d,"END"))
	    XTERM(END);
	if (strEQ(d,"else"))
	    XTERM(ELSE);
	if (strEQ(d,"exit")) {
	    saw_line_op = TRUE;
	    XTERM(EXIT);
	}
	if (strEQ(d,"exp")) {
	    yylval = OEXP;
	    XTERM(FUN1);
	}
	ID(d);
    case 'f': case 'F':
	SNARFWORD;
	if (strEQ(d,"FS")) {
	    saw_FS++;
	    if (saw_FS == 1 && in_begin) {
		for (d = s; *d && isspace(*d); d++) ;
		if (*d == '=') {
		    for (d++; *d && isspace(*d); d++) ;
		    if (*d == '"' && d[2] == '"')
			const_FS = d[1];
		}
	    }
	    ID(tokenbuf);
	}
	if (strEQ(d,"FILENAME"))
	    d = "ARGV";
	if (strEQ(d,"for"))
	    XTERM(FOR);
	ID(d);
    case 'g': case 'G':
	SNARFWORD;
	if (strEQ(d,"getline"))
	    XTERM(GETLINE);
	ID(d);
    case 'h': case 'H':
	SNARFWORD;
	ID(d);
    case 'i': case 'I':
	SNARFWORD;
	if (strEQ(d,"if"))
	    XTERM(IF);
	if (strEQ(d,"in"))
	    XTERM(IN);
	if (strEQ(d,"index")) {
	    set_array_base = TRUE;
	    XTERM(INDEX);
	}
	if (strEQ(d,"int")) {
	    yylval = OINT;
	    XTERM(FUN1);
	}
	ID(d);
    case 'j': case 'J':
	SNARFWORD;
	ID(d);
    case 'k': case 'K':
	SNARFWORD;
	ID(d);
    case 'l': case 'L':
	SNARFWORD;
	if (strEQ(d,"length")) {
	    yylval = OLENGTH;
	    XTERM(FUN1);
	}
	if (strEQ(d,"log")) {
	    yylval = OLOG;
	    XTERM(FUN1);
	}
	ID(d);
    case 'm': case 'M':
	SNARFWORD;
	ID(d);
    case 'n': case 'N':
	SNARFWORD;
	if (strEQ(d,"NF"))
	    do_split = split_to_array = set_array_base = TRUE;
	if (strEQ(d,"next")) {
	    saw_line_op = TRUE;
	    XTERM(NEXT);
	}
	ID(d);
    case 'o': case 'O':
	SNARFWORD;
	if (strEQ(d,"ORS")) {
	    saw_ORS = TRUE;
	    d = "$\\";
	}
	if (strEQ(d,"OFS")) {
	    saw_OFS = TRUE;
	    d = "$,";
	}
	if (strEQ(d,"OFMT")) {
	    d = "$#";
	}
	ID(d);
    case 'p': case 'P':
	SNARFWORD;
	if (strEQ(d,"print")) {
	    XTERM(PRINT);
	}
	if (strEQ(d,"printf")) {
	    XTERM(PRINTF);
	}
	ID(d);
    case 'q': case 'Q':
	SNARFWORD;
	ID(d);
    case 'r': case 'R':
	SNARFWORD;
	if (strEQ(d,"RS")) {
	    d = "$/";
	    saw_RS = TRUE;
	}
	ID(d);
    case 's': case 'S':
	SNARFWORD;
	if (strEQ(d,"split")) {
	    set_array_base = TRUE;
	    XOP(SPLIT);
	}
	if (strEQ(d,"substr")) {
	    set_array_base = TRUE;
	    XTERM(SUBSTR);
	}
	if (strEQ(d,"sprintf"))
	    XTERM(SPRINTF);
	if (strEQ(d,"sqrt")) {
	    yylval = OSQRT;
	    XTERM(FUN1);
	}
	ID(d);
    case 't': case 'T':
	SNARFWORD;
	ID(d);
    case 'u': case 'U':
	SNARFWORD;
	ID(d);
    case 'v': case 'V':
	SNARFWORD;
	ID(d);
    case 'w': case 'W':
	SNARFWORD;
	if (strEQ(d,"while"))
	    XTERM(WHILE);
	ID(d);
    case 'x': case 'X':
	SNARFWORD;
	ID(d);
    case 'y': case 'Y':
	SNARFWORD;
	ID(d);
    case 'z': case 'Z':
	SNARFWORD;
	ID(d);
    }
}

char *
scanpat(s)
register char *s;
{
    register char *d;

    switch (*s++) {
    case '/':
	break;
    default:
	fatal("Search pattern not found:\n%s",str_get(linestr));
    }
    s = cpytill(tokenbuf,s,s[-1]);
    if (!*s)
	fatal("Search pattern not terminated:\n%s",str_get(linestr));
    s++;
    yylval = string(tokenbuf,0);
    return s;
}

yyerror(s)
char *s;
{
    fprintf(stderr,"%s in file %s at line %d\n",
      s,filename,line);
}

char *
scannum(s)
register char *s;
{
    register char *d;

    switch (*s) {
    case '1': case '2': case '3': case '4': case '5':
    case '6': case '7': case '8': case '9': case '0' : case '.':
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
	yylval = string(tokenbuf,0);
	break;
    }
    return s;
}

string(ptr,len)
char *ptr;
{
    int retval = mop;

    ops[mop++].ival = OSTRING + (1<<8);
    if (!len)
	len = strlen(ptr);
    ops[mop].cval = safemalloc(len+1);
    strncpy(ops[mop].cval,ptr,len);
    ops[mop++].cval[len] = '\0';
    return retval;
}

oper0(type)
int type;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type;
    return retval;
}

oper1(type,arg1)
int type;
int arg1;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type + (1<<8);
    ops[mop++].ival = arg1;
    return retval;
}

oper2(type,arg1,arg2)
int type;
int arg1;
int arg2;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type + (2<<8);
    ops[mop++].ival = arg1;
    ops[mop++].ival = arg2;
    return retval;
}

oper3(type,arg1,arg2,arg3)
int type;
int arg1;
int arg2;
int arg3;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type + (3<<8);
    ops[mop++].ival = arg1;
    ops[mop++].ival = arg2;
    ops[mop++].ival = arg3;
    return retval;
}

oper4(type,arg1,arg2,arg3,arg4)
int type;
int arg1;
int arg2;
int arg3;
int arg4;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type + (4<<8);
    ops[mop++].ival = arg1;
    ops[mop++].ival = arg2;
    ops[mop++].ival = arg3;
    ops[mop++].ival = arg4;
    return retval;
}

oper5(type,arg1,arg2,arg3,arg4,arg5)
int type;
int arg1;
int arg2;
int arg3;
int arg4;
int arg5;
{
    int retval = mop;

    if (type > 255)
	fatal("type > 255 (%d)\n",type);
    ops[mop++].ival = type + (5<<8);
    ops[mop++].ival = arg1;
    ops[mop++].ival = arg2;
    ops[mop++].ival = arg3;
    ops[mop++].ival = arg4;
    ops[mop++].ival = arg5;
    return retval;
}

int depth = 0;

dump(branch)
int branch;
{
    register int type;
    register int len;
    register int i;

    type = ops[branch].ival;
    len = type >> 8;
    type &= 255;
    for (i=depth; i; i--)
	printf(" ");
    if (type == OSTRING) {
	printf("%-5d\"%s\"\n",branch,ops[branch+1].cval);
    }
    else {
	printf("(%-5d%s %d\n",branch,opname[type],len);
	depth++;
	for (i=1; i<=len; i++)
	    dump(ops[branch+i].ival);
	depth--;
	for (i=depth; i; i--)
	    printf(" ");
	printf(")\n");
    }
}

bl(arg,maybe)
int arg;
int maybe;
{
    if (!arg)
	return 0;
    else if ((ops[arg].ival & 255) != OBLOCK)
	return oper2(OBLOCK,arg,maybe);
    else if ((ops[arg].ival >> 8) != 2)
	return oper2(OBLOCK,ops[arg+1].ival,maybe);
    else
	return arg;
}

fixup(str)
STR *str;
{
    register char *s;
    register char *t;

    for (s = str->str_ptr; *s; s++) {
	if (*s == ';' && s[1] == ' ' && s[2] == '\n') {
	    strcpy(s+1,s+2);
	    s++;
	}
	else if (*s == '\n') {
	    for (t = s+1; isspace(*t & 127); t++) ;
	    t--;
	    while (isspace(*t & 127) && *t != '\n') t--;
	    if (*t == '\n' && t-s > 1) {
		if (s[-1] == '{')
		    s--;
		strcpy(s+1,t);
	    }
	    s++;
	}
    }
}

putlines(str)
STR *str;
{
    register char *d, *s, *t, *e;
    register int pos, newpos;

    d = tokenbuf;
    pos = 0;
    for (s = str->str_ptr; *s; s++) {
	*d++ = *s;
	pos++;
	if (*s == '\n') {
	    *d = '\0';
	    d = tokenbuf;
	    pos = 0;
	    putone();
	}
	else if (*s == '\t')
	    pos += 7;
	if (pos > 78) {		/* split a long line? */
	    *d-- = '\0';
	    newpos = 0;
	    for (t = tokenbuf; isspace(*t & 127); t++) {
		if (*t == '\t')
		    newpos += 8;
		else
		    newpos += 1;
	    }
	    e = d;
	    while (d > tokenbuf && (*d != ' ' || d[-1] != ';'))
		d--;
	    if (d < t+10) {
		d = e;
		while (d > tokenbuf &&
		  (*d != ' ' || d[-1] != '|' || d[-2] != '|') )
		    d--;
	    }
	    if (d < t+10) {
		d = e;
		while (d > tokenbuf &&
		  (*d != ' ' || d[-1] != '&' || d[-2] != '&') )
		    d--;
	    }
	    if (d < t+10) {
		d = e;
		while (d > tokenbuf && (*d != ' ' || d[-1] != ','))
		    d--;
	    }
	    if (d < t+10) {
		d = e;
		while (d > tokenbuf && *d != ' ')
		    d--;
	    }
	    if (d > t+3) {
		*d = '\0';
		putone();
		putchar('\n');
		if (d[-1] != ';' && !(newpos % 4)) {
		    *t++ = ' ';
		    *t++ = ' ';
		    newpos += 2;
		}
		strcpy(t,d+1);
		newpos += strlen(t);
		d = t + strlen(t);
		pos = newpos;
	    }
	    else
		d = e + 1;
	}
    }
}

putone()
{
    register char *t;

    for (t = tokenbuf; *t; t++) {
	*t &= 127;
	if (*t == 127) {
	    *t = ' ';
	    strcpy(t+strlen(t)-1, "\t#???\n");
	}
    }
    t = tokenbuf;
    if (*t == '#') {
	if (strnEQ(t,"#!/bin/awk",10) || strnEQ(t,"#! /bin/awk",11))
	    return;
    }
    fputs(tokenbuf,stdout);
}

numary(arg)
int arg;
{
    STR *key;
    int dummy;

    key = walk(0,0,arg,&dummy);
    str_cat(key,"[]");
    hstore(symtab,key->str_ptr,str_make("1"));
    str_free(key);
    set_array_base = TRUE;
    return arg;
}
