/*    pp_ctl.c
 *
 *    Copyright (c) 1991-2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * Now far ahead the Road has gone,
 * And I must follow, if I can,
 * Pursuing it with eager feet,
 * Until it joins some larger way
 * Where many paths and errands meet.
 * And whither then?  I cannot say.
 */

#include "EXTERN.h"
#define PERL_IN_PP_CTL_C
#include "perl.h"

#ifndef WORD_ALIGN
#define WORD_ALIGN sizeof(U16)
#endif

#define DOCATCH(o) ((CATCH_GET == TRUE) ? docatch(o) : (o))

static I32 sortcv(pTHXo_ SV *a, SV *b);
static I32 sortcv_stacked(pTHXo_ SV *a, SV *b);
static I32 sortcv_xsub(pTHXo_ SV *a, SV *b);
static I32 sv_ncmp(pTHXo_ SV *a, SV *b);
static I32 sv_i_ncmp(pTHXo_ SV *a, SV *b);
static I32 amagic_ncmp(pTHXo_ SV *a, SV *b);
static I32 amagic_i_ncmp(pTHXo_ SV *a, SV *b);
static I32 amagic_cmp(pTHXo_ SV *a, SV *b);
static I32 amagic_cmp_locale(pTHXo_ SV *a, SV *b);
static I32 run_user_filter(pTHXo_ int idx, SV *buf_sv, int maxlen);

#ifdef PERL_OBJECT
static I32 sv_cmp_static(pTHXo_ SV *a, SV *b);
static I32 sv_cmp_locale_static(pTHXo_ SV *a, SV *b);
#else
#define sv_cmp_static Perl_sv_cmp
#define sv_cmp_locale_static Perl_sv_cmp_locale
#endif

PP(pp_wantarray)
{
    dSP;
    I32 cxix;
    EXTEND(SP, 1);

    cxix = dopoptosub(cxstack_ix);
    if (cxix < 0)
	RETPUSHUNDEF;

    switch (cxstack[cxix].blk_gimme) {
    case G_ARRAY:
	RETPUSHYES;
    case G_SCALAR:
	RETPUSHNO;
    default:
	RETPUSHUNDEF;
    }
}

PP(pp_regcmaybe)
{
    return NORMAL;
}

PP(pp_regcreset)
{
    /* XXXX Should store the old value to allow for tie/overload - and
       restore in regcomp, where marked with XXXX. */
    PL_reginterp_cnt = 0;
    return NORMAL;
}

PP(pp_regcomp)
{
    dSP;
    register PMOP *pm = (PMOP*)cLOGOP->op_other;
    register char *t;
    SV *tmpstr;
    STRLEN len;
    MAGIC *mg = Null(MAGIC*);

    tmpstr = POPs;

    /* prevent recompiling under /o and ithreads. */
#if defined(USE_ITHREADS) || defined(USE_THREADS)
    if (pm->op_pmflags & PMf_KEEP && PM_GETRE(pm))
    	RETURN;
#endif

    if (SvROK(tmpstr)) {
	SV *sv = SvRV(tmpstr);
	if(SvMAGICAL(sv))
	    mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (mg) {
	regexp *re = (regexp *)mg->mg_obj;
	ReREFCNT_dec(pm->op_pmregexp);
	pm->op_pmregexp = ReREFCNT_inc(re);
    }
    else {
	t = SvPV(tmpstr, len);

	/* Check against the last compiled regexp. */
	if (!pm->op_pmregexp || !pm->op_pmregexp->precomp ||
	    pm->op_pmregexp->prelen != len ||
	    memNE(pm->op_pmregexp->precomp, t, len))
	{
	    if (pm->op_pmregexp) {
		ReREFCNT_dec(pm->op_pmregexp);
		pm->op_pmregexp = Null(REGEXP*);	/* crucial if regcomp aborts */
	    }
	    if (PL_op->op_flags & OPf_SPECIAL)
		PL_reginterp_cnt = I32_MAX; /* Mark as safe.  */

	    pm->op_pmflags = pm->op_pmpermflags;	/* reset case sensitivity */
	    if (DO_UTF8(tmpstr))
		pm->op_pmdynflags |= PMdf_DYN_UTF8;
	    else {
		pm->op_pmdynflags &= ~PMdf_DYN_UTF8;
		if (pm->op_pmdynflags & PMdf_UTF8)
		    t = (char*)bytes_to_utf8((U8*)t, &len);
	    }
	    pm->op_pmregexp = CALLREGCOMP(aTHX_ t, t + len, pm);
	    if (!DO_UTF8(tmpstr) && (pm->op_pmdynflags & PMdf_UTF8))
		Safefree(t);
	    PL_reginterp_cnt = 0;	/* XXXX Be extra paranoid - needed
					   inside tie/overload accessors.  */
	}
    }

#ifndef INCOMPLETE_TAINTS
    if (PL_tainting) {
	if (PL_tainted)
	    pm->op_pmdynflags |= PMdf_TAINTED;
	else
	    pm->op_pmdynflags &= ~PMdf_TAINTED;
    }
#endif

    if (!pm->op_pmregexp->prelen && PL_curpm)
	pm = PL_curpm;
    else if (strEQ("\\s+", pm->op_pmregexp->precomp))
	pm->op_pmflags |= PMf_WHITE;

    /* XXX runtime compiled output needs to move to the pad */
    if (pm->op_pmflags & PMf_KEEP) {
	pm->op_private &= ~OPpRUNTIME;	/* no point compiling again */
#if !defined(USE_ITHREADS) && !defined(USE_THREADS)
	/* XXX can't change the optree at runtime either */
	cLOGOP->op_first->op_next = PL_op->op_next;
#endif
    }
    RETURN;
}

PP(pp_substcont)
{
    dSP;
    register PMOP *pm = (PMOP*) cLOGOP->op_other;
    register PERL_CONTEXT *cx = &cxstack[cxstack_ix];
    register SV *dstr = cx->sb_dstr;
    register char *s = cx->sb_s;
    register char *m = cx->sb_m;
    char *orig = cx->sb_orig;
    register REGEXP *rx = cx->sb_rx;

    rxres_restore(&cx->sb_rxres, rx);

    if (cx->sb_iters++) {
	if (cx->sb_iters > cx->sb_maxiters)
	    DIE(aTHX_ "Substitution loop");

	if (!(cx->sb_rxtainted & 2) && SvTAINTED(TOPs))
	    cx->sb_rxtainted |= 2;
	sv_catsv(dstr, POPs);

	/* Are we done */
	if (cx->sb_once || !CALLREGEXEC(aTHX_ rx, s, cx->sb_strend, orig,
				     s == m, cx->sb_targ, NULL,
				     ((cx->sb_rflags & REXEC_COPY_STR)
				      ? (REXEC_IGNOREPOS|REXEC_NOT_FIRST)
				      : (REXEC_COPY_STR|REXEC_IGNOREPOS|REXEC_NOT_FIRST))))
	{
	    SV *targ = cx->sb_targ;

	    sv_catpvn(dstr, s, cx->sb_strend - s);
	    cx->sb_rxtainted |= RX_MATCH_TAINTED(rx);

	    (void)SvOOK_off(targ);
	    Safefree(SvPVX(targ));
	    SvPVX(targ) = SvPVX(dstr);
	    SvCUR_set(targ, SvCUR(dstr));
	    SvLEN_set(targ, SvLEN(dstr));
	    if (DO_UTF8(dstr))
		SvUTF8_on(targ);
	    SvPVX(dstr) = 0;
	    sv_free(dstr);

	    TAINT_IF(cx->sb_rxtainted & 1);
	    PUSHs(sv_2mortal(newSViv((I32)cx->sb_iters - 1)));

	    (void)SvPOK_only_UTF8(targ);
	    TAINT_IF(cx->sb_rxtainted);
	    SvSETMAGIC(targ);
	    SvTAINT(targ);

	    LEAVE_SCOPE(cx->sb_oldsave);
	    POPSUBST(cx);
	    RETURNOP(pm->op_next);
	}
    }
    if (RX_MATCH_COPIED(rx) && rx->subbeg != orig) {
	m = s;
	s = orig;
	cx->sb_orig = orig = rx->subbeg;
	s = orig + (m - s);
	cx->sb_strend = s + (cx->sb_strend - m);
    }
    cx->sb_m = m = rx->startp[0] + orig;
    if (m > s)
	sv_catpvn(dstr, s, m-s);
    cx->sb_s = rx->endp[0] + orig;
    { /* Update the pos() information. */
	SV *sv = cx->sb_targ;
	MAGIC *mg;
	I32 i;
	if (SvTYPE(sv) < SVt_PVMG)
	    (void)SvUPGRADE(sv, SVt_PVMG);
	if (!(mg = mg_find(sv, PERL_MAGIC_regex_global))) {
	    sv_magic(sv, Nullsv, PERL_MAGIC_regex_global, Nullch, 0);
	    mg = mg_find(sv, PERL_MAGIC_regex_global);
	}
	i = m - orig;
	if (DO_UTF8(sv))
	    sv_pos_b2u(sv, &i);
	mg->mg_len = i;
    }
    cx->sb_rxtainted |= RX_MATCH_TAINTED(rx);
    rxres_save(&cx->sb_rxres, rx);
    RETURNOP(pm->op_pmreplstart);
}

void
Perl_rxres_save(pTHX_ void **rsp, REGEXP *rx)
{
    UV *p = (UV*)*rsp;
    U32 i;

    if (!p || p[1] < rx->nparens) {
	i = 6 + rx->nparens * 2;
	if (!p)
	    New(501, p, i, UV);
	else
	    Renew(p, i, UV);
	*rsp = (void*)p;
    }

    *p++ = PTR2UV(RX_MATCH_COPIED(rx) ? rx->subbeg : Nullch);
    RX_MATCH_COPIED_off(rx);

    *p++ = rx->nparens;

    *p++ = PTR2UV(rx->subbeg);
    *p++ = (UV)rx->sublen;
    for (i = 0; i <= rx->nparens; ++i) {
	*p++ = (UV)rx->startp[i];
	*p++ = (UV)rx->endp[i];
    }
}

void
Perl_rxres_restore(pTHX_ void **rsp, REGEXP *rx)
{
    UV *p = (UV*)*rsp;
    U32 i;

    if (RX_MATCH_COPIED(rx))
	Safefree(rx->subbeg);
    RX_MATCH_COPIED_set(rx, *p);
    *p++ = 0;

    rx->nparens = *p++;

    rx->subbeg = INT2PTR(char*,*p++);
    rx->sublen = (I32)(*p++);
    for (i = 0; i <= rx->nparens; ++i) {
	rx->startp[i] = (I32)(*p++);
	rx->endp[i] = (I32)(*p++);
    }
}

void
Perl_rxres_free(pTHX_ void **rsp)
{
    UV *p = (UV*)*rsp;

    if (p) {
	Safefree(INT2PTR(char*,*p));
	Safefree(p);
	*rsp = Null(void*);
    }
}

PP(pp_formline)
{
    dSP; dMARK; dORIGMARK;
    register SV *tmpForm = *++MARK;
    register U16 *fpc;
    register char *t;
    register char *f;
    register char *s;
    register char *send;
    register I32 arg;
    register SV *sv = Nullsv;
    char *item = Nullch;
    I32 itemsize  = 0;
    I32 fieldsize = 0;
    I32 lines = 0;
    bool chopspace = (strchr(PL_chopset, ' ') != Nullch);
    char *chophere = Nullch;
    char *linemark = Nullch;
    NV value;
    bool gotsome = FALSE;
    STRLEN len;
    STRLEN fudge = SvCUR(tmpForm) * (IN_BYTES ? 1 : 3) + 1;
    bool item_is_utf = FALSE;

    if (!SvMAGICAL(tmpForm) || !SvCOMPILED(tmpForm)) {
	if (SvREADONLY(tmpForm)) {
	    SvREADONLY_off(tmpForm);
	    doparseform(tmpForm);
	    SvREADONLY_on(tmpForm);
	}
	else
	    doparseform(tmpForm);
    }

    SvPV_force(PL_formtarget, len);
    t = SvGROW(PL_formtarget, len + fudge + 1);  /* XXX SvCUR bad */
    t += len;
    f = SvPV(tmpForm, len);
    /* need to jump to the next word */
    s = f + len + WORD_ALIGN - SvCUR(tmpForm) % WORD_ALIGN;

    fpc = (U16*)s;

    for (;;) {
	DEBUG_f( {
	    char *name = "???";
	    arg = -1;
	    switch (*fpc) {
	    case FF_LITERAL:	arg = fpc[1]; name = "LITERAL";	break;
	    case FF_BLANK:	arg = fpc[1]; name = "BLANK";	break;
	    case FF_SKIP:	arg = fpc[1]; name = "SKIP";	break;
	    case FF_FETCH:	arg = fpc[1]; name = "FETCH";	break;
	    case FF_DECIMAL:	arg = fpc[1]; name = "DECIMAL";	break;

	    case FF_CHECKNL:	name = "CHECKNL";	break;
	    case FF_CHECKCHOP:	name = "CHECKCHOP";	break;
	    case FF_SPACE:	name = "SPACE";		break;
	    case FF_HALFSPACE:	name = "HALFSPACE";	break;
	    case FF_ITEM:	name = "ITEM";		break;
	    case FF_CHOP:	name = "CHOP";		break;
	    case FF_LINEGLOB:	name = "LINEGLOB";	break;
	    case FF_NEWLINE:	name = "NEWLINE";	break;
	    case FF_MORE:	name = "MORE";		break;
	    case FF_LINEMARK:	name = "LINEMARK";	break;
	    case FF_END:	name = "END";		break;
            case FF_0DECIMAL:	name = "0DECIMAL";	break;
	    }
	    if (arg >= 0)
		PerlIO_printf(Perl_debug_log, "%-16s%ld\n", name, (long) arg);
	    else
		PerlIO_printf(Perl_debug_log, "%-16s\n", name);
	} );
	switch (*fpc++) {
	case FF_LINEMARK:
	    linemark = t;
	    lines++;
	    gotsome = FALSE;
	    break;

	case FF_LITERAL:
	    arg = *fpc++;
	    while (arg--)
		*t++ = *f++;
	    break;

	case FF_SKIP:
	    f += *fpc++;
	    break;

	case FF_FETCH:
	    arg = *fpc++;
	    f += arg;
	    fieldsize = arg;

	    if (MARK < SP)
		sv = *++MARK;
	    else {
		sv = &PL_sv_no;
		if (ckWARN(WARN_SYNTAX))
		    Perl_warner(aTHX_ WARN_SYNTAX, "Not enough format arguments");
	    }
	    break;

	case FF_CHECKNL:
	    item = s = SvPV(sv, len);
	    itemsize = len;
	    if (DO_UTF8(sv)) {
		itemsize = sv_len_utf8(sv);
		if (itemsize != len) {
		    I32 itembytes;
		    if (itemsize > fieldsize) {
			itemsize = fieldsize;
			itembytes = itemsize;
			sv_pos_u2b(sv, &itembytes, 0);
		    }
		    else
			itembytes = len;
		    send = chophere = s + itembytes;
		    while (s < send) {
			if (*s & ~31)
			    gotsome = TRUE;
			else if (*s == '\n')
			    break;
			s++;
		    }
		    item_is_utf = TRUE;
		    itemsize = s - item;
		    sv_pos_b2u(sv, &itemsize);
		    break;
		}
	    }
	    item_is_utf = FALSE;
	    if (itemsize > fieldsize)
		itemsize = fieldsize;
	    send = chophere = s + itemsize;
	    while (s < send) {
		if (*s & ~31)
		    gotsome = TRUE;
		else if (*s == '\n')
		    break;
		s++;
	    }
	    itemsize = s - item;
	    break;

	case FF_CHECKCHOP:
	    item = s = SvPV(sv, len);
	    itemsize = len;
	    if (DO_UTF8(sv)) {
		itemsize = sv_len_utf8(sv);
		if (itemsize != len) {
		    I32 itembytes;
		    if (itemsize <= fieldsize) {
			send = chophere = s + itemsize;
			while (s < send) {
			    if (*s == '\r') {
				itemsize = s - item;
				break;
			    }
			    if (*s++ & ~31)
				gotsome = TRUE;
			}
		    }
		    else {
			itemsize = fieldsize;
			itembytes = itemsize;
			sv_pos_u2b(sv, &itembytes, 0);
			send = chophere = s + itembytes;
			while (s < send || (s == send && isSPACE(*s))) {
			    if (isSPACE(*s)) {
				if (chopspace)
				    chophere = s;
				if (*s == '\r')
				    break;
			    }
			    else {
				if (*s & ~31)
				    gotsome = TRUE;
				if (strchr(PL_chopset, *s))
				    chophere = s + 1;
			    }
			    s++;
			}
			itemsize = chophere - item;
			sv_pos_b2u(sv, &itemsize);
		    }
		    item_is_utf = TRUE;
		    break;
		}
	    }
	    item_is_utf = FALSE;
	    if (itemsize <= fieldsize) {
		send = chophere = s + itemsize;
		while (s < send) {
		    if (*s == '\r') {
			itemsize = s - item;
			break;
		    }
		    if (*s++ & ~31)
			gotsome = TRUE;
		}
	    }
	    else {
		itemsize = fieldsize;
		send = chophere = s + itemsize;
		while (s < send || (s == send && isSPACE(*s))) {
		    if (isSPACE(*s)) {
			if (chopspace)
			    chophere = s;
			if (*s == '\r')
			    break;
		    }
		    else {
			if (*s & ~31)
			    gotsome = TRUE;
			if (strchr(PL_chopset, *s))
			    chophere = s + 1;
		    }
		    s++;
		}
		itemsize = chophere - item;
	    }
	    break;

	case FF_SPACE:
	    arg = fieldsize - itemsize;
	    if (arg) {
		fieldsize -= arg;
		while (arg-- > 0)
		    *t++ = ' ';
	    }
	    break;

	case FF_HALFSPACE:
	    arg = fieldsize - itemsize;
	    if (arg) {
		arg /= 2;
		fieldsize -= arg;
		while (arg-- > 0)
		    *t++ = ' ';
	    }
	    break;

	case FF_ITEM:
	    arg = itemsize;
	    s = item;
	    if (item_is_utf) {
		while (arg--) {
		    if (UTF8_IS_CONTINUED(*s)) {
			STRLEN skip = UTF8SKIP(s);
			switch (skip) {
			default:
			    Move(s,t,skip,char);
			    s += skip;
			    t += skip;
			    break;
			case 7: *t++ = *s++;
			case 6: *t++ = *s++;
			case 5: *t++ = *s++;
			case 4: *t++ = *s++;
			case 3: *t++ = *s++;
			case 2: *t++ = *s++;
			case 1: *t++ = *s++;
			}
		    }
		    else {
			if ( !((*t++ = *s++) & ~31) )
			    t[-1] = ' ';
		    }
		}
		break;
	    }
	    while (arg--) {
#ifdef EBCDIC
		int ch = *t++ = *s++;
		if (iscntrl(ch))
#else
		if ( !((*t++ = *s++) & ~31) )
#endif
		    t[-1] = ' ';
	    }
	    break;

	case FF_CHOP:
	    s = chophere;
	    if (chopspace) {
		while (*s && isSPACE(*s))
		    s++;
	    }
	    sv_chop(sv,s);
	    break;

	case FF_LINEGLOB:
	    item = s = SvPV(sv, len);
	    itemsize = len;
	    item_is_utf = FALSE;		/* XXX is this correct? */
	    if (itemsize) {
		gotsome = TRUE;
		send = s + itemsize;
		while (s < send) {
		    if (*s++ == '\n') {
			if (s == send)
			    itemsize--;
			else
			    lines++;
		    }
		}
		SvCUR_set(PL_formtarget, t - SvPVX(PL_formtarget));
		sv_catpvn(PL_formtarget, item, itemsize);
		SvGROW(PL_formtarget, SvCUR(PL_formtarget) + fudge + 1);
		t = SvPVX(PL_formtarget) + SvCUR(PL_formtarget);
	    }
	    break;

	case FF_DECIMAL:
	    /* If the field is marked with ^ and the value is undefined,
	       blank it out. */
	    arg = *fpc++;
	    if ((arg & 512) && !SvOK(sv)) {
		arg = fieldsize;
		while (arg--)
		    *t++ = ' ';
		break;
	    }
	    gotsome = TRUE;
	    value = SvNV(sv);
	    /* Formats aren't yet marked for locales, so assume "yes". */
	    {
		STORE_NUMERIC_STANDARD_SET_LOCAL();
#if defined(USE_LONG_DOUBLE)
		if (arg & 256) {
		    sprintf(t, "%#*.*" PERL_PRIfldbl,
			    (int) fieldsize, (int) arg & 255, value);
		} else {
		    sprintf(t, "%*.0" PERL_PRIfldbl, (int) fieldsize, value);
		}
#else
		if (arg & 256) {
		    sprintf(t, "%#*.*f",
			    (int) fieldsize, (int) arg & 255, value);
		} else {
		    sprintf(t, "%*.0f",
			    (int) fieldsize, value);
		}
#endif
		RESTORE_NUMERIC_STANDARD();
	    }
	    t += fieldsize;
	    break;

	case FF_0DECIMAL:
	    /* If the field is marked with ^ and the value is undefined,
	       blank it out. */
	    arg = *fpc++;
	    if ((arg & 512) && !SvOK(sv)) {
		arg = fieldsize;
		while (arg--)
		    *t++ = ' ';
		break;
	    }
	    gotsome = TRUE;
	    value = SvNV(sv);
	    /* Formats aren't yet marked for locales, so assume "yes". */
	    {
		STORE_NUMERIC_STANDARD_SET_LOCAL();
#if defined(USE_LONG_DOUBLE)
		if (arg & 256) {
		    sprintf(t, "%#0*.*" PERL_PRIfldbl,
			    (int) fieldsize, (int) arg & 255, value);
/* is this legal? I don't have long doubles */
		} else {
		    sprintf(t, "%0*.0" PERL_PRIfldbl, (int) fieldsize, value);
		}
#else
		if (arg & 256) {
		    sprintf(t, "%#0*.*f",
			    (int) fieldsize, (int) arg & 255, value);
		} else {
		    sprintf(t, "%0*.0f",
			    (int) fieldsize, value);
		}
#endif
		RESTORE_NUMERIC_STANDARD();
	    }
	    t += fieldsize;
	    break;
	
	case FF_NEWLINE:
	    f++;
	    while (t-- > linemark && *t == ' ') ;
	    t++;
	    *t++ = '\n';
	    break;

	case FF_BLANK:
	    arg = *fpc++;
	    if (gotsome) {
		if (arg) {		/* repeat until fields exhausted? */
		    *t = '\0';
		    SvCUR_set(PL_formtarget, t - SvPVX(PL_formtarget));
		    lines += FmLINES(PL_formtarget);
		    if (lines == 200) {
			arg = t - linemark;
			if (strnEQ(linemark, linemark - arg, arg))
			    DIE(aTHX_ "Runaway format");
		    }
		    FmLINES(PL_formtarget) = lines;
		    SP = ORIGMARK;
		    RETURNOP(cLISTOP->op_first);
		}
	    }
	    else {
		t = linemark;
		lines--;
	    }
	    break;

	case FF_MORE:
	    s = chophere;
	    send = item + len;
	    if (chopspace) {
		while (*s && isSPACE(*s) && s < send)
		    s++;
	    }
	    if (s < send) {
		arg = fieldsize - itemsize;
		if (arg) {
		    fieldsize -= arg;
		    while (arg-- > 0)
			*t++ = ' ';
		}
		s = t - 3;
		if (strnEQ(s,"   ",3)) {
		    while (s > SvPVX(PL_formtarget) && isSPACE(s[-1]))
			s--;
		}
		*s++ = '.';
		*s++ = '.';
		*s++ = '.';
	    }
	    break;

	case FF_END:
	    *t = '\0';
	    SvCUR_set(PL_formtarget, t - SvPVX(PL_formtarget));
	    FmLINES(PL_formtarget) += lines;
	    SP = ORIGMARK;
	    RETPUSHYES;
	}
    }
}

PP(pp_grepstart)
{
    dSP;
    SV *src;

    if (PL_stack_base + *PL_markstack_ptr == SP) {
	(void)POPMARK;
	if (GIMME_V == G_SCALAR)
	    XPUSHs(sv_2mortal(newSViv(0)));
	RETURNOP(PL_op->op_next->op_next);
    }
    PL_stack_sp = PL_stack_base + *PL_markstack_ptr + 1;
    pp_pushmark();				/* push dst */
    pp_pushmark();				/* push src */
    ENTER;					/* enter outer scope */

    SAVETMPS;
    /* SAVE_DEFSV does *not* suffice here for USE_THREADS */
    SAVESPTR(DEFSV);
    ENTER;					/* enter inner scope */
    SAVEVPTR(PL_curpm);

    src = PL_stack_base[*PL_markstack_ptr];
    SvTEMP_off(src);
    DEFSV = src;

    PUTBACK;
    if (PL_op->op_type == OP_MAPSTART)
	pp_pushmark();			/* push top */
    return ((LOGOP*)PL_op->op_next)->op_other;
}

PP(pp_mapstart)
{
    DIE(aTHX_ "panic: mapstart");	/* uses grepstart */
}

PP(pp_mapwhile)
{
    dSP;
    I32 items = (SP - PL_stack_base) - *PL_markstack_ptr; /* how many new items */
    I32 count;
    I32 shift;
    SV** src;
    SV** dst;

    /* first, move source pointer to the next item in the source list */
    ++PL_markstack_ptr[-1];

    /* if there are new items, push them into the destination list */
    if (items) {
	/* might need to make room back there first */
	if (items > PL_markstack_ptr[-1] - PL_markstack_ptr[-2]) {
	    /* XXX this implementation is very pessimal because the stack
	     * is repeatedly extended for every set of items.  Is possible
	     * to do this without any stack extension or copying at all
	     * by maintaining a separate list over which the map iterates
	     * (like foreach does). --gsar */

	    /* everything in the stack after the destination list moves
	     * towards the end the stack by the amount of room needed */
	    shift = items - (PL_markstack_ptr[-1] - PL_markstack_ptr[-2]);

	    /* items to shift up (accounting for the moved source pointer) */
	    count = (SP - PL_stack_base) - (PL_markstack_ptr[-1] - 1);

	    /* This optimization is by Ben Tilly and it does
	     * things differently from what Sarathy (gsar)
	     * is describing.  The downside of this optimization is
	     * that leaves "holes" (uninitialized and hopefully unused areas)
	     * to the Perl stack, but on the other hand this
	     * shouldn't be a problem.  If Sarathy's idea gets
	     * implemented, this optimization should become
	     * irrelevant.  --jhi */
            if (shift < count)
                shift = count; /* Avoid shifting too often --Ben Tilly */
	
	    EXTEND(SP,shift);
	    src = SP;
	    dst = (SP += shift);
	    PL_markstack_ptr[-1] += shift;
	    *PL_markstack_ptr += shift;
	    while (count--)
		*dst-- = *src--;
	}
	/* copy the new items down to the destination list */
	dst = PL_stack_base + (PL_markstack_ptr[-2] += items) - 1;
	while (items--)
	    *dst-- = SvTEMP(TOPs) ? POPs : sv_mortalcopy(POPs);
    }
    LEAVE;					/* exit inner scope */

    /* All done yet? */
    if (PL_markstack_ptr[-1] > *PL_markstack_ptr) {
	I32 gimme = GIMME_V;

	(void)POPMARK;				/* pop top */
	LEAVE;					/* exit outer scope */
	(void)POPMARK;				/* pop src */
	items = --*PL_markstack_ptr - PL_markstack_ptr[-1];
	(void)POPMARK;				/* pop dst */
	SP = PL_stack_base + POPMARK;		/* pop original mark */
	if (gimme == G_SCALAR) {
	    dTARGET;
	    XPUSHi(items);
	}
	else if (gimme == G_ARRAY)
	    SP += items;
	RETURN;
    }
    else {
	SV *src;

	ENTER;					/* enter inner scope */
	SAVEVPTR(PL_curpm);

	/* set $_ to the new source item */
	src = PL_stack_base[PL_markstack_ptr[-1]];
	SvTEMP_off(src);
	DEFSV = src;

	RETURNOP(cLOGOP->op_other);
    }
}

PP(pp_sort)
{
    dSP; dMARK; dORIGMARK;
    register SV **up;
    SV **myorigmark = ORIGMARK;
    register I32 max;
    HV *stash;
    GV *gv;
    CV *cv = 0;
    I32 gimme = GIMME;
    OP* nextop = PL_op->op_next;
    I32 overloading = 0;
    bool hasargs = FALSE;
    I32 is_xsub = 0;

    if (gimme != G_ARRAY) {
	SP = MARK;
	RETPUSHUNDEF;
    }

    ENTER;
    SAVEVPTR(PL_sortcop);
    if (PL_op->op_flags & OPf_STACKED) {
	if (PL_op->op_flags & OPf_SPECIAL) {
	    OP *kid = cLISTOP->op_first->op_sibling;	/* pass pushmark */
	    kid = kUNOP->op_first;			/* pass rv2gv */
	    kid = kUNOP->op_first;			/* pass leave */
	    PL_sortcop = kid->op_next;
	    stash = CopSTASH(PL_curcop);
	}
	else {
	    cv = sv_2cv(*++MARK, &stash, &gv, 0);
	    if (cv && SvPOK(cv)) {
		STRLEN n_a;
		char *proto = SvPV((SV*)cv, n_a);
		if (proto && strEQ(proto, "$$")) {
		    hasargs = TRUE;
		}
	    }
	    if (!(cv && CvROOT(cv))) {
		if (cv && CvXSUB(cv)) {
		    is_xsub = 1;
		}
		else if (gv) {
		    SV *tmpstr = sv_newmortal();
		    gv_efullname3(tmpstr, gv, Nullch);
		    DIE(aTHX_ "Undefined sort subroutine \"%s\" called",
			SvPVX(tmpstr));
		}
		else {
		    DIE(aTHX_ "Undefined subroutine in sort");
		}
	    }

	    if (is_xsub)
		PL_sortcop = (OP*)cv;
	    else {
		PL_sortcop = CvSTART(cv);
		SAVEVPTR(CvROOT(cv)->op_ppaddr);
		CvROOT(cv)->op_ppaddr = PL_ppaddr[OP_NULL];

		SAVEVPTR(PL_curpad);
		PL_curpad = AvARRAY((AV*)AvARRAY(CvPADLIST(cv))[1]);
            }
	}
    }
    else {
	PL_sortcop = Nullop;
	stash = CopSTASH(PL_curcop);
    }

    up = myorigmark + 1;
    while (MARK < SP) {	/* This may or may not shift down one here. */
	/*SUPPRESS 560*/
	if ((*up = *++MARK)) {			/* Weed out nulls. */
	    SvTEMP_off(*up);
	    if (!PL_sortcop && !SvPOK(*up)) {
		STRLEN n_a;
	        if (SvAMAGIC(*up))
	            overloading = 1;
	        else
		    (void)sv_2pv(*up, &n_a);
	    }
	    up++;
	}
    }
    max = --up - myorigmark;
    if (PL_sortcop) {
	if (max > 1) {
	    PERL_CONTEXT *cx;
	    SV** newsp;
	    bool oldcatch = CATCH_GET;

	    SAVETMPS;
	    SAVEOP();

	    CATCH_SET(TRUE);
	    PUSHSTACKi(PERLSI_SORT);
	    if (!hasargs && !is_xsub) {
		if (PL_sortstash != stash || !PL_firstgv || !PL_secondgv) {
		    SAVESPTR(PL_firstgv);
		    SAVESPTR(PL_secondgv);
		    PL_firstgv = gv_fetchpv("a", TRUE, SVt_PV);
		    PL_secondgv = gv_fetchpv("b", TRUE, SVt_PV);
		    PL_sortstash = stash;
		}
#ifdef USE_THREADS
		sv_lock((SV *)PL_firstgv);
		sv_lock((SV *)PL_secondgv);
#endif
		SAVESPTR(GvSV(PL_firstgv));
		SAVESPTR(GvSV(PL_secondgv));
	    }

	    PUSHBLOCK(cx, CXt_NULL, PL_stack_base);
	    if (!(PL_op->op_flags & OPf_SPECIAL)) {
		cx->cx_type = CXt_SUB;
		cx->blk_gimme = G_SCALAR;
		PUSHSUB(cx);
		if (!CvDEPTH(cv))
		    (void)SvREFCNT_inc(cv); /* in preparation for POPSUB */
	    }
	    PL_sortcxix = cxstack_ix;

	    if (hasargs && !is_xsub) {
		/* This is mostly copied from pp_entersub */
		AV *av = (AV*)PL_curpad[0];

#ifndef USE_THREADS
		cx->blk_sub.savearray = GvAV(PL_defgv);
		GvAV(PL_defgv) = (AV*)SvREFCNT_inc(av);
#endif /* USE_THREADS */
		cx->blk_sub.oldcurpad = PL_curpad;
		cx->blk_sub.argarray = av;
	    }
	    qsortsv((myorigmark+1), max,
		    is_xsub ? sortcv_xsub : hasargs ? sortcv_stacked : sortcv);

	    POPBLOCK(cx,PL_curpm);
	    PL_stack_sp = newsp;
	    POPSTACK;
	    CATCH_SET(oldcatch);
	}
    }
    else {
	if (max > 1) {
	    MEXTEND(SP, 20);	/* Can't afford stack realloc on signal. */
	    qsortsv(ORIGMARK+1, max,
 		    (PL_op->op_private & OPpSORT_NUMERIC)
			? ( (PL_op->op_private & OPpSORT_INTEGER)
			    ? ( overloading ? amagic_i_ncmp : sv_i_ncmp)
			    : ( overloading ? amagic_ncmp : sv_ncmp))
			: ( IN_LOCALE_RUNTIME
			    ? ( overloading
				? amagic_cmp_locale
				: sv_cmp_locale_static)
			    : ( overloading ? amagic_cmp : sv_cmp_static)));
	    if (PL_op->op_private & OPpSORT_REVERSE) {
		SV **p = ORIGMARK+1;
		SV **q = ORIGMARK+max;
		while (p < q) {
		    SV *tmp = *p;
		    *p++ = *q;
		    *q-- = tmp;
		}
	    }
	}
    }
    LEAVE;
    PL_stack_sp = ORIGMARK + max;
    return nextop;
}

/* Range stuff. */

PP(pp_range)
{
    if (GIMME == G_ARRAY)
	return NORMAL;
    if (SvTRUEx(PAD_SV(PL_op->op_targ)))
	return cLOGOP->op_other;
    else
	return NORMAL;
}

PP(pp_flip)
{
    dSP;

    if (GIMME == G_ARRAY) {
	RETURNOP(((LOGOP*)cUNOP->op_first)->op_other);
    }
    else {
	dTOPss;
	SV *targ = PAD_SV(PL_op->op_targ);
 	int flip;

 	if (PL_op->op_private & OPpFLIP_LINENUM) {
 	    struct io *gp_io;
 	    flip = PL_last_in_gv
 		&& (gp_io = GvIO(PL_last_in_gv))
 		&& SvIV(sv) == (IV)IoLINES(gp_io);
 	} else {
 	    flip = SvTRUE(sv);
 	}
 	if (flip) {
	    sv_setiv(PAD_SV(cUNOP->op_first->op_targ), 1);
	    if (PL_op->op_flags & OPf_SPECIAL) {
		sv_setiv(targ, 1);
		SETs(targ);
		RETURN;
	    }
	    else {
		sv_setiv(targ, 0);
		SP--;
		RETURNOP(((LOGOP*)cUNOP->op_first)->op_other);
	    }
	}
	sv_setpv(TARG, "");
	SETs(targ);
	RETURN;
    }
}

PP(pp_flop)
{
    dSP;

    if (GIMME == G_ARRAY) {
	dPOPPOPssrl;
	register I32 i, j;
	register SV *sv;
	I32 max;

	if (SvGMAGICAL(left))
	    mg_get(left);
	if (SvGMAGICAL(right))
	    mg_get(right);

	if (SvNIOKp(left) || !SvPOKp(left) ||
	    SvNIOKp(right) || !SvPOKp(right) ||
	    (looks_like_number(left) && *SvPVX(left) != '0' &&
	     looks_like_number(right) && *SvPVX(right) != '0'))
	{
	    if (SvNV(left) < IV_MIN || SvNV(right) > IV_MAX)
		DIE(aTHX_ "Range iterator outside integer range");
	    i = SvIV(left);
	    max = SvIV(right);
	    if (max >= i) {
		j = max - i + 1;
		EXTEND_MORTAL(j);
		EXTEND(SP, j);
	    }
	    else
		j = 0;
	    while (j--) {
		sv = sv_2mortal(newSViv(i++));
		PUSHs(sv);
	    }
	}
	else {
	    SV *final = sv_mortalcopy(right);
	    STRLEN len, n_a;
	    char *tmps = SvPV(final, len);

	    sv = sv_mortalcopy(left);
	    SvPV_force(sv,n_a);
	    while (!SvNIOKp(sv) && SvCUR(sv) <= len) {
		XPUSHs(sv);
	        if (strEQ(SvPVX(sv),tmps))
	            break;
		sv = sv_2mortal(newSVsv(sv));
		sv_inc(sv);
	    }
	}
    }
    else {
	dTOPss;
	SV *targ = PAD_SV(cUNOP->op_first->op_targ);
	sv_inc(targ);
	if ((PL_op->op_private & OPpFLIP_LINENUM)
	  ? (GvIO(PL_last_in_gv)
	     && SvIV(sv) == (IV)IoLINES(GvIOp(PL_last_in_gv)))
	  : SvTRUE(sv) ) {
	    sv_setiv(PAD_SV(((UNOP*)cUNOP->op_first)->op_first->op_targ), 0);
	    sv_catpv(targ, "E0");
	}
	SETs(targ);
    }

    RETURN;
}

/* Control. */

STATIC I32
S_dopoptolabel(pTHX_ char *label)
{
    register I32 i;
    register PERL_CONTEXT *cx;

    for (i = cxstack_ix; i >= 0; i--) {
	cx = &cxstack[i];
	switch (CxTYPE(cx)) {
	case CXt_SUBST:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting substitution via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_SUB:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting subroutine via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_FORMAT:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting format via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_EVAL:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting eval via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_NULL:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting pseudo-block via %s",
			PL_op_name[PL_op->op_type]);
	    return -1;
	case CXt_LOOP:
	    if (!cx->blk_loop.label ||
	      strNE(label, cx->blk_loop.label) ) {
		DEBUG_l(Perl_deb(aTHX_ "(Skipping label #%ld %s)\n",
			(long)i, cx->blk_loop.label));
		continue;
	    }
	    DEBUG_l( Perl_deb(aTHX_ "(Found label #%ld %s)\n", (long)i, label));
	    return i;
	}
    }
    return i;
}

I32
Perl_dowantarray(pTHX)
{
    I32 gimme = block_gimme();
    return (gimme == G_VOID) ? G_SCALAR : gimme;
}

I32
Perl_block_gimme(pTHX)
{
    I32 cxix;

    cxix = dopoptosub(cxstack_ix);
    if (cxix < 0)
	return G_VOID;

    switch (cxstack[cxix].blk_gimme) {
    case G_VOID:
	return G_VOID;
    case G_SCALAR:
	return G_SCALAR;
    case G_ARRAY:
	return G_ARRAY;
    default:
	Perl_croak(aTHX_ "panic: bad gimme: %d\n", cxstack[cxix].blk_gimme);
	/* NOTREACHED */
	return 0;
    }
}

I32
Perl_is_lvalue_sub(pTHX)
{
    I32 cxix;

    cxix = dopoptosub(cxstack_ix);
    assert(cxix >= 0);  /* We should only be called from inside subs */

    if (cxstack[cxix].blk_sub.lval && CvLVALUE(cxstack[cxix].blk_sub.cv))
	return cxstack[cxix].blk_sub.lval;
    else
	return 0;
}

STATIC I32
S_dopoptosub(pTHX_ I32 startingblock)
{
    return dopoptosub_at(cxstack, startingblock);
}

STATIC I32
S_dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 startingblock)
{
    I32 i;
    register PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
	cx = &cxstk[i];
	switch (CxTYPE(cx)) {
	default:
	    continue;
	case CXt_EVAL:
	case CXt_SUB:
	case CXt_FORMAT:
	    DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
	    return i;
	}
    }
    return i;
}

STATIC I32
S_dopoptoeval(pTHX_ I32 startingblock)
{
    I32 i;
    register PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
	cx = &cxstack[i];
	switch (CxTYPE(cx)) {
	default:
	    continue;
	case CXt_EVAL:
	    DEBUG_l( Perl_deb(aTHX_ "(Found eval #%ld)\n", (long)i));
	    return i;
	}
    }
    return i;
}

STATIC I32
S_dopoptoloop(pTHX_ I32 startingblock)
{
    I32 i;
    register PERL_CONTEXT *cx;
    for (i = startingblock; i >= 0; i--) {
	cx = &cxstack[i];
	switch (CxTYPE(cx)) {
	case CXt_SUBST:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting substitution via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_SUB:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting subroutine via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_FORMAT:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting format via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_EVAL:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting eval via %s",
			PL_op_name[PL_op->op_type]);
	    break;
	case CXt_NULL:
	    if (ckWARN(WARN_EXITING))
		Perl_warner(aTHX_ WARN_EXITING, "Exiting pseudo-block via %s",
			PL_op_name[PL_op->op_type]);
	    return -1;
	case CXt_LOOP:
	    DEBUG_l( Perl_deb(aTHX_ "(Found loop #%ld)\n", (long)i));
	    return i;
	}
    }
    return i;
}

void
Perl_dounwind(pTHX_ I32 cxix)
{
    register PERL_CONTEXT *cx;
    I32 optype;

    while (cxstack_ix > cxix) {
	SV *sv;
	cx = &cxstack[cxstack_ix];
	DEBUG_l(PerlIO_printf(Perl_debug_log, "Unwinding block %ld, type %s\n",
			      (long) cxstack_ix, PL_block_type[CxTYPE(cx)]));
	/* Note: we don't need to restore the base context info till the end. */
	switch (CxTYPE(cx)) {
	case CXt_SUBST:
	    POPSUBST(cx);
	    continue;  /* not break */
	case CXt_SUB:
	    POPSUB(cx,sv);
	    LEAVESUB(sv);
	    break;
	case CXt_EVAL:
	    POPEVAL(cx);
	    break;
	case CXt_LOOP:
	    POPLOOP(cx);
	    break;
	case CXt_NULL:
	    break;
	case CXt_FORMAT:
	    POPFORMAT(cx);
	    break;
	}
	cxstack_ix--;
    }
}

void
Perl_qerror(pTHX_ SV *err)
{
    if (PL_in_eval)
	sv_catsv(ERRSV, err);
    else if (PL_errors)
	sv_catsv(PL_errors, err);
    else
	Perl_warn(aTHX_ "%"SVf, err);
    ++PL_error_count;
}

OP *
Perl_die_where(pTHX_ char *message, STRLEN msglen)
{
    STRLEN n_a;
    if (PL_in_eval) {
	I32 cxix;
	register PERL_CONTEXT *cx;
	I32 gimme;
	SV **newsp;

	if (message) {
	    if (PL_in_eval & EVAL_KEEPERR) {
		static char prefix[] = "\t(in cleanup) ";
		SV *err = ERRSV;
		char *e = Nullch;
		if (!SvPOK(err))
		    sv_setpv(err,"");
		else if (SvCUR(err) >= sizeof(prefix)+msglen-1) {
		    e = SvPV(err, n_a);
		    e += n_a - msglen;
		    if (*e != *message || strNE(e,message))
			e = Nullch;
		}
		if (!e) {
		    SvGROW(err, SvCUR(err)+sizeof(prefix)+msglen);
		    sv_catpvn(err, prefix, sizeof(prefix)-1);
		    sv_catpvn(err, message, msglen);
		    if (ckWARN(WARN_MISC)) {
			STRLEN start = SvCUR(err)-msglen-sizeof(prefix)+1;
			Perl_warner(aTHX_ WARN_MISC, SvPVX(err)+start);
		    }
		}
	    }
	    else {
		sv_setpvn(ERRSV, message, msglen);
	    }
	}
	else
	    message = SvPVx(ERRSV, msglen);

	while ((cxix = dopoptoeval(cxstack_ix)) < 0
	       && PL_curstackinfo->si_prev)
	{
	    dounwind(-1);
	    POPSTACK;
	}

	if (cxix >= 0) {
	    I32 optype;

	    if (cxix < cxstack_ix)
		dounwind(cxix);

	    POPBLOCK(cx,PL_curpm);
	    if (CxTYPE(cx) != CXt_EVAL) {
		PerlIO_write(Perl_error_log, "panic: die ", 11);
		PerlIO_write(Perl_error_log, message, msglen);
		my_exit(1);
	    }
	    POPEVAL(cx);

	    if (gimme == G_SCALAR)
		*++newsp = &PL_sv_undef;
	    PL_stack_sp = newsp;

	    LEAVE;

	    /* LEAVE could clobber PL_curcop (see save_re_context())
	     * XXX it might be better to find a way to avoid messing with
	     * PL_curcop in save_re_context() instead, but this is a more
	     * minimal fix --GSAR */
	    PL_curcop = cx->blk_oldcop;

	    if (optype == OP_REQUIRE) {
		char* msg = SvPVx(ERRSV, n_a);
		DIE(aTHX_ "%sCompilation failed in require",
		    *msg ? msg : "Unknown error\n");
	    }
	    return pop_return();
	}
    }
    if (!message)
	message = SvPVx(ERRSV, msglen);
    {
#ifdef USE_SFIO
	/* SFIO can really mess with your errno */
	int e = errno;
#endif
	PerlIO *serr = Perl_error_log;

	PerlIO_write(serr, message, msglen);
	(void)PerlIO_flush(serr);
#ifdef USE_SFIO
	errno = e;
#endif
    }
    my_failure_exit();
    /* NOTREACHED */
    return 0;
}

PP(pp_xor)
{
    dSP; dPOPTOPssrl;
    if (SvTRUE(left) != SvTRUE(right))
	RETSETYES;
    else
	RETSETNO;
}

PP(pp_andassign)
{
    dSP;
    if (!SvTRUE(TOPs))
	RETURN;
    else
	RETURNOP(cLOGOP->op_other);
}

PP(pp_orassign)
{
    dSP;
    if (SvTRUE(TOPs))
	RETURN;
    else
	RETURNOP(cLOGOP->op_other);
}
	
PP(pp_caller)
{
    dSP;
    register I32 cxix = dopoptosub(cxstack_ix);
    register PERL_CONTEXT *cx;
    register PERL_CONTEXT *ccstack = cxstack;
    PERL_SI *top_si = PL_curstackinfo;
    I32 dbcxix;
    I32 gimme;
    char *stashname;
    SV *sv;
    I32 count = 0;

    if (MAXARG)
	count = POPi;
    EXTEND(SP, 10);
    for (;;) {
	/* we may be in a higher stacklevel, so dig down deeper */
	while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
	    top_si = top_si->si_prev;
	    ccstack = top_si->si_cxstack;
	    cxix = dopoptosub_at(ccstack, top_si->si_cxix);
	}
	if (cxix < 0) {
	    if (GIMME != G_ARRAY)
		RETPUSHUNDEF;
	    RETURN;
	}
	if (PL_DBsub && cxix >= 0 &&
		ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
	    count++;
	if (!count--)
	    break;
	cxix = dopoptosub_at(ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        dbcxix = dopoptosub_at(ccstack, cxix - 1);
	/* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
	   field below is defined for any cx. */
	if (PL_DBsub && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
	    cx = &ccstack[dbcxix];
    }

    stashname = CopSTASHPV(cx->blk_oldcop);
    if (GIMME != G_ARRAY) {
	if (!stashname)
	    PUSHs(&PL_sv_undef);
	else {
	    dTARGET;
	    sv_setpv(TARG, stashname);
	    PUSHs(TARG);
	}
	RETURN;
    }

    if (!stashname)
	PUSHs(&PL_sv_undef);
    else
	PUSHs(sv_2mortal(newSVpv(stashname, 0)));
    PUSHs(sv_2mortal(newSVpv(CopFILE(cx->blk_oldcop), 0)));
    PUSHs(sv_2mortal(newSViv((I32)CopLINE(cx->blk_oldcop))));
    if (!MAXARG)
	RETURN;
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
	/* So is ccstack[dbcxix]. */
	sv = NEWSV(49, 0);
	gv_efullname3(sv, CvGV(ccstack[cxix].blk_sub.cv), Nullch);
	PUSHs(sv_2mortal(sv));
	PUSHs(sv_2mortal(newSViv((I32)cx->blk_sub.hasargs)));
    }
    else {
	PUSHs(sv_2mortal(newSVpvn("(eval)",6)));
	PUSHs(sv_2mortal(newSViv(0)));
    }
    gimme = (I32)cx->blk_gimme;
    if (gimme == G_VOID)
	PUSHs(&PL_sv_undef);
    else
	PUSHs(sv_2mortal(newSViv(gimme & G_ARRAY)));
    if (CxTYPE(cx) == CXt_EVAL) {
	/* eval STRING */
	if (cx->blk_eval.old_op_type == OP_ENTEREVAL) {
	    PUSHs(cx->blk_eval.cur_text);
	    PUSHs(&PL_sv_no);
	}
	/* require */
	else if (cx->blk_eval.old_namesv) {
	    PUSHs(sv_2mortal(newSVsv(cx->blk_eval.old_namesv)));
	    PUSHs(&PL_sv_yes);
	}
	/* eval BLOCK (try blocks have old_namesv == 0) */
	else {
	    PUSHs(&PL_sv_undef);
	    PUSHs(&PL_sv_undef);
	}
    }
    else {
	PUSHs(&PL_sv_undef);
	PUSHs(&PL_sv_undef);
    }
    if (CxTYPE(cx) == CXt_SUB && cx->blk_sub.hasargs
	&& CopSTASH_eq(PL_curcop, PL_debstash))
    {
	AV *ary = cx->blk_sub.argarray;
	int off = AvARRAY(ary) - AvALLOC(ary);

	if (!PL_dbargs) {
	    GV* tmpgv;
	    PL_dbargs = GvAV(gv_AVadd(tmpgv = gv_fetchpv("DB::args", TRUE,
				SVt_PVAV)));
	    GvMULTI_on(tmpgv);
	    AvREAL_off(PL_dbargs);	/* XXX should be REIFY (see av.h) */
	}

	if (AvMAX(PL_dbargs) < AvFILLp(ary) + off)
	    av_extend(PL_dbargs, AvFILLp(ary) + off);
	Copy(AvALLOC(ary), AvARRAY(PL_dbargs), AvFILLp(ary) + 1 + off, SV*);
	AvFILLp(PL_dbargs) = AvFILLp(ary) + off;
    }
    /* XXX only hints propagated via op_private are currently
     * visible (others are not easily accessible, since they
     * use the global PL_hints) */
    PUSHs(sv_2mortal(newSViv((I32)cx->blk_oldcop->op_private &
			     HINT_PRIVATE_MASK)));
    {
	SV * mask ;
	SV * old_warnings = cx->blk_oldcop->cop_warnings ;

	if  (old_warnings == pWARN_NONE ||
		(old_warnings == pWARN_STD && (PL_dowarn & G_WARN_ON) == 0))
            mask = newSVpvn(WARN_NONEstring, WARNsize) ;
        else if (old_warnings == pWARN_ALL ||
		  (old_warnings == pWARN_STD && PL_dowarn & G_WARN_ON))
            mask = newSVpvn(WARN_ALLstring, WARNsize) ;
        else
            mask = newSVsv(old_warnings);
        PUSHs(sv_2mortal(mask));
    }
    RETURN;
}

PP(pp_reset)
{
    dSP;
    char *tmps;
    STRLEN n_a;

    if (MAXARG < 1)
	tmps = "";
    else
	tmps = POPpx;
    sv_reset(tmps, CopSTASH(PL_curcop));
    PUSHs(&PL_sv_yes);
    RETURN;
}

PP(pp_lineseq)
{
    return NORMAL;
}

PP(pp_dbstate)
{
    PL_curcop = (COP*)PL_op;
    TAINT_NOT;		/* Each statement is presumed innocent */
    PL_stack_sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
    FREETMPS;

    if (PL_op->op_private || SvIV(PL_DBsingle) || SvIV(PL_DBsignal) || SvIV(PL_DBtrace))
    {
	dSP;
	register CV *cv;
	register PERL_CONTEXT *cx;
	I32 gimme = G_ARRAY;
	I32 hasargs;
	GV *gv;

	gv = PL_DBgv;
	cv = GvCV(gv);
	if (!cv)
	    DIE(aTHX_ "No DB::DB routine defined");

	if (CvDEPTH(cv) >= 1 && !(PL_debug & DEBUG_DB_RECURSE_FLAG))
	    /* don't do recursive DB::DB call */
	    return NORMAL;

	ENTER;
	SAVETMPS;

	SAVEI32(PL_debug);
	SAVESTACK_POS();
	PL_debug = 0;
	hasargs = 0;
	SPAGAIN;

	push_return(PL_op->op_next);
	PUSHBLOCK(cx, CXt_SUB, SP);
	PUSHSUB(cx);
	CvDEPTH(cv)++;
	(void)SvREFCNT_inc(cv);
	SAVEVPTR(PL_curpad);
	PL_curpad = AvARRAY((AV*)*av_fetch(CvPADLIST(cv),1,FALSE));
	RETURNOP(CvSTART(cv));
    }
    else
	return NORMAL;
}

PP(pp_scope)
{
    return NORMAL;
}

PP(pp_enteriter)
{
    dSP; dMARK;
    register PERL_CONTEXT *cx;
    I32 gimme = GIMME_V;
    SV **svp;
    U32 cxtype = CXt_LOOP;
#ifdef USE_ITHREADS
    void *iterdata;
#endif

    ENTER;
    SAVETMPS;

#ifdef USE_THREADS
    if (PL_op->op_flags & OPf_SPECIAL) {
	svp = &THREADSV(PL_op->op_targ);	/* per-thread variable */
	SAVEGENERICSV(*svp);
	*svp = NEWSV(0,0);
    }
    else
#endif /* USE_THREADS */
    if (PL_op->op_targ) {
#ifndef USE_ITHREADS
	svp = &PL_curpad[PL_op->op_targ];		/* "my" variable */
	SAVESPTR(*svp);
#else
	SAVEPADSV(PL_op->op_targ);
	iterdata = (void*)PL_op->op_targ;
	cxtype |= CXp_PADVAR;
#endif
    }
    else {
	GV *gv = (GV*)POPs;
	svp = &GvSV(gv);			/* symbol table variable */
	SAVEGENERICSV(*svp);
	*svp = NEWSV(0,0);
#ifdef USE_ITHREADS
	iterdata = (void*)gv;
#endif
    }

    ENTER;

    PUSHBLOCK(cx, cxtype, SP);
#ifdef USE_ITHREADS
    PUSHLOOP(cx, iterdata, MARK);
#else
    PUSHLOOP(cx, svp, MARK);
#endif
    if (PL_op->op_flags & OPf_STACKED) {
	cx->blk_loop.iterary = (AV*)SvREFCNT_inc(POPs);
	if (SvTYPE(cx->blk_loop.iterary) != SVt_PVAV) {
	    dPOPss;
	    if (SvNIOKp(sv) || !SvPOKp(sv) ||
		SvNIOKp(cx->blk_loop.iterary) || !SvPOKp(cx->blk_loop.iterary) ||
		(looks_like_number(sv) && *SvPVX(sv) != '0' &&
		 looks_like_number((SV*)cx->blk_loop.iterary) &&
		 *SvPVX(cx->blk_loop.iterary) != '0'))
	    {
		 if (SvNV(sv) < IV_MIN ||
		     SvNV((SV*)cx->blk_loop.iterary) >= IV_MAX)
		     DIE(aTHX_ "Range iterator outside integer range");
		 cx->blk_loop.iterix = SvIV(sv);
		 cx->blk_loop.itermax = SvIV((SV*)cx->blk_loop.iterary);
	    }
	    else
		cx->blk_loop.iterlval = newSVsv(sv);
	}
    }
    else {
	cx->blk_loop.iterary = PL_curstack;
	AvFILLp(PL_curstack) = SP - PL_stack_base;
	cx->blk_loop.iterix = MARK - PL_stack_base;
    }

    RETURN;
}

PP(pp_enterloop)
{
    dSP;
    register PERL_CONTEXT *cx;
    I32 gimme = GIMME_V;

    ENTER;
    SAVETMPS;
    ENTER;

    PUSHBLOCK(cx, CXt_LOOP, SP);
    PUSHLOOP(cx, 0, SP);

    RETURN;
}

PP(pp_leaveloop)
{
    dSP;
    register PERL_CONTEXT *cx;
    I32 gimme;
    SV **newsp;
    PMOP *newpm;
    SV **mark;

    POPBLOCK(cx,newpm);
    mark = newsp;
    newsp = PL_stack_base + cx->blk_loop.resetsp;

    TAINT_NOT;
    if (gimme == G_VOID)
	; /* do nothing */
    else if (gimme == G_SCALAR) {
	if (mark < SP)
	    *++newsp = sv_mortalcopy(*SP);
	else
	    *++newsp = &PL_sv_undef;
    }
    else {
	while (mark < SP) {
	    *++newsp = sv_mortalcopy(*++mark);
	    TAINT_NOT;		/* Each item is independent */
	}
    }
    SP = newsp;
    PUTBACK;

    POPLOOP(cx);	/* Stack values are safe: release loop vars ... */
    PL_curpm = newpm;	/* ... and pop $1 et al */

    LEAVE;
    LEAVE;

    return NORMAL;
}

PP(pp_return)
{
    dSP; dMARK;
    I32 cxix;
    register PERL_CONTEXT *cx;
    bool popsub2 = FALSE;
    bool clear_errsv = FALSE;
    I32 gimme;
    SV **newsp;
    PMOP *newpm;
    I32 optype = 0;
    SV *sv;

    if (PL_curstackinfo->si_type == PERLSI_SORT) {
	if (cxstack_ix == PL_sortcxix
	    || dopoptosub(cxstack_ix) <= PL_sortcxix)
	{
	    if (cxstack_ix > PL_sortcxix)
		dounwind(PL_sortcxix);
	    AvARRAY(PL_curstack)[1] = *SP;
	    PL_stack_sp = PL_stack_base + 1;
	    return 0;
	}
    }

    cxix = dopoptosub(cxstack_ix);
    if (cxix < 0)
	DIE(aTHX_ "Can't return outside a subroutine");
    if (cxix < cxstack_ix)
	dounwind(cxix);

    POPBLOCK(cx,newpm);
    switch (CxTYPE(cx)) {
    case CXt_SUB:
	popsub2 = TRUE;
	break;
    case CXt_EVAL:
	if (!(PL_in_eval & EVAL_KEEPERR))
	    clear_errsv = TRUE;
	POPEVAL(cx);
	if (CxTRYBLOCK(cx))
	    break;
	lex_end();
	if (optype == OP_REQUIRE &&
	    (MARK == SP || (gimme == G_SCALAR && !SvTRUE(*SP))) )
	{
	    /* Unassume the success we assumed earlier. */
	    SV *nsv = cx->blk_eval.old_namesv;
	    (void)hv_delete(GvHVn(PL_incgv), SvPVX(nsv), SvCUR(nsv), G_DISCARD);
	    DIE(aTHX_ "%s did not return a true value", SvPVX(nsv));
	}
	break;
    case CXt_FORMAT:
	POPFORMAT(cx);
	break;
    default:
	DIE(aTHX_ "panic: return");
    }

    TAINT_NOT;
    if (gimme == G_SCALAR) {
	if (MARK < SP) {
	    if (popsub2) {
		if (cx->blk_sub.cv && CvDEPTH(cx->blk_sub.cv) > 1) {
		    if (SvTEMP(TOPs)) {
			*++newsp = SvREFCNT_inc(*SP);
			FREETMPS;
			sv_2mortal(*newsp);
		    }
		    else {
			sv = SvREFCNT_inc(*SP);	/* FREETMPS could clobber it */
			FREETMPS;
			*++newsp = sv_mortalcopy(sv);
			SvREFCNT_dec(sv);
		    }
		}
		else
		    *++newsp = (SvTEMP(*SP)) ? *SP : sv_mortalcopy(*SP);
	    }
	    else
		*++newsp = sv_mortalcopy(*SP);
	}
	else
	    *++newsp = &PL_sv_undef;
    }
    else if (gimme == G_ARRAY) {
	while (++MARK <= SP) {
	    *++newsp = (popsub2 && SvTEMP(*MARK))
			? *MARK : sv_mortalcopy(*MARK);
	    TAINT_NOT;		/* Each item is independent */
	}
    }
    PL_stack_sp = newsp;

    /* Stack values are safe: */
    if (popsub2) {
	POPSUB(cx,sv);	/* release CV and @_ ... */
    }
    else
	sv = Nullsv;
    PL_curpm = newpm;	/* ... and pop $1 et al */

    LEAVE;
    LEAVESUB(sv);
    if (clear_errsv)
	sv_setpv(ERRSV,"");
    return pop_return();
}

PP(pp_last)
{
    dSP;
    I32 cxix;
    register PERL_CONTEXT *cx;
    I32 pop2 = 0;
    I32 gimme;
    I32 optype;
    OP *nextop;
    SV **newsp;
    PMOP *newpm;
    SV **mark;
    SV *sv = Nullsv;

    if (PL_op->op_flags & OPf_SPECIAL) {
	cxix = dopoptoloop(cxstack_ix);
	if (cxix < 0)
	    DIE(aTHX_ "Can't \"last\" outside a loop block");
    }
    else {
	cxix = dopoptolabel(cPVOP->op_pv);
	if (cxix < 0)
	    DIE(aTHX_ "Label not found for \"last %s\"", cPVOP->op_pv);
    }
    if (cxix < cxstack_ix)
	dounwind(cxix);

    POPBLOCK(cx,newpm);
    mark = newsp;
    switch (CxTYPE(cx)) {
    case CXt_LOOP:
	pop2 = CXt_LOOP;
	newsp = PL_stack_base + cx->blk_loop.resetsp;
	nextop = cx->blk_loop.last_op->op_next;
	break;
    case CXt_SUB:
	pop2 = CXt_SUB;
	nextop = pop_return();
	break;
    case CXt_EVAL:
	POPEVAL(cx);
	nextop = pop_return();
	break;
    case CXt_FORMAT:
	POPFORMAT(cx);
	nextop = pop_return();
	break;
    default:
	DIE(aTHX_ "panic: last");
    }

    TAINT_NOT;
    if (gimme == G_SCALAR) {
	if (MARK < SP)
	    *++newsp = ((pop2 == CXt_SUB) && SvTEMP(*SP))
			? *SP : sv_mortalcopy(*SP);
	else
	    *++newsp = &PL_sv_undef;
    }
    else if (gimme == G_ARRAY) {
	while (++MARK <= SP) {
	    *++newsp = ((pop2 == CXt_SUB) && SvTEMP(*MARK))
			? *MARK : sv_mortalcopy(*MARK);
	    TAINT_NOT;		/* Each item is independent */
	}
    }
    SP = newsp;
    PUTBACK;

    /* Stack values are safe: */
    switch (pop2) {
    case CXt_LOOP:
	POPLOOP(cx);	/* release loop vars ... */
	LEAVE;
	break;
    case CXt_SUB:
	POPSUB(cx,sv);	/* release CV and @_ ... */
	break;
    }
    PL_curpm = newpm;	/* ... and pop $1 et al */

    LEAVE;
    LEAVESUB(sv);
    return nextop;
}

PP(pp_next)
{
    I32 cxix;
    register PERL_CONTEXT *cx;
    I32 inner;

    if (PL_op->op_flags & OPf_SPECIAL) {
	cxix = dopoptoloop(cxstack_ix);
	if (cxix < 0)
	    DIE(aTHX_ "Can't \"next\" outside a loop block");
    }
    else {
	cxix = dopoptolabel(cPVOP->op_pv);
	if (cxix < 0)
	    DIE(aTHX_ "Label not found for \"next %s\"", cPVOP->op_pv);
    }
    if (cxix < cxstack_ix)
	dounwind(cxix);

    /* clear off anything above the scope we're re-entering, but
     * save the rest until after a possible continue block */
    inner = PL_scopestack_ix;
    TOPBLOCK(cx);
    if (PL_scopestack_ix < inner)
	leave_scope(PL_scopestack[PL_scopestack_ix]);
    return cx->blk_loop.next_op;
}

PP(pp_redo)
{
    I32 cxix;
    register PERL_CONTEXT *cx;
    I32 oldsave;

    if (PL_op->op_flags & OPf_SPECIAL) {
	cxix = dopoptoloop(cxstack_ix);
	if (cxix < 0)
	    DIE(aTHX_ "Can't \"redo\" outside a loop block");
    }
    else {
	cxix = dopoptolabel(cPVOP->op_pv);
	if (cxix < 0)
	    DIE(aTHX_ "Label not found for \"redo %s\"", cPVOP->op_pv);
    }
    if (cxix < cxstack_ix)
	dounwind(cxix);

    TOPBLOCK(cx);
    oldsave = PL_scopestack[PL_scopestack_ix - 1];
    LEAVE_SCOPE(oldsave);
    return cx->blk_loop.redo_op;
}

STATIC OP *
S_dofindlabel(pTHX_ OP *o, char *label, OP **opstack, OP **oplimit)
{
    OP *kid;
    OP **ops = opstack;
    static char too_deep[] = "Target of goto is too deeply nested";

    if (ops >= oplimit)
	Perl_croak(aTHX_ too_deep);
    if (o->op_type == OP_LEAVE ||
	o->op_type == OP_SCOPE ||
	o->op_type == OP_LEAVELOOP ||
	o->op_type == OP_LEAVETRY)
    {
	*ops++ = cUNOPo->op_first;
	if (ops >= oplimit)
	    Perl_croak(aTHX_ too_deep);
    }
    *ops = 0;
    if (o->op_flags & OPf_KIDS) {
	/* First try all the kids at this level, since that's likeliest. */
	for (kid = cUNOPo->op_first; kid; kid = kid->op_sibling) {
	    if ((kid->op_type == OP_NEXTSTATE || kid->op_type == OP_DBSTATE) &&
		    kCOP->cop_label && strEQ(kCOP->cop_label, label))
		return kid;
	}
	for (kid = cUNOPo->op_first; kid; kid = kid->op_sibling) {
	    if (kid == PL_lastgotoprobe)
		continue;
	    if ((kid->op_type == OP_NEXTSTATE || kid->op_type == OP_DBSTATE) &&
		(ops == opstack ||
		 (ops[-1]->op_type != OP_NEXTSTATE &&
		  ops[-1]->op_type != OP_DBSTATE)))
		*ops++ = kid;
	    if ((o = dofindlabel(kid, label, ops, oplimit)))
		return o;
	}
    }
    *ops = 0;
    return 0;
}

PP(pp_dump)
{
    return pp_goto();
    /*NOTREACHED*/
}

PP(pp_goto)
{
    dSP;
    OP *retop = 0;
    I32 ix;
    register PERL_CONTEXT *cx;
#define GOTO_DEPTH 64
    OP *enterops[GOTO_DEPTH];
    char *label;
    int do_dump = (PL_op->op_type == OP_DUMP);
    static char must_have_label[] = "goto must have label";

    label = 0;
    if (PL_op->op_flags & OPf_STACKED) {
	SV *sv = POPs;
	STRLEN n_a;

	/* This egregious kludge implements goto &subroutine */
	if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) {
	    I32 cxix;
	    register PERL_CONTEXT *cx;
	    CV* cv = (CV*)SvRV(sv);
	    SV** mark;
	    I32 items = 0;
	    I32 oldsave;

	retry:
	    if (!CvROOT(cv) && !CvXSUB(cv)) {
		GV *gv = CvGV(cv);
		GV *autogv;
		if (gv) {
		    SV *tmpstr;
		    /* autoloaded stub? */
		    if (cv != GvCV(gv) && (cv = GvCV(gv)))
			goto retry;
		    autogv = gv_autoload4(GvSTASH(gv), GvNAME(gv),
					  GvNAMELEN(gv), FALSE);
		    if (autogv && (cv = GvCV(autogv)))
			goto retry;
		    tmpstr = sv_newmortal();
		    gv_efullname3(tmpstr, gv, Nullch);
		    DIE(aTHX_ "Goto undefined subroutine &%s",SvPVX(tmpstr));
		}
		DIE(aTHX_ "Goto undefined subroutine");
	    }

	    /* First do some returnish stuff. */
	    cxix = dopoptosub(cxstack_ix);
	    if (cxix < 0)
		DIE(aTHX_ "Can't goto subroutine outside a subroutine");
	    if (cxix < cxstack_ix)
		dounwind(cxix);
	    TOPBLOCK(cx);
	    if (CxREALEVAL(cx))
		DIE(aTHX_ "Can't goto subroutine from an eval-string");
	    mark = PL_stack_sp;
	    if (CxTYPE(cx) == CXt_SUB && cx->blk_sub.hasargs) {
		/* put @_ back onto stack */
		AV* av = cx->blk_sub.argarray;
		
		items = AvFILLp(av) + 1;
		PL_stack_sp++;
		EXTEND(PL_stack_sp, items); /* @_ could have been extended. */
		Copy(AvARRAY(av), PL_stack_sp, items, SV*);
		PL_stack_sp += items;
#ifndef USE_THREADS
		SvREFCNT_dec(GvAV(PL_defgv));
		GvAV(PL_defgv) = cx->blk_sub.savearray;
#endif /* USE_THREADS */
		/* abandon @_ if it got reified */
		if (AvREAL(av)) {
		    (void)sv_2mortal((SV*)av);	/* delay until return */
		    av = newAV();
		    av_extend(av, items-1);
		    AvFLAGS(av) = AVf_REIFY;
		    PL_curpad[0] = (SV*)(cx->blk_sub.argarray = av);
		}
	    }
	    else if (CvXSUB(cv)) {	/* put GvAV(defgv) back onto stack */
		AV* av;
#ifdef USE_THREADS
		av = (AV*)PL_curpad[0];
#else
		av = GvAV(PL_defgv);
#endif
		items = AvFILLp(av) + 1;
		PL_stack_sp++;
		EXTEND(PL_stack_sp, items); /* @_ could have been extended. */
		Copy(AvARRAY(av), PL_stack_sp, items, SV*);
		PL_stack_sp += items;
	    }
	    if (CxTYPE(cx) == CXt_SUB &&
		!(CvDEPTH(cx->blk_sub.cv) = cx->blk_sub.olddepth))
		SvREFCNT_dec(cx->blk_sub.cv);
	    oldsave = PL_scopestack[PL_scopestack_ix - 1];
	    LEAVE_SCOPE(oldsave);

	    /* Now do some callish stuff. */
	    SAVETMPS;
	    if (CvXSUB(cv)) {
#ifdef PERL_XSUB_OLDSTYLE
		if (CvOLDSTYLE(cv)) {
		    I32 (*fp3)(int,int,int);
		    while (SP > mark) {
			SP[1] = SP[0];
			SP--;
		    }
		    fp3 = (I32(*)(int,int,int))CvXSUB(cv);
		    items = (*fp3)(CvXSUBANY(cv).any_i32,
		                   mark - PL_stack_base + 1,
				   items);
		    SP = PL_stack_base + items;
		}
		else
#endif /* PERL_XSUB_OLDSTYLE */
		{
		    SV **newsp;
		    I32 gimme;

		    PL_stack_sp--;		/* There is no cv arg. */
		    /* Push a mark for the start of arglist */
		    PUSHMARK(mark);
		    (void)(*CvXSUB(cv))(aTHXo_ cv);
		    /* Pop the current context like a decent sub should */
		    POPBLOCK(cx, PL_curpm);
		    /* Do _not_ use PUTBACK, keep the XSUB's return stack! */
		}
		LEAVE;
		return pop_return();
	    }
	    else {
		AV* padlist = CvPADLIST(cv);
		SV** svp = AvARRAY(padlist);
		if (CxTYPE(cx) == CXt_EVAL) {
		    PL_in_eval = cx->blk_eval.old_in_eval;
		    PL_eval_root = cx->blk_eval.old_eval_root;
		    cx->cx_type = CXt_SUB;
		    cx->blk_sub.hasargs = 0;
		}
		cx->blk_sub.cv = cv;
		cx->blk_sub.olddepth = CvDEPTH(cv);
		CvDEPTH(cv)++;
		if (CvDEPTH(cv) < 2)
		    (void)SvREFCNT_inc(cv);
		else {	/* save temporaries on recursion? */
		    if (CvDEPTH(cv) == 100 && ckWARN(WARN_RECURSION))
			sub_crush_depth(cv);
		    if (CvDEPTH(cv) > AvFILLp(padlist)) {
			AV *newpad = newAV();
			SV **oldpad = AvARRAY(svp[CvDEPTH(cv)-1]);
			I32 ix = AvFILLp((AV*)svp[1]);
			I32 names_fill = AvFILLp((AV*)svp[0]);
			svp = AvARRAY(svp[0]);
			for ( ;ix > 0; ix--) {
			    if (names_fill >= ix && svp[ix] != &PL_sv_undef) {
				char *name = SvPVX(svp[ix]);
				if ((SvFLAGS(svp[ix]) & SVf_FAKE)
				    || *name == '&')
				{
				    /* outer lexical or anon code */
				    av_store(newpad, ix,
					SvREFCNT_inc(oldpad[ix]) );
				}
				else {		/* our own lexical */
				    if (*name == '@')
					av_store(newpad, ix, sv = (SV*)newAV());
				    else if (*name == '%')
					av_store(newpad, ix, sv = (SV*)newHV());
				    else
					av_store(newpad, ix, sv = NEWSV(0,0));
				    SvPADMY_on(sv);
				}
			    }
			    else if (IS_PADGV(oldpad[ix]) || IS_PADCONST(oldpad[ix])) {
				av_store(newpad, ix, sv = SvREFCNT_inc(oldpad[ix]));
			    }
			    else {
				av_store(newpad, ix, sv = NEWSV(0,0));
				SvPADTMP_on(sv);
			    }
			}
			if (cx->blk_sub.hasargs) {
			    AV* av = newAV();
			    av_extend(av, 0);
			    av_store(newpad, 0, (SV*)av);
			    AvFLAGS(av) = AVf_REIFY;
			}
			av_store(padlist, CvDEPTH(cv), (SV*)newpad);
			AvFILLp(padlist) = CvDEPTH(cv);
			svp = AvARRAY(padlist);
		    }
		}
#ifdef USE_THREADS
		if (!cx->blk_sub.hasargs) {
		    AV* av = (AV*)PL_curpad[0];
		
		    items = AvFILLp(av) + 1;
		    if (items) {
			/* Mark is at the end of the stack. */
			EXTEND(SP, items);
			Copy(AvARRAY(av), SP + 1, items, SV*);
			SP += items;
			PUTBACK ;		
		    }
		}
#endif /* USE_THREADS */		
		SAVEVPTR(PL_curpad);
		PL_curpad = AvARRAY((AV*)svp[CvDEPTH(cv)]);
#ifndef USE_THREADS
		if (cx->blk_sub.hasargs)
#endif /* USE_THREADS */
		{
		    AV* av = (AV*)PL_curpad[0];
		    SV** ary;

#ifndef USE_THREADS
		    cx->blk_sub.savearray = GvAV(PL_defgv);
		    GvAV(PL_defgv) = (AV*)SvREFCNT_inc(av);
#endif /* USE_THREADS */
		    cx->blk_sub.oldcurpad = PL_curpad;
		    cx->blk_sub.argarray = av;
		    ++mark;

		    if (items >= AvMAX(av) + 1) {
			ary = AvALLOC(av);
			if (AvARRAY(av) != ary) {
			    AvMAX(av) += AvARRAY(av) - AvALLOC(av);
			    SvPVX(av) = (char*)ary;
			}
			if (items >= AvMAX(av) + 1) {
			    AvMAX(av) = items - 1;
			    Renew(ary,items+1,SV*);
			    AvALLOC(av) = ary;
			    SvPVX(av) = (char*)ary;
			}
		    }
		    Copy(mark,AvARRAY(av),items,SV*);
		    AvFILLp(av) = items - 1;
		    assert(!AvREAL(av));
		    while (items--) {
			if (*mark)
			    SvTEMP_off(*mark);
			mark++;
		    }
		}
		if (PERLDB_SUB) {	/* Checking curstash breaks DProf. */
		    /*
		     * We do not care about using sv to call CV;
		     * it's for informational purposes only.
		     */
		    SV *sv = GvSV(PL_DBsub);
		    CV *gotocv;
		
		    if (PERLDB_SUB_NN) {
			SvIVX(sv) = PTR2IV(cv); /* Already upgraded, saved */
		    } else {
			save_item(sv);
			gv_efullname3(sv, CvGV(cv), Nullch);
		    }
		    if (  PERLDB_GOTO
			  && (gotocv = get_cv("DB::goto", FALSE)) ) {
			PUSHMARK( PL_stack_sp );
			call_sv((SV*)gotocv, G_SCALAR | G_NODEBUG);
			PL_stack_sp--;
		    }
		}
		RETURNOP(CvSTART(cv));
	    }
	}
	else {
	    label = SvPV(sv,n_a);
	    if (!(do_dump || *label))
		DIE(aTHX_ must_have_label);
	}
    }
    else if (PL_op->op_flags & OPf_SPECIAL) {
	if (! do_dump)
	    DIE(aTHX_ must_have_label);
    }
    else
	label = cPVOP->op_pv;

    if (label && *label) {
	OP *gotoprobe = 0;
	bool leaving_eval = FALSE;
        PERL_CONTEXT *last_eval_cx = 0;

	/* find label */

	PL_lastgotoprobe = 0;
	*enterops = 0;
	for (ix = cxstack_ix; ix >= 0; ix--) {
	    cx = &cxstack[ix];
	    switch (CxTYPE(cx)) {
	    case CXt_EVAL:
		leaving_eval = TRUE;
                if (CxREALEVAL(cx)) {
		    gotoprobe = (last_eval_cx ?
				last_eval_cx->blk_eval.old_eval_root :
				PL_eval_root);
		    last_eval_cx = cx;
		    break;
                }
                /* else fall through */
	    case CXt_LOOP:
		gotoprobe = cx->blk_oldcop->op_sibling;
		break;
	    case CXt_SUBST:
		continue;
	    case CXt_BLOCK:
		if (ix)
		    gotoprobe = cx->blk_oldcop->op_sibling;
		else
		    gotoprobe = PL_main_root;
		break;
	    case CXt_SUB:
		if (CvDEPTH(cx->blk_sub.cv)) {
		    gotoprobe = CvROOT(cx->blk_sub.cv);
		    break;
		}
		/* FALL THROUGH */
	    case CXt_FORMAT:
	    case CXt_NULL:
		DIE(aTHX_ "Can't \"goto\" out of a pseudo block");
	    default:
		if (ix)
		    DIE(aTHX_ "panic: goto");
		gotoprobe = PL_main_root;
		break;
	    }
	    if (gotoprobe) {
		retop = dofindlabel(gotoprobe, label,
				    enterops, enterops + GOTO_DEPTH);
		if (retop)
		    break;
	    }
	    PL_lastgotoprobe = gotoprobe;
	}
	if (!retop)
	    DIE(aTHX_ "Can't find label %s", label);

	/* if we're leaving an eval, check before we pop any frames
           that we're not going to punt, otherwise the error
	   won't be caught */

	if (leaving_eval && *enterops && enterops[1]) {
	    I32 i;
            for (i = 1; enterops[i]; i++)
                if (enterops[i]->op_type == OP_ENTERITER)
                    DIE(aTHX_ "Can't \"goto\" into the middle of a foreach loop");
	}

	/* pop unwanted frames */

	if (ix < cxstack_ix) {
	    I32 oldsave;

	    if (ix < 0)
		ix = 0;
	    dounwind(ix);
	    TOPBLOCK(cx);
	    oldsave = PL_scopestack[PL_scopestack_ix];
	    LEAVE_SCOPE(oldsave);
	}

	/* push wanted frames */

	if (*enterops && enterops[1]) {
	    OP *oldop = PL_op;
	    for (ix = 1; enterops[ix]; ix++) {
		PL_op = enterops[ix];
		/* Eventually we may want to stack the needed arguments
		 * for each op.  For now, we punt on the hard ones. */
		if (PL_op->op_type == OP_ENTERITER)
		    DIE(aTHX_ "Can't \"goto\" into the middle of a foreach loop");
		CALL_FPTR(PL_op->op_ppaddr)(aTHX);
	    }
	    PL_op = oldop;
	}
    }

    if (do_dump) {
#ifdef VMS
	if (!retop) retop = PL_main_start;
#endif
	PL_restartop = retop;
	PL_do_undump = TRUE;

	my_unexec();

	PL_restartop = 0;		/* hmm, must be GNU unexec().. */
	PL_do_undump = FALSE;
    }

    RETURNOP(retop);
}

PP(pp_exit)
{
    dSP;
    I32 anum;

    if (MAXARG < 1)
	anum = 0;
    else {
	anum = SvIVx(POPs);
#ifdef VMS
        if (anum == 1 && (PL_op->op_private & OPpEXIT_VMSISH))
	    anum = 0;
#endif
    }
    PL_exit_flags |= PERL_EXIT_EXPECTED;
    my_exit(anum);
    PUSHs(&PL_sv_undef);
    RETURN;
}

#ifdef NOTYET
PP(pp_nswitch)
{
    dSP;
    NV value = SvNVx(GvSV(cCOP->cop_gv));
    register I32 match = I_32(value);

    if (value < 0.0) {
	if (((NV)match) > value)
	    --match;		/* was fractional--truncate other way */
    }
    match -= cCOP->uop.scop.scop_offset;
    if (match < 0)
	match = 0;
    else if (match > cCOP->uop.scop.scop_max)
	match = cCOP->uop.scop.scop_max;
    PL_op = cCOP->uop.scop.scop_next[match];
    RETURNOP(PL_op);
}

PP(pp_cswitch)
{
    dSP;
    register I32 match;

    if (PL_multiline)
	PL_op = PL_op->op_next;			/* can't assume anything */
    else {
	STRLEN n_a;
	match = *(SvPVx(GvSV(cCOP->cop_gv), n_a)) & 255;
	match -= cCOP->uop.scop.scop_offset;
	if (match < 0)
	    match = 0;
	else if (match > cCOP->uop.scop.scop_max)
	    match = cCOP->uop.scop.scop_max;
	PL_op = cCOP->uop.scop.scop_next[match];
    }
    RETURNOP(PL_op);
}
#endif

/* Eval. */

STATIC void
S_save_lines(pTHX_ AV *array, SV *sv)
{
    register char *s = SvPVX(sv);
    register char *send = SvPVX(sv) + SvCUR(sv);
    register char *t;
    register I32 line = 1;

    while (s && s < send) {
	SV *tmpstr = NEWSV(85,0);

	sv_upgrade(tmpstr, SVt_PVMG);
	t = strchr(s, '\n');
	if (t)
	    t++;
	else
	    t = send;

	sv_setpvn(tmpstr, s, t - s);
	av_store(array, line++, tmpstr);
	s = t;
    }
}

#ifdef PERL_FLEXIBLE_EXCEPTIONS
STATIC void *
S_docatch_body(pTHX_ va_list args)
{
    return docatch_body();
}
#endif

STATIC void *
S_docatch_body(pTHX)
{
    CALLRUNOPS(aTHX);
    return NULL;
}

STATIC OP *
S_docatch(pTHX_ OP *o)
{
    int ret;
    OP *oldop = PL_op;
    volatile PERL_SI *cursi = PL_curstackinfo;
    dJMPENV;

#ifdef DEBUGGING
    assert(CATCH_GET == TRUE);
#endif
    PL_op = o;
#ifdef PERL_FLEXIBLE_EXCEPTIONS
 redo_body:
    CALLPROTECT(aTHX_ pcur_env, &ret, MEMBER_TO_FPTR(S_docatch_body));
#else
    JMPENV_PUSH(ret);
#endif
    switch (ret) {
    case 0:
#ifndef PERL_FLEXIBLE_EXCEPTIONS
 redo_body:
	docatch_body();
#endif
	break;
    case 3:
	if (PL_restartop && cursi == PL_curstackinfo) {
	    PL_op = PL_restartop;
	    PL_restartop = 0;
	    goto redo_body;
	}
	/* FALL THROUGH */
    default:
	JMPENV_POP;
	PL_op = oldop;
	JMPENV_JUMP(ret);
	/* NOTREACHED */
    }
    JMPENV_POP;
    PL_op = oldop;
    return Nullop;
}

OP *
Perl_sv_compile_2op(pTHX_ SV *sv, OP** startop, char *code, AV** avp)
/* sv Text to convert to OP tree. */
/* startop op_free() this to undo. */
/* code Short string id of the caller. */
{
    dSP;				/* Make POPBLOCK work. */
    PERL_CONTEXT *cx;
    SV **newsp;
    I32 gimme = 0;   /* SUSPECT - INITIALZE TO WHAT?  NI-S */
    I32 optype;
    OP dummy;
    OP *rop;
    char tbuf[TYPE_DIGITS(long) + 12 + 10];
    char *tmpbuf = tbuf;
    char *safestr;

    ENTER;
    lex_start(sv);
    SAVETMPS;
    /* switch to eval mode */

    if (PL_curcop == &PL_compiling) {
	SAVECOPSTASH_FREE(&PL_compiling);
	CopSTASH_set(&PL_compiling, PL_curstash);
    }
    if (PERLDB_NAMEEVAL && CopLINE(PL_curcop)) {
	SV *sv = sv_newmortal();
	Perl_sv_setpvf(aTHX_ sv, "_<(%.10seval %lu)[%s:%"IVdf"]",
		       code, (unsigned long)++PL_evalseq,
		       CopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
	tmpbuf = SvPVX(sv);
    }
    else
	sprintf(tmpbuf, "_<(%.10s_eval %lu)", code, (unsigned long)++PL_evalseq);
    SAVECOPFILE_FREE(&PL_compiling);
    CopFILE_set(&PL_compiling, tmpbuf+2);
    SAVECOPLINE(&PL_compiling);
    CopLINE_set(&PL_compiling, 1);
    /* XXX For C<eval "...">s within BEGIN {} blocks, this ends up
       deleting the eval's FILEGV from the stash before gv_check() runs
       (i.e. before run-time proper). To work around the coredump that
       ensues, we always turn GvMULTI_on for any globals that were
       introduced within evals. See force_ident(). GSAR 96-10-12 */
    safestr = savepv(tmpbuf);
    SAVEDELETE(PL_defstash, safestr, strlen(safestr));
    SAVEHINTS();
#ifdef OP_IN_REGISTER
    PL_opsave = op;
#else
    SAVEVPTR(PL_op);
#endif
    PL_hints &= HINT_UTF8;

    PL_op = &dummy;
    PL_op->op_type = OP_ENTEREVAL;
    PL_op->op_flags = 0;			/* Avoid uninit warning. */
    PUSHBLOCK(cx, CXt_EVAL|(PL_curcop == &PL_compiling ? 0 : CXp_REAL), SP);
    PUSHEVAL(cx, 0, Nullgv);
    rop = doeval(G_SCALAR, startop);
    POPBLOCK(cx,PL_curpm);
    POPEVAL(cx);

    (*startop)->op_type = OP_NULL;
    (*startop)->op_ppaddr = PL_ppaddr[OP_NULL];
    lex_end();
    *avp = (AV*)SvREFCNT_inc(PL_comppad);
    LEAVE;
    if (PL_curcop == &PL_compiling)
	PL_compiling.op_private = PL_hints;
#ifdef OP_IN_REGISTER
    op = PL_opsave;
#endif
    return rop;
}

/* With USE_THREADS, eval_owner must be held on entry to doeval */
STATIC OP *
S_doeval(pTHX_ int gimme, OP** startop)
{
    dSP;
    OP *saveop = PL_op;
    CV *caller;
    AV* comppadlist;
    I32 i;

    PL_in_eval = ((saveop && saveop->op_type == OP_REQUIRE)
		  ? (EVAL_INREQUIRE | (PL_in_eval & EVAL_INEVAL))
		  : EVAL_INEVAL);

    PUSHMARK(SP);

    /* set up a scratch pad */

    SAVEI32(PL_padix);
    SAVEVPTR(PL_curpad);
    SAVESPTR(PL_comppad);
    SAVESPTR(PL_comppad_name);
    SAVEI32(PL_comppad_name_fill);
    SAVEI32(PL_min_intro_pending);
    SAVEI32(PL_max_intro_pending);

    caller = PL_compcv;
    for (i = cxstack_ix - 1; i >= 0; i--) {
	PERL_CONTEXT *cx = &cxstack[i];
	if (CxTYPE(cx) == CXt_EVAL)
	    break;
	else if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
	    caller = cx->blk_sub.cv;
	    break;
	}
    }

    SAVESPTR(PL_compcv);
    PL_compcv = (CV*)NEWSV(1104,0);
    sv_upgrade((SV *)PL_compcv, SVt_PVCV);
    CvEVAL_on(PL_compcv);
    assert(CxTYPE(&cxstack[cxstack_ix]) == CXt_EVAL);
    cxstack[cxstack_ix].blk_eval.cv = PL_compcv;

#ifdef USE_THREADS
    CvOWNER(PL_compcv) = 0;
    New(666, CvMUTEXP(PL_compcv), 1, perl_mutex);
    MUTEX_INIT(CvMUTEXP(PL_compcv));
#endif /* USE_THREADS */

    PL_comppad = newAV();
    av_push(PL_comppad, Nullsv);
    PL_curpad = AvARRAY(PL_comppad);
    PL_comppad_name = newAV();
    PL_comppad_name_fill = 0;
    PL_min_intro_pending = 0;
    PL_padix = 0;
#ifdef USE_THREADS
    av_store(PL_comppad_name, 0, newSVpvn("@_", 2));
    PL_curpad[0] = (SV*)newAV();
    SvPADMY_on(PL_curpad[0]);	/* XXX Needed? */
#endif /* USE_THREADS */

    comppadlist = newAV();
    AvREAL_off(comppadlist);
    av_store(comppadlist, 0, (SV*)PL_comppad_name);
    av_store(comppadlist, 1, (SV*)PL_comppad);
    CvPADLIST(PL_compcv) = comppadlist;

    if (!saveop ||
	(saveop->op_type != OP_REQUIRE && saveop->op_type != OP_DOFILE))
    {
	CvOUTSIDE(PL_compcv) = (CV*)SvREFCNT_inc(caller);
    }

    SAVEMORTALIZESV(PL_compcv);	/* must remain until end of current statement */

    /* make sure we compile in the right package */

    if (CopSTASH_ne(PL_curcop, PL_curstash)) {
	SAVESPTR(PL_curstash);
	PL_curstash = CopSTASH(PL_curcop);
    }
    SAVESPTR(PL_beginav);
    PL_beginav = newAV();
    SAVEFREESV(PL_beginav);
    SAVEI32(PL_error_count);

    /* try to compile it */

    PL_eval_root = Nullop;
    PL_error_count = 0;
    PL_curcop = &PL_compiling;
    PL_curcop->cop_arybase = 0;
    SvREFCNT_dec(PL_rs);
    PL_rs = newSVpvn("\n", 1);
    if (saveop && saveop->op_flags & OPf_SPECIAL)
	PL_in_eval |= EVAL_KEEPERR;
    else
	sv_setpv(ERRSV,"");
    if (yyparse() || PL_error_count || !PL_eval_root) {
	SV **newsp;
	I32 gimme;
	PERL_CONTEXT *cx;
	I32 optype = 0;			/* Might be reset by POPEVAL. */
	STRLEN n_a;
	
	PL_op = saveop;
	if (PL_eval_root) {
	    op_free(PL_eval_root);
	    PL_eval_root = Nullop;
	}
	SP = PL_stack_base + POPMARK;		/* pop original mark */
	if (!startop) {
	    POPBLOCK(cx,PL_curpm);
	    POPEVAL(cx);
	    pop_return();
	}
	lex_end();
	LEAVE;
	if (optype == OP_REQUIRE) {
	    char* msg = SvPVx(ERRSV, n_a);
	    DIE(aTHX_ "%sCompilation failed in require",
		*msg ? msg : "Unknown error\n");
	}
	else if (startop) {
	    char* msg = SvPVx(ERRSV, n_a);

	    POPBLOCK(cx,PL_curpm);
	    POPEVAL(cx);
	    Perl_croak(aTHX_ "%sCompilation failed in regexp",
		       (*msg ? msg : "Unknown error\n"));
	}
	SvREFCNT_dec(PL_rs);
	PL_rs = SvREFCNT_inc(PL_nrs);
#ifdef USE_THREADS
	MUTEX_LOCK(&PL_eval_mutex);
	PL_eval_owner = 0;
	COND_SIGNAL(&PL_eval_cond);
	MUTEX_UNLOCK(&PL_eval_mutex);
#endif /* USE_THREADS */
	RETPUSHUNDEF;
    }
    SvREFCNT_dec(PL_rs);
    PL_rs = SvREFCNT_inc(PL_nrs);
    CopLINE_set(&PL_compiling, 0);
    if (startop) {
	*startop = PL_eval_root;
	SvREFCNT_dec(CvOUTSIDE(PL_compcv));
	CvOUTSIDE(PL_compcv) = Nullcv;
    } else
	SAVEFREEOP(PL_eval_root);
    if (gimme & G_VOID)
	scalarvoid(PL_eval_root);
    else if (gimme & G_ARRAY)
	list(PL_eval_root);
    else
	scalar(PL_eval_root);

    DEBUG_x(dump_eval());

    /* Register with debugger: */
    if (PERLDB_INTER && saveop->op_type == OP_REQUIRE) {
	CV *cv = get_cv("DB::postponed", FALSE);
	if (cv) {
	    dSP;
	    PUSHMARK(SP);
	    XPUSHs((SV*)CopFILEGV(&PL_compiling));
	    PUTBACK;
	    call_sv((SV*)cv, G_DISCARD);
	}
    }

    /* compiled okay, so do it */

    CvDEPTH(PL_compcv) = 1;
    SP = PL_stack_base + POPMARK;		/* pop original mark */
    PL_op = saveop;			/* The caller may need it. */
    PL_lex_state = LEX_NOTPARSING;	/* $^S needs this. */
#ifdef USE_THREADS
    MUTEX_LOCK(&PL_eval_mutex);
    PL_eval_owner = 0;
    COND_SIGNAL(&PL_eval_cond);
    MUTEX_UNLOCK(&PL_eval_mutex);
#endif /* USE_THREADS */

    RETURNOP(PL_eval_start);
}

STATIC PerlIO *
S_doopen_pmc(pTHX_ const char *name, const char *mode)
{
    STRLEN namelen = strlen(name);
    PerlIO *fp;

    if (namelen > 3 && strEQ(name + namelen - 3, ".pm")) {
	SV *pmcsv = Perl_newSVpvf(aTHX_ "%s%c", name, 'c');
	char *pmc = SvPV_nolen(pmcsv);
	Stat_t pmstat;
	Stat_t pmcstat;
	if (PerlLIO_stat(pmc, &pmcstat) < 0) {
	    fp = PerlIO_open(name, mode);
	}
	else {
	    if (PerlLIO_stat(name, &pmstat) < 0 ||
	        pmstat.st_mtime < pmcstat.st_mtime)
	    {
		fp = PerlIO_open(pmc, mode);
	    }
	    else {
		fp = PerlIO_open(name, mode);
	    }
	}
	SvREFCNT_dec(pmcsv);
    }
    else {
	fp = PerlIO_open(name, mode);
    }
    return fp;
}

PP(pp_require)
{
    dSP;
    register PERL_CONTEXT *cx;
    SV *sv;
    char *name;
    STRLEN len;
    char *tryname = Nullch;
    SV *namesv = Nullsv;
    SV** svp;
    I32 gimme = GIMME_V;
    PerlIO *tryrsfp = 0;
    STRLEN n_a;
    int filter_has_file = 0;
    GV *filter_child_proc = 0;
    SV *filter_state = 0;
    SV *filter_sub = 0;

    sv = POPs;
    if (SvNIOKp(sv)) {
	if (SvPOK(sv) && SvNOK(sv) && SvNV(sv)) {		/* require v5.6.1 */
	    UV rev = 0, ver = 0, sver = 0;
	    STRLEN len;
	    U8 *s = (U8*)SvPVX(sv);
	    U8 *end = (U8*)SvPVX(sv) + SvCUR(sv);
	    if (s < end) {
		rev = utf8n_to_uvchr(s, end - s, &len, 0);
		s += len;
		if (s < end) {
		    ver = utf8n_to_uvchr(s, end - s, &len, 0);
		    s += len;
		    if (s < end)
			sver = utf8n_to_uvchr(s, end - s, &len, 0);
		}
	    }
	    if (PERL_REVISION < rev
		|| (PERL_REVISION == rev
		    && (PERL_VERSION < ver
			|| (PERL_VERSION == ver
			    && PERL_SUBVERSION < sver))))
	    {
		DIE(aTHX_ "Perl v%"UVuf".%"UVuf".%"UVuf" required--this is only "
		    "v%d.%d.%d, stopped", rev, ver, sver, PERL_REVISION,
		    PERL_VERSION, PERL_SUBVERSION);
	    }
	    RETPUSHYES;
	}
	else if (!SvPOKp(sv)) {			/* require 5.005_03 */
	    if ((NV)PERL_REVISION + ((NV)PERL_VERSION/(NV)1000)
		+ ((NV)PERL_SUBVERSION/(NV)1000000)
		+ 0.00000099 < SvNV(sv))
	    {
		NV nrev = SvNV(sv);
		UV rev = (UV)nrev;
		NV nver = (nrev - rev) * 1000;
		UV ver = (UV)(nver + 0.0009);
		NV nsver = (nver - ver) * 1000;
		UV sver = (UV)(nsver + 0.0009);

		/* help out with the "use 5.6" confusion */
		if (sver == 0 && (rev > 5 || (rev == 5 && ver >= 100))) {
		    DIE(aTHX_ "Perl v%"UVuf".%"UVuf".%"UVuf" required--"
			"this is only v%d.%d.%d, stopped"
			" (did you mean v%"UVuf".%"UVuf".0?)",
			rev, ver, sver, PERL_REVISION, PERL_VERSION,
			PERL_SUBVERSION, rev, ver/100);
		}
		else {
		    DIE(aTHX_ "Perl v%"UVuf".%"UVuf".%"UVuf" required--"
			"this is only v%d.%d.%d, stopped",
			rev, ver, sver, PERL_REVISION, PERL_VERSION,
			PERL_SUBVERSION);
		}
	    }
	    RETPUSHYES;
	}
    }
    name = SvPV(sv, len);
    if (!(name && len > 0 && *name))
	DIE(aTHX_ "Null filename used");
    TAINT_PROPER("require");
    if (PL_op->op_type == OP_REQUIRE &&
      (svp = hv_fetch(GvHVn(PL_incgv), name, len, 0)) &&
      *svp != &PL_sv_undef)
	RETPUSHYES;

    /* prepare to compile file */

#ifdef MACOS_TRADITIONAL
    if (PERL_FILE_IS_ABSOLUTE(name)
	|| (*name == ':' && name[1] != ':' && strchr(name+2, ':')))
    {
	tryname = name;
	tryrsfp = doopen_pmc(name,PERL_SCRIPT_MODE);
	/* We consider paths of the form :a:b ambiguous and interpret them first
	   as global then as local
	*/
    	if (!tryrsfp && *name == ':' && name[1] != ':' && strchr(name+2, ':'))
	    goto trylocal;
    }
    else
trylocal: {
#else
    if (PERL_FILE_IS_ABSOLUTE(name)
	|| (*name == '.' && (name[1] == '/' ||
			     (name[1] == '.' && name[2] == '/'))))
    {
	tryname = name;
	tryrsfp = doopen_pmc(name,PERL_SCRIPT_MODE);
    }
    else {
#endif
	AV *ar = GvAVn(PL_incgv);
	I32 i;
#ifdef VMS
	char *unixname;
	if ((unixname = tounixspec(name, Nullch)) != Nullch)
#endif
	{
	    namesv = NEWSV(806, 0);
	    for (i = 0; i <= AvFILL(ar); i++) {
		SV *dirsv = *av_fetch(ar, i, TRUE);

		if (SvROK(dirsv)) {
		    int count;
		    SV *loader = dirsv;

		    if (SvTYPE(SvRV(loader)) == SVt_PVAV) {
			loader = *av_fetch((AV *)SvRV(loader), 0, TRUE);
		    }

		    Perl_sv_setpvf(aTHX_ namesv, "/loader/0x%"UVxf"/%s",
				   PTR2UV(SvANY(loader)), name);
		    tryname = SvPVX(namesv);
		    tryrsfp = 0;

		    ENTER;
		    SAVETMPS;
		    EXTEND(SP, 2);

		    PUSHMARK(SP);
		    PUSHs(dirsv);
		    PUSHs(sv);
		    PUTBACK;
		    if (sv_isobject(loader))
			count = call_method("INC", G_ARRAY);
		    else
			count = call_sv(loader, G_ARRAY);
		    SPAGAIN;

		    if (count > 0) {
			int i = 0;
			SV *arg;

			SP -= count - 1;
			arg = SP[i++];

			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVGV) {
			    arg = SvRV(arg);
			}

			if (SvTYPE(arg) == SVt_PVGV) {
			    IO *io = GvIO((GV *)arg);

			    ++filter_has_file;

			    if (io) {
				tryrsfp = IoIFP(io);
				if (IoTYPE(io) == IoTYPE_PIPE) {
				    /* reading from a child process doesn't
				       nest -- when returning from reading
				       the inner module, the outer one is
				       unreadable (closed?)  I've tried to
				       save the gv to manage the lifespan of
				       the pipe, but this didn't help. XXX */
				    filter_child_proc = (GV *)arg;
				    (void)SvREFCNT_inc(filter_child_proc);
				}
				else {
				    if (IoOFP(io) && IoOFP(io) != IoIFP(io)) {
					PerlIO_close(IoOFP(io));
				    }
				    IoIFP(io) = Nullfp;
				    IoOFP(io) = Nullfp;
				}
			    }

			    if (i < count) {
				arg = SP[i++];
			    }
			}

			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVCV) {
			    filter_sub = arg;
			    (void)SvREFCNT_inc(filter_sub);

			    if (i < count) {
				filter_state = SP[i];
				(void)SvREFCNT_inc(filter_state);
			    }

			    if (tryrsfp == 0) {
				tryrsfp = PerlIO_open("/dev/null",
						      PERL_SCRIPT_MODE);
			    }
			}
		    }

		    PUTBACK;
		    FREETMPS;
		    LEAVE;

		    if (tryrsfp) {
			break;
		    }

		    filter_has_file = 0;
		    if (filter_child_proc) {
			SvREFCNT_dec(filter_child_proc);
			filter_child_proc = 0;
		    }
		    if (filter_state) {
			SvREFCNT_dec(filter_state);
			filter_state = 0;
		    }
		    if (filter_sub) {
			SvREFCNT_dec(filter_sub);
			filter_sub = 0;
		    }
		}
		else {
		    char *dir = SvPVx(dirsv, n_a);
#ifdef MACOS_TRADITIONAL
		    char buf[256];
		    Perl_sv_setpvf(aTHX_ namesv, "%s%s", MacPerl_CanonDir(dir, buf), name+(name[0] == ':'));
#else
#ifdef VMS
		    char *unixdir;
		    if ((unixdir = tounixpath(dir, Nullch)) == Nullch)
			continue;
		    sv_setpv(namesv, unixdir);
		    sv_catpv(namesv, unixname);
#else
		    Perl_sv_setpvf(aTHX_ namesv, "%s/%s", dir, name);
#endif
#endif
		    TAINT_PROPER("require");
		    tryname = SvPVX(namesv);
#ifdef MACOS_TRADITIONAL
		    {
		    	/* Convert slashes in the name part, but not the directory part, to colons */
		    	char * colon;
		    	for (colon = tryname+strlen(dir); colon = strchr(colon, '/'); )
			    *colon++ = ':';
		    }
#endif
		    tryrsfp = doopen_pmc(tryname, PERL_SCRIPT_MODE);
		    if (tryrsfp) {
			if (tryname[0] == '.' && tryname[1] == '/')
			    tryname += 2;
			break;
		    }
		}
	    }
	}
    }
    SAVECOPFILE_FREE(&PL_compiling);
    CopFILE_set(&PL_compiling, tryrsfp ? tryname : name);
    SvREFCNT_dec(namesv);
    if (!tryrsfp) {
	if (PL_op->op_type == OP_REQUIRE) {
	    char *msgstr = name;
	    if (namesv) {			/* did we lookup @INC? */
		SV *msg = sv_2mortal(newSVpv(msgstr,0));
		SV *dirmsgsv = NEWSV(0, 0);
		AV *ar = GvAVn(PL_incgv);
		I32 i;
		sv_catpvn(msg, " in @INC", 8);
		if (instr(SvPVX(msg), ".h "))
		    sv_catpv(msg, " (change .h to .ph maybe?)");
		if (instr(SvPVX(msg), ".ph "))
		    sv_catpv(msg, " (did you run h2ph?)");
		sv_catpv(msg, " (@INC contains:");
		for (i = 0; i <= AvFILL(ar); i++) {
		    char *dir = SvPVx(*av_fetch(ar, i, TRUE), n_a);
		    Perl_sv_setpvf(aTHX_ dirmsgsv, " %s", dir);
		    sv_catsv(msg, dirmsgsv);
		}
		sv_catpvn(msg, ")", 1);
		SvREFCNT_dec(dirmsgsv);
		msgstr = SvPV_nolen(msg);
	    }
	    DIE(aTHX_ "Can't locate %s", msgstr);
	}

	RETPUSHUNDEF;
    }
    else
	SETERRNO(0, SS$_NORMAL);

    /* Assume success here to prevent recursive requirement. */
    (void)hv_store(GvHVn(PL_incgv), name, strlen(name),
		   newSVpv(CopFILE(&PL_compiling), 0), 0 );

    ENTER;
    SAVETMPS;
    lex_start(sv_2mortal(newSVpvn("",0)));
    SAVEGENERICSV(PL_rsfp_filters);
    PL_rsfp_filters = Nullav;

    PL_rsfp = tryrsfp;
    SAVEHINTS();
    PL_hints = 0;
    SAVESPTR(PL_compiling.cop_warnings);
    if (PL_dowarn & G_WARN_ALL_ON)
        PL_compiling.cop_warnings = pWARN_ALL ;
    else if (PL_dowarn & G_WARN_ALL_OFF)
        PL_compiling.cop_warnings = pWARN_NONE ;
    else
        PL_compiling.cop_warnings = pWARN_STD ;
    SAVESPTR(PL_compiling.cop_io);
    PL_compiling.cop_io = Nullsv;

    if (filter_sub || filter_child_proc) {
	SV *datasv = filter_add(run_user_filter, Nullsv);
	IoLINES(datasv) = filter_has_file;
	IoFMT_GV(datasv) = (GV *)filter_child_proc;
	IoTOP_GV(datasv) = (GV *)filter_state;
	IoBOTTOM_GV(datasv) = (GV *)filter_sub;
    }

    /* switch to eval mode */
    push_return(PL_op->op_next);
    PUSHBLOCK(cx, CXt_EVAL, SP);
    PUSHEVAL(cx, name, Nullgv);

    SAVECOPLINE(&PL_compiling);
    CopLINE_set(&PL_compiling, 0);

    PUTBACK;
#ifdef USE_THREADS
    MUTEX_LOCK(&PL_eval_mutex);
    if (PL_eval_owner && PL_eval_owner != thr)
	while (PL_eval_owner)
	    COND_WAIT(&PL_eval_cond, &PL_eval_mutex);
    PL_eval_owner = thr;
    MUTEX_UNLOCK(&PL_eval_mutex);
#endif /* USE_THREADS */
    return DOCATCH(doeval(gimme, NULL));
}

PP(pp_dofile)
{
    return pp_require();
}

PP(pp_entereval)
{
    dSP;
    register PERL_CONTEXT *cx;
    dPOPss;
    I32 gimme = GIMME_V, was = PL_sub_generation;
    char tbuf[TYPE_DIGITS(long) + 12];
    char *tmpbuf = tbuf;
    char *safestr;
    STRLEN len;
    OP *ret;

    if (!SvPV(sv,len) || !len)
	RETPUSHUNDEF;
    TAINT_PROPER("eval");

    ENTER;
    lex_start(sv);
    SAVETMPS;

    /* switch to eval mode */

    if (PERLDB_NAMEEVAL && CopLINE(PL_curcop)) {
	SV *sv = sv_newmortal();
	Perl_sv_setpvf(aTHX_ sv, "_<(eval %lu)[%s:%"IVdf"]",
		       (unsigned long)++PL_evalseq,
		       CopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
	tmpbuf = SvPVX(sv);
    }
    else
	sprintf(tmpbuf, "_<(eval %lu)", (unsigned long)++PL_evalseq);
    SAVECOPFILE_FREE(&PL_compiling);
    CopFILE_set(&PL_compiling, tmpbuf+2);
    SAVECOPLINE(&PL_compiling);
    CopLINE_set(&PL_compiling, 1);
    /* XXX For C<eval "...">s within BEGIN {} blocks, this ends up
       deleting the eval's FILEGV from the stash before gv_check() runs
       (i.e. before run-time proper). To work around the coredump that
       ensues, we always turn GvMULTI_on for any globals that were
       introduced within evals. See force_ident(). GSAR 96-10-12 */
    safestr = savepv(tmpbuf);
    SAVEDELETE(PL_defstash, safestr, strlen(safestr));
    SAVEHINTS();
    PL_hints = PL_op->op_targ;
    SAVESPTR(PL_compiling.cop_warnings);
    if (specialWARN(PL_curcop->cop_warnings))
        PL_compiling.cop_warnings = PL_curcop->cop_warnings;
    else {
        PL_compiling.cop_warnings = newSVsv(PL_curcop->cop_warnings);
        SAVEFREESV(PL_compiling.cop_warnings);
    }
    SAVESPTR(PL_compiling.cop_io);
    if (specialCopIO(PL_curcop->cop_io))
        PL_compiling.cop_io = PL_curcop->cop_io;
    else {
        PL_compiling.cop_io = newSVsv(PL_curcop->cop_io);
        SAVEFREESV(PL_compiling.cop_io);
    }

    push_return(PL_op->op_next);
    PUSHBLOCK(cx, (CXt_EVAL|CXp_REAL), SP);
    PUSHEVAL(cx, 0, Nullgv);

    /* prepare to compile string */

    if (PERLDB_LINE && PL_curstash != PL_debstash)
	save_lines(CopFILEAV(&PL_compiling), PL_linestr);
    PUTBACK;
#ifdef USE_THREADS
    MUTEX_LOCK(&PL_eval_mutex);
    if (PL_eval_owner && PL_eval_owner != thr)
	while (PL_eval_owner)
	    COND_WAIT(&PL_eval_cond, &PL_eval_mutex);
    PL_eval_owner = thr;
    MUTEX_UNLOCK(&PL_eval_mutex);
#endif /* USE_THREADS */
    ret = doeval(gimme, NULL);
    if (PERLDB_INTER && was != PL_sub_generation /* Some subs defined here. */
	&& ret != PL_op->op_next) {	/* Successive compilation. */
	strcpy(safestr, "_<(eval )");	/* Anything fake and short. */
    }
    return DOCATCH(ret);
}

PP(pp_leaveeval)
{
    dSP;
    register SV **mark;
    SV **newsp;
    PMOP *newpm;
    I32 gimme;
    register PERL_CONTEXT *cx;
    OP *retop;
    U8 save_flags = PL_op -> op_flags;
    I32 optype;

    POPBLOCK(cx,newpm);
    POPEVAL(cx);
    retop = pop_return();

    TAINT_NOT;
    if (gimme == G_VOID)
	MARK = newsp;
    else if (gimme == G_SCALAR) {
	MARK = newsp + 1;
	if (MARK <= SP) {
	    if (SvFLAGS(TOPs) & SVs_TEMP)
		*MARK = TOPs;
	    else
		*MARK = sv_mortalcopy(TOPs);
	}
	else {
	    MEXTEND(mark,0);
	    *MARK = &PL_sv_undef;
	}
	SP = MARK;
    }
    else {
	/* in case LEAVE wipes old return values */
	for (mark = newsp + 1; mark <= SP; mark++) {
	    if (!(SvFLAGS(*mark) & SVs_TEMP)) {
		*mark = sv_mortalcopy(*mark);
		TAINT_NOT;	/* Each item is independent */
	    }
	}
    }
    PL_curpm = newpm;	/* Don't pop $1 et al till now */

#ifdef DEBUGGING
    assert(CvDEPTH(PL_compcv) == 1);
#endif
    CvDEPTH(PL_compcv) = 0;
    lex_end();

    if (optype == OP_REQUIRE &&
	!(gimme == G_SCALAR ? SvTRUE(*SP) : SP > newsp))
    {
	/* Unassume the success we assumed earlier. */
	SV *nsv = cx->blk_eval.old_namesv;
	(void)hv_delete(GvHVn(PL_incgv), SvPVX(nsv), SvCUR(nsv), G_DISCARD);
	retop = Perl_die(aTHX_ "%s did not return a true value", SvPVX(nsv));
	/* die_where() did LEAVE, or we won't be here */
    }
    else {
	LEAVE;
	if (!(save_flags & OPf_SPECIAL))
	    sv_setpv(ERRSV,"");
    }

    RETURNOP(retop);
}

PP(pp_entertry)
{
    dSP;
    register PERL_CONTEXT *cx;
    I32 gimme = GIMME_V;

    ENTER;
    SAVETMPS;

    push_return(cLOGOP->op_other->op_next);
    PUSHBLOCK(cx, (CXt_EVAL|CXp_TRYBLOCK), SP);
    PUSHEVAL(cx, 0, 0);

    PL_in_eval = EVAL_INEVAL;
    sv_setpv(ERRSV,"");
    PUTBACK;
    return DOCATCH(PL_op->op_next);
}

PP(pp_leavetry)
{
    dSP;
    register SV **mark;
    SV **newsp;
    PMOP *newpm;
    I32 gimme;
    register PERL_CONTEXT *cx;
    I32 optype;

    POPBLOCK(cx,newpm);
    POPEVAL(cx);
    pop_return();

    TAINT_NOT;
    if (gimme == G_VOID)
	SP = newsp;
    else if (gimme == G_SCALAR) {
	MARK = newsp + 1;
	if (MARK <= SP) {
	    if (SvFLAGS(TOPs) & (SVs_PADTMP|SVs_TEMP))
		*MARK = TOPs;
	    else
		*MARK = sv_mortalcopy(TOPs);
	}
	else {
	    MEXTEND(mark,0);
	    *MARK = &PL_sv_undef;
	}
	SP = MARK;
    }
    else {
	/* in case LEAVE wipes old return values */
	for (mark = newsp + 1; mark <= SP; mark++) {
	    if (!(SvFLAGS(*mark) & (SVs_PADTMP|SVs_TEMP))) {
		*mark = sv_mortalcopy(*mark);
		TAINT_NOT;	/* Each item is independent */
	    }
	}
    }
    PL_curpm = newpm;	/* Don't pop $1 et al till now */

    LEAVE;
    sv_setpv(ERRSV,"");
    RETURN;
}

STATIC void
S_doparseform(pTHX_ SV *sv)
{
    STRLEN len;
    register char *s = SvPV_force(sv, len);
    register char *send = s + len;
    register char *base = Nullch;
    register I32 skipspaces = 0;
    bool noblank   = FALSE;
    bool repeat    = FALSE;
    bool postspace = FALSE;
    U16 *fops;
    register U16 *fpc;
    U16 *linepc = 0;
    register I32 arg;
    bool ischop;

    if (len == 0)
	Perl_croak(aTHX_ "Null picture in formline");

    New(804, fops, (send - s)*3+10, U16);    /* Almost certainly too long... */
    fpc = fops;

    if (s < send) {
	linepc = fpc;
	*fpc++ = FF_LINEMARK;
	noblank = repeat = FALSE;
	base = s;
    }

    while (s <= send) {
	switch (*s++) {
	default:
	    skipspaces = 0;
	    continue;

	case '~':
	    if (*s == '~') {
		repeat = TRUE;
		*s = ' ';
	    }
	    noblank = TRUE;
	    s[-1] = ' ';
	    /* FALL THROUGH */
	case ' ': case '\t':
	    skipspaces++;
	    continue;
	
	case '\n': case 0:
	    arg = s - base;
	    skipspaces++;
	    arg -= skipspaces;
	    if (arg) {
		if (postspace)
		    *fpc++ = FF_SPACE;
		*fpc++ = FF_LITERAL;
		*fpc++ = arg;
	    }
	    postspace = FALSE;
	    if (s <= send)
		skipspaces--;
	    if (skipspaces) {
		*fpc++ = FF_SKIP;
		*fpc++ = skipspaces;
	    }
	    skipspaces = 0;
	    if (s <= send)
		*fpc++ = FF_NEWLINE;
	    if (noblank) {
		*fpc++ = FF_BLANK;
		if (repeat)
		    arg = fpc - linepc + 1;
		else
		    arg = 0;
		*fpc++ = arg;
	    }
	    if (s < send) {
		linepc = fpc;
		*fpc++ = FF_LINEMARK;
		noblank = repeat = FALSE;
		base = s;
	    }
	    else
		s++;
	    continue;

	case '@':
	case '^':
	    ischop = s[-1] == '^';

	    if (postspace) {
		*fpc++ = FF_SPACE;
		postspace = FALSE;
	    }
	    arg = (s - base) - 1;
	    if (arg) {
		*fpc++ = FF_LITERAL;
		*fpc++ = arg;
	    }

	    base = s - 1;
	    *fpc++ = FF_FETCH;
	    if (*s == '*') {
		s++;
		*fpc++ = 0;
		*fpc++ = FF_LINEGLOB;
	    }
	    else if (*s == '#' || (*s == '.' && s[1] == '#')) {
		arg = ischop ? 512 : 0;
		base = s - 1;
		while (*s == '#')
		    s++;
		if (*s == '.') {
		    char *f;
		    s++;
		    f = s;
		    while (*s == '#')
			s++;
		    arg |= 256 + (s - f);
		}
		*fpc++ = s - base;		/* fieldsize for FETCH */
		*fpc++ = FF_DECIMAL;
                *fpc++ = arg;
            }
            else if (*s == '0' && s[1] == '#') {  /* Zero padded decimals */
                arg = ischop ? 512 : 0;
		base = s - 1;
                s++;                                /* skip the '0' first */
                while (*s == '#')
                    s++;
                if (*s == '.') {
                    char *f;
                    s++;
                    f = s;
                    while (*s == '#')
                        s++;
                    arg |= 256 + (s - f);
                }
                *fpc++ = s - base;                /* fieldsize for FETCH */
                *fpc++ = FF_0DECIMAL;
		*fpc++ = arg;
	    }
	    else {
		I32 prespace = 0;
		bool ismore = FALSE;

		if (*s == '>') {
		    while (*++s == '>') ;
		    prespace = FF_SPACE;
		}
		else if (*s == '|') {
		    while (*++s == '|') ;
		    prespace = FF_HALFSPACE;
		    postspace = TRUE;
		}
		else {
		    if (*s == '<')
			while (*++s == '<') ;
		    postspace = TRUE;
		}
		if (*s == '.' && s[1] == '.' && s[2] == '.') {
		    s += 3;
		    ismore = TRUE;
		}
		*fpc++ = s - base;		/* fieldsize for FETCH */

		*fpc++ = ischop ? FF_CHECKCHOP : FF_CHECKNL;

		if (prespace)
		    *fpc++ = prespace;
		*fpc++ = FF_ITEM;
		if (ismore)
		    *fpc++ = FF_MORE;
		if (ischop)
		    *fpc++ = FF_CHOP;
	    }
	    base = s;
	    skipspaces = 0;
	    continue;
	}
    }
    *fpc++ = FF_END;

    arg = fpc - fops;
    { /* need to jump to the next word */
        int z;
	z = WORD_ALIGN - SvCUR(sv) % WORD_ALIGN;
	SvGROW(sv, SvCUR(sv) + z + arg * sizeof(U16) + 4);
	s = SvPVX(sv) + SvCUR(sv) + z;
    }
    Copy(fops, s, arg, U16);
    Safefree(fops);
    sv_magic(sv, Nullsv, PERL_MAGIC_fm, Nullch, 0);
    SvCOMPILED_on(sv);
}

/*
 * The mergesort implementation is by Peter M. Mcilroy <pmcilroy@lucent.com>.
 *
 * The original code was written in conjunction with BSD Computer Software
 * Research Group at University of California, Berkeley.
 *
 * See also: "Optimistic Merge Sort" (SODA '92)
 *
 * The integration to Perl is by John P. Linderman <jpl@research.att.com>.
 *
 * The code can be distributed under the same terms as Perl itself.
 *
 */

#ifdef	TESTHARNESS
#include <sys/types.h>
typedef	void SV;
#define pTHXo_
#define pTHX_
#define STATIC
#define New(ID,VAR,N,TYPE) VAR=(TYPE *)malloc((N)*sizeof(TYPE))
#define	Safefree(VAR) free(VAR)
typedef int  (*SVCOMPARE_t) (pTHXo_ SV*, SV*);
#endif	/* TESTHARNESS */

typedef char * aptr;		/* pointer for arithmetic on sizes */
typedef SV * gptr;		/* pointers in our lists */

/* Binary merge internal sort, with a few special mods
** for the special perl environment it now finds itself in.
**
** Things that were once options have been hotwired
** to values suitable for this use.  In particular, we'll always
** initialize looking for natural runs, we'll always produce stable
** output, and we'll always do Peter McIlroy's binary merge.
*/

/* Pointer types for arithmetic and storage and convenience casts */

#define	APTR(P)	((aptr)(P))
#define	GPTP(P)	((gptr *)(P))
#define GPPP(P) ((gptr **)(P))


/* byte offset from pointer P to (larger) pointer Q */
#define	BYTEOFF(P, Q) (APTR(Q) - APTR(P))

#define PSIZE sizeof(gptr)

/* If PSIZE is power of 2, make PSHIFT that power, if that helps */

#ifdef	PSHIFT
#define	PNELEM(P, Q)	(BYTEOFF(P,Q) >> (PSHIFT))
#define	PNBYTE(N)	((N) << (PSHIFT))
#define	PINDEX(P, N)	(GPTP(APTR(P) + PNBYTE(N)))
#else
/* Leave optimization to compiler */
#define	PNELEM(P, Q)	(GPTP(Q) - GPTP(P))
#define	PNBYTE(N)	((N) * (PSIZE))
#define	PINDEX(P, N)	(GPTP(P) + (N))
#endif

/* Pointer into other corresponding to pointer into this */
#define	POTHER(P, THIS, OTHER) GPTP(APTR(OTHER) + BYTEOFF(THIS,P))

#define FROMTOUPTO(src, dst, lim) do *dst++ = *src++; while(src<lim)


/* Runs are identified by a pointer in the auxilliary list.
** The pointer is at the start of the list,
** and it points to the start of the next list.
** NEXT is used as an lvalue, too.
*/

#define	NEXT(P)		(*GPPP(P))


/* PTHRESH is the minimum number of pairs with the same sense to justify
** checking for a run and extending it.  Note that PTHRESH counts PAIRS,
** not just elements, so PTHRESH == 8 means a run of 16.
*/

#define	PTHRESH (8)

/* RTHRESH is the number of elements in a run that must compare low
** to the low element from the opposing run before we justify
** doing a binary rampup instead of single stepping.
** In random input, N in a row low should only happen with
** probability 2^(1-N), so we can risk that we are dealing
** with orderly input without paying much when we aren't.
*/

#define RTHRESH (6)


/*
** Overview of algorithm and variables.
** The array of elements at list1 will be organized into runs of length 2,
** or runs of length >= 2 * PTHRESH.  We only try to form long runs when
** PTHRESH adjacent pairs compare in the same way, suggesting overall order.
**
** Unless otherwise specified, pair pointers address the first of two elements.
**
** b and b+1 are a pair that compare with sense ``sense''.
** b is the ``bottom'' of adjacent pairs that might form a longer run.
**
** p2 parallels b in the list2 array, where runs are defined by
** a pointer chain.
**
** t represents the ``top'' of the adjacent pairs that might extend
** the run beginning at b.  Usually, t addresses a pair
** that compares with opposite sense from (b,b+1).
** However, it may also address a singleton element at the end of list1,
** or it may be equal to ``last'', the first element beyond list1.
**
** r addresses the Nth pair following b.  If this would be beyond t,
** we back it off to t.  Only when r is less than t do we consider the
** run long enough to consider checking.
**
** q addresses a pair such that the pairs at b through q already form a run.
** Often, q will equal b, indicating we only are sure of the pair itself.
** However, a search on the previous cycle may have revealed a longer run,
** so q may be greater than b.
**
** p is used to work back from a candidate r, trying to reach q,
** which would mean b through r would be a run.  If we discover such a run,
** we start q at r and try to push it further towards t.
** If b through r is NOT a run, we detect the wrong order at (p-1,p).
** In any event, after the check (if any), we have two main cases.
**
** 1) Short run.  b <= q < p <= r <= t.
**	b through q is a run (perhaps trivial)
**	q through p are uninteresting pairs
**	p through r is a run
**
** 2) Long run.  b < r <= q < t.
**	b through q is a run (of length >= 2 * PTHRESH)
**
** Note that degenerate cases are not only possible, but likely.
** For example, if the pair following b compares with opposite sense,
** then b == q < p == r == t.
*/


static void
dynprep(pTHX_ gptr *list1, gptr *list2, size_t nmemb, SVCOMPARE_t cmp)
{
    int sense;
    register gptr *b, *p, *q, *t, *p2;
    register gptr c, *last, *r;
    gptr *savep;

    b = list1;
    last = PINDEX(b, nmemb);
    sense = (cmp(aTHX_ *b, *(b+1)) > 0);
    for (p2 = list2; b < last; ) {
	/* We just started, or just reversed sense.
	** Set t at end of pairs with the prevailing sense.
	*/
	for (p = b+2, t = p; ++p < last; t = ++p) {
	    if ((cmp(aTHX_ *t, *p) > 0) != sense) break;
	}
	q = b;
	/* Having laid out the playing field, look for long runs */
	do {
	    p = r = b + (2 * PTHRESH);
	    if (r >= t) p = r = t;	/* too short to care about */
	    else {
		while (((cmp(aTHX_ *(p-1), *p) > 0) == sense) &&
		       ((p -= 2) > q));
		if (p <= q) {
		    /* b through r is a (long) run.
		    ** Extend it as far as possible.
		    */
		    p = q = r;
		    while (((p += 2) < t) &&
			   ((cmp(aTHX_ *(p-1), *p) > 0) == sense)) q = p;
		    r = p = q + 2;	/* no simple pairs, no after-run */
		}
	    }
	    if (q > b) {		/* run of greater than 2 at b */
		savep = p;
		p = q += 2;
		/* pick up singleton, if possible */
		if ((p == t) &&
		    ((t + 1) == last) &&
		    ((cmp(aTHX_ *(p-1), *p) > 0) == sense))
		    savep = r = p = q = last;
		p2 = NEXT(p2) = p2 + (p - b);
		if (sense) while (b < --p) {
		    c = *b;
		    *b++ = *p;
		    *p = c;
		}
		p = savep;
	    }
	    while (q < p) {		/* simple pairs */
		p2 = NEXT(p2) = p2 + 2;
		if (sense) {
		    c = *q++;
		    *(q-1) = *q;
		    *q++ = c;
		} else q += 2;
	    }
	    if (((b = p) == t) && ((t+1) == last)) {
		NEXT(p2) = p2 + 1;
		b++;
	    }
	    q = r;
	} while (b < t);
	sense = !sense;
    }
    return;
}


/* Overview of bmerge variables:
**
** list1 and list2 address the main and auxiliary arrays.
** They swap identities after each merge pass.
** Base points to the original list1, so we can tell if
** the pointers ended up where they belonged (or must be copied).
**
** When we are merging two lists, f1 and f2 are the next elements
** on the respective lists.  l1 and l2 mark the end of the lists.
** tp2 is the current location in the merged list.
**
** p1 records where f1 started.
** After the merge, a new descriptor is built there.
**
** p2 is a ``parallel'' pointer in (what starts as) descriptor space.
** It is used to identify and delimit the runs.
**
** In the heat of determining where q, the greater of the f1/f2 elements,
** belongs in the other list, b, t and p, represent bottom, top and probe
** locations, respectively, in the other list.
** They make convenient temporary pointers in other places.
*/

STATIC void
S_qsortsv(pTHX_ gptr *list1, size_t nmemb, SVCOMPARE_t cmp)
{
    int i, run;
    int sense;
    register gptr *f1, *f2, *t, *b, *p, *tp2, *l1, *l2, *q;
    gptr *aux, *list2, *p2, *last;
    gptr *base = list1;
    gptr *p1;

    if (nmemb <= 1) return;	/* sorted trivially */
    New(799,list2,nmemb,gptr);	/* allocate auxilliary array */
    aux = list2;
    dynprep(aTHX_ list1, list2, nmemb, cmp);
    last = PINDEX(list2, nmemb);
    while (NEXT(list2) != last) {
	/* More than one run remains.  Do some merging to reduce runs. */
	l2 = p1 = list1;
	for (tp2 = p2 = list2; p2 != last;) {
	    /* The new first run begins where the old second list ended.
	    ** Use the p2 ``parallel'' pointer to identify the end of the run.
	    */
	    f1 = l2;
	    t = NEXT(p2);
	    f2 = l1 = POTHER(t, list2, list1);
	    if (t != last) t = NEXT(t);
	    l2 = POTHER(t, list2, list1);
	    p2 = t;
	    while (f1 < l1 && f2 < l2) {
		/* If head 1 is larger than head 2, find ALL the elements
		** in list 2 strictly less than head1, write them all,
		** then head 1.  Then compare the new heads, and repeat,
		** until one or both lists are exhausted.
		**
		** In all comparisons (after establishing
		** which head to merge) the item to merge
		** (at pointer q) is the first operand of
		** the comparison.  When we want to know
		** if ``q is strictly less than the other'',
		** we can't just do
		**    cmp(q, other) < 0
		** because stability demands that we treat equality
		** as high when q comes from l2, and as low when
		** q was from l1.  So we ask the question by doing
		**    cmp(q, other) <= sense
		** and make sense == 0 when equality should look low,
		** and -1 when equality should look high.
		*/


		if (cmp(aTHX_ *f1, *f2) <= 0) {
		    q = f2; b = f1; t = l1;
		    sense = -1;
		} else {
		    q = f1; b = f2; t = l2;
		    sense = 0;
		}


		/* ramp up
		**
		** Leave t at something strictly
		** greater than q (or at the end of the list),
		** and b at something strictly less than q.
		*/
		for (i = 1, run = 0 ;;) {
		    if ((p = PINDEX(b, i)) >= t) {
			/* off the end */
			if (((p = PINDEX(t, -1)) > b) &&
			    (cmp(aTHX_ *q, *p) <= sense))
			     t = p;
			else b = p;
			break;
		    } else if (cmp(aTHX_ *q, *p) <= sense) {
			t = p;
			break;
		    } else b = p;
		    if (++run >= RTHRESH) i += i;
		}


		/* q is known to follow b and must be inserted before t.
		** Increment b, so the range of possibilities is [b,t).
		** Round binary split down, to favor early appearance.
		** Adjust b and t until q belongs just before t.
		*/

		b++;
		while (b < t) {
		    p = PINDEX(b, (PNELEM(b, t) - 1) / 2);
		    if (cmp(aTHX_ *q, *p) <= sense) {
			t = p;
		    } else b = p + 1;
		}


		/* Copy all the strictly low elements */

		if (q == f1) {
		    FROMTOUPTO(f2, tp2, t);
		    *tp2++ = *f1++;
		} else {
		    FROMTOUPTO(f1, tp2, t);
		    *tp2++ = *f2++;
		}
	    }


	    /* Run out remaining list */
	    if (f1 == l1) {
		   if (f2 < l2) FROMTOUPTO(f2, tp2, l2);
	    } else              FROMTOUPTO(f1, tp2, l1);
	    p1 = NEXT(p1) = POTHER(tp2, list2, list1);
	}
	t = list1;
	list1 = list2;
	list2 = t;
	last = PINDEX(list2, nmemb);
    }
    if (base == list2) {
	last = PINDEX(list1, nmemb);
	FROMTOUPTO(list1, list2, last);
    }
    Safefree(aux);
    return;
}


#ifdef PERL_OBJECT
#undef this
#define this pPerl
#include "XSUB.h"
#endif


static I32
sortcv(pTHXo_ SV *a, SV *b)
{
    I32 oldsaveix = PL_savestack_ix;
    I32 oldscopeix = PL_scopestack_ix;
    I32 result;
    GvSV(PL_firstgv) = a;
    GvSV(PL_secondgv) = b;
    PL_stack_sp = PL_stack_base;
    PL_op = PL_sortcop;
    CALLRUNOPS(aTHX);
    if (PL_stack_sp != PL_stack_base + 1)
	Perl_croak(aTHX_ "Sort subroutine didn't return single value");
    if (!SvNIOKp(*PL_stack_sp))
	Perl_croak(aTHX_ "Sort subroutine didn't return a numeric value");
    result = SvIV(*PL_stack_sp);
    while (PL_scopestack_ix > oldscopeix) {
	LEAVE;
    }
    leave_scope(oldsaveix);
    return result;
}

static I32
sortcv_stacked(pTHXo_ SV *a, SV *b)
{
    I32 oldsaveix = PL_savestack_ix;
    I32 oldscopeix = PL_scopestack_ix;
    I32 result;
    AV *av;

#ifdef USE_THREADS
    av = (AV*)PL_curpad[0];
#else
    av = GvAV(PL_defgv);
#endif

    if (AvMAX(av) < 1) {
	SV** ary = AvALLOC(av);
	if (AvARRAY(av) != ary) {
	    AvMAX(av) += AvARRAY(av) - AvALLOC(av);
	    SvPVX(av) = (char*)ary;
	}
	if (AvMAX(av) < 1) {
	    AvMAX(av) = 1;
	    Renew(ary,2,SV*);
	    SvPVX(av) = (char*)ary;
	}
    }
    AvFILLp(av) = 1;

    AvARRAY(av)[0] = a;
    AvARRAY(av)[1] = b;
    PL_stack_sp = PL_stack_base;
    PL_op = PL_sortcop;
    CALLRUNOPS(aTHX);
    if (PL_stack_sp != PL_stack_base + 1)
	Perl_croak(aTHX_ "Sort subroutine didn't return single value");
    if (!SvNIOKp(*PL_stack_sp))
	Perl_croak(aTHX_ "Sort subroutine didn't return a numeric value");
    result = SvIV(*PL_stack_sp);
    while (PL_scopestack_ix > oldscopeix) {
	LEAVE;
    }
    leave_scope(oldsaveix);
    return result;
}

static I32
sortcv_xsub(pTHXo_ SV *a, SV *b)
{
    dSP;
    I32 oldsaveix = PL_savestack_ix;
    I32 oldscopeix = PL_scopestack_ix;
    I32 result;
    CV *cv=(CV*)PL_sortcop;

    SP = PL_stack_base;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    *++SP = a;
    *++SP = b;
    PUTBACK;
    (void)(*CvXSUB(cv))(aTHXo_ cv);
    if (PL_stack_sp != PL_stack_base + 1)
	Perl_croak(aTHX_ "Sort subroutine didn't return single value");
    if (!SvNIOKp(*PL_stack_sp))
	Perl_croak(aTHX_ "Sort subroutine didn't return a numeric value");
    result = SvIV(*PL_stack_sp);
    while (PL_scopestack_ix > oldscopeix) {
	LEAVE;
    }
    leave_scope(oldsaveix);
    return result;
}


static I32
sv_ncmp(pTHXo_ SV *a, SV *b)
{
    NV nv1 = SvNV(a);
    NV nv2 = SvNV(b);
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}

static I32
sv_i_ncmp(pTHXo_ SV *a, SV *b)
{
    IV iv1 = SvIV(a);
    IV iv2 = SvIV(b);
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}
#define tryCALL_AMAGICbin(left,right,meth,svp) STMT_START { \
	  *svp = Nullsv;				\
          if (PL_amagic_generation) { \
	    if (SvAMAGIC(left)||SvAMAGIC(right))\
		*svp = amagic_call(left, \
				   right, \
				   CAT2(meth,_amg), \
				   0); \
	  } \
	} STMT_END

static I32
amagic_ncmp(pTHXo_ register SV *a, register SV *b)
{
    SV *tmpsv;
    tryCALL_AMAGICbin(a,b,ncmp,&tmpsv);
    if (tmpsv) {
    	NV d;
    	
        if (SvIOK(tmpsv)) {
            I32 i = SvIVX(tmpsv);
            if (i > 0)
               return 1;
            return i? -1 : 0;
        }
        d = SvNV(tmpsv);
        if (d > 0)
           return 1;
        return d? -1 : 0;
     }
     return sv_ncmp(aTHXo_ a, b);
}

static I32
amagic_i_ncmp(pTHXo_ register SV *a, register SV *b)
{
    SV *tmpsv;
    tryCALL_AMAGICbin(a,b,ncmp,&tmpsv);
    if (tmpsv) {
    	NV d;
    	
        if (SvIOK(tmpsv)) {
            I32 i = SvIVX(tmpsv);
            if (i > 0)
               return 1;
            return i? -1 : 0;
        }
        d = SvNV(tmpsv);
        if (d > 0)
           return 1;
        return d? -1 : 0;
    }
    return sv_i_ncmp(aTHXo_ a, b);
}

static I32
amagic_cmp(pTHXo_ register SV *str1, register SV *str2)
{
    SV *tmpsv;
    tryCALL_AMAGICbin(str1,str2,scmp,&tmpsv);
    if (tmpsv) {
    	NV d;
    	
        if (SvIOK(tmpsv)) {
            I32 i = SvIVX(tmpsv);
            if (i > 0)
               return 1;
            return i? -1 : 0;
        }
        d = SvNV(tmpsv);
        if (d > 0)
           return 1;
        return d? -1 : 0;
    }
    return sv_cmp(str1, str2);
}

static I32
amagic_cmp_locale(pTHXo_ register SV *str1, register SV *str2)
{
    SV *tmpsv;
    tryCALL_AMAGICbin(str1,str2,scmp,&tmpsv);
    if (tmpsv) {
    	NV d;
    	
        if (SvIOK(tmpsv)) {
            I32 i = SvIVX(tmpsv);
            if (i > 0)
               return 1;
            return i? -1 : 0;
        }
        d = SvNV(tmpsv);
        if (d > 0)
           return 1;
        return d? -1 : 0;
    }
    return sv_cmp_locale(str1, str2);
}

static I32
run_user_filter(pTHXo_ int idx, SV *buf_sv, int maxlen)
{
    SV *datasv = FILTER_DATA(idx);
    int filter_has_file = IoLINES(datasv);
    GV *filter_child_proc = (GV *)IoFMT_GV(datasv);
    SV *filter_state = (SV *)IoTOP_GV(datasv);
    SV *filter_sub = (SV *)IoBOTTOM_GV(datasv);
    int len = 0;

    /* I was having segfault trouble under Linux 2.2.5 after a
       parse error occured.  (Had to hack around it with a test
       for PL_error_count == 0.)  Solaris doesn't segfault --
       not sure where the trouble is yet.  XXX */

    if (filter_has_file) {
	len = FILTER_READ(idx+1, buf_sv, maxlen);
    }

    if (filter_sub && len >= 0) {
	dSP;
	int count;

	ENTER;
	SAVE_DEFSV;
	SAVETMPS;
	EXTEND(SP, 2);

	DEFSV = buf_sv;
	PUSHMARK(SP);
	PUSHs(sv_2mortal(newSViv(maxlen)));
	if (filter_state) {
	    PUSHs(filter_state);
	}
	PUTBACK;
	count = call_sv(filter_sub, G_SCALAR);
	SPAGAIN;

	if (count > 0) {
	    SV *out = POPs;
	    if (SvOK(out)) {
		len = SvIV(out);
	    }
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
    }

    if (len <= 0) {
	IoLINES(datasv) = 0;
	if (filter_child_proc) {
	    SvREFCNT_dec(filter_child_proc);
	    IoFMT_GV(datasv) = Nullgv;
	}
	if (filter_state) {
	    SvREFCNT_dec(filter_state);
	    IoTOP_GV(datasv) = Nullgv;
	}
	if (filter_sub) {
	    SvREFCNT_dec(filter_sub);
	    IoBOTTOM_GV(datasv) = Nullgv;
	}
	filter_del(run_user_filter);
    }

    return len;
}

#ifdef PERL_OBJECT

static I32
sv_cmp_locale_static(pTHXo_ register SV *str1, register SV *str2)
{
    return sv_cmp_locale(str1, str2);
}

static I32
sv_cmp_static(pTHXo_ register SV *str1, register SV *str2)
{
    return sv_cmp(str1, str2);
}

#endif /* PERL_OBJECT */
