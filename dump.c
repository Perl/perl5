/*    dump.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000,
 *    2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "'You have talked long in your sleep, Frodo,' said Gandalf gently, 'and
 * it has not been hard for me to read your mind and memory.'"
 */

/* This file contains utility routines to dump the contents of SV and OP
 * structures, as used by command-line options like -Dt and -Dx, and
 * by Devel::Peek.
 *
 * It also holds the debugging version of the  runops function.
 */

#include "EXTERN.h"
#define PERL_IN_DUMP_C
#include "perl.h"
#include "regcomp.h"
#include "proto.h"


static const char* const svtypenames[SVt_LAST] = {
    "NULL",
    "IV",
    "NV",
    "RV",
    "PV",
    "PVIV",
    "PVNV",
    "PVMG",
    "PVBM",
    "PVLV",
    "PVAV",
    "PVHV",
    "PVCV",
    "PVGV",
    "PVFM",
    "PVIO"
};


static const char* const svshorttypenames[SVt_LAST] = {
    "UNDEF",
    "IV",
    "NV",
    "RV",
    "PV",
    "PVIV",
    "PVNV",
    "PVMG",
    "BM",
    "PVLV",
    "AV",
    "HV",
    "CV",
    "GV",
    "FM",
    "IO"
};

void
Perl_dump_indent(pTHX_ I32 level, PerlIO *file, const char* pat, ...)
{
    va_list args;
    va_start(args, pat);
    dump_vindent(level, file, pat, &args);
    va_end(args);
}

void
Perl_dump_vindent(pTHX_ I32 level, PerlIO *file, const char* pat, va_list *args)
{
    PerlIO_printf(file, "%*s", (int)(level*PL_dumpindent), "");
    PerlIO_vprintf(file, pat, *args);
}

void
Perl_dump_all(pTHX)
{
    PerlIO_setlinebuf(Perl_debug_log);
    if (PL_main_root)
	op_dump(PL_main_root);
    dump_packsubs(PL_defstash);
}

void
Perl_dump_packsubs(pTHX_ HV *stash)
{
    I32	i;

    if (!HvARRAY(stash))
	return;
    for (i = 0; i <= (I32) HvMAX(stash); i++) {
        const HE *entry;
	for (entry = HvARRAY(stash)[i]; entry; entry = HeNEXT(entry)) {
	    const GV * const gv = (GV*)HeVAL(entry);
	    if (SvTYPE(gv) != SVt_PVGV || !GvGP(gv))
		continue;
	    if (GvCVu(gv))
		dump_sub((GV *)gv);
	    if (GvFORM(gv))
		dump_form((GV *)gv);
	    if (HeKEY(entry)[HeKLEN(entry)-1] == ':') {
		const HV * const hv = GvHV(gv);
		if (hv && (hv != PL_defstash))
		    dump_packsubs((HV *) hv);		/* nested package */
	    }
	}
    }
}

void
Perl_dump_sub(pTHX_ GV *gv)
{
    SV * const sv = sv_newmortal();

    gv_fullname3(sv, gv, NULL);
    Perl_dump_indent(aTHX_ 0, Perl_debug_log, "\nSUB %s = ", SvPVX_const(sv));
    if (CvISXSUB(GvCV(gv)))
	Perl_dump_indent(aTHX_ 0, Perl_debug_log, "(xsub 0x%"UVxf" %d)\n",
	    PTR2UV(CvXSUB(GvCV(gv))),
	    (int)CvXSUBANY(GvCV(gv)).any_i32);
    else if (CvROOT(GvCV(gv)))
	op_dump(CvROOT(GvCV(gv)));
    else
	Perl_dump_indent(aTHX_ 0, Perl_debug_log, "<undef>\n");
}

void
Perl_dump_form(pTHX_ GV *gv)
{
    SV * const sv = sv_newmortal();

    gv_fullname3(sv, gv, NULL);
    Perl_dump_indent(aTHX_ 0, Perl_debug_log, "\nFORMAT %s = ", SvPVX_const(sv));
    if (CvROOT(GvFORM(gv)))
	op_dump(CvROOT(GvFORM(gv)));
    else
	Perl_dump_indent(aTHX_ 0, Perl_debug_log, "<undef>\n");
}

void
Perl_dump_eval(pTHX)
{
    op_dump(PL_eval_root);
}


/*
=for apidoc pv_escape

Escapes at most the first "count" chars of pv and puts the results into
dsv such that the size of the escaped string will not exceed "max" chars
and will not contain any incomplete escape sequences.

If flags contains PERL_PV_ESCAPE_QUOTE then any double quotes in the string
will also be escaped.

Normally the SV will be cleared before the escaped string is prepared,
but when PERL_PV_ESCAPE_NOCLEAR is set this will not occur.

If PERL_PV_ESCAPE_UNI is set then the input string is treated as Unicode,
if PERL_PV_ESCAPE_UNI_DETECT is set then the input string is scanned
using C<is_utf8_string()> to determine if it is Unicode.

If PERL_PV_ESCAPE_ALL is set then all input chars will be output
using C<\x01F1> style escapes, otherwise only chars above 255 will be
escaped using this style, other non printable chars will use octal or
common escaped patterns like C<\n>. If PERL_PV_ESCAPE_NOBACKSLASH
then all chars below 255 will be treated as printable and 
will be output as literals.

If PERL_PV_ESCAPE_FIRSTCHAR is set then only the first char of the
string will be escaped, regardles of max. If the string is utf8 and 
the chars value is >255 then it will be returned as a plain hex 
sequence. Thus the output will either be a single char, 
an octal escape sequence, a special escape like C<\n> or a 3 or 
more digit hex value. 

Returns a pointer to the escaped text as held by dsv.

=cut
*/
#define PV_ESCAPE_OCTBUFSIZE 32

char *
Perl_pv_escape( pTHX_ SV *dsv, char const * const str, 
                const STRLEN count, const STRLEN max, 
                STRLEN * const escaped, const U32 flags ) 
{
    const char dq = (flags & PERL_PV_ESCAPE_QUOTE) ? '"' : '\\';
    char octbuf[PV_ESCAPE_OCTBUFSIZE] = "\\123456789ABCDF";
    STRLEN wrote = 0;    /* chars written so far */
    STRLEN chsize = 0;   /* size of data to be written */
    STRLEN readsize = 1; /* size of data just read */
    bool isuni= flags & PERL_PV_ESCAPE_UNI ? 1 : 0; /* is this Unicode */
    const char *pv  = str;
    const char * const end = pv + count; /* end of string */

    if (!(flags & PERL_PV_ESCAPE_NOCLEAR))
	    sv_setpvn(dsv, "", 0);
    
    if ((flags & PERL_PV_ESCAPE_UNI_DETECT) && is_utf8_string((U8*)pv, count))
        isuni = 1;
    
    for ( ; (pv < end && (!max || (wrote < max))) ; pv += readsize ) {
        const UV u= (isuni) ? utf8_to_uvchr((U8*)pv, &readsize) : (U8)*pv;            
        const U8 c = (U8)u & 0xFF;
        
        if ( ( u > 255 ) || (flags & PERL_PV_ESCAPE_ALL)) {
            if (flags & PERL_PV_ESCAPE_FIRSTCHAR) 
                chsize = my_snprintf( octbuf, PV_ESCAPE_OCTBUFSIZE, 
                                      "%"UVxf, u);
            else
                chsize = my_snprintf( octbuf, PV_ESCAPE_OCTBUFSIZE, 
                                      "\\x{%"UVxf"}", u);
        } else if (flags & PERL_PV_ESCAPE_NOBACKSLASH) {
            chsize = 1;            
        } else {         
            if ( (c == dq) || (c == '\\') || !isPRINT(c) ) {
	    chsize = 2;
                switch (c) {
		case '\\' : octbuf[1] = '\\'; break;
		case '\v' : octbuf[1] = 'v';  break;
		case '\t' : octbuf[1] = 't';  break;
		case '\r' : octbuf[1] = 'r';  break;
		case '\n' : octbuf[1] = 'n';  break;
		case '\f' : octbuf[1] = 'f';  break;
                    case '"'  : 
                        if ( dq == '"' ) 
				octbuf[1] = '"';
                        else 
                            chsize = 1;
				break;
		default:
                        if ( (pv < end) && isDIGIT((U8)*(pv+readsize)) )
                            chsize = my_snprintf( octbuf, PV_ESCAPE_OCTBUFSIZE, 
                                                  "\\%03o", c);
			    else
                            chsize = my_snprintf( octbuf, PV_ESCAPE_OCTBUFSIZE, 
                                                  "\\%o", c);
                }
            } else {
                chsize=1;
            }
	    }
	    if ( max && (wrote + chsize > max) ) {
		break;
        } else if (chsize > 1) {
		sv_catpvn(dsv, octbuf, chsize);
		wrote += chsize;
	} else {
            Perl_sv_catpvf( aTHX_ dsv, "%c", c);
	    wrote++;
	}
        if ( flags & PERL_PV_ESCAPE_FIRSTCHAR ) 
            break;
    }
    if (escaped != NULL)
        *escaped= pv - str;
    return SvPVX(dsv);
}
/*
=for apidoc pv_pretty

Converts a string into something presentable, handling escaping via
pv_escape() and supporting quoting and elipses. 

If the PERL_PV_PRETTY_QUOTE flag is set then the result will be 
double quoted with any double quotes in the string escaped. Otherwise
if the PERL_PV_PRETTY_LTGT flag is set then the result be wrapped in
angle brackets. 
           
If the PERL_PV_PRETTY_ELIPSES flag is set and not all characters in
string were output then an elipses C<...> will be appended to the 
string. Note that this happens AFTER it has been quoted.
           
If start_color is non-null then it will be inserted after the opening
quote (if there is one) but before the escaped text. If end_color
is non-null then it will be inserted after the escaped text but before
any quotes or elipses.

Returns a pointer to the prettified text as held by dsv.
           
=cut           
*/

char *
Perl_pv_pretty( pTHX_ SV *dsv, char const * const str, const STRLEN count, 
  const STRLEN max, char const * const start_color, char const * const end_color, 
  const U32 flags ) 
{
    const U8 dq = (flags & PERL_PV_PRETTY_QUOTE) ? '"' : '\\';
    STRLEN escaped;
    
    if ( dq == '"' )
        sv_setpvn(dsv, "\"", 1);
    else if ( flags & PERL_PV_PRETTY_LTGT )
        sv_setpvn(dsv, "<", 1);
    else 
        sv_setpvn(dsv, "", 0);
        
    if ( start_color != NULL ) 
        Perl_sv_catpv( aTHX_ dsv, start_color);
    
    pv_escape( dsv, str, count, max, &escaped, flags | PERL_PV_ESCAPE_NOCLEAR );    
    
    if ( end_color != NULL ) 
        Perl_sv_catpv( aTHX_ dsv, end_color);

    if ( dq == '"' ) 
	sv_catpvn( dsv, "\"", 1 );
    else if ( flags & PERL_PV_PRETTY_LTGT )
        sv_catpvn( dsv, ">", 1);         
    
    if ( (flags & PERL_PV_PRETTY_ELIPSES) && ( escaped < count ) )
	    sv_catpvn( dsv, "...", 3 );
 
    return SvPVX(dsv);
}

/*
=for apidoc pv_display

Similar to

  pv_escape(dsv,pv,cur,pvlim,PERL_PV_ESCAPE_QUOTE);

except that an additional "\0" will be appended to the string when
len > cur and pv[cur] is "\0".

Note that the final string may be up to 7 chars longer than pvlim.

=cut
*/

char *
Perl_pv_display(pTHX_ SV *dsv, char *pv, STRLEN cur, STRLEN len, STRLEN pvlim)
{
    pv_pretty( dsv, (char *)pv, cur, pvlim, NULL, NULL, PERL_PV_PRETTY_DUMP);
    if (len > cur && pv[cur] == '\0')
            sv_catpvn( dsv, "\\0", 2 );
    return SvPVX(dsv);
}

char *
Perl_sv_peek(pTHX_ SV *sv)
{
    SV * const t = sv_newmortal();
    int unref = 0;
    U32 type;

    sv_setpvn(t, "", 0);
  retry:
    if (!sv) {
	sv_catpv(t, "VOID");
	goto finish;
    }
    else if (sv == (SV*)0x55555555 || SvTYPE(sv) == 'U') {
	sv_catpv(t, "WILD");
	goto finish;
    }
    else if (sv == &PL_sv_undef || sv == &PL_sv_no || sv == &PL_sv_yes || sv == &PL_sv_placeholder) {
	if (sv == &PL_sv_undef) {
	    sv_catpv(t, "SV_UNDEF");
	    if (!(SvFLAGS(sv) & (SVf_OK|SVf_OOK|SVs_OBJECT|
				 SVs_GMG|SVs_SMG|SVs_RMG)) &&
		SvREADONLY(sv))
		goto finish;
	}
	else if (sv == &PL_sv_no) {
	    sv_catpv(t, "SV_NO");
	    if (!(SvFLAGS(sv) & (SVf_ROK|SVf_OOK|SVs_OBJECT|
				 SVs_GMG|SVs_SMG|SVs_RMG)) &&
		!(~SvFLAGS(sv) & (SVf_POK|SVf_NOK|SVf_READONLY|
				  SVp_POK|SVp_NOK)) &&
		SvCUR(sv) == 0 &&
		SvNVX(sv) == 0.0)
		goto finish;
	}
	else if (sv == &PL_sv_yes) {
	    sv_catpv(t, "SV_YES");
	    if (!(SvFLAGS(sv) & (SVf_ROK|SVf_OOK|SVs_OBJECT|
				 SVs_GMG|SVs_SMG|SVs_RMG)) &&
		!(~SvFLAGS(sv) & (SVf_POK|SVf_NOK|SVf_READONLY|
				  SVp_POK|SVp_NOK)) &&
		SvCUR(sv) == 1 &&
		SvPVX_const(sv) && *SvPVX_const(sv) == '1' &&
		SvNVX(sv) == 1.0)
		goto finish;
	}
	else {
	    sv_catpv(t, "SV_PLACEHOLDER");
	    if (!(SvFLAGS(sv) & (SVf_OK|SVf_OOK|SVs_OBJECT|
				 SVs_GMG|SVs_SMG|SVs_RMG)) &&
		SvREADONLY(sv))
		goto finish;
	}
	sv_catpv(t, ":");
    }
    else if (SvREFCNT(sv) == 0) {
	sv_catpv(t, "(");
	unref++;
    }
    else if (DEBUG_R_TEST_) {
	int is_tmp = 0;
	I32 ix;
	/* is this SV on the tmps stack? */
	for (ix=PL_tmps_ix; ix>=0; ix--) {
	    if (PL_tmps_stack[ix] == sv) {
		is_tmp = 1;
		break;
	    }
	}
	if (SvREFCNT(sv) > 1)
	    Perl_sv_catpvf(aTHX_ t, "<%"UVuf"%s>", (UV)SvREFCNT(sv),
		    is_tmp ? "T" : "");
	else if (is_tmp)
	    sv_catpv(t, "<T>");
    }

    if (SvROK(sv)) {
	sv_catpv(t, "\\");
	if (SvCUR(t) + unref > 10) {
	    SvCUR_set(t, unref + 3);
	    *SvEND(t) = '\0';
	    sv_catpv(t, "...");
	    goto finish;
	}
	sv = (SV*)SvRV(sv);
	goto retry;
    }
    type = SvTYPE(sv);
    if (type == SVt_PVCV) {
	Perl_sv_catpvf(aTHX_ t, "CV(%s)", CvGV(sv) ? GvNAME(CvGV(sv)) : "");
	goto finish;
    } else if (type < SVt_LAST) {
	sv_catpv(t, svshorttypenames[type]);

	if (type == SVt_NULL)
	    goto finish;
    } else {
	sv_catpv(t, "FREED");
	goto finish;
    }

    if (SvPOKp(sv)) {
	if (!SvPVX_const(sv))
	    sv_catpv(t, "(null)");
	else {
	    SV * const tmp = newSVpvs("");
	    sv_catpv(t, "(");
	    if (SvOOK(sv))
		Perl_sv_catpvf(aTHX_ t, "[%s]", pv_display(tmp, (char *)SvPVX_const(sv)-SvIVX(sv), SvIVX(sv), 0, 127));
	    Perl_sv_catpvf(aTHX_ t, "%s)", pv_display(tmp, (char *)SvPVX_const(sv), SvCUR(sv), SvLEN(sv), 127));
	    if (SvUTF8(sv))
		Perl_sv_catpvf(aTHX_ t, " [UTF8 \"%s\"]",
			       sv_uni_display(tmp, sv, 6 * SvCUR(sv),
					      UNI_DISPLAY_QQ));
	    SvREFCNT_dec(tmp);
	}
    }
    else if (SvNOKp(sv)) {
	STORE_NUMERIC_LOCAL_SET_STANDARD();
	Perl_sv_catpvf(aTHX_ t, "(%"NVgf")",SvNVX(sv));
	RESTORE_NUMERIC_LOCAL();
    }
    else if (SvIOKp(sv)) {
	if (SvIsUV(sv))
	    Perl_sv_catpvf(aTHX_ t, "(%"UVuf")", (UV)SvUVX(sv));
	else
            Perl_sv_catpvf(aTHX_ t, "(%"IVdf")", (IV)SvIVX(sv));
    }
    else
	sv_catpv(t, "()");

  finish:
    while (unref--)
	sv_catpv(t, ")");
    return SvPV_nolen(t);
}

void
Perl_do_pmop_dump(pTHX_ I32 level, PerlIO *file, PMOP *pm)
{
    char ch;

    if (!pm) {
	Perl_dump_indent(aTHX_ level, file, "{}\n");
	return;
    }
    Perl_dump_indent(aTHX_ level, file, "{\n");
    level++;
    if (pm->op_pmflags & PMf_ONCE)
	ch = '?';
    else
	ch = '/';
    if (PM_GETRE(pm))
	Perl_dump_indent(aTHX_ level, file, "PMf_PRE %c%s%c%s\n",
	     ch, PM_GETRE(pm)->precomp, ch,
	     (pm->op_private & OPpRUNTIME) ? " (RUNTIME)" : "");
    else
	Perl_dump_indent(aTHX_ level, file, "PMf_PRE (RUNTIME)\n");
    if (pm->op_type != OP_PUSHRE && pm->op_pmreplroot) {
	Perl_dump_indent(aTHX_ level, file, "PMf_REPL = ");
	op_dump(pm->op_pmreplroot);
    }
    if (pm->op_pmflags || (PM_GETRE(pm) && PM_GETRE(pm)->check_substr)) {
	SV * const tmpsv = pm_description(pm);
	Perl_dump_indent(aTHX_ level, file, "PMFLAGS = (%s)\n", SvCUR(tmpsv) ? SvPVX_const(tmpsv) + 1 : "");
	SvREFCNT_dec(tmpsv);
    }

    Perl_dump_indent(aTHX_ level-1, file, "}\n");
}

static SV *
S_pm_description(pTHX_ const PMOP *pm)
{
    SV * const desc = newSVpvs("");
    const REGEXP * const regex = PM_GETRE(pm);
    const U32 pmflags = pm->op_pmflags;

    if (pm->op_pmdynflags & PMdf_USED)
	sv_catpv(desc, ",USED");
    if (pm->op_pmdynflags & PMdf_TAINTED)
	sv_catpv(desc, ",TAINTED");

    if (pmflags & PMf_ONCE)
	sv_catpv(desc, ",ONCE");
    if (regex && regex->check_substr) {
	if (!(regex->reganch & ROPT_NOSCAN))
	    sv_catpv(desc, ",SCANFIRST");
	if (regex->reganch & ROPT_CHECK_ALL)
	    sv_catpv(desc, ",ALL");
    }
    if (pmflags & PMf_SKIPWHITE)
	sv_catpv(desc, ",SKIPWHITE");
    if (pmflags & PMf_CONST)
	sv_catpv(desc, ",CONST");
    if (pmflags & PMf_KEEP)
	sv_catpv(desc, ",KEEP");
    if (pmflags & PMf_GLOBAL)
	sv_catpv(desc, ",GLOBAL");
    if (pmflags & PMf_CONTINUE)
	sv_catpv(desc, ",CONTINUE");
    if (pmflags & PMf_RETAINT)
	sv_catpv(desc, ",RETAINT");
    if (pmflags & PMf_EVAL)
	sv_catpv(desc, ",EVAL");
    return desc;
}

void
Perl_pmop_dump(pTHX_ PMOP *pm)
{
    do_pmop_dump(0, Perl_debug_log, pm);
}

void
Perl_do_op_dump(pTHX_ I32 level, PerlIO *file, OP *o)
{
    const OPCODE optype = o->op_type;

    Perl_dump_indent(aTHX_ level, file, "{\n");
    level++;
    if (o->op_seq)
	PerlIO_printf(file, "%-4d", o->op_seq);
    else
	PerlIO_printf(file, "    ");
    PerlIO_printf(file,
		  "%*sTYPE = %s  ===> ",
		  (int)(PL_dumpindent*level-4), "", OP_NAME(o));
    if (o->op_next) {
	if (o->op_seq)
	    PerlIO_printf(file, "%d\n", o->op_next->op_seq);
	else
	    PerlIO_printf(file, "(%d)\n", o->op_next->op_seq);
    }
    else
	PerlIO_printf(file, "DONE\n");
    if (o->op_targ) {
	if (optype == OP_NULL) {
	    Perl_dump_indent(aTHX_ level, file, "  (was %s)\n", PL_op_name[o->op_targ]);
	    if (o->op_targ == OP_NEXTSTATE) {
		if (CopLINE(cCOPo))
		    Perl_dump_indent(aTHX_ level, file, "LINE = %"UVuf"\n",
				     (UV)CopLINE(cCOPo));
		if (CopSTASHPV(cCOPo))
		    Perl_dump_indent(aTHX_ level, file, "PACKAGE = \"%s\"\n",
				     CopSTASHPV(cCOPo));
		if (cCOPo->cop_label)
		    Perl_dump_indent(aTHX_ level, file, "LABEL = \"%s\"\n",
				     cCOPo->cop_label);
	    }
	}
	else
	    Perl_dump_indent(aTHX_ level, file, "TARG = %ld\n", (long)o->op_targ);
    }
#ifdef DUMPADDR
    Perl_dump_indent(aTHX_ level, file, "ADDR = 0x%"UVxf" => 0x%"UVxf"\n", (UV)o, (UV)o->op_next);
#endif
    if (o->op_flags) {
	SV * const tmpsv = newSVpvs("");
	switch (o->op_flags & OPf_WANT) {
	case OPf_WANT_VOID:
	    sv_catpv(tmpsv, ",VOID");
	    break;
	case OPf_WANT_SCALAR:
	    sv_catpv(tmpsv, ",SCALAR");
	    break;
	case OPf_WANT_LIST:
	    sv_catpv(tmpsv, ",LIST");
	    break;
	default:
	    sv_catpv(tmpsv, ",UNKNOWN");
	    break;
	}
	if (o->op_flags & OPf_KIDS)
	    sv_catpv(tmpsv, ",KIDS");
	if (o->op_flags & OPf_PARENS)
	    sv_catpv(tmpsv, ",PARENS");
	if (o->op_flags & OPf_STACKED)
	    sv_catpv(tmpsv, ",STACKED");
	if (o->op_flags & OPf_REF)
	    sv_catpv(tmpsv, ",REF");
	if (o->op_flags & OPf_MOD)
	    sv_catpv(tmpsv, ",MOD");
	if (o->op_flags & OPf_SPECIAL)
	    sv_catpv(tmpsv, ",SPECIAL");
	Perl_dump_indent(aTHX_ level, file, "FLAGS = (%s)\n", SvCUR(tmpsv) ? SvPVX_const(tmpsv) + 1 : "");
	SvREFCNT_dec(tmpsv);
    }
    if (o->op_private) {
	SV * const tmpsv = newSVpvs("");
	if (PL_opargs[optype] & OA_TARGLEX) {
	    if (o->op_private & OPpTARGET_MY)
		sv_catpv(tmpsv, ",TARGET_MY");
	}
	else if (optype == OP_LEAVESUB ||
		 optype == OP_LEAVE ||
		 optype == OP_LEAVESUBLV ||
		 optype == OP_LEAVEWRITE) {
	    if (o->op_private & OPpREFCOUNTED)
		sv_catpv(tmpsv, ",REFCOUNTED");
	}
        else if (optype == OP_AASSIGN) {
	    if (o->op_private & OPpASSIGN_COMMON)
		sv_catpv(tmpsv, ",COMMON");
	    if (o->op_private & OPpASSIGN_HASH)
		sv_catpv(tmpsv, ",HASH");
	}
	else if (optype == OP_SASSIGN) {
	    if (o->op_private & OPpASSIGN_BACKWARDS)
		sv_catpv(tmpsv, ",BACKWARDS");
	}
	else if (optype == OP_TRANS) {
	    if (o->op_private & OPpTRANS_SQUASH)
		sv_catpv(tmpsv, ",SQUASH");
	    if (o->op_private & OPpTRANS_DELETE)
		sv_catpv(tmpsv, ",DELETE");
	    if (o->op_private & OPpTRANS_COMPLEMENT)
		sv_catpv(tmpsv, ",COMPLEMENT");
	    if (o->op_private & OPpTRANS_IDENTICAL)
		sv_catpv(tmpsv, ",IDENTICAL");
	    if (o->op_private & OPpTRANS_GROWS)
		sv_catpv(tmpsv, ",GROWS");
	}
	else if (optype == OP_REPEAT) {
	    if (o->op_private & OPpREPEAT_DOLIST)
		sv_catpv(tmpsv, ",DOLIST");
	}
	else if (optype == OP_ENTERSUB ||
		 optype == OP_RV2SV ||
		 optype == OP_GVSV ||
		 optype == OP_RV2AV ||
		 optype == OP_RV2HV ||
		 optype == OP_RV2GV ||
		 optype == OP_AELEM ||
		 optype == OP_HELEM )
	{
	    if (optype == OP_ENTERSUB) {
		if (o->op_private & OPpENTERSUB_AMPER)
		    sv_catpv(tmpsv, ",AMPER");
		if (o->op_private & OPpENTERSUB_DB)
		    sv_catpv(tmpsv, ",DB");
		if (o->op_private & OPpENTERSUB_HASTARG)
		    sv_catpv(tmpsv, ",HASTARG");
		if (o->op_private & OPpENTERSUB_NOPAREN)
		    sv_catpv(tmpsv, ",NOPAREN");
		if (o->op_private & OPpENTERSUB_INARGS)
		    sv_catpv(tmpsv, ",INARGS");
		if (o->op_private & OPpENTERSUB_NOMOD)
		    sv_catpv(tmpsv, ",NOMOD");
	    }
	    else {
		switch (o->op_private & OPpDEREF) {
		case OPpDEREF_SV:
		    sv_catpv(tmpsv, ",SV");
		    break;
		case OPpDEREF_AV:
		    sv_catpv(tmpsv, ",AV");
		    break;
		case OPpDEREF_HV:
		    sv_catpv(tmpsv, ",HV");
		    break;
		}
		if (o->op_private & OPpMAYBE_LVSUB)
		    sv_catpv(tmpsv, ",MAYBE_LVSUB");
	    }
	    if (optype == OP_AELEM || optype == OP_HELEM) {
		if (o->op_private & OPpLVAL_DEFER)
		    sv_catpv(tmpsv, ",LVAL_DEFER");
	    }
	    else {
		if (o->op_private & HINT_STRICT_REFS)
		    sv_catpv(tmpsv, ",STRICT_REFS");
		if (o->op_private & OPpOUR_INTRO)
		    sv_catpv(tmpsv, ",OUR_INTRO");
	    }
	}
	else if (optype == OP_CONST) {
	    if (o->op_private & OPpCONST_BARE)
		sv_catpv(tmpsv, ",BARE");
	    if (o->op_private & OPpCONST_STRICT)
		sv_catpv(tmpsv, ",STRICT");
	    if (o->op_private & OPpCONST_ARYBASE)
		sv_catpv(tmpsv, ",ARYBASE");
	    if (o->op_private & OPpCONST_WARNING)
		sv_catpv(tmpsv, ",WARNING");
	    if (o->op_private & OPpCONST_ENTERED)
		sv_catpv(tmpsv, ",ENTERED");
	}
	else if (optype == OP_FLIP) {
	    if (o->op_private & OPpFLIP_LINENUM)
		sv_catpv(tmpsv, ",LINENUM");
	}
	else if (optype == OP_FLOP) {
	    if (o->op_private & OPpFLIP_LINENUM)
		sv_catpv(tmpsv, ",LINENUM");
	}
	else if (optype == OP_RV2CV) {
	    if (o->op_private & OPpLVAL_INTRO)
		sv_catpv(tmpsv, ",INTRO");
	}
	else if (optype == OP_GV) {
	    if (o->op_private & OPpEARLY_CV)
		sv_catpv(tmpsv, ",EARLY_CV");
	}
	else if (optype == OP_LIST) {
	    if (o->op_private & OPpLIST_GUESSED)
		sv_catpv(tmpsv, ",GUESSED");
	}
	else if (optype == OP_DELETE) {
	    if (o->op_private & OPpSLICE)
		sv_catpv(tmpsv, ",SLICE");
	}
	else if (optype == OP_EXISTS) {
	    if (o->op_private & OPpEXISTS_SUB)
		sv_catpv(tmpsv, ",EXISTS_SUB");
	}
	else if (optype == OP_SORT) {
	    if (o->op_private & OPpSORT_NUMERIC)
		sv_catpv(tmpsv, ",NUMERIC");
	    if (o->op_private & OPpSORT_INTEGER)
		sv_catpv(tmpsv, ",INTEGER");
	    if (o->op_private & OPpSORT_REVERSE)
		sv_catpv(tmpsv, ",REVERSE");
	}
	else if (optype == OP_THREADSV) {
	    if (o->op_private & OPpDONE_SVREF)
		sv_catpv(tmpsv, ",SVREF");
	}
	else if (optype == OP_OPEN || optype == OP_BACKTICK) {
	    if (o->op_private & OPpOPEN_IN_RAW)
		sv_catpv(tmpsv, ",IN_RAW");
	    if (o->op_private & OPpOPEN_IN_CRLF)
		sv_catpv(tmpsv, ",IN_CRLF");
	    if (o->op_private & OPpOPEN_OUT_RAW)
		sv_catpv(tmpsv, ",OUT_RAW");
	    if (o->op_private & OPpOPEN_OUT_CRLF)
		sv_catpv(tmpsv, ",OUT_CRLF");
	}
	else if (optype == OP_EXIT) {
	    if (o->op_private & OPpEXIT_VMSISH)
		sv_catpv(tmpsv, ",EXIT_VMSISH");
	    if (o->op_private & OPpHUSH_VMSISH)
		sv_catpv(tmpsv, ",HUSH_VMSISH");
	}
	else if (optype == OP_DIE) {
	    if (o->op_private & OPpHUSH_VMSISH)
		sv_catpv(tmpsv, ",HUSH_VMSISH");
	}
	else if (OP_IS_FILETEST_ACCESS(o)) {
	     if (o->op_private & OPpFT_ACCESS)
		  sv_catpv(tmpsv, ",FT_ACCESS");
	}
	if (o->op_flags & OPf_MOD && o->op_private & OPpLVAL_INTRO)
	    sv_catpv(tmpsv, ",INTRO");
	if (SvCUR(tmpsv))
	    Perl_dump_indent(aTHX_ level, file, "PRIVATE = (%s)\n", SvPVX_const(tmpsv) + 1);
	SvREFCNT_dec(tmpsv);
    }

    switch (optype) {
    case OP_AELEMFAST:
    case OP_GVSV:
    case OP_GV:
#ifdef USE_ITHREADS
	Perl_dump_indent(aTHX_ level, file, "PADIX = %" IVdf "\n", (IV)cPADOPo->op_padix);
#else
	if ( ! PL_op->op_flags & OPf_SPECIAL) { /* not lexical */
	    if (cSVOPo->op_sv) {
		SV * const tmpsv = newSV(0);
		ENTER;
		SAVEFREESV(tmpsv);
		gv_fullname3(tmpsv, (GV*)cSVOPo->op_sv, NULL);
		Perl_dump_indent(aTHX_ level, file, "GV = %s\n",
				 SvPV_nolen_const(tmpsv));
		LEAVE;
	    }
	    else
		Perl_dump_indent(aTHX_ level, file, "GV = NULL\n");
	}
#endif
	break;
    case OP_CONST:
    case OP_METHOD_NAMED:
#ifndef USE_ITHREADS
	/* with ITHREADS, consts are stored in the pad, and the right pad
	 * may not be active here, so skip */
	Perl_dump_indent(aTHX_ level, file, "SV = %s\n", SvPEEK(cSVOPo_sv));
#endif
	break;
    case OP_SETSTATE:
    case OP_NEXTSTATE:
    case OP_DBSTATE:
	if (CopLINE(cCOPo))
	    Perl_dump_indent(aTHX_ level, file, "LINE = %"UVuf"\n",
			     (UV)CopLINE(cCOPo));
	if (CopSTASHPV(cCOPo))
	    Perl_dump_indent(aTHX_ level, file, "PACKAGE = \"%s\"\n",
			     CopSTASHPV(cCOPo));
	if (cCOPo->cop_label)
	    Perl_dump_indent(aTHX_ level, file, "LABEL = \"%s\"\n",
			     cCOPo->cop_label);
	break;
    case OP_ENTERLOOP:
	Perl_dump_indent(aTHX_ level, file, "REDO ===> ");
	if (cLOOPo->op_redoop)
	    PerlIO_printf(file, "%d\n", cLOOPo->op_redoop->op_seq);
	else
	    PerlIO_printf(file, "DONE\n");
	Perl_dump_indent(aTHX_ level, file, "NEXT ===> ");
	if (cLOOPo->op_nextop)
	    PerlIO_printf(file, "%d\n", cLOOPo->op_nextop->op_seq);
	else
	    PerlIO_printf(file, "DONE\n");
	Perl_dump_indent(aTHX_ level, file, "LAST ===> ");
	if (cLOOPo->op_lastop)
	    PerlIO_printf(file, "%d\n", cLOOPo->op_lastop->op_seq);
	else
	    PerlIO_printf(file, "DONE\n");
	break;
    case OP_COND_EXPR:
    case OP_RANGE:
    case OP_MAPWHILE:
    case OP_GREPWHILE:
    case OP_OR:
    case OP_AND:
	Perl_dump_indent(aTHX_ level, file, "OTHER ===> ");
	if (cLOGOPo->op_other)
	    PerlIO_printf(file, "%d\n", cLOGOPo->op_other->op_seq);
	else
	    PerlIO_printf(file, "DONE\n");
	break;
    case OP_PUSHRE:
    case OP_MATCH:
    case OP_QR:
    case OP_SUBST:
	do_pmop_dump(level, file, cPMOPo);
	break;
    case OP_LEAVE:
    case OP_LEAVEEVAL:
    case OP_LEAVESUB:
    case OP_LEAVESUBLV:
    case OP_LEAVEWRITE:
    case OP_SCOPE:
	if (o->op_private & OPpREFCOUNTED)
	    Perl_dump_indent(aTHX_ level, file, "REFCNT = %"UVuf"\n", (UV)o->op_targ);
	break;
    default:
	break;
    }
    if (o->op_flags & OPf_KIDS) {
	OP *kid;
	for (kid = cUNOPo->op_first; kid; kid = kid->op_sibling)
	    do_op_dump(level, file, kid);
    }
    Perl_dump_indent(aTHX_ level-1, file, "}\n");
}

void
Perl_op_dump(pTHX_ OP *o)
{
    do_op_dump(0, Perl_debug_log, o);
}

void
Perl_gv_dump(pTHX_ GV *gv)
{
    SV *sv;

    if (!gv) {
	PerlIO_printf(Perl_debug_log, "{}\n");
	return;
    }
    sv = sv_newmortal();
    PerlIO_printf(Perl_debug_log, "{\n");
    gv_fullname3(sv, gv, NULL);
    Perl_dump_indent(aTHX_ 1, Perl_debug_log, "GV_NAME = %s", SvPVX_const(sv));
    if (gv != GvEGV(gv)) {
	gv_efullname3(sv, GvEGV(gv), NULL);
	Perl_dump_indent(aTHX_ 1, Perl_debug_log, "-> %s", SvPVX_const(sv));
    }
    PerlIO_putc(Perl_debug_log, '\n');
    Perl_dump_indent(aTHX_ 0, Perl_debug_log, "}\n");
}


/* map magic types to the symbolic names
 * (with the PERL_MAGIC_ prefixed stripped)
 */

static const struct { const char type; const char *name; } magic_names[] = {
	{ PERL_MAGIC_sv,             "sv(\\0)" },
	{ PERL_MAGIC_arylen,         "arylen(#)" },
	{ PERL_MAGIC_glob,           "glob(*)" },
	{ PERL_MAGIC_pos,            "pos(.)" },
	{ PERL_MAGIC_backref,        "backref(<)" },
	{ PERL_MAGIC_overload,       "overload(A)" },
	{ PERL_MAGIC_bm,             "bm(B)" },
	{ PERL_MAGIC_regdata,        "regdata(D)" },
	{ PERL_MAGIC_env,            "env(E)" },
	{ PERL_MAGIC_isa,            "isa(I)" },
	{ PERL_MAGIC_dbfile,         "dbfile(L)" },
	{ PERL_MAGIC_shared,         "shared(N)" },
	{ PERL_MAGIC_tied,           "tied(P)" },
	{ PERL_MAGIC_sig,            "sig(S)" },
	{ PERL_MAGIC_uvar,           "uvar(U)" },
	{ PERL_MAGIC_overload_elem,  "overload_elem(a)" },
	{ PERL_MAGIC_overload_table, "overload_table(c)" },
	{ PERL_MAGIC_regdatum,       "regdatum(d)" },
	{ PERL_MAGIC_envelem,        "envelem(e)" },
	{ PERL_MAGIC_fm,             "fm(f)" },
	{ PERL_MAGIC_regex_global,   "regex_global(g)" },
	{ PERL_MAGIC_isaelem,        "isaelem(i)" },
	{ PERL_MAGIC_nkeys,          "nkeys(k)" },
	{ PERL_MAGIC_dbline,         "dbline(l)" },
	{ PERL_MAGIC_mutex,          "mutex(m)" },
	{ PERL_MAGIC_shared_scalar,  "shared_scalar(n)" },
	{ PERL_MAGIC_collxfrm,       "collxfrm(o)" },
	{ PERL_MAGIC_tiedelem,       "tiedelem(p)" },
	{ PERL_MAGIC_tiedscalar,     "tiedscalar(q)" },
	{ PERL_MAGIC_qr,             "qr(r)" },
	{ PERL_MAGIC_sigelem,        "sigelem(s)" },
	{ PERL_MAGIC_taint,          "taint(t)" },
	{ PERL_MAGIC_uvar_elem,      "uvar_elem(u)" },
	{ PERL_MAGIC_vec,            "vec(v)" },
	{ PERL_MAGIC_vstring,        "v-string(V)" },
	{ PERL_MAGIC_utf8,           "utf8(w)" },
	{ PERL_MAGIC_substr,         "substr(x)" },
	{ PERL_MAGIC_defelem,        "defelem(y)" },
	{ PERL_MAGIC_ext,            "ext(~)" },
	/* this null string terminates the list */
	{ 0,                         NULL },
};

void
Perl_do_magic_dump(pTHX_ I32 level, PerlIO *file, MAGIC *mg, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim)
{
    for (; mg; mg = mg->mg_moremagic) {
 	Perl_dump_indent(aTHX_ level, file,
			 "  MAGIC = 0x%"UVxf"\n", PTR2UV(mg));
 	if (mg->mg_virtual) {
            const MGVTBL * const v = mg->mg_virtual;
 	    const char *s;
 	    if      (v == &PL_vtbl_sv)         s = "sv";
            else if (v == &PL_vtbl_env)        s = "env";
            else if (v == &PL_vtbl_envelem)    s = "envelem";
            else if (v == &PL_vtbl_sig)        s = "sig";
            else if (v == &PL_vtbl_sigelem)    s = "sigelem";
            else if (v == &PL_vtbl_pack)       s = "pack";
            else if (v == &PL_vtbl_packelem)   s = "packelem";
            else if (v == &PL_vtbl_dbline)     s = "dbline";
            else if (v == &PL_vtbl_isa)        s = "isa";
            else if (v == &PL_vtbl_arylen)     s = "arylen";
            else if (v == &PL_vtbl_glob)       s = "glob";
            else if (v == &PL_vtbl_mglob)      s = "mglob";
            else if (v == &PL_vtbl_nkeys)      s = "nkeys";
            else if (v == &PL_vtbl_taint)      s = "taint";
            else if (v == &PL_vtbl_substr)     s = "substr";
            else if (v == &PL_vtbl_vec)        s = "vec";
            else if (v == &PL_vtbl_pos)        s = "pos";
            else if (v == &PL_vtbl_bm)         s = "bm";
            else if (v == &PL_vtbl_fm)         s = "fm";
            else if (v == &PL_vtbl_uvar)       s = "uvar";
            else if (v == &PL_vtbl_defelem)    s = "defelem";
#ifdef USE_LOCALE_COLLATE
	    else if (v == &PL_vtbl_collxfrm)   s = "collxfrm";
#endif
	    else if (v == &PL_vtbl_amagic)     s = "amagic";
	    else if (v == &PL_vtbl_amagicelem) s = "amagicelem";
	    else if (v == &PL_vtbl_backref)    s = "backref";
	    else if (v == &PL_vtbl_utf8)       s = "utf8";
	    else			       s = NULL;
	    if (s)
	        Perl_dump_indent(aTHX_ level, file, "    MG_VIRTUAL = &PL_vtbl_%s\n", s);
	    else
	        Perl_dump_indent(aTHX_ level, file, "    MG_VIRTUAL = 0x%"UVxf"\n", PTR2UV(v));
        }
	else
	    Perl_dump_indent(aTHX_ level, file, "    MG_VIRTUAL = 0\n");

	if (mg->mg_private)
	    Perl_dump_indent(aTHX_ level, file, "    MG_PRIVATE = %d\n", mg->mg_private);

	{
	    int n;
	    const char *name = NULL;
	    for (n = 0; magic_names[n].name; n++) {
		if (mg->mg_type == magic_names[n].type) {
		    name = magic_names[n].name;
		    break;
		}
	    }
	    if (name)
		Perl_dump_indent(aTHX_ level, file,
				"    MG_TYPE = PERL_MAGIC_%s\n", name);
	    else
		Perl_dump_indent(aTHX_ level, file,
				"    MG_TYPE = UNKNOWN(\\%o)\n", mg->mg_type);
	}

        if (mg->mg_flags) {
            Perl_dump_indent(aTHX_ level, file, "    MG_FLAGS = 0x%02X\n", mg->mg_flags);
	    if (mg->mg_type == PERL_MAGIC_envelem &&
		mg->mg_flags & MGf_TAINTEDDIR)
	        Perl_dump_indent(aTHX_ level, file, "      TAINTEDDIR\n");
	    if (mg->mg_flags & MGf_REFCOUNTED)
	        Perl_dump_indent(aTHX_ level, file, "      REFCOUNTED\n");
            if (mg->mg_flags & MGf_GSKIP)
	        Perl_dump_indent(aTHX_ level, file, "      GSKIP\n");
	    if (mg->mg_type == PERL_MAGIC_regex_global &&
		mg->mg_flags & MGf_MINMATCH)
	        Perl_dump_indent(aTHX_ level, file, "      MINMATCH\n");
        }
	if (mg->mg_obj) {
	    Perl_dump_indent(aTHX_ level, file, "    MG_OBJ = 0x%"UVxf"\n", PTR2UV(mg->mg_obj));
	    if (mg->mg_flags & MGf_REFCOUNTED)
		do_sv_dump(level+2, file, mg->mg_obj, nest+1, maxnest, dumpops, pvlim); /* MG is already +1 */
	}
        if (mg->mg_len)
	    Perl_dump_indent(aTHX_ level, file, "    MG_LEN = %ld\n", (long)mg->mg_len);
        if (mg->mg_ptr) {
	    Perl_dump_indent(aTHX_ level, file, "    MG_PTR = 0x%"UVxf, PTR2UV(mg->mg_ptr));
	    if (mg->mg_len >= 0) {
		if (mg->mg_type != PERL_MAGIC_utf8) {
		    SV * const sv = newSVpvs("");
		    PerlIO_printf(file, " %s", pv_display(sv, mg->mg_ptr, mg->mg_len, 0, pvlim));
		    SvREFCNT_dec(sv);
		}
            }
	    else if (mg->mg_len == HEf_SVKEY) {
		PerlIO_puts(file, " => HEf_SVKEY\n");
		do_sv_dump(level+2, file, (SV*)((mg)->mg_ptr), nest+1, maxnest, dumpops, pvlim); /* MG is already +1 */
		continue;
	    }
	    else
		PerlIO_puts(file, " ???? - please notify IZ");
            PerlIO_putc(file, '\n');
        }
	if (mg->mg_type == PERL_MAGIC_utf8) {
	    const STRLEN * const cache = (STRLEN *) mg->mg_ptr;
	    if (cache) {
		IV i;
		for (i = 0; i < PERL_MAGIC_UTF8_CACHESIZE; i++)
		    Perl_dump_indent(aTHX_ level, file,
				     "      %2"IVdf": %"UVuf" -> %"UVuf"\n",
				     i,
				     (UV)cache[i * 2],
				     (UV)cache[i * 2 + 1]);
	    }
	}
    }
}

void
Perl_magic_dump(pTHX_ MAGIC *mg)
{
    do_magic_dump(0, Perl_debug_log, mg, 0, 0, FALSE, 0);
}

void
Perl_do_hv_dump(pTHX_ I32 level, PerlIO *file, char *name, HV *sv)
{
    const char *hvname;
    Perl_dump_indent(aTHX_ level, file, "%s = 0x%"UVxf, name, PTR2UV(sv));
    if (sv && (hvname = HvNAME_get(sv)))
	PerlIO_printf(file, "\t\"%s\"\n", hvname);
    else
	PerlIO_putc(file, '\n');
}

void
Perl_do_gv_dump(pTHX_ I32 level, PerlIO *file, char *name, GV *sv)
{
    Perl_dump_indent(aTHX_ level, file, "%s = 0x%"UVxf, name, PTR2UV(sv));
    if (sv && GvNAME(sv))
	PerlIO_printf(file, "\t\"%s\"\n", GvNAME(sv));
    else
	PerlIO_putc(file, '\n');
}

void
Perl_do_gvgv_dump(pTHX_ I32 level, PerlIO *file, char *name, GV *sv)
{
    Perl_dump_indent(aTHX_ level, file, "%s = 0x%"UVxf, name, PTR2UV(sv));
    if (sv && GvNAME(sv)) {
	const char *hvname;
	PerlIO_printf(file, "\t\"");
	if (GvSTASH(sv) && (hvname = HvNAME_get(GvSTASH(sv))))
	    PerlIO_printf(file, "%s\" :: \"", hvname);
	PerlIO_printf(file, "%s\"\n", GvNAME(sv));
    }
    else
	PerlIO_putc(file, '\n');
}

void
Perl_do_sv_dump(pTHX_ I32 level, PerlIO *file, SV *sv, I32 nest, I32 maxnest, bool dumpops, STRLEN pvlim)
{
    SV *d;
    const char *s;
    U32 flags;
    U32 type;

    if (!sv) {
	Perl_dump_indent(aTHX_ level, file, "SV = 0\n");
	return;
    }

    flags = SvFLAGS(sv);
    type = SvTYPE(sv);

    d = Perl_newSVpvf(aTHX_
		   "(0x%"UVxf") at 0x%"UVxf"\n%*s  REFCNT = %"IVdf"\n%*s  FLAGS = (",
		   PTR2UV(SvANY(sv)), PTR2UV(sv),
		   (int)(PL_dumpindent*level), "", (IV)SvREFCNT(sv),
		   (int)(PL_dumpindent*level), "");

    if (flags & SVs_PADBUSY)	sv_catpv(d, "PADBUSY,");
    if (flags & SVs_PADTMP)	sv_catpv(d, "PADTMP,");
    if (flags & SVs_PADMY)	sv_catpv(d, "PADMY,");
    if (flags & SVs_TEMP)	sv_catpv(d, "TEMP,");
    if (flags & SVs_OBJECT)	sv_catpv(d, "OBJECT,");
    if (flags & SVs_GMG)	sv_catpv(d, "GMG,");
    if (flags & SVs_SMG)	sv_catpv(d, "SMG,");
    if (flags & SVs_RMG)	sv_catpv(d, "RMG,");

    if (flags & SVf_IOK)	sv_catpv(d, "IOK,");
    if (flags & SVf_NOK)	sv_catpv(d, "NOK,");
    if (flags & SVf_POK)	sv_catpv(d, "POK,");
    if (flags & SVf_ROK)  {	
    				sv_catpv(d, "ROK,");
	if (SvWEAKREF(sv))	sv_catpv(d, "WEAKREF,");
    }
    if (flags & SVf_OOK)	sv_catpv(d, "OOK,");
    if (flags & SVf_FAKE)	sv_catpv(d, "FAKE,");
    if (flags & SVf_READONLY)	sv_catpv(d, "READONLY,");
    if (flags & SVf_BREAK)	sv_catpv(d, "BREAK,");

    if (flags & SVf_AMAGIC && type != SVt_PVHV)
				sv_catpv(d, "OVERLOAD,");
    if (flags & SVp_IOK)	sv_catpv(d, "pIOK,");
    if (flags & SVp_NOK)	sv_catpv(d, "pNOK,");
    if (flags & SVp_POK)	sv_catpv(d, "pPOK,");
    if (flags & SVp_SCREAM && type != SVt_PVHV) {
	if (SvPCS_IMPORTED(sv))
				sv_catpv(d, "PCS_IMPORTED,");
	else
				sv_catpv(d, "SCREAM,");
    }

    switch (type) {
    case SVt_PVCV:
    case SVt_PVFM:
	if (CvANON(sv))		sv_catpv(d, "ANON,");
	if (CvUNIQUE(sv))	sv_catpv(d, "UNIQUE,");
	if (CvCLONE(sv))	sv_catpv(d, "CLONE,");
	if (CvCLONED(sv))	sv_catpv(d, "CLONED,");
	if (CvCONST(sv))	sv_catpv(d, "CONST,");
	if (CvNODEBUG(sv))	sv_catpv(d, "NODEBUG,");
	if (SvCOMPILED(sv))	sv_catpv(d, "COMPILED,");
	if (CvLVALUE(sv))	sv_catpv(d, "LVALUE,");
	if (CvMETHOD(sv))	sv_catpv(d, "METHOD,");
	if (CvLOCKED(sv))	sv_catpv(d, "LOCKED,");
	if (CvWEAKOUTSIDE(sv))	sv_catpv(d, "WEAKOUTSIDE,");
	break;
    case SVt_PVHV:
	if (HvSHAREKEYS(sv))	sv_catpv(d, "SHAREKEYS,");
	if (HvLAZYDEL(sv))	sv_catpv(d, "LAZYDEL,");
	if (HvHASKFLAGS(sv))	sv_catpv(d, "HASKFLAGS,");
	if (HvREHASH(sv))	sv_catpv(d, "REHASH,");
	if (flags & SVphv_CLONEABLE) sv_catpv(d, "CLONEABLE,");
	break;
    case SVt_PVGV:
	if (GvINTRO(sv))	sv_catpv(d, "INTRO,");
	if (GvMULTI(sv))	sv_catpv(d, "MULTI,");
	if (GvUNIQUE(sv))       sv_catpv(d, "UNIQUE,");
	if (GvASSUMECV(sv))	sv_catpv(d, "ASSUMECV,");
	if (GvIN_PAD(sv))       sv_catpv(d, "IN_PAD,");
	if (SvPAD_OUR(sv))	sv_catpv(d, "OUR,");
	if (SvPAD_TYPED(sv))	sv_catpv(d, "TYPED,");
	if (GvIMPORTED(sv)) {
	    sv_catpv(d, "IMPORT");
	    if (GvIMPORTED(sv) == GVf_IMPORTED)
		sv_catpv(d, "ALL,");
	    else {
		sv_catpv(d, "(");
		if (GvIMPORTED_SV(sv))	sv_catpv(d, " SV");
		if (GvIMPORTED_AV(sv))	sv_catpv(d, " AV");
		if (GvIMPORTED_HV(sv))	sv_catpv(d, " HV");
		if (GvIMPORTED_CV(sv))	sv_catpv(d, " CV");
		sv_catpv(d, " ),");
	    }
	}
	/* FALL THROUGH */
    default:
    evaled_or_uv:
	if (SvEVALED(sv))	sv_catpv(d, "EVALED,");
	if (SvIsUV(sv) && !(flags & SVf_ROK))	sv_catpv(d, "IsUV,");
	break;
    case SVt_PVBM:
	if (SvTAIL(sv))		sv_catpv(d, "TAIL,");
	if (SvVALID(sv))	sv_catpv(d, "VALID,");
	break;
    case SVt_PVMG:
	if (SvPAD_TYPED(sv))	sv_catpv(d, "TYPED,");
	goto evaled_or_uv;
    }
    /* SVphv_SHAREKEYS is also 0x20000000 */
    if ((type != SVt_PVHV) && SvUTF8(sv))
        sv_catpv(d, "UTF8");

    if (*(SvEND(d) - 1) == ',') {
        SvCUR_set(d, SvCUR(d) - 1);
	SvPVX(d)[SvCUR(d)] = '\0';
    }
    sv_catpv(d, ")");
    s = SvPVX_const(d);

    Perl_dump_indent(aTHX_ level, file, "SV = ");
    if (type < SVt_LAST) {
	PerlIO_printf(file, "%s%s\n", svtypenames[type], s);

	if (type ==  SVt_NULL) {
	    SvREFCNT_dec(d);
	    return;
	}
    } else {
	PerlIO_printf(file, "UNKNOWN(0x%"UVxf") %s\n", (UV)type, s);
	SvREFCNT_dec(d);
	return;
    }
    if (type >= SVt_PVIV || type == SVt_IV) {
	if (SvIsUV(sv))
	    Perl_dump_indent(aTHX_ level, file, "  UV = %"UVuf, (UV)SvUVX(sv));
	else
	    Perl_dump_indent(aTHX_ level, file, "  IV = %"IVdf, (IV)SvIVX(sv));
	if (SvOOK(sv))
	    PerlIO_printf(file, "  (OFFSET)");
	PerlIO_putc(file, '\n');
    }
    if (type >= SVt_PVNV || type == SVt_NV) {
	STORE_NUMERIC_LOCAL_SET_STANDARD();
	/* %Vg doesn't work? --jhi */
#ifdef USE_LONG_DOUBLE
	Perl_dump_indent(aTHX_ level, file, "  NV = %.*" PERL_PRIgldbl "\n", LDBL_DIG, SvNVX(sv));
#else
	Perl_dump_indent(aTHX_ level, file, "  NV = %.*g\n", DBL_DIG, SvNVX(sv));
#endif
	RESTORE_NUMERIC_LOCAL();
    }
    if (SvROK(sv)) {
	Perl_dump_indent(aTHX_ level, file, "  RV = 0x%"UVxf"\n", PTR2UV(SvRV(sv)));
	if (nest < maxnest)
	    do_sv_dump(level+1, file, SvRV(sv), nest+1, maxnest, dumpops, pvlim);
    }
    if (type < SVt_PV) {
	SvREFCNT_dec(d);
	return;
    }
    if (type <= SVt_PVLV || type == SVt_PVGV || type == SVt_PVFM) {
	if (SvPVX_const(sv)) {
	    Perl_dump_indent(aTHX_ level, file,"  PV = 0x%"UVxf" ", PTR2UV(SvPVX_const(sv)));
	    if (SvOOK(sv))
		PerlIO_printf(file, "( %s . ) ", pv_display(d, (char *)SvPVX_const(sv)-SvIVX(sv), SvIVX(sv), 0, pvlim));
	    PerlIO_printf(file, "%s", pv_display(d, (char *)SvPVX_const(sv), SvCUR(sv), SvLEN(sv), pvlim));
	    if (SvUTF8(sv)) /* the 6?  \x{....} */
	        PerlIO_printf(file, " [UTF8 \"%s\"]", sv_uni_display(d, sv, 6 * SvCUR(sv), UNI_DISPLAY_QQ));
	    PerlIO_printf(file, "\n");
	    Perl_dump_indent(aTHX_ level, file, "  CUR = %"IVdf"\n", (IV)SvCUR(sv));
	    Perl_dump_indent(aTHX_ level, file, "  LEN = %"IVdf"\n", (IV)SvLEN(sv));
	}
	else
	    Perl_dump_indent(aTHX_ level, file, "  PV = 0\n");
    }
    if (type >= SVt_PVMG) {
	if (SvMAGIC(sv))
            do_magic_dump(level, file, SvMAGIC(sv), nest, maxnest, dumpops, pvlim);
	if (SvSTASH(sv))
	    do_hv_dump(level, file, "  STASH", SvSTASH(sv));
    }
    switch (type) {
    case SVt_PVLV:
	Perl_dump_indent(aTHX_ level, file, "  TYPE = %c\n", LvTYPE(sv));
	Perl_dump_indent(aTHX_ level, file, "  TARGOFF = %"IVdf"\n", (IV)LvTARGOFF(sv));
	Perl_dump_indent(aTHX_ level, file, "  TARGLEN = %"IVdf"\n", (IV)LvTARGLEN(sv));
	Perl_dump_indent(aTHX_ level, file, "  TARG = 0x%"UVxf"\n", PTR2UV(LvTARG(sv)));
	if (LvTYPE(sv) != 't' && LvTYPE(sv) != 'T')
	    do_sv_dump(level+1, file, LvTARG(sv), nest+1, maxnest,
		    dumpops, pvlim);
	break;
    case SVt_PVAV:
	Perl_dump_indent(aTHX_ level, file, "  ARRAY = 0x%"UVxf, PTR2UV(AvARRAY(sv)));
	if (AvARRAY(sv) != AvALLOC(sv)) {
	    PerlIO_printf(file, " (offset=%"IVdf")\n", (IV)(AvARRAY(sv) - AvALLOC(sv)));
	    Perl_dump_indent(aTHX_ level, file, "  ALLOC = 0x%"UVxf"\n", PTR2UV(AvALLOC(sv)));
	}
	else
	    PerlIO_putc(file, '\n');
	Perl_dump_indent(aTHX_ level, file, "  FILL = %"IVdf"\n", (IV)AvFILLp(sv));
	Perl_dump_indent(aTHX_ level, file, "  MAX = %"IVdf"\n", (IV)AvMAX(sv));
	Perl_dump_indent(aTHX_ level, file, "  ARYLEN = 0x%"UVxf"\n", PTR2UV(AvARYLEN(sv)));
	flags = AvFLAGS(sv);
	sv_setpvn(d, "", 0);
	if (flags & AVf_REAL)	sv_catpv(d, ",REAL");
	if (flags & AVf_REIFY)	sv_catpv(d, ",REIFY");
	if (flags & AVf_REUSED)	sv_catpv(d, ",REUSED");
	Perl_dump_indent(aTHX_ level, file, "  FLAGS = (%s)\n",
			 SvCUR(d) ? SvPVX_const(d) + 1 : "");
	if (nest < maxnest && av_len((AV*)sv) >= 0) {
	    int count;
	    for (count = 0; count <=  av_len((AV*)sv) && count < maxnest; count++) {
		SV** const elt = av_fetch((AV*)sv,count,0);

		Perl_dump_indent(aTHX_ level + 1, file, "Elt No. %"IVdf"\n", (IV)count);
		if (elt)
		    do_sv_dump(level+1, file, *elt, nest+1, maxnest, dumpops, pvlim);
	    }
	}
	break;
    case SVt_PVHV:
	Perl_dump_indent(aTHX_ level, file, "  ARRAY = 0x%"UVxf, PTR2UV(HvARRAY(sv)));
	if (HvARRAY(sv) && HvKEYS(sv)) {
	    /* Show distribution of HEs in the ARRAY */
	    int freq[200];
#define FREQ_MAX ((int)(sizeof freq / sizeof freq[0] - 1))
	    int i;
	    int max = 0;
	    U32 pow2 = 2, keys = HvKEYS(sv);
	    NV theoret, sum = 0;

	    PerlIO_printf(file, "  (");
	    Zero(freq, FREQ_MAX + 1, int);
	    for (i = 0; (STRLEN)i <= HvMAX(sv); i++) {
		HE* h;
		int count = 0;
                for (h = HvARRAY(sv)[i]; h; h = HeNEXT(h))
		    count++;
		if (count > FREQ_MAX)
		    count = FREQ_MAX;
	        freq[count]++;
	        if (max < count)
		    max = count;
	    }
	    for (i = 0; i <= max; i++) {
		if (freq[i]) {
		    PerlIO_printf(file, "%d%s:%d", i,
				  (i == FREQ_MAX) ? "+" : "",
				  freq[i]);
		    if (i != max)
			PerlIO_printf(file, ", ");
		}
            }
	    PerlIO_putc(file, ')');
	    /* The "quality" of a hash is defined as the total number of
	       comparisons needed to access every element once, relative
	       to the expected number needed for a random hash.

	       The total number of comparisons is equal to the sum of
	       the squares of the number of entries in each bucket.
	       For a random hash of n keys into k buckets, the expected
	       value is
				n + n(n-1)/2k
	    */

	    for (i = max; i > 0; i--) { /* Precision: count down. */
		sum += freq[i] * i * i;
            }
	    while ((keys = keys >> 1))
		pow2 = pow2 << 1;
	    theoret = HvKEYS(sv);
	    theoret += theoret * (theoret-1)/pow2;
	    PerlIO_putc(file, '\n');
	    Perl_dump_indent(aTHX_ level, file, "  hash quality = %.1"NVff"%%", theoret/sum*100);
	}
	PerlIO_putc(file, '\n');
	Perl_dump_indent(aTHX_ level, file, "  KEYS = %"IVdf"\n", (IV)HvKEYS(sv));
	Perl_dump_indent(aTHX_ level, file, "  FILL = %"IVdf"\n", (IV)HvFILL(sv));
	Perl_dump_indent(aTHX_ level, file, "  MAX = %"IVdf"\n", (IV)HvMAX(sv));
	Perl_dump_indent(aTHX_ level, file, "  RITER = %"IVdf"\n", (IV)HvRITER_get(sv));
	Perl_dump_indent(aTHX_ level, file, "  EITER = 0x%"UVxf"\n", PTR2UV(HvEITER_get(sv)));
	if (HvPMROOT(sv))
	    Perl_dump_indent(aTHX_ level, file, "  PMROOT = 0x%"UVxf"\n", PTR2UV(HvPMROOT(sv)));
	{
	    const char * const hvname = HvNAME_get(sv);
	    if (hvname)
		Perl_dump_indent(aTHX_ level, file, "  NAME = \"%s\"\n", hvname);
	}
	if (nest < maxnest && !HvEITER_get(sv)) { /* Try to preserve iterator */
	    HE *he;
	    HV * const hv = (HV*)sv;
	    int count = maxnest - nest;

	    hv_iterinit(hv);
	    while ((he = hv_iternext_flags(hv, HV_ITERNEXT_WANTPLACEHOLDERS))
                   && count--) {
		STRLEN len;
		const U32 hash = HeHASH(he);
		SV * const keysv = hv_iterkeysv(he);
		const char * const keypv = SvPV_const(keysv, len);
		SV * const elt = hv_iterval(hv, he);

		Perl_dump_indent(aTHX_ level+1, file, "Elt %s ", pv_display(d, (char *)keypv, len, 0, pvlim));
		if (SvUTF8(keysv))
		    PerlIO_printf(file, "[UTF8 \"%s\"] ", sv_uni_display(d, keysv, 6 * SvCUR(keysv), UNI_DISPLAY_QQ));
		if (HeKREHASH(he))
		    PerlIO_printf(file, "[REHASH] ");
		PerlIO_printf(file, "HASH = 0x%"UVxf"\n", (UV)hash);
		do_sv_dump(level+1, file, elt, nest+1, maxnest, dumpops, pvlim);
	    }
	    hv_iterinit(hv);		/* Return to status quo */
	}
	break;
    case SVt_PVCV:
	if (SvPOK(sv)) {
	    STRLEN len;
	    const char *const proto =  SvPV_const(sv, len);
	    Perl_dump_indent(aTHX_ level, file, "  PROTOTYPE = \"%.*s\"\n",
			     (int) len, proto);
	}
	/* FALL THROUGH */
    case SVt_PVFM:
	do_hv_dump(level, file, "  COMP_STASH", CvSTASH(sv));
	if (CvSTART(sv))
	    Perl_dump_indent(aTHX_ level, file, "  START = 0x%"UVxf" ===> %"IVdf"\n", PTR2UV(CvSTART(sv)), (IV)CvSTART(sv)->op_seq);
	Perl_dump_indent(aTHX_ level, file, "  ROOT = 0x%"UVxf"\n", PTR2UV(CvROOT(sv)));
        if (CvROOT(sv) && dumpops)
	    do_op_dump(level+1, file, CvROOT(sv));
	Perl_dump_indent(aTHX_ level, file, "  XSUB = 0x%"UVxf"\n", PTR2UV(CvXSUB(sv)));
	{
	    SV * const constant = cv_const_sv((CV *)sv);


	    if (constant) {
		Perl_dump_indent(aTHX_ level, file, "  XSUBANY = 0x%"UVxf
				 " (CONST SV)\n",
				 PTR2UV(CvXSUBANY(sv).any_ptr));
		do_sv_dump(level+1, file, constant, nest+1, maxnest, dumpops,
			   pvlim);
	    } else {
		Perl_dump_indent(aTHX_ level, file, "  XSUBANY = %"IVdf"\n",
				 (IV)CvXSUBANY(sv).any_i32);
	    }
	}
 	do_gvgv_dump(level, file, "  GVGV::GV", CvGV(sv));
	Perl_dump_indent(aTHX_ level, file, "  FILE = \"%s\"\n", CvFILE(sv));
	Perl_dump_indent(aTHX_ level, file, "  DEPTH = %"IVdf"\n", (IV)CvDEPTH(sv));
#ifdef USE_5005THREADS
	Perl_dump_indent(aTHX_ level, file, "  MUTEXP = 0x%"UVxf"\n", PTR2UV(CvMUTEXP(sv)));
	Perl_dump_indent(aTHX_ level, file, "  OWNER = 0x%"UVxf"\n",  PTR2UV(CvOWNER(sv)));
#endif /* USE_5005THREADS */
	Perl_dump_indent(aTHX_ level, file, "  FLAGS = 0x%"UVxf"\n", (UV)CvFLAGS(sv));
	Perl_dump_indent(aTHX_ level, file, "  OUTSIDE_SEQ = %"UVuf"\n", (UV)CvOUTSIDE_SEQ(sv));
	if (type == SVt_PVFM)
	    Perl_dump_indent(aTHX_ level, file, "  LINES = %"IVdf"\n", (IV)FmLINES(sv));
	Perl_dump_indent(aTHX_ level, file, "  PADLIST = 0x%"UVxf"\n", PTR2UV(CvPADLIST(sv)));
	if (nest < maxnest) {
	    do_dump_pad(level+1, file, CvPADLIST(sv), 0);
	}
	{
	    const CV * const outside = CvOUTSIDE(sv);
	    Perl_dump_indent(aTHX_ level, file, "  OUTSIDE = 0x%"UVxf" (%s)\n",
			PTR2UV(outside),
			(!outside ? "null"
			 : CvANON(outside) ? "ANON"
			 : (outside == PL_main_cv) ? "MAIN"
			 : CvUNIQUE(outside) ? "UNIQUE"
			 : CvGV(outside) ? GvNAME(CvGV(outside)) : "UNDEFINED"));
	}
	if (nest < maxnest && (CvCLONE(sv) || CvCLONED(sv)))
	    do_sv_dump(level+1, file, (SV*)CvOUTSIDE(sv), nest+1, maxnest, dumpops, pvlim);
	break;
    case SVt_PVBM:
	Perl_dump_indent(aTHX_ level, file, "  FLAGS = %u\n", (U8)BmFLAGS(sv));
	Perl_dump_indent(aTHX_ level, file, "  RARE = %u\n", (U8)BmRARE(sv));
	Perl_dump_indent(aTHX_ level, file, "  PREVIOUS = %"UVuf"\n", (UV)BmPREVIOUS(sv));
	Perl_dump_indent(aTHX_ level, file, "  USEFUL = %"IVdf"\n", (IV)BmUSEFUL(sv));
	break;
    case SVt_PVGV:
	Perl_dump_indent(aTHX_ level, file, "  NAME = \"%s\"\n", GvNAME(sv));
	Perl_dump_indent(aTHX_ level, file, "  NAMELEN = %"IVdf"\n", (IV)GvNAMELEN(sv));
	do_hv_dump (level, file, "  GvSTASH", GvSTASH(sv));
	Perl_dump_indent(aTHX_ level, file, "  GP = 0x%"UVxf"\n", PTR2UV(GvGP(sv)));
	if (!GvGP(sv))
	    break;
	Perl_dump_indent(aTHX_ level, file, "    SV = 0x%"UVxf"\n", PTR2UV(GvSV(sv)));
	Perl_dump_indent(aTHX_ level, file, "    REFCNT = %"IVdf"\n", (IV)GvREFCNT(sv));
	Perl_dump_indent(aTHX_ level, file, "    IO = 0x%"UVxf"\n", PTR2UV(GvIOp(sv)));
	Perl_dump_indent(aTHX_ level, file, "    FORM = 0x%"UVxf"  \n", PTR2UV(GvFORM(sv)));
	Perl_dump_indent(aTHX_ level, file, "    AV = 0x%"UVxf"\n", PTR2UV(GvAV(sv)));
	Perl_dump_indent(aTHX_ level, file, "    HV = 0x%"UVxf"\n", PTR2UV(GvHV(sv)));
	Perl_dump_indent(aTHX_ level, file, "    CV = 0x%"UVxf"\n", PTR2UV(GvCV(sv)));
	Perl_dump_indent(aTHX_ level, file, "    CVGEN = 0x%"UVxf"\n", (UV)GvCVGEN(sv));
	Perl_dump_indent(aTHX_ level, file, "    GPFLAGS = 0x%"UVxf"\n", (UV)GvGPFLAGS(sv));
	Perl_dump_indent(aTHX_ level, file, "    LINE = %"IVdf"\n", (IV)GvLINE(sv));
	Perl_dump_indent(aTHX_ level, file, "    FILE = \"%s\"\n", GvFILE(sv));
	Perl_dump_indent(aTHX_ level, file, "    FLAGS = 0x%"UVxf"\n", (UV)GvFLAGS(sv));
	do_gv_dump (level, file, "    EGV", GvEGV(sv));
	break;
    case SVt_PVIO:
	Perl_dump_indent(aTHX_ level, file, "  IFP = 0x%"UVxf"\n", PTR2UV(IoIFP(sv)));
	Perl_dump_indent(aTHX_ level, file, "  OFP = 0x%"UVxf"\n", PTR2UV(IoOFP(sv)));
	Perl_dump_indent(aTHX_ level, file, "  DIRP = 0x%"UVxf"\n", PTR2UV(IoDIRP(sv)));
	Perl_dump_indent(aTHX_ level, file, "  LINES = %"IVdf"\n", (IV)IoLINES(sv));
	Perl_dump_indent(aTHX_ level, file, "  PAGE = %"IVdf"\n", (IV)IoPAGE(sv));
	Perl_dump_indent(aTHX_ level, file, "  PAGE_LEN = %"IVdf"\n", (IV)IoPAGE_LEN(sv));
	Perl_dump_indent(aTHX_ level, file, "  LINES_LEFT = %"IVdf"\n", (IV)IoLINES_LEFT(sv));
        if (IoTOP_NAME(sv))
            Perl_dump_indent(aTHX_ level, file, "  TOP_NAME = \"%s\"\n", IoTOP_NAME(sv));
	if (!IoTOP_GV(sv) || SvTYPE(IoTOP_GV(sv)) == SVt_PVGV)
	    do_gv_dump (level, file, "  TOP_GV", IoTOP_GV(sv));
	else {
	    Perl_dump_indent(aTHX_ level, file, "  TOP_GV = 0x%"UVxf"\n",
			     PTR2UV(IoTOP_GV(sv)));
	    do_sv_dump (level+1, file, (SV *) IoTOP_GV(sv), nest+1, maxnest,
			dumpops, pvlim);
	}
	/* Source filters hide things that are not GVs in these three, so let's
	   be careful out there.  */
        if (IoFMT_NAME(sv))
            Perl_dump_indent(aTHX_ level, file, "  FMT_NAME = \"%s\"\n", IoFMT_NAME(sv));
	if (!IoFMT_GV(sv) || SvTYPE(IoFMT_GV(sv)) == SVt_PVGV)
	    do_gv_dump (level, file, "  FMT_GV", IoFMT_GV(sv));
	else {
	    Perl_dump_indent(aTHX_ level, file, "  FMT_GV = 0x%"UVxf"\n",
			     PTR2UV(IoFMT_GV(sv)));
	    do_sv_dump (level+1, file, (SV *) IoFMT_GV(sv), nest+1, maxnest,
			dumpops, pvlim);
	}
        if (IoBOTTOM_NAME(sv))
            Perl_dump_indent(aTHX_ level, file, "  BOTTOM_NAME = \"%s\"\n", IoBOTTOM_NAME(sv));
	if (!IoBOTTOM_GV(sv) || SvTYPE(IoBOTTOM_GV(sv)) == SVt_PVGV)
	    do_gv_dump (level, file, "  BOTTOM_GV", IoBOTTOM_GV(sv));
	else {
	    Perl_dump_indent(aTHX_ level, file, "  BOTTOM_GV = 0x%"UVxf"\n",
			     PTR2UV(IoBOTTOM_GV(sv)));
	    do_sv_dump (level+1, file, (SV *) IoBOTTOM_GV(sv), nest+1, maxnest,
			dumpops, pvlim);
	}
	Perl_dump_indent(aTHX_ level, file, "  SUBPROCESS = %"IVdf"\n", (IV)IoSUBPROCESS(sv));
	if (isPRINT(IoTYPE(sv)))
            Perl_dump_indent(aTHX_ level, file, "  TYPE = '%c'\n", IoTYPE(sv));
	else
            Perl_dump_indent(aTHX_ level, file, "  TYPE = '\\%o'\n", IoTYPE(sv));
	Perl_dump_indent(aTHX_ level, file, "  FLAGS = 0x%"UVxf"\n", (UV)IoFLAGS(sv));
	break;
    }
    SvREFCNT_dec(d);
}

void
Perl_sv_dump(pTHX_ SV *sv)
{
    do_sv_dump(0, Perl_debug_log, sv, 0, 0, 0, 0);
}

int
Perl_runops_debug(pTHX)
{
    if (!PL_op) {
	if (ckWARN_d(WARN_DEBUGGING))
	    Perl_warner(aTHX_ packWARN(WARN_DEBUGGING), "NULL OP IN RUN");
	return 0;
    }

    DEBUG_l(Perl_deb(aTHX_ "Entering new RUNOPS level\n"));
    do {
	PERL_ASYNC_CHECK();
	if (PL_debug) {
	    if (PL_watchaddr && (*PL_watchaddr != PL_watchok))
		PerlIO_printf(Perl_debug_log,
			      "WARNING: %"UVxf" changed from %"UVxf" to %"UVxf"\n",
			      PTR2UV(PL_watchaddr), PTR2UV(PL_watchok),
			      PTR2UV(*PL_watchaddr));
	    if (DEBUG_s_TEST_) {
		if (DEBUG_v_TEST_) {
		    PerlIO_printf(Perl_debug_log, "\n");
		    deb_stack_all();
		}
		else
		    debstack();
	    }


	    if (DEBUG_t_TEST_) debop(PL_op);
	    if (DEBUG_P_TEST_) debprof(PL_op);
	}
    } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));
    DEBUG_l(Perl_deb(aTHX_ "leaving RUNOPS level\n"));

    TAINT_NOT;
    return 0;
}

I32
Perl_debop(pTHX_ OP *o)
{
    if (CopSTASH_eq(PL_curcop, PL_debstash) && !DEBUG_J_TEST_)
	return 0;

    Perl_deb(aTHX_ "%s", OP_NAME(o));
    switch (o->op_type) {
    case OP_CONST:
	/* With ITHREADS, consts are stored in the pad, and the right pad
	 * may not be active here, so check.
	 * Looks like only during compiling the pads are illegal.
	 */
#ifdef USE_ITHREADS
	if ((((SVOP*)o)->op_sv) || !IN_PERL_COMPILETIME)
#endif
	    PerlIO_printf(Perl_debug_log, "(%s)", SvPEEK(cSVOPo_sv));
	break;
    case OP_GVSV:
    case OP_GV:
	if (cGVOPo_gv) {
	    SV * const sv = newSV(0);
	    gv_fullname3(sv, cGVOPo_gv, NULL);
	    PerlIO_printf(Perl_debug_log, "(%s)", SvPV_nolen_const(sv));
	    SvREFCNT_dec(sv);
	}
	else
	    PerlIO_printf(Perl_debug_log, "(NULL)");
	break;
    case OP_PADSV:
    case OP_PADAV:
    case OP_PADHV:
	{
	/* print the lexical's name */
	CV * const cv = deb_curcv(cxstack_ix);
	SV *sv;
        if (cv) {
	    AV * const padlist = CvPADLIST(cv);
            AV * const comppad = (AV*)(*av_fetch(padlist, 0, FALSE));
            sv = *av_fetch(comppad, o->op_targ, FALSE);
        } else
            sv = NULL;
        if (sv)
	    PerlIO_printf(Perl_debug_log, "(%s)", SvPV_nolen_const(sv));
        else
	    PerlIO_printf(Perl_debug_log, "[%"UVuf"]", (UV)o->op_targ);
	}
        break;
    default:
	break;
    }
    PerlIO_printf(Perl_debug_log, "\n");
    return 0;
}

STATIC CV*
S_deb_curcv(pTHX_ const I32 ix)
{
    const PERL_CONTEXT * const cx = &cxstack[ix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)
        return cx->blk_sub.cv;
    else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx))
        return PL_compcv;
    else if (ix == 0 && PL_curstackinfo->si_type == PERLSI_MAIN)
        return PL_main_cv;
    else if (ix <= 0)
        return Nullcv;
    else
        return deb_curcv(ix - 1);
}

void
Perl_watch(pTHX_ char **addr)
{
    PL_watchaddr = addr;
    PL_watchok = *addr;
    PerlIO_printf(Perl_debug_log, "WATCHING, %"UVxf" is currently %"UVxf"\n",
	PTR2UV(PL_watchaddr), PTR2UV(PL_watchok));
}

STATIC void
S_debprof(pTHX_ const OP *o)
{
    if (!DEBUG_J_TEST_ && CopSTASH_eq(PL_curcop, PL_debstash))
	return;
    if (!PL_profiledata)
	Newxz(PL_profiledata, MAXO, U32);
    ++PL_profiledata[o->op_type];
}

void
Perl_debprofdump(pTHX)
{
    unsigned i;
    if (!PL_profiledata)
	return;
    for (i = 0; i < MAXO; i++) {
	if (PL_profiledata[i])
	    PerlIO_printf(Perl_debug_log,
			  "%5lu %s\n", (unsigned long)PL_profiledata[i],
                                       PL_op_name[i]);
    }
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
