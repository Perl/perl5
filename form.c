/* $Header: form.c,v 3.0 89/10/18 15:17:26 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	form.c,v $
 * Revision 3.0  89/10/18  15:17:26  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

/* Forms stuff */

void
form_parseargs(fcmd)
register FCMD *fcmd;
{
    register int i;
    register ARG *arg;
    register int items;
    STR *str;
    ARG *parselist();
    line_t oldline = line;
    int oldsave = savestack->ary_fill;

    str = fcmd->f_unparsed;
    line = fcmd->f_line;
    fcmd->f_unparsed = Nullstr;
    (void)savehptr(&curstash);
    curstash = str->str_u.str_hash;
    arg = parselist(str);
    restorelist(oldsave);

    items = arg->arg_len - 1;	/* ignore $$ on end */
    for (i = 1; i <= items; i++) {
	if (!fcmd || fcmd->f_type == F_NULL)
	    fatal("Too many field values");
	dehoist(arg,i);
	fcmd->f_expr = make_op(O_ITEM,1,
	  arg[i].arg_ptr.arg_arg,Nullarg,Nullarg);
	if (fcmd->f_flags & FC_CHOP) {
	    if ((fcmd->f_expr[1].arg_type & A_MASK) == A_STAB)
		fcmd->f_expr[1].arg_type = A_LVAL;
	    else if ((fcmd->f_expr[1].arg_type & A_MASK) == A_EXPR)
		fcmd->f_expr[1].arg_type = A_LEXPR;
	    else
		fatal("^ field requires scalar lvalue");
	}
	fcmd = fcmd->f_next;
    }
    if (fcmd && fcmd->f_type)
	fatal("Not enough field values");
    line = oldline;
    Safefree(arg);
    str_free(str);
}

int newsize;

#define CHKLEN(allow) \
newsize = (d - orec->o_str) + (allow); \
if (newsize >= curlen) { \
    curlen = d - orec->o_str; \
    GROWSTR(&orec->o_str,&orec->o_len,orec->o_len + (allow)); \
    d = orec->o_str + curlen;	/* in case it moves */ \
    curlen = orec->o_len - 2; \
}

format(orec,fcmd,sp)
register struct outrec *orec;
register FCMD *fcmd;
int sp;
{
    register char *d = orec->o_str;
    register char *s;
    register int curlen = orec->o_len - 2;
    register int size;
    FCMD *nextfcmd;
    FCMD *linebeg = fcmd;
    char tmpchar;
    char *t;
    CMD mycmd;
    STR *str;
    char *chophere;

    mycmd.c_type = C_NULL;
    orec->o_lines = 0;
    for (; fcmd; fcmd = nextfcmd) {
	nextfcmd = fcmd->f_next;
	CHKLEN(fcmd->f_presize);
	if (s = fcmd->f_pre) {
	    while (*s) {
		if (*s == '\n') {
		    while (d > orec->o_str && (d[-1] == ' ' || d[-1] == '\t'))
			d--;
		    if (fcmd->f_flags & FC_NOBLANK) {
			if (d == orec->o_str || d[-1] == '\n') {
			    orec->o_lines--;	/* don't print blank line */
			    linebeg = fcmd->f_next;
			    break;
			}
			else if (fcmd->f_flags & FC_REPEAT)
			    nextfcmd = linebeg;
		    }
		    else
			linebeg = fcmd->f_next;
		}
		*d++ = *s++;
	    }
	}
	if (fcmd->f_unparsed)
	    form_parseargs(fcmd);
	switch (fcmd->f_type) {
	case F_NULL:
	    orec->o_lines++;
	    break;
	case F_LEFT:
	    (void)eval(fcmd->f_expr,G_SCALAR,sp);
	    str = stack->ary_array[sp+1];
	    s = str_get(str);
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		if (*s == '\t')
		    *s = ' ';
		size--;
		if (*s && index(chopset,(*d++ = *s++)))
		    chophere = s;
		if (*s == '\n' && (fcmd->f_flags & FC_CHOP))
		    *s = ' ';
	    }
	    if (size)
		chophere = s;
	    else if (chophere && chophere < s && *s && index(chopset,*s))
		chophere = s;
	    if (fcmd->f_flags & FC_CHOP) {
		if (!chophere)
		    chophere = s;
		size += (s - chophere);
		d -= (s - chophere);
		if (fcmd->f_flags & FC_MORE &&
		  *chophere && strNE(chophere,"\n")) {
		    while (size < 3) {
			d--;
			size++;
		    }
		    while (d[-1] == ' ' && size < fcmd->f_size) {
			d--;
			size++;
		    }
		    *d++ = '.';
		    *d++ = '.';
		    *d++ = '.';
		}
		while (*chophere && index(chopset,*chophere))
		    chophere++;
		str_chop(str,chophere);
	    }
	    if (fcmd->f_next && fcmd->f_next->f_pre[0] == '\n')
		size = 0;			/* no spaces before newline */
	    while (size) {
		size--;
		*d++ = ' ';
	    }
	    break;
	case F_RIGHT:
	    (void)eval(fcmd->f_expr,G_SCALAR,sp);
	    str = stack->ary_array[sp+1];
	    t = s = str_get(str);
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		if (*s == '\t')
		    *s = ' ';
		size--;
		if (*s && index(chopset,*s++))
		    chophere = s;
		if (*s == '\n' && (fcmd->f_flags & FC_CHOP))
		    *s = ' ';
	    }
	    if (size)
		chophere = s;
	    else if (chophere && chophere < s && *s && index(chopset,*s))
		chophere = s;
	    if (fcmd->f_flags & FC_CHOP) {
		if (!chophere)
		    chophere = s;
		size += (s - chophere);
		s = chophere;
		while (*chophere && index(chopset,*chophere))
		    chophere++;
	    }
	    tmpchar = *s;
	    *s = '\0';
	    while (size) {
		size--;
		*d++ = ' ';
	    }
	    size = s - t;
	    (void)bcopy(t,d,size);
	    d += size;
	    *s = tmpchar;
	    if (fcmd->f_flags & FC_CHOP)
		str_chop(str,chophere);
	    break;
	case F_CENTER: {
	    int halfsize;

	    (void)eval(fcmd->f_expr,G_SCALAR,sp);
	    str = stack->ary_array[sp+1];
	    t = s = str_get(str);
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		if (*s == '\t')
		    *s = ' ';
		size--;
		if (*s && index(chopset,*s++))
		    chophere = s;
		if (*s == '\n' && (fcmd->f_flags & FC_CHOP))
		    *s = ' ';
	    }
	    if (size)
		chophere = s;
	    else if (chophere && chophere < s && *s && index(chopset,*s))
		chophere = s;
	    if (fcmd->f_flags & FC_CHOP) {
		if (!chophere)
		    chophere = s;
		size += (s - chophere);
		s = chophere;
		while (*chophere && index(chopset,*chophere))
		    chophere++;
	    }
	    tmpchar = *s;
	    *s = '\0';
	    halfsize = size / 2;
	    while (size > halfsize) {
		size--;
		*d++ = ' ';
	    }
	    size = s - t;
	    (void)bcopy(t,d,size);
	    d += size;
	    *s = tmpchar;
	    if (fcmd->f_next && fcmd->f_next->f_pre[0] == '\n')
		size = 0;			/* no spaces before newline */
	    else
		size = halfsize;
	    while (size) {
		size--;
		*d++ = ' ';
	    }
	    if (fcmd->f_flags & FC_CHOP)
		str_chop(str,chophere);
	    break;
	}
	case F_LINES:
	    (void)eval(fcmd->f_expr,G_SCALAR,sp);
	    str = stack->ary_array[sp+1];
	    s = str_get(str);
	    size = str_len(str);
	    CHKLEN(size);
	    orec->o_lines += countlines(s);
	    (void)bcopy(s,d,size);
	    d += size;
	    linebeg = fcmd->f_next;
	    break;
	}
    }
    *d++ = '\0';
}

countlines(s)
register char *s;
{
    register int count = 0;

    while (*s) {
	if (*s++ == '\n')
	    count++;
    }
    return count;
}

do_write(orec,stio,sp)
struct outrec *orec;
register STIO *stio;
int sp;
{
    FILE *ofp = stio->ofp;

#ifdef DEBUGGING
    if (debug & 256)
	fprintf(stderr,"left=%ld, todo=%ld\n",
	  (long)stio->lines_left, (long)orec->o_lines);
#endif
    if (stio->lines_left < orec->o_lines) {
	if (!stio->top_stab) {
	    STAB *topstab;

	    if (!stio->top_name)
		stio->top_name = savestr("top");
	    topstab = stabent(stio->top_name,FALSE);
	    if (!topstab || !stab_form(topstab)) {
		stio->lines_left = 100000000;
		goto forget_top;
	    }
	    stio->top_stab = topstab;
	}
	if (stio->lines_left >= 0 && stio->page > 0)
	    (void)putc('\f',ofp);
	stio->lines_left = stio->page_len;
	stio->page++;
	format(&toprec,stab_form(stio->top_stab),sp);
	fputs(toprec.o_str,ofp);
	stio->lines_left -= toprec.o_lines;
    }
  forget_top:
    fputs(orec->o_str,ofp);
    stio->lines_left -= orec->o_lines;
}
