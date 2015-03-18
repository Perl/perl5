/*    inline.h
 *
 *    Copyright (C) 2012 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * This file is a home for static inline functions that cannot go in other
 * headers files, because they depend on proto.h (included after most other
 * headers) or struct definitions.
 *
 * Each section names the header file that the functions "belong" to.
 */

/* ------------------------------- av.h ------------------------------- */

PERL_STATIC_INLINE SSize_t
S_av_top_index(pTHX_ AV *av)
{
    PERL_ARGS_ASSERT_AV_TOP_INDEX;
    assert(SvTYPE(av) == SVt_PVAV);

    return AvFILL(av);
}

/* ------------------------------- cv.h ------------------------------- */

PERL_STATIC_INLINE GV *
S_CvGV(pTHX_ CV *sv)
{
    return CvNAMED(sv)
	? Perl_cvgv_from_hek(aTHX_ sv)
	: ((XPVCV*)MUTABLE_PTR(SvANY(sv)))->xcv_gv_u.xcv_gv;
}

PERL_STATIC_INLINE I32 *
S_CvDEPTHp(const CV * const sv)
{
    assert(SvTYPE(sv) == SVt_PVCV || SvTYPE(sv) == SVt_PVFM);
    return &((XPVCV*)SvANY(sv))->xcv_depth;
}

/*
 CvPROTO returns the prototype as stored, which is not necessarily what
 the interpreter should be using. Specifically, the interpreter assumes
 that spaces have been stripped, which has been the case if the prototype
 was added by toke.c, but is generally not the case if it was added elsewhere.
 Since we can't enforce the spacelessness at assignment time, this routine
 provides a temporary copy at parse time with spaces removed.
 I<orig> is the start of the original buffer, I<len> is the length of the
 prototype and will be updated when this returns.
 */

#ifdef PERL_CORE
PERL_STATIC_INLINE char *
S_strip_spaces(pTHX_ const char * orig, STRLEN * const len)
{
    SV * tmpsv;
    char * tmps;
    tmpsv = newSVpvn_flags(orig, *len, SVs_TEMP);
    tmps = SvPVX(tmpsv);
    while ((*len)--) {
	if (!isSPACE(*orig))
	    *tmps++ = *orig;
	orig++;
    }
    *tmps = '\0';
    *len = tmps - SvPVX(tmpsv);
		return SvPVX(tmpsv);
}
#endif

/* ------------------------------- mg.h ------------------------------- */

#if defined(PERL_CORE) || defined(PERL_EXT)
/* assumes get-magic and stringification have already occurred */
PERL_STATIC_INLINE STRLEN
S_MgBYTEPOS(pTHX_ MAGIC *mg, SV *sv, const char *s, STRLEN len)
{
    assert(mg->mg_type == PERL_MAGIC_regex_global);
    assert(mg->mg_len != -1);
    if (mg->mg_flags & MGf_BYTES || !DO_UTF8(sv))
	return (STRLEN)mg->mg_len;
    else {
	const STRLEN pos = (STRLEN)mg->mg_len;
	/* Without this check, we may read past the end of the buffer: */
	if (pos > sv_or_pv_len_utf8(sv, s, len)) return len+1;
	return sv_or_pv_pos_u2b(sv, s, pos, NULL);
    }
}
#endif

/* ------------------------------- pad.h ------------------------------ */

#if defined(PERL_IN_PAD_C) || defined(PERL_IN_OP_C)
PERL_STATIC_INLINE bool
PadnameIN_SCOPE(const PADNAME * const pn, const U32 seq)
{
    /* is seq within the range _LOW to _HIGH ?
     * This is complicated by the fact that PL_cop_seqmax
     * may have wrapped around at some point */
    if (COP_SEQ_RANGE_LOW(pn) == PERL_PADSEQ_INTRO)
	return FALSE; /* not yet introduced */

    if (COP_SEQ_RANGE_HIGH(pn) == PERL_PADSEQ_INTRO) {
    /* in compiling scope */
	if (
	    (seq >  COP_SEQ_RANGE_LOW(pn))
	    ? (seq - COP_SEQ_RANGE_LOW(pn) < (U32_MAX >> 1))
	    : (COP_SEQ_RANGE_LOW(pn) - seq > (U32_MAX >> 1))
	)
	    return TRUE;
    }
    else if (
	(COP_SEQ_RANGE_LOW(pn) > COP_SEQ_RANGE_HIGH(pn))
	?
	    (  seq >  COP_SEQ_RANGE_LOW(pn)
	    || seq <= COP_SEQ_RANGE_HIGH(pn))

	:    (  seq >  COP_SEQ_RANGE_LOW(pn)
	     && seq <= COP_SEQ_RANGE_HIGH(pn))
    )
	return TRUE;
    return FALSE;
}
#endif

/* ----------------------------- regexp.h ----------------------------- */

PERL_STATIC_INLINE struct regexp *
S_ReANY(const REGEXP * const re)
{
    assert(isREGEXP(re));
    return re->sv_u.svu_rx;
}

/* ------------------------------- sv.h ------------------------------- */

PERL_STATIC_INLINE SV *
S_SvREFCNT_inc(SV *sv)
{
    if (LIKELY(sv != NULL))
	SvREFCNT(sv)++;
    return sv;
}
PERL_STATIC_INLINE SV *
S_SvREFCNT_inc_NN(SV *sv)
{
    SvREFCNT(sv)++;
    return sv;
}
PERL_STATIC_INLINE void
S_SvREFCNT_inc_void(SV *sv)
{
    if (LIKELY(sv != NULL))
	SvREFCNT(sv)++;
}
PERL_STATIC_INLINE void
S_SvREFCNT_dec(pTHX_ SV *sv)
{
    if (LIKELY(sv != NULL)) {
	U32 rc = SvREFCNT(sv);
	if (LIKELY(rc > 1))
	    SvREFCNT(sv) = rc - 1;
	else
	    Perl_sv_free2(aTHX_ sv, rc);
    }
}

PERL_STATIC_INLINE void
S_SvREFCNT_dec_NN(pTHX_ SV *sv)
{
    U32 rc = SvREFCNT(sv);
    if (LIKELY(rc > 1))
	SvREFCNT(sv) = rc - 1;
    else
	Perl_sv_free2(aTHX_ sv, rc);
}

PERL_STATIC_INLINE void
SvAMAGIC_on(SV *sv)
{
    assert(SvROK(sv));
    if (SvOBJECT(SvRV(sv))) HvAMAGIC_on(SvSTASH(SvRV(sv)));
}
PERL_STATIC_INLINE void
SvAMAGIC_off(SV *sv)
{
    if (SvROK(sv) && SvOBJECT(SvRV(sv)))
	HvAMAGIC_off(SvSTASH(SvRV(sv)));
}

PERL_STATIC_INLINE U32
S_SvPADSTALE_on(SV *sv)
{
    assert(!(SvFLAGS(sv) & SVs_PADTMP));
    return SvFLAGS(sv) |= SVs_PADSTALE;
}
PERL_STATIC_INLINE U32
S_SvPADSTALE_off(SV *sv)
{
    assert(!(SvFLAGS(sv) & SVs_PADTMP));
    return SvFLAGS(sv) &= ~SVs_PADSTALE;
}
#if defined(PERL_CORE) || defined (PERL_EXT)
PERL_STATIC_INLINE STRLEN
S_sv_or_pv_pos_u2b(pTHX_ SV *sv, const char *pv, STRLEN pos, STRLEN *lenp)
{
    PERL_ARGS_ASSERT_SV_OR_PV_POS_U2B;
    if (SvGAMAGIC(sv)) {
	U8 *hopped = utf8_hop((U8 *)pv, pos);
	if (lenp) *lenp = (STRLEN)(utf8_hop(hopped, *lenp) - hopped);
	return (STRLEN)(hopped - (U8 *)pv);
    }
    return sv_pos_u2b_flags(sv,pos,lenp,SV_CONST_RETURN);
}
#endif

/* ------------------------------- handy.h ------------------------------- */

/* saves machine code for a common noreturn idiom typically used in Newx*() */
#ifdef GCC_DIAG_PRAGMA
GCC_DIAG_IGNORE(-Wunused-function) /* Intentionally left semicolonless. */
#endif
static void
S_croak_memory_wrap(void)
{
    Perl_croak_nocontext("%s",PL_memory_wrap);
}
#ifdef GCC_DIAG_PRAGMA
GCC_DIAG_RESTORE /* Intentionally left semicolonless. */
#endif

/* ------------------------------- utf8.h ------------------------------- */

PERL_STATIC_INLINE void
S_append_utf8_from_native_byte(const U8 byte, U8** dest)
{
    /* Takes an input 'byte' (Latin1 or EBCDIC) and appends it to the UTF-8
     * encoded string at '*dest', updating '*dest' to include it */

    PERL_ARGS_ASSERT_APPEND_UTF8_FROM_NATIVE_BYTE;

    if (NATIVE_BYTE_IS_INVARIANT(byte))
        *(*dest)++ = byte;
    else {
        *(*dest)++ = UTF8_EIGHT_BIT_HI(byte);
        *(*dest)++ = UTF8_EIGHT_BIT_LO(byte);
    }
}

/*

A helper function for the macro isUTF8_CHAR(), which should be used instead of
this function.  The macro will handle smaller code points directly saving time,
using this function as a fall-back for higher code points.

Tests if the first bytes of string C<s> form a valid UTF-8 character.  0 is
returned if the bytes starting at C<s> up to but not including C<e> do not form a
complete well-formed UTF-8 character; otherwise the number of bytes in the
character is returned.

Note that an INVARIANT (i.e. ASCII on non-EBCDIC) character is a valid UTF-8
character.

=cut */
PERL_STATIC_INLINE STRLEN
S__is_utf8_char_slow(const U8 *s, const U8 *e)
{
    dTHX;   /* The function called below requires thread context */

    STRLEN actual_len;

    PERL_ARGS_ASSERT__IS_UTF8_CHAR_SLOW;

    assert(e >= s);
    utf8n_to_uvchr(s, e - s, &actual_len, UTF8_CHECK_ONLY);

    return (actual_len == (STRLEN) -1) ? 0 : actual_len;
}

/* ------------------------------- perl.h ----------------------------- */

/*
=head1 Miscellaneous Functions

=for apidoc AiR|bool|is_safe_syscall|const char *pv|STRLEN len|const char *what|const char *op_name

Test that the given C<pv> doesn't contain any internal C<NUL> characters.
If it does, set C<errno> to ENOENT, optionally warn, and return FALSE.

Return TRUE if the name is safe.

Used by the IS_SAFE_SYSCALL() macro.

=cut
*/

PERL_STATIC_INLINE bool
S_is_safe_syscall(pTHX_ const char *pv, STRLEN len, const char *what, const char *op_name) {
    /* While the Windows CE API provides only UCS-16 (or UTF-16) APIs
     * perl itself uses xce*() functions which accept 8-bit strings.
     */

    PERL_ARGS_ASSERT_IS_SAFE_SYSCALL;

    if (len > 1) {
        char *null_at;
        if (UNLIKELY((null_at = (char *)memchr(pv, 0, len-1)) != NULL)) {
                SETERRNO(ENOENT, LIB_INVARG);
                Perl_ck_warner(aTHX_ packWARN(WARN_SYSCALLS),
                                   "Invalid \\0 character in %s for %s: %s\\0%s",
                                   what, op_name, pv, null_at+1);
                return FALSE;
        }
    }

    return TRUE;
}

/*

Return true if the supplied filename has a newline character
immediately before the final NUL.

My original look at this incorrectly used the len from SvPV(), but
that's incorrect, since we allow for a NUL in pv[len-1].

So instead, strlen() and work from there.

This allow for the user reading a filename, forgetting to chomp it,
then calling:

  open my $foo, "$file\0";

*/

#ifdef PERL_CORE

PERL_STATIC_INLINE bool
S_should_warn_nl(const char *pv) {
    STRLEN len;

    PERL_ARGS_ASSERT_SHOULD_WARN_NL;

    len = strlen(pv);

    return len > 0 && pv[len-1] == '\n';
}

#endif

/* ------------------ pp.c, regcomp.c, toke.c, universal.c ------------ */

#define MAX_CHARSET_NAME_LENGTH 2

PERL_STATIC_INLINE const char *
get_regex_charset_name(const U32 flags, STRLEN* const lenp)
{
    /* Returns a string that corresponds to the name of the regex character set
     * given by 'flags', and *lenp is set the length of that string, which
     * cannot exceed MAX_CHARSET_NAME_LENGTH characters */

    *lenp = 1;
    switch (get_regex_charset(flags)) {
        case REGEX_DEPENDS_CHARSET: return DEPENDS_PAT_MODS;
        case REGEX_LOCALE_CHARSET:  return LOCALE_PAT_MODS;
        case REGEX_UNICODE_CHARSET: return UNICODE_PAT_MODS;
	case REGEX_ASCII_RESTRICTED_CHARSET: return ASCII_RESTRICT_PAT_MODS;
	case REGEX_ASCII_MORE_RESTRICTED_CHARSET:
	    *lenp = 2;
	    return ASCII_MORE_RESTRICT_PAT_MODS;
    }
    /* The NOT_REACHED; hides an assert() which has a rather complex
     * definition in perl.h. */
    NOT_REACHED; /* NOTREACHED */
    return "?";	    /* Unknown */
}

/*

Return false if any get magic is on the SV other than taint magic.

*/

PERL_STATIC_INLINE bool
S_sv_only_taint_gmagic(SV *sv) {
    MAGIC *mg = SvMAGIC(sv);

    PERL_ARGS_ASSERT_SV_ONLY_TAINT_GMAGIC;

    while (mg) {
        if (mg->mg_type != PERL_MAGIC_taint
            && !(mg->mg_flags & MGf_GSKIP)
            && mg->mg_virtual->svt_get) {
            return FALSE;
        }
        mg = mg->mg_moremagic;
    }

    return TRUE;
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
