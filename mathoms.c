/*    mathoms.c
 *
 *    Copyright (C) 2005, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "Anything that Hobbits had no immediate use for, but were unwilling to 
 * throw away, they called a mathom. Their dwellings were apt to become
 * rather crowded with mathoms, and many of the presents that passed from
 * hand to hand were of that sort." 
 */

/* 
 * This file contains mathoms, various binary artifacts from previous
 * versions of Perl.  For binary or source compatibility reasons, though,
 * we cannot completely remove them from the core code.  
 *
 * SMP - Oct. 24, 2005
 *
 */

#include "EXTERN.h"
#define PERL_IN_MATHOMS_C
#include "perl.h"

/* ref() is now a macro using Perl_doref;
 * this version provided for binary compatibility only.
 */
OP *
Perl_ref(pTHX_ OP *o, I32 type)
{
    return doref(o, type, TRUE);
}

/* sv_2iv() is now a macro using Perl_sv_2iv_flags();
 * this function provided for binary compatibility only
 */

IV
Perl_sv_2iv(pTHX_ register SV *sv)
{
    return sv_2iv_flags(sv, SV_GMAGIC);
}

/* sv_2uv() is now a macro using Perl_sv_2uv_flags();
 * this function provided for binary compatibility only
 */

UV
Perl_sv_2uv(pTHX_ register SV *sv)
{
    return sv_2uv_flags(sv, SV_GMAGIC);
}

/* sv_2pv() is now a macro using Perl_sv_2pv_flags();
 * this function provided for binary compatibility only
 */

char *
Perl_sv_2pv(pTHX_ register SV *sv, STRLEN *lp)
{
    return sv_2pv_flags(sv, lp, SV_GMAGIC);
}


/* sv_setsv() is now a macro using Perl_sv_setsv_flags();
 * this function provided for binary compatibility only
 */

void
Perl_sv_setsv(pTHX_ SV *dstr, register SV *sstr)
{
    sv_setsv_flags(dstr, sstr, SV_GMAGIC);
}

/* sv_catpvn() is now a macro using Perl_sv_catpvn_flags();
 * this function provided for binary compatibility only
 */

void
Perl_sv_catpvn(pTHX_ SV *dsv, const char* sstr, STRLEN slen)
{
    sv_catpvn_flags(dsv, sstr, slen, SV_GMAGIC);
}

/* sv_catsv() is now a macro using Perl_sv_catsv_flags();
 * this function provided for binary compatibility only
 */

void
Perl_sv_catsv(pTHX_ SV *dstr, register SV *sstr)
{
    sv_catsv_flags(dstr, sstr, SV_GMAGIC);
}

/* sv_pv() is now a macro using SvPV_nolen();
 * this function provided for binary compatibility only
 */

char *
Perl_sv_pv(pTHX_ SV *sv)
{
    if (SvPOK(sv))
        return SvPVX(sv);

    return sv_2pv(sv, 0);
}

/* sv_pvn_force() is now a macro using Perl_sv_pvn_force_flags();
 * this function provided for binary compatibility only
 */

char *
Perl_sv_pvn_force(pTHX_ SV *sv, STRLEN *lp)
{
    return sv_pvn_force_flags(sv, lp, SV_GMAGIC);
}

/* sv_pvbyte () is now a macro using Perl_sv_2pv_flags();
 * this function provided for binary compatibility only
 */

char *
Perl_sv_pvbyte(pTHX_ SV *sv)
{
    sv_utf8_downgrade(sv,0);
    return sv_pv(sv);
}

/* sv_pvutf8 () is now a macro using Perl_sv_2pv_flags();
 * this function provided for binary compatibility only
 */

char *
Perl_sv_pvutf8(pTHX_ SV *sv)
{
    sv_utf8_upgrade(sv);
    return sv_pv(sv);
}

/*
=for apidoc A|U8 *|uvchr_to_utf8|U8 *d|UV uv

Adds the UTF-8 representation of the Native codepoint C<uv> to the end
of the string C<d>; C<d> should be have at least C<UTF8_MAXBYTES+1> free
bytes available. The return value is the pointer to the byte after the
end of the new character. In other words,

    d = uvchr_to_utf8(d, uv);

is the recommended wide native character-aware way of saying

    *(d++) = uv;

=cut
*/

/* On ASCII machines this is normally a macro but we want a
   real function in case XS code wants it
*/
#undef Perl_uvchr_to_utf8
U8 *
Perl_uvchr_to_utf8(pTHX_ U8 *d, UV uv)
{
    return Perl_uvuni_to_utf8_flags(aTHX_ d, NATIVE_TO_UNI(uv), 0);
}


/*
=for apidoc A|UV|utf8n_to_uvchr|U8 *s|STRLEN curlen|STRLEN *retlen|U32 
flags

Returns the native character value of the first character in the string 
C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

Allows length and flags to be passed to low level routine.

=cut
*/
/* On ASCII machines this is normally a macro but we want
   a real function in case XS code wants it
*/
#undef Perl_utf8n_to_uvchr
UV
Perl_utf8n_to_uvchr(pTHX_ const U8 *s, STRLEN curlen, STRLEN *retlen, 
U32 flags)
{
    const UV uv = Perl_utf8n_to_uvuni(aTHX_ s, curlen, retlen, flags);
    return UNI_TO_NATIVE(uv);
}
int
Perl_fprintf_nocontext(PerlIO *stream, const char *format, ...)
{
    dTHXs;
    va_list(arglist);
    va_start(arglist, format);
    return PerlIO_vprintf(stream, format, arglist);
}

int
Perl_printf_nocontext(const char *format, ...)
{
    dTHX;
    va_list(arglist);
    va_start(arglist, format);
    return PerlIO_vprintf(PerlIO_stdout(), format, arglist);
}

#if defined(HUGE_VAL) || (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL))
/*
 * This hack is to force load of "huge" support from libm.a
 * So it is in perl for (say) POSIX to use.
 * Needed for SunOS with Sun's 'acc' for example.
 */
NV
Perl_huge(void)
{
#   if defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)
    return HUGE_VALL;
#   endif
    return HUGE_VAL;
}
#endif

#ifndef USE_SFIO
int
perlsio_binmode(FILE *fp, int iotype, int mode)
{
    /*
     * This used to be contents of do_binmode in doio.c
     */
#ifdef DOSISH
#  if defined(atarist) || defined(__MINT__)
    if (!fflush(fp)) {
        if (mode & O_BINARY)
            ((FILE *) fp)->_flag |= _IOBIN;
        else
            ((FILE *) fp)->_flag &= ~_IOBIN;
        return 1;
    }
    return 0;
#  else
    dTHX;
#ifdef NETWARE
    if (PerlLIO_setmode(fp, mode) != -1) {
#else
    if (PerlLIO_setmode(fileno(fp), mode) != -1) {
#endif
#    if defined(WIN32) && defined(__BORLANDC__)
        /*
         * The translation mode of the stream is maintained independent 
of
         * the translation mode of the fd in the Borland RTL (heavy
         * digging through their runtime sources reveal).  User has to 
set
         * the mode explicitly for the stream (though they don't 
document
         * this anywhere). GSAR 97-5-24
         */
        fseek(fp, 0L, 0);
        if (mode & O_BINARY)
            fp->flags |= _F_BIN;
        else
            fp->flags &= ~_F_BIN;
#    endif
        return 1;
    }
    else
        return 0;
#  endif
#else
#  if defined(USEMYBINMODE)
    dTHX;
    if (my_binmode(fp, iotype, mode) != FALSE)
        return 1;
    else
        return 0;
#  else
    PERL_UNUSED_ARG(fp);
    PERL_UNUSED_ARG(iotype);
    PERL_UNUSED_ARG(mode);
    return 1;
#  endif
#endif
}
#endif /* sfio */

/* compatibility with versions <= 5.003. */
void
Perl_gv_fullname(pTHX_ SV *sv, const GV *gv)
{
    gv_fullname3(sv, gv, sv == (const SV*)gv ? "*" : "");
}

/* compatibility with versions <= 5.003. */
void
Perl_gv_efullname(pTHX_ SV *sv, const GV *gv)
{
    gv_efullname3(sv, gv, sv == (const SV*)gv ? "*" : "");
}

void
Perl_gv_fullname3(pTHX_ SV *sv, const GV *gv, const char *prefix)
{
    gv_fullname4(sv, gv, prefix, TRUE);
}

void
Perl_gv_efullname3(pTHX_ SV *sv, const GV *gv, const char *prefix)
{
    gv_efullname4(sv, gv, prefix, TRUE);
}

AV *
Perl_av_fake(pTHX_ register I32 size, register SV **strp)
{
    register SV** ary;
    register AV * const av = (AV*)NEWSV(9,0);

    sv_upgrade((SV *)av, SVt_PVAV);
    Newx(ary,size+1,SV*);
    AvALLOC(av) = ary;
    Copy(strp,ary,size,SV*);
    AvREIFY_only(av);
    SvPV_set(av, (char*)ary);
    AvFILLp(av) = size - 1;
    AvMAX(av) = size - 1;
    while (size--) {
        assert (*strp);
        SvTEMP_off(*strp);
        strp++;
    }
    return av;
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
