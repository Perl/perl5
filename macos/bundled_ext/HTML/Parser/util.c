/* $Id: util.c,v 2.15 2001/03/26 22:27:48 gisle Exp $
 *
 * Copyright 1999-2001, Gisle Aas.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#ifndef EXTERN
#define EXTERN extern
#endif


EXTERN SV*
sv_lower(pTHX_ SV* sv)
{
    STRLEN len;
    char *s = SvPV_force(sv, len);
    for (; len--; s++)
	*s = toLOWER(*s);
    return sv;
}

EXTERN int
strnEQx(const char* s1, const char* s2, STRLEN n, int ignore_case)
{
    while (n--) {
	if (ignore_case) {
	    if (toLOWER(*s1) != toLOWER(*s2))
		return 0;
	}
	else {
	    if (*s1 != *s2)
		return 0;
	}
	s1++;
	s2++;
    }
    return 1;
}

static void
grow_gap(pTHX_ SV* sv, STRLEN grow, char** t, char** s, char** e)
{
    /*
     SvPVX ---> AAAAAA...BBBBBB
                     ^   ^     ^
                     t   s     e
    */
    STRLEN t_offset = *t - SvPVX(sv);
    STRLEN s_offset = *s - SvPVX(sv);
    STRLEN e_offset = *e - SvPVX(sv);

    SvGROW(sv, e_offset + grow + 1);

    *t = SvPVX(sv) + t_offset;
    *s = SvPVX(sv) + s_offset;
    *e = SvPVX(sv) + e_offset;

    Move(*s, *s+grow, *e - *s, char);
    *s += grow;
    *e += grow;
}

EXTERN SV*
decode_entities(pTHX_ SV* sv, HV* entity2char)
{
    STRLEN len;
    char *s = SvPV_force(sv, len);
    char *t = s;
    char *end = s + len;
    char *ent_start;

    char *repl;
    STRLEN repl_len;
#ifdef UNICODE_ENTITIES
    char buf[UTF8_MAXLEN];
    int repl_utf8;
#else
    char buf[1];
#endif

    while (s < end) {
	assert(t <= s);

	if ((*t++ = *s++) != '&')
	    continue;

	ent_start = s;
	repl = 0;

	if (*s == '#') {
	    UV num = 0;
	    UV prev = 0;
	    int ok = 0;
	    s++;
	    if (*s == 'x' || *s == 'X') {
		char *tmp;
		s++;
		while (*s) {
		    char *tmp = strchr(PL_hexdigit, *s);
		    if (!tmp)
			break;
		    num = num << 4 | ((tmp - PL_hexdigit) & 15);
		    if (prev && num <= prev) {
			/* overflow */
			ok = 0;
			break;
		    }
		    prev = num;
		    s++;
		    ok = 1;
		}
	    }
	    else {
		while (isDIGIT(*s)) {
		    num = num * 10 + (*s - '0');
		    if (prev && num < prev) {
			/* overflow */
			ok = 0;
			break;
		    }
		    prev = num;
		    s++;
		    ok = 1;
		}
	    }
	    if (ok) {
#ifdef UNICODE_ENTITIES
		if (!SvUTF8(sv) && num <= 255) {
		    buf[0] = num;
		    repl = buf;
		    repl_len = 1;
		    repl_utf8 = 0;
		}
		else {
		    char *tmp = uvuni_to_utf8(buf, num);
		    repl = buf;
		    repl_len = tmp - buf;
		    repl_utf8 = 1;
		}
#else
		if (num <= 255) {
		    buf[0] = num & 0xFF;
		    repl = buf;
		    repl_len = 1;
		}
#endif
	    }
	}
	else {
	    char *ent_name = s;
	    while (isALNUM(*s))
		s++;
	    if (ent_name != s && entity2char) {
		SV** svp = hv_fetch(entity2char, ent_name, s - ent_name, 0);
		if (svp) {
		    repl = SvPV(*svp, repl_len);
#ifdef UNICODE_ENTITIES
		    repl_utf8 = SvUTF8(*svp);
#endif
		}
	    }
	}

	if (repl) {
	    char *repl_allocated = 0;
	    if (*s == ';')
		s++;
	    t--;  /* '&' already copied, undo it */

#ifdef UNICODE_ENTITIES
	    if (!SvUTF8(sv) && repl_utf8) {
		int len = t - SvPVX(sv);
		if (len) {
		    /* need to upgrade the part that we have looked though */
		    int old_len = len;
		    char *ustr = bytes_to_utf8(SvPVX(sv), &len);
		    int grow = len - old_len;
		    if (grow) {
			/* XXX It might already be enough gap, so we don't need this,
			   but it should not hurt either.
			*/
			grow_gap(aTHX_ sv, grow, &t, &s, &end);
			Copy(ustr, SvPVX(sv), len, char);
			t = SvPVX(sv) + len;
		    }
		    Safefree(ustr);
		}
		SvUTF8_on(sv);
	    }
	    else if (SvUTF8(sv) && !repl_utf8) {
		repl = bytes_to_utf8(repl, &repl_len);
		repl_allocated = repl;
	    }
#endif

	    if (t + repl_len > s) {
		/* need to grow the string */
		grow_gap(aTHX_ sv, repl_len - (s - t), &t, &s, &end);
	    }

	    /* copy replacement string into string */
	    while (repl_len--)
		*t++ = *repl++;

	    if (repl_allocated)
		Safefree(repl_allocated);
	}
	else {
	    while (ent_start < s)
		*t++ = *ent_start++;
	}
    }

    *t = '\0';
    SvCUR_set(sv, t - SvPVX(sv));

    return sv;
}
