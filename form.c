/* $Header: form.c,v 1.0 87/12/18 13:05:07 root Exp $
 *
 * $Log:	form.c,v $
 * Revision 1.0  87/12/18  13:05:07  root
 * Initial revision
 * 
 */

#include "handy.h"
#include "EXTERN.h"
#include "search.h"
#include "util.h"
#include "perl.h"

/* Forms stuff */

#define CHKLEN(allow) \
if (d - orec->o_str + (allow) >= curlen) { \
    curlen = d - orec->o_str; \
    GROWSTR(&orec->o_str,&orec->o_len,orec->o_len + (allow) + 1); \
    d = orec->o_str + curlen;	/* in case it moves */ \
    curlen = orec->o_len - 2; \
}

format(orec,fcmd)
register struct outrec *orec;
register FCMD *fcmd;
{
    register char *d = orec->o_str;
    register char *s;
    register int curlen = orec->o_len - 2;
    register int size;
    char tmpchar;
    char *t;
    CMD mycmd;
    STR *str;
    char *chophere;

    mycmd.c_type = C_NULL;
    orec->o_lines = 0;
    for (; fcmd; fcmd = fcmd->f_next) {
	CHKLEN(fcmd->f_presize);
	for (s=fcmd->f_pre; *s;) {
	    if (*s == '\n') {
		while (d > orec->o_str && (d[-1] == ' ' || d[-1] == '\t'))
		    d--;
		if (fcmd->f_flags & FC_NOBLANK &&
		  (d == orec->o_str || d[-1] == '\n') ) {
		    orec->o_lines--;		/* don't print blank line */
		    break;
		}
	    }
	    *d++ = *s++;
	}
	switch (fcmd->f_type) {
	case F_NULL:
	    orec->o_lines++;
	    break;
	case F_LEFT:
	    str = eval(fcmd->f_expr,Null(char***),(double*)0);
	    s = str_get(str);
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		size--;
		if ((*d++ = *s++) == ' ')
		    chophere = s;
	    }
	    if (size)
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
		s = chophere;
		while (*chophere == ' ' || *chophere == '\n')
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
	    t = s = str_get(eval(fcmd->f_expr,Null(char***),(double*)0));
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		size--;
		if (*s++ == ' ')
			chophere = s;
	    }
	    if (size)
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
		s = chophere;
		while (*chophere == ' ' || *chophere == '\n')
			chophere++;
		str_chop(str,chophere);
	    }
	    tmpchar = *s;
	    *s = '\0';
	    while (size) {
		size--;
		*d++ = ' ';
	    }
	    size = s - t;
	    bcopy(t,d,size);
	    d += size;
	    *s = tmpchar;
	    break;
	case F_CENTER: {
	    int halfsize;

	    t = s = str_get(eval(fcmd->f_expr,Null(char***),(double*)0));
	    size = fcmd->f_size;
	    CHKLEN(size);
	    chophere = Nullch;
	    while (size && *s && *s != '\n') {
		size--;
		if (*s++ == ' ')
			chophere = s;
	    }
	    if (size)
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
		s = chophere;
		while (*chophere == ' ' || *chophere == '\n')
			chophere++;
		str_chop(str,chophere);
	    }
	    tmpchar = *s;
	    *s = '\0';
	    halfsize = size / 2;
	    while (size > halfsize) {
		size--;
		*d++ = ' ';
	    }
	    size = s - t;
	    bcopy(t,d,size);
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
	    break;
	}
	case F_LINES:
	    str = eval(fcmd->f_expr,Null(char***),(double*)0);
	    s = str_get(str);
	    size = str_len(str);
	    CHKLEN(size);
	    orec->o_lines += countlines(s);
	    bcopy(s,d,size);
	    d += size;
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

do_write(orec,stio)
struct outrec *orec;
register STIO *stio;
{
    FILE *ofp = stio->fp;

#ifdef DEBUGGING
    if (debug & 256)
	fprintf(stderr,"left=%d, todo=%d\n",stio->lines_left, orec->o_lines);
#endif
    if (stio->lines_left < orec->o_lines) {
	if (!stio->top_stab) {
	    STAB *topstab;

	    if (!stio->top_name)
		stio->top_name = savestr("top");
	    topstab = stabent(stio->top_name,FALSE);
	    if (!topstab || !topstab->stab_form) {
		stio->lines_left = 100000000;
		goto forget_top;
	    }
	    stio->top_stab = topstab;
	}
	if (stio->lines_left >= 0)
	    putc('\f',ofp);
	stio->lines_left = stio->page_len;
	stio->page++;
	format(&toprec,stio->top_stab->stab_form);
	fputs(toprec.o_str,ofp);
	stio->lines_left -= toprec.o_lines;
    }
  forget_top:
    fputs(orec->o_str,ofp);
    stio->lines_left -= orec->o_lines;
}
