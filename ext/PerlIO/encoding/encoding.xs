/*
 * $Id$
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define U8 U8

#if defined(USE_PERLIO) && !defined(USE_SFIO)

/* Define an encoding "layer" in the perliol.h sense.

   The layer defined here "inherits" in an object-oriented sense from
   the "perlio" layer with its PerlIOBuf_* "methods".  The
   implementation is particularly efficient as until Encode settles
   down there is no point in tryint to tune it.

   The layer works by overloading the "fill" and "flush" methods.

   "fill" calls "SUPER::fill" in perl terms, then calls the encode OO
   perl API to convert the encoded data to UTF-8 form, then copies it
   back to the buffer. The "base class's" read methods then see the
   UTF-8 data.

   "flush" transforms the UTF-8 data deposited by the "base class's
   write method in the buffer back into the encoded form using the
   encode OO perl API, then copies data back into the buffer and calls
   "SUPER::flush.

   Note that "flush" is _also_ called for read mode - we still do the
   (back)-translate so that the the base class's "flush" sees the
   correct number of encoded chars for positioning the seek
   pointer. (This double translation is the worst performance issue -
   particularly with all-perl encode engine.)

*/

#include "perliol.h"

typedef struct {
    PerlIOBuf base;		/* PerlIOBuf stuff */
    SV *bufsv;			/* buffer seen by layers above */
    SV *dataSV;			/* data we have read from layer below */
    SV *enc;			/* the encoding object */
    SV *chk;                    /* CHECK in Encode methods */
} PerlIOEncode;


#define ENCODE_FB_QUIET "Encode::FB_QUIET"


SV *
PerlIOEncode_getarg(pTHX_ PerlIO * f, CLONE_PARAMS * param, int flags)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    SV *sv = &PL_sv_undef;
    if (e->enc) {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(e->enc);
	PUTBACK;
	if (call_method("name", G_SCALAR) == 1) {
	    SPAGAIN;
	    sv = newSVsv(POPs);
	    PUTBACK;
	}
    }
    return sv;
}

IV
PerlIOEncode_pushed(pTHX_ PerlIO * f, const char *mode, SV * arg)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    dSP;
    IV code;
    code = PerlIOBuf_pushed(aTHX_ f, mode, Nullsv);
    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    PUTBACK;
    if (call_pv(ENCODE_FB_QUIET, G_SCALAR|G_NOARGS) != 1) {
	Perl_die(aTHX_ "Call to Encode::FB_QUIET failed!");
	code = -1;
    }
    SPAGAIN;
    e->chk = newSVsv(POPs);
    PUTBACK;

    PUSHMARK(sp);
    XPUSHs(arg);
    PUTBACK;
    if (call_pv("Encode::find_encoding", G_SCALAR) != 1) {
	/* should never happen */
	Perl_die(aTHX_ "Encode::find_encoding did not return a value");
	return -1;
    }
    SPAGAIN;
    e->enc = POPs;
    PUTBACK;

    if (!SvROK(e->enc)) {
	e->enc = Nullsv;
	errno = EINVAL;
	Perl_warner(aTHX_ packWARN(WARN_IO), "Cannot find encoding \"%" SVf "\"",
		    arg); 
	code = -1;
    }
    else {
	SvREFCNT_inc(e->enc);
	PerlIOBase(f)->flags |= PERLIO_F_UTF8;
    }
    FREETMPS;
    LEAVE;
    return code;
}

IV
PerlIOEncode_popped(pTHX_ PerlIO * f)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    if (e->enc) {
	SvREFCNT_dec(e->enc);
	e->enc = Nullsv;
    }
    if (e->bufsv) {
	SvREFCNT_dec(e->bufsv);
	e->bufsv = Nullsv;
    }
    if (e->dataSV) {
	SvREFCNT_dec(e->dataSV);
	e->dataSV = Nullsv;
    }
    return 0;
}

STDCHAR *
PerlIOEncode_get_base(pTHX_ PerlIO * f)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    if (!e->base.bufsiz)
	e->base.bufsiz = 1024;
    if (!e->bufsv) {
	e->bufsv = newSV(e->base.bufsiz);
	sv_setpvn(e->bufsv, "", 0);
    }
    e->base.buf = (STDCHAR *) SvPVX(e->bufsv);
    if (!e->base.ptr)
	e->base.ptr = e->base.buf;
    if (!e->base.end)
	e->base.end = e->base.buf;
    if (e->base.ptr < e->base.buf
	|| e->base.ptr > e->base.buf + SvLEN(e->bufsv)) {
	Perl_warn(aTHX_ " ptr %p(%p)%p", e->base.buf, e->base.ptr,
		  e->base.buf + SvLEN(e->bufsv));
	abort();
    }
    if (SvLEN(e->bufsv) < e->base.bufsiz) {
	SSize_t poff = e->base.ptr - e->base.buf;
	SSize_t eoff = e->base.end - e->base.buf;
	e->base.buf = (STDCHAR *) SvGROW(e->bufsv, e->base.bufsiz);
	e->base.ptr = e->base.buf + poff;
	e->base.end = e->base.buf + eoff;
    }
    if (e->base.ptr < e->base.buf
	|| e->base.ptr > e->base.buf + SvLEN(e->bufsv)) {
	Perl_warn(aTHX_ " ptr %p(%p)%p", e->base.buf, e->base.ptr,
		  e->base.buf + SvLEN(e->bufsv));
	abort();
    }
    return e->base.buf;
}

IV
PerlIOEncode_fill(pTHX_ PerlIO * f)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    dSP;
    IV code = 0;
    PerlIO *n;
    SSize_t avail;
    if (PerlIO_flush(f) != 0)
	return -1;
    n  = PerlIONext(f);
    if (!PerlIO_fast_gets(n)) {
	/* Things get too messy if we don't have a buffer layer
	   push a :perlio to do the job */
	char mode[8];
	n  = PerlIO_push(aTHX_ n, &PerlIO_perlio, PerlIO_modestr(f,mode), Nullsv);
	if (!n) {
	    Perl_die(aTHX_ "panic: cannot push :perlio for %p",f);
	}
    }
    ENTER;
    SAVETMPS;
  retry:
    avail = PerlIO_get_cnt(n);
    if (avail <= 0) {
	avail = PerlIO_fill(n);
	if (avail == 0) {
	    avail = PerlIO_get_cnt(n);
	}
	else {
	    if (!PerlIO_error(n) && PerlIO_eof(n))
		avail = 0;
	}
    }
    if (avail > 0) {
	STDCHAR *ptr = PerlIO_get_ptr(n);
	SSize_t use  = avail;
	SV *uni;
	char *s;
	STRLEN len = 0;
	e->base.ptr = e->base.end = (STDCHAR *) Nullch;
	(void) PerlIOEncode_get_base(aTHX_ f);
	if (!e->dataSV)
	    e->dataSV = newSV(0);
	if (SvTYPE(e->dataSV) < SVt_PV) {
	    sv_upgrade(e->dataSV,SVt_PV);
	}
	if (SvCUR(e->dataSV)) {
	    /* something left over from last time - create a normal
	       SV with new data appended
	     */
	    if (use + SvCUR(e->dataSV) > e->base.bufsiz) {
	       use = e->base.bufsiz - SvCUR(e->dataSV);
	    }
	    sv_catpvn(e->dataSV,(char*)ptr,use);
	}
	else {
	    /* Create a "dummy" SV to represent the available data from layer below */
	    if (SvLEN(e->dataSV) && SvPVX(e->dataSV)) {
		Safefree(SvPVX(e->dataSV));
	    }
	    if (use > (SSize_t)e->base.bufsiz) {
	       use = e->base.bufsiz;
	    }
	    SvPVX(e->dataSV) = (char *) ptr;
	    SvLEN(e->dataSV) = 0;  /* Hands off sv.c - it isn't yours */
	    SvCUR_set(e->dataSV,use);
	    SvPOK_only(e->dataSV);
	}
	SvUTF8_off(e->dataSV);
	PUSHMARK(sp);
	XPUSHs(e->enc);
	XPUSHs(e->dataSV);
	XPUSHs(e->chk);
	PUTBACK;
	if (call_method("decode", G_SCALAR) != 1) {
	    Perl_die(aTHX_ "panic: decode did not return a value");
	}
	SPAGAIN;
	uni = POPs;
	PUTBACK;
	/* Now get translated string (forced to UTF-8) and use as buffer */
	if (SvPOK(uni)) {
	    s = SvPVutf8(uni, len);
#ifdef PARANOID_ENCODE_CHECKS
	    if (len && !is_utf8_string((U8*)s,len)) {
		Perl_warn(aTHX_ "panic: decode did not return UTF-8 '%.*s'",(int) len,s);
	    }
#endif
	}
	if (len > 0) {
	    /* Got _something */
	    /* if decode gave us back dataSV then data may vanish when
	       we do ptrcnt adjust - so take our copy now.
	       (The copy is a pain - need a put-it-here option for decode.)
	     */
	    sv_setpvn(e->bufsv,s,len);
	    e->base.ptr = e->base.buf = (STDCHAR*)SvPVX(e->bufsv);
	    e->base.end = e->base.ptr + SvCUR(e->bufsv);
	    PerlIOBase(f)->flags |= PERLIO_F_RDBUF;
	    SvUTF8_on(e->bufsv);

	    /* Adjust ptr/cnt not taking anything which
	       did not translate - not clear this is a win */
	    /* compute amount we took */
	    use -= SvCUR(e->dataSV);
	    PerlIO_set_ptrcnt(n, ptr+use, (avail-use));
	    /* and as we did not take it it isn't pending */
	    SvCUR_set(e->dataSV,0);
	} else {
	    /* Got nothing - assume partial character so we need some more */
	    /* Make sure e->dataSV is a normal SV before re-filling as
	       buffer alias will change under us
	     */
	    s = SvPV(e->dataSV,len);
	    sv_setpvn(e->dataSV,s,len);
	    PerlIO_set_ptrcnt(n, ptr+use, (avail-use));
	    goto retry;
	}
	FREETMPS;
	LEAVE;
	return code;
    }
    else {
	if (avail == 0)
	    PerlIOBase(f)->flags |= PERLIO_F_EOF;
	else
	    PerlIOBase(f)->flags |= PERLIO_F_ERROR;
	return -1;
    }
}

IV
PerlIOEncode_flush(pTHX_ PerlIO * f)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    IV code = 0;
    if (e->bufsv && (e->base.ptr > e->base.buf)) {
	dSP;
	SV *str;
	char *s;
	STRLEN len;
	SSize_t count = 0;
	if (PerlIOBase(f)->flags & PERLIO_F_WRBUF) {
	    /* Write case encode the buffer and write() to layer below */
	    ENTER;
	    SAVETMPS;
	    PUSHMARK(sp);
	    XPUSHs(e->enc);
	    SvCUR_set(e->bufsv, e->base.ptr - e->base.buf);
	    SvUTF8_on(e->bufsv);
	    XPUSHs(e->bufsv);
	    XPUSHs(e->chk);
	    PUTBACK;
	    if (call_method("encode", G_SCALAR) != 1) {
		Perl_die(aTHX_ "panic: encode did not return a value");
	    }
	    SPAGAIN;
	    str = POPs;
	    PUTBACK;
	    s = SvPV(str, len);
	    count = PerlIO_write(PerlIONext(f),s,len);
	    if (count != len) {
		code = -1;
	    }
	    FREETMPS;
	    LEAVE;
	    if (PerlIO_flush(PerlIONext(f)) != 0) {
		code = -1;
	    }
	    if (SvCUR(e->bufsv)) {
		/* Did not all translate */
		e->base.ptr = e->base.buf+SvCUR(e->bufsv);
		return code;
	    }
	}
	else if (PerlIOBase(f)->flags & PERLIO_F_RDBUF) {
	    /* read case */
	    /* if we have any untranslated stuff then unread that first */
	    if (e->dataSV && SvCUR(e->dataSV)) {
		s = SvPV(e->dataSV, len);
		count = PerlIO_unread(PerlIONext(f),s,len);
		if (count != len) {
		    code = -1;
		}
	    }
	    /* See if there is anything left in the buffer */
	    if (e->base.ptr < e->base.end) {
		/* Bother - have unread data.
		   re-encode and unread() to layer below
		 */
		ENTER;
		SAVETMPS;
		str = sv_newmortal();
		sv_upgrade(str, SVt_PV);
		SvPVX(str) = (char*)e->base.ptr;
		SvLEN(str) = 0;
		SvCUR_set(str, e->base.end - e->base.ptr);
		SvPOK_only(str);
		SvUTF8_on(str);
		PUSHMARK(sp);
		XPUSHs(e->enc);
		XPUSHs(str);
		XPUSHs(e->chk);
		PUTBACK;
		if (call_method("encode", G_SCALAR) != 1) {
		     Perl_die(aTHX_ "panic: encode did not return a value");
		}
		SPAGAIN;
		str = POPs;
		PUTBACK;
		s = SvPV(str, len);
		count = PerlIO_unread(PerlIONext(f),s,len);
		if (count != len) {
		    code = -1;
		}
		FREETMPS;
		LEAVE;
	    }
	}
	e->base.ptr = e->base.end = e->base.buf;
	PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF | PERLIO_F_WRBUF);
    }
    return code;
}

IV
PerlIOEncode_close(pTHX_ PerlIO * f)
{
    PerlIOEncode *e = PerlIOSelf(f, PerlIOEncode);
    IV code = PerlIOBase_close(aTHX_ f);
    if (e->bufsv) {
	if (e->base.buf && e->base.ptr > e->base.buf) {
	    Perl_croak(aTHX_ "Close with partial character");
	}
	SvREFCNT_dec(e->bufsv);
	e->bufsv = Nullsv;
    }
    e->base.buf = NULL;
    e->base.ptr = NULL;
    e->base.end = NULL;
    PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF | PERLIO_F_WRBUF);
    return code;
}

Off_t
PerlIOEncode_tell(pTHX_ PerlIO * f)
{
    PerlIOBuf *b = PerlIOSelf(f, PerlIOBuf);
    /* Unfortunately the only way to get a postion is to (re-)translate,
       the UTF8 we have in bufefr and then ask layer below
     */
    PerlIO_flush(f);
    if (b->buf && b->ptr > b->buf) {
	Perl_croak(aTHX_ "Cannot tell at partial character");
    }
    return PerlIO_tell(PerlIONext(f));
}

PerlIO *
PerlIOEncode_dup(pTHX_ PerlIO * f, PerlIO * o,
		 CLONE_PARAMS * params, int flags)
{
    if ((f = PerlIOBase_dup(aTHX_ f, o, params, flags))) {
	PerlIOEncode *fe = PerlIOSelf(f, PerlIOEncode);
	PerlIOEncode *oe = PerlIOSelf(o, PerlIOEncode);
	if (oe->enc) {
	    fe->enc = PerlIO_sv_dup(aTHX_ oe->enc, params);
	}
    }
    return f;
}

PerlIO_funcs PerlIO_encode = {
    "encoding",
    sizeof(PerlIOEncode),
    PERLIO_K_BUFFERED|PERLIO_K_DESTRUCT,
    PerlIOEncode_pushed,
    PerlIOEncode_popped,
    PerlIOBuf_open,
    PerlIOEncode_getarg,
    PerlIOBase_fileno,
    PerlIOEncode_dup,
    PerlIOBuf_read,
    PerlIOBuf_unread,
    PerlIOBuf_write,
    PerlIOBuf_seek,
    PerlIOEncode_tell,
    PerlIOEncode_close,
    PerlIOEncode_flush,
    PerlIOEncode_fill,
    PerlIOBase_eof,
    PerlIOBase_error,
    PerlIOBase_clearerr,
    PerlIOBase_setlinebuf,
    PerlIOEncode_get_base,
    PerlIOBuf_bufsiz,
    PerlIOBuf_get_ptr,
    PerlIOBuf_get_cnt,
    PerlIOBuf_set_ptrcnt,
};
#endif				/* encode layer */

MODULE = PerlIO::encoding PACKAGE = PerlIO::encoding

PROTOTYPES: ENABLE

BOOT:
{
#ifdef PERLIO_LAYERS
 PerlIO_define_layer(aTHX_ &PerlIO_encode);
#endif
}
