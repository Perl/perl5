/* $Header: util.c,v 2.0 88/06/05 00:15:11 root Exp $
 *
 * $Log:	util.c,v $
 * Revision 2.0  88/06/05  00:15:11  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#define FLUSH

static char nomem[] = "Out of memory!\n";

/* paranoid version of malloc */

#ifdef DEBUGGING
static int an = 0;
#endif

char *
safemalloc(size)
MEM_SIZE size;
{
    char *ptr;
    char *malloc();

    ptr = malloc(size?size:1);	/* malloc(0) is NASTY on our system */
#ifdef DEBUGGING
    if (debug & 128)
	fprintf(stderr,"0x%x: (%05d) malloc %d bytes\n",ptr,an++,size);
#endif
    if (ptr != Nullch)
	return ptr;
    else {
	fputs(nomem,stdout) FLUSH;
	exit(1);
    }
    /*NOTREACHED*/
}

/* paranoid version of realloc */

char *
saferealloc(where,size)
char *where;
MEM_SIZE size;
{
    char *ptr;
    char *realloc();

    if (!where)
	fatal("Null realloc");
    ptr = realloc(where,size?size:1);	/* realloc(0) is NASTY on our system */
#ifdef DEBUGGING
    if (debug & 128) {
	fprintf(stderr,"0x%x: (%05d) rfree\n",where,an++);
	fprintf(stderr,"0x%x: (%05d) realloc %d bytes\n",ptr,an++,size);
    }
#endif
    if (ptr != Nullch)
	return ptr;
    else {
	fputs(nomem,stdout) FLUSH;
	exit(1);
    }
    /*NOTREACHED*/
}

/* safe version of free */

safefree(where)
char *where;
{
#ifdef DEBUGGING
    if (debug & 128)
	fprintf(stderr,"0x%x: (%05d) free\n",where,an++);
#endif
    if (where) {
	free(where);
    }
}

#ifdef NOTDEF
/* safe version of string copy */

char *
safecpy(to,from,len)
char *to;
register char *from;
register int len;
{
    register char *dest = to;

    if (from != Nullch) 
	for (len--; len && (*dest++ = *from++); len--) ;
    *dest = '\0';
    return to;
}
#endif /*NOTDEF*/

#ifdef undef
/* safe version of string concatenate, with \n deletion and space padding */

char *
safecat(to,from,len)
char *to;
register char *from;
register int len;
{
    register char *dest = to;

    len--;				/* leave room for null */
    if (*dest) {
	while (len && *dest++) len--;
	if (len) {
	    len--;
	    *(dest-1) = ' ';
	}
    }
    if (from != Nullch)
	while (len && (*dest++ = *from++)) len--;
    if (len)
	dest--;
    if (*(dest-1) == '\n')
	dest--;
    *dest = '\0';
    return to;
}
#endif

/* copy a string up to some (non-backslashed) delimiter, if any */

char *
cpytill(to,from,delim)
register char *to, *from;
register int delim;
{
    for (; *from; from++,to++) {
	if (*from == '\\') {
	    if (from[1] == delim)
		from++;
	    else if (from[1] == '\\')
		*to++ = *from++;
	}
	else if (*from == delim)
	    break;
	*to = *from;
    }
    *to = '\0';
    return from;
}

/* return ptr to little string in big string, NULL if not found */
/* This routine was donated by Corey Satten. */

char *
instr(big, little)
register char *big;
register char *little;
{
    register char *s, *x;
    register int first = *little++;

    if (!first)
	return big;
    while (*big) {
	if (*big++ != first)
	    continue;
	for (x=big,s=little; *s; /**/ ) {
	    if (!*x)
		return Nullch;
	    if (*s++ != *x++) {
		s--;
		break;
	    }
	}
	if (!*s)
	    return big-1;
    }
    return Nullch;
}

#ifdef NOTDEF
void
bmcompile(str)
STR *str;
{
    register char *s;
    register char *table;
    register int i;
    register int len = str->str_cur;

    str_grow(str,len+128);
    s = str->str_ptr;
    table = s + len;
    for (i = 1; i < 128; i++) {
	table[i] = len;
    }
    i = 0;
    while (*s) {
	if (!isascii(*s))
	    return;
	if (table[*s] == len)
	    table[*s] = i;
	s++,i++;
    }
    str->str_pok |= 2;		/* deep magic */
}
#endif /* NOTDEF */

static unsigned char freq[] = {
	1,	2,	84,	151,	154,	155,	156,	157,
	165,	246,	250,	3,	158,	7,	18,	29,
	40,	51,	62,	73,	85,	96,	107,	118,
	129,	140,	147,	148,	149,	150,	152,	153,
	255,	182,	224,	205,	174,	176,	180,	217,
	233,	232,	236,	187,	235,	228,	234,	226,
	222,	219,	211,	195,	188,	193,	185,	184,
	191,	183,	201,	229,	181,	220,	194,	162,
	163,	208,	186,	202,	200,	218,	198,	179,
	178,	214,	166,	170,	207,	199,	209,	206,
	204,	160,	212,	216,	215,	192,	175,	173,
	243,	172,	161,	190,	203,	189,	164,	230,
	167,	248,	227,	244,	242,	255,	241,	231,
	240,	253,	169,	210,	245,	237,	249,	247,
	239,	168,	252,	251,	254,	238,	223,	221,
	213,	225,	177,	197,	171,	196,	159,	4,
	5,	6,	8,	9,	10,	11,	12,	13,
	14,	15,	16,	17,	19,	20,	21,	22,
	23,	24,	25,	26,	27,	28,	30,	31,
	32,	33,	34,	35,	36,	37,	38,	39,
	41,	42,	43,	44,	45,	46,	47,	48,
	49,	50,	52,	53,	54,	55,	56,	57,
	58,	59,	60,	61,	63,	64,	65,	66,
	67,	68,	69,	70,	71,	72,	74,	75,
	76,	77,	78,	79,	80,	81,	82,	83,
	86,	87,	88,	89,	90,	91,	92,	93,
	94,	95,	97,	98,	99,	100,	101,	102,
	103,	104,	105,	106,	108,	109,	110,	111,
	112,	113,	114,	115,	116,	117,	119,	120,
	121,	122,	123,	124,	125,	126,	127,	128,
	130,	131,	132,	133,	134,	135,	136,	137,
	138,	139,	141,	142,	143,	144,	145,	146
};

void
fbmcompile(str)
STR *str;
{
    register char *s;
    register char *table;
    register int i;
    register int len = str->str_cur;
    int rarest = 0;
    int frequency = 256;

    str_grow(str,len+128);
    table = str->str_ptr + len;		/* actually points at final '\0' */
    s = table - 1;
    for (i = 1; i < 128; i++) {
	table[i] = len;
    }
    i = 0;
    while (s >= str->str_ptr) {
	if (!isascii(*s))
	    return;
	if (table[*s] == len)
	    table[*s] = i;
	s--,i++;
    }
    str->str_pok |= 2;		/* deep magic */

    s = str->str_ptr;		/* deeper magic */
    for (i = 0; i < len; i++) {
	if (freq[s[i]] < frequency) {
	    rarest = i;
	    frequency = freq[s[i]];
	}
    }
    str->str_rare = s[rarest];
    str->str_prev = rarest;
#ifdef DEBUGGING
    if (debug & 512)
	fprintf(stderr,"rarest char %c at %d\n",str->str_rare, str->str_prev);
#endif
}

#ifdef NOTDEF
char *
bminstr(big, biglen, littlestr)
register char *big;
int biglen;
STR *littlestr;
{
    register char *s;
    register int tmp;
    register char *little = littlestr->str_ptr;
    int littlelen = littlestr->str_cur;
    register char *table = little + littlelen;

    s = big + biglen - littlelen;
    while (s >= big) {
	if (tmp = table[*s]) {
	    s -= tmp;
	}
	else {
	    if (strnEQ(s,little,littlelen))
		return s;
	    s--;
	}
    }
    return Nullch;
}
#endif /* NOTDEF */

char *
fbminstr(big, bigend, littlestr)
char *big;
register char *bigend;
STR *littlestr;
{
    register char *s;
    register int tmp;
    register int littlelen;
    register char *little;
    register char *table;
    register char *olds;
    register char *oldlittle;
    register int min;
    char *screaminstr();

    if (littlestr->str_pok != 3)
	return instr(big,littlestr->str_ptr);

    littlelen = littlestr->str_cur;
    table = littlestr->str_ptr + littlelen;
    s = big + --littlelen;
    oldlittle = little = table - 1;
    while (s < bigend) {
      top:
	if (tmp = table[*s]) {
	    s += tmp;
	}
	else {
	    tmp = littlelen;	/* less expensive than calling strncmp() */
	    olds = s;
	    while (tmp--) {
		if (*--s == *--little)
		    continue;
		s = olds + 1;	/* here we pay the price for failure */
		little = oldlittle;
		if (s < bigend)	/* fake up continue to outer loop */
		    goto top;
		return Nullch;
	    }
	    return s;
	}
    }
    return Nullch;
}

char *
screaminstr(bigstr, littlestr)
STR *bigstr;
STR *littlestr;
{
    register char *s, *x;
    register char *big = bigstr->str_ptr;
    register int pos;
    register int previous;
    register int first;
    register char *little;

    if ((pos = screamfirst[littlestr->str_rare]) < 0) 
	return Nullch;
    little = littlestr->str_ptr;
    first = *little++;
    previous = littlestr->str_prev;
    big -= previous;
    while (pos < previous) {
	if (!(pos += screamnext[pos]))
	    return Nullch;
    }
    do {
	if (big[pos] != first)
	    continue;
	for (x=big+pos+1,s=little; *s; /**/ ) {
	    if (!*x)
		return Nullch;
	    if (*s++ != *x++) {
		s--;
		break;
	    }
	}
	if (!*s)
	    return big+pos;
    } while (pos += screamnext[pos]);
    return Nullch;
}

/* copy a string to a safe spot */

char *
savestr(str)
char *str;
{
    register char *newaddr = safemalloc((MEM_SIZE)(strlen(str)+1));

    (void)strcpy(newaddr,str);
    return newaddr;
}

/* grow a static string to at least a certain length */

void
growstr(strptr,curlen,newlen)
char **strptr;
int *curlen;
int newlen;
{
    if (newlen > *curlen) {		/* need more room? */
	if (*curlen)
	    *strptr = saferealloc(*strptr,(MEM_SIZE)newlen);
	else
	    *strptr = safemalloc((MEM_SIZE)newlen);
	*curlen = newlen;
    }
}

extern int errno;

/*VARARGS1*/
mess(pat,a1,a2,a3,a4)
char *pat;
{
    char *s;

    s = tokenbuf;
    sprintf(s,pat,a1,a2,a3,a4);
    s += strlen(s);
    if (s[-1] != '\n') {
	if (line) {
	    sprintf(s," at %s line %ld",
	      in_eval?filename:origfilename, (long)line);
	    s += strlen(s);
	}
	if (last_in_stab &&
	    last_in_stab->stab_io &&
	    last_in_stab->stab_io->lines ) {
	    sprintf(s,", <%s> line %ld",
	      last_in_stab == argvstab ? "" : last_in_stab->stab_name,
	      (long)last_in_stab->stab_io->lines);
	    s += strlen(s);
	}
	strcpy(s,".\n");
    }
}

/*VARARGS1*/
fatal(pat,a1,a2,a3,a4)
char *pat;
{
    extern FILE *e_fp;
    extern char *e_tmpname;

    mess(pat,a1,a2,a3,a4);
    if (in_eval) {
	str_set(stabent("@",TRUE)->stab_val,tokenbuf);
	longjmp(eval_env,1);
    }
    fputs(tokenbuf,stderr);
    fflush(stderr);
    if (e_fp)
	UNLINK(e_tmpname);
    statusvalue >>= 8;
    exit(errno?errno:(statusvalue?statusvalue:255));
}

/*VARARGS1*/
warn(pat,a1,a2,a3,a4)
char *pat;
{
    mess(pat,a1,a2,a3,a4);
    fputs(tokenbuf,stderr);
    fflush(stderr);
}

static bool firstsetenv = TRUE;
extern char **environ;

void
setenv(nam,val)
char *nam, *val;
{
    register int i=envix(nam);		/* where does it go? */

    if (!environ[i]) {			/* does not exist yet */
	if (firstsetenv) {		/* need we copy environment? */
	    int j;
#ifndef lint
	    char **tmpenv = (char**)	/* point our wand at memory */
		safemalloc((i+2) * sizeof(char*));
#else
	    char **tmpenv = Null(char **);
#endif /* lint */
    
	    firstsetenv = FALSE;
	    for (j=0; j<i; j++)		/* copy environment */
		tmpenv[j] = environ[j];
	    environ = tmpenv;		/* tell exec where it is now */
	}
#ifndef lint
	else
	    environ = (char**) saferealloc((char*) environ,
		(i+2) * sizeof(char*));
					/* just expand it a bit */
#endif /* lint */
	environ[i+1] = Nullch;	/* make sure it's null terminated */
    }
    environ[i] = safemalloc((MEM_SIZE)(strlen(nam) + strlen(val) + 2));
					/* this may or may not be in */
					/* the old environ structure */
    sprintf(environ[i],"%s=%s",nam,val);/* all that work just for this */
}

int
envix(nam)
char *nam;
{
    register int i, len = strlen(nam);

    for (i = 0; environ[i]; i++) {
	if (strnEQ(environ[i],nam,len) && environ[i][len] == '=')
	    break;			/* strnEQ must come first to avoid */
    }					/* potential SEGV's */
    return i;
}

#ifdef EUNICE
unlnk(f)	/* unlink all versions of a file */
char *f;
{
    int i;

    for (i = 0; unlink(f) >= 0; i++) ;
    return i ? 0 : -1;
}
#endif

#ifndef BCOPY
#ifndef MEMCPY
char *
bcopy(from,to,len)
register char *from;
register char *to;
register int len;
{
    char *retval = to;

    while (len--)
	*to++ = *from++;
    return retval;
}

char *
bzero(loc,len)
register char *loc;
register int len;
{
    char *retval = loc;

    while (len--)
	*loc++ = 0;
    return retval;
}
#endif
#endif
