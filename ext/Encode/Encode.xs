#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define U8 U8
#include "encode.h"
#include "8859.h"
#include "EBCDIC.h"
#include "Symbols.h"


#define UNIMPLEMENTED(x,y) y x (SV *sv, char *encoding) {dTHX;   \
                         Perl_croak(aTHX_ "panic_unimplemented"); \
			 return (y)0; /* fool picky compilers */ \
                         }
UNIMPLEMENTED(_encoded_utf8_to_bytes, I32)
    UNIMPLEMENTED(_encoded_bytes_to_utf8, I32)
#if defined(USE_PERLIO) && !defined(USE_SFIO)
/* Define an encoding "layer" in the perliol.h sense.
   The layer defined here "inherits" in an object-oriented sense from the
   "perlio" layer with its PerlIOBuf_* "methods".
   The implementation is particularly efficient as until Encode settles down
   there is no point in tryint to tune it.

   The layer works by overloading the "fill" and "flush" methods.

   "fill" calls "SUPER::fill" in perl terms, then calls the encode OO perl API
   to convert the encoded data to UTF-8 form, then copies it back to the
   buffer. The "base class's" read methods then see the UTF-8 data.

   "flush" transforms the UTF-8 data deposited by the "base class's write
   method in the buffer back into the encoded form using the encode OO perl API,
   then copies data back into the buffer and calls "SUPER::flush.

   Note that "flush" is _also_ called for read mode - we still do the (back)-translate
   so that the the base class's "flush" sees the correct number of encoded chars
   for positioning the seek pointer. (This double translation is the worst performance
   issue - particularly with all-perl encode engine.)

*/
#include "perliol.h"
typedef struct {
    PerlIOBuf base;		/* PerlIOBuf stuff */
    SV *bufsv;			/* buffer seen by layers above */
    SV *dataSV;			/* data we have read from layer below */
    SV *enc;			/* the encoding object */
} PerlIOEncode;

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
	if (perl_call_method("name", G_SCALAR) == 1) {
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
    XPUSHs(arg);
    PUTBACK;
    if (perl_call_pv("Encode::find_encoding", G_SCALAR) != 1) {
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
	Perl_warner(aTHX_ WARN_IO, "Cannot find encoding \"%" SVf "\"",
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
	e->bufsv = Nullsv;
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
	    sv_catpvn(e->dataSV,ptr,use);
	}
	else {
	    /* Create a "dummy" SV to represent the available data from layer below */
	    if (SvLEN(e->dataSV) && SvPVX(e->dataSV)) {
		Safefree(SvPVX(e->dataSV));
	    }
	    if (use > e->base.bufsiz) {
	       use = e->base.bufsiz;
	    }
	    SvPVX(e->dataSV) = (char *) ptr;
	    SvLEN(e->dataSV) = 0;  /* Hands off sv.c - it isn't yours */
	    SvCUR_set(e->dataSV,use);
	    SvPOK_on(e->dataSV);
	}
	SvUTF8_off(e->dataSV);
	PUSHMARK(sp);
	XPUSHs(e->enc);
	XPUSHs(e->dataSV);
	XPUSHs(&PL_sv_yes);
	PUTBACK;
	if (perl_call_method("decode", G_SCALAR) != 1) {
	    Perl_die(aTHX_ "panic: decode did not return a value");
	}
	SPAGAIN;
	uni = POPs;
	PUTBACK;
	/* Now get translated string (forced to UTF-8) and use as buffer */
	if (SvPOK(uni)) {
	    s = SvPVutf8(uni, len);
	    if (len && !is_utf8_string(s,len)) {
		Perl_warn(aTHX_ "panic: decode did not return UTF-8 '%.*s'",(int) len,s);
	    }
	}
	if (len > 0) {
	    /* Got _something */
	    /* if decode gave us back dataSV then data may vanish when
	       we do ptrcnt adjust - so take our copy now.
	       (The copy is a pain - need a put-it-here option for decode.)
	     */
	    sv_setpvn(e->bufsv,s,len);
	    e->base.ptr = e->base.buf = SvPVX(e->bufsv);
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
	    Perl_warn(aTHX_ "flush %_",e->bufsv);
	    XPUSHs(e->bufsv);
	    XPUSHs(&PL_sv_yes);
	    PUTBACK;
	    if (perl_call_method("encode", G_SCALAR) != 1)
		code = -1;
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
		SvPVX(str) = e->base.ptr;
		SvLEN(str) = 0;
		SvCUR_set(str, e->base.end - e->base.ptr);
		SvUTF8_on(str);
		PUSHMARK(sp);
		XPUSHs(e->enc);
		XPUSHs(str);
		XPUSHs(&PL_sv_yes);
		PUTBACK;
		if (perl_call_method("encode", G_SCALAR) != 1)
		    code = -1;
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
    PERLIO_K_BUFFERED,
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

void
Encode_XSEncoding(pTHX_ encode_t * enc)
{
    dSP;
    HV *stash = gv_stashpv("Encode::XS", TRUE);
    SV *sv = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))), stash);
    int i = 0;
    PUSHMARK(sp);
    XPUSHs(sv);
    while (enc->name[i]) {
	const char *name = enc->name[i++];
	XPUSHs(sv_2mortal(newSVpvn(name, strlen(name))));
    }
    PUTBACK;
    call_pv("Encode::define_encoding", G_DISCARD);
    SvREFCNT_dec(sv);
}

void
call_failure(SV * routine, U8 * done, U8 * dest, U8 * orig)
{
}

static SV *
encode_method(pTHX_ encode_t * enc, encpage_t * dir, SV * src,
			 int check)
{
    STRLEN slen;
    U8 *s = (U8 *) SvPV(src, slen);
    STRLEN tlen = slen;
    SV *dst = sv_2mortal(newSV(slen+1));
    if (slen) {
	U8 *d = (U8 *) SvPVX(dst);
	STRLEN dlen = SvLEN(dst)-1;
	int code;
	while ((code = do_encode(dir, s, &slen, d, dlen, &dlen, !check))) {
	    SvCUR_set(dst, dlen);
	    SvPOK_on(dst);

#if 0
	    Perl_warn(aTHX_ "code=%d @ s=%d/%d d=%d",code,slen,tlen,dlen);
#endif
	
	    if (code == ENCODE_FALLBACK || code == ENCODE_PARTIAL)
		break;

	    switch (code) {
	    case ENCODE_NOSPACE:
		{
		    STRLEN done = tlen-slen;
		    STRLEN need ;
		    if (done) {
			need = (tlen*dlen)/done+1;
		    }
		    else {
			need = dlen + UTF8_MAXLEN;
		    }
		
		    d = (U8 *) SvGROW(dst, need);
		    if (dlen >= SvLEN(dst)) {
			Perl_croak(aTHX_
				   "Destination couldn't be grown (the need may be miscalculated).");
		    }
		    dlen = SvLEN(dst);
		    slen = tlen;
		    break;
		}

	    case ENCODE_NOREP:
		if (dir == enc->f_utf8) {
		    if (!check && ckWARN_d(WARN_UTF8)) {
			STRLEN clen;
			UV ch =
			    utf8n_to_uvuni(s + slen, (SvCUR(src) - slen),
					   &clen, 0);
			Perl_warner(aTHX_ WARN_UTF8,
				    "\"\\N{U+%" UVxf
				    "}\" does not map to %s", ch,
				    enc->name[0]);
			/* FIXME: Skip over the character, copy in replacement and continue
			 * but that is messy so for now just fail.
			 */
			return &PL_sv_undef;
		    }
		    else {
			return &PL_sv_undef;
		    }
		}
		else {
		    /* UTF-8 is supposed to be "Universal" so should not happen */
		    Perl_croak(aTHX_ "%s '%.*s' does not map to UTF-8",
			       enc->name[0], (int) (SvCUR(src) - slen),
			       s + slen);
		}
		break;

	    default:
		Perl_croak(aTHX_ "Unexpected code %d converting %s %s",
			   code, (dir == enc->f_utf8) ? "to" : "from",
			   enc->name[0]);
		return &PL_sv_undef;
	    }
	}
	SvCUR_set(dst, dlen);
	SvPOK_on(dst);
	if (check) {
	    if (slen < SvCUR(src)) {
		Move(s + slen, s, SvCUR(src) - slen, U8);
	    }
	    SvCUR_set(src, SvCUR(src) - slen);
	    *SvEND(src) = '\0';
	}
    }
    else {
	SvCUR_set(dst, 0);
	SvPOK_on(dst);
    }
    *SvEND(dst) = '\0';
    return dst;
}

MODULE = Encode		PACKAGE = Encode::XS	PREFIX = Method_

PROTOTYPES: ENABLE

void
Method_decode(obj,src,check = FALSE)
SV *	obj
SV *	src
bool	check
CODE:
 {
  encode_t *enc = INT2PTR(encode_t *, SvIV(SvRV(obj)));
  ST(0) = encode_method(aTHX_ enc, enc->t_utf8, src, check);
  SvUTF8_on(ST(0));
  XSRETURN(1);
 }

void
Method_encode(obj,src,check = FALSE)
SV *	obj
SV *	src
bool	check
CODE:
 {
  encode_t *enc = INT2PTR(encode_t *, SvIV(SvRV(obj)));
  sv_utf8_upgrade(src);
  ST(0) = encode_method(aTHX_ enc, enc->f_utf8, src, check);
  XSRETURN(1);
 }

MODULE = Encode         PACKAGE = Encode

PROTOTYPES: ENABLE

I32
_bytes_to_utf8(sv, ...)
        SV *    sv
      CODE:
        {
          SV * encoding = items == 2 ? ST(1) : Nullsv;

          if (encoding)
            RETVAL = _encoded_bytes_to_utf8(sv, SvPV_nolen(encoding));
          else {
            STRLEN len;
            U8*    s = (U8*)SvPV(sv, len);
            U8*    converted;

            converted = bytes_to_utf8(s, &len); /* This allocs */
            sv_setpvn(sv, (char *)converted, len);
            SvUTF8_on(sv); /* XXX Should we? */
            Safefree(converted);                /* ... so free it */
            RETVAL = len;
          }
        }
      OUTPUT:
        RETVAL

I32
_utf8_to_bytes(sv, ...)
        SV *    sv
      CODE:
        {
          SV * to    = items > 1 ? ST(1) : Nullsv;
          SV * check = items > 2 ? ST(2) : Nullsv;

          if (to)
            RETVAL = _encoded_utf8_to_bytes(sv, SvPV_nolen(to));
          else {
            STRLEN len;
            U8 *s = (U8*)SvPV(sv, len);

	    RETVAL = 0;
            if (SvTRUE(check)) {
              /* Must do things the slow way */
              U8 *dest;
              U8 *src  = (U8*)savepv((char *)s); /* We need a copy to pass to check() */
              U8 *send = s + len;

              New(83, dest, len, U8); /* I think */

              while (s < send) {
                if (*s < 0x80)
                  *dest++ = *s++;
                else {
                  STRLEN ulen;
		  UV uv = *s++;

                  /* Have to do it all ourselves because of error routine,
		     aargh. */
		  if (!(uv & 0x40))
		    goto failure;
		  if      (!(uv & 0x20)) { ulen = 2;  uv &= 0x1f; }
		  else if (!(uv & 0x10)) { ulen = 3;  uv &= 0x0f; }
		  else if (!(uv & 0x08)) { ulen = 4;  uv &= 0x07; }
		  else if (!(uv & 0x04)) { ulen = 5;  uv &= 0x03; }
		  else if (!(uv & 0x02)) { ulen = 6;  uv &= 0x01; }
		  else if (!(uv & 0x01)) { ulen = 7;  uv = 0; }
		  else                   { ulen = 13; uv = 0; }
		
		  /* Note change to utf8.c variable naming, for variety */
		  while (ulen--) {
		    if ((*s & 0xc0) != 0x80)
		      goto failure;
		
		    else
		      uv = (uv << 6) | (*s++ & 0x3f);
		  }
		  if (uv > 256) {
		  failure:
		    call_failure(check, s, dest, src);
		    /* Now what happens? */
		  }
		  *dest++ = (U8)uv;
               }
               }
	    } else
	      RETVAL = (utf8_to_bytes(s, &len) ? len : 0);
	  }
	}
      OUTPUT:
	RETVAL

bool
is_utf8(sv, check = FALSE)
SV *	sv
bool	check
      CODE:
	{
	  if (SvGMAGICAL(sv)) /* it could be $1, for example */
	    sv = newSVsv(sv); /* GMAGIG will be done */
	  if (SvPOK(sv)) {
	    RETVAL = SvUTF8(sv) ? TRUE : FALSE;
	    if (RETVAL &&
		check  &&
		!is_utf8_string((U8*)SvPVX(sv), SvCUR(sv)))
	      RETVAL = FALSE;
	  } else {
	    RETVAL = FALSE;
	  }
	  if (sv != ST(0))
	    SvREFCNT_dec(sv); /* it was a temp copy */
	}
      OUTPUT:
	RETVAL

SV *
_utf8_on(sv)
	SV *	sv
      CODE:
	{
	  if (SvPOK(sv)) {
	    SV *rsv = newSViv(SvUTF8(sv));
	    RETVAL = rsv;
	    SvUTF8_on(sv);
	  } else {
	    RETVAL = &PL_sv_undef;
	  }
	}
      OUTPUT:
	RETVAL

SV *
_utf8_off(sv)
	SV *	sv
      CODE:
	{
	  if (SvPOK(sv)) {
	    SV *rsv = newSViv(SvUTF8(sv));
	    RETVAL = rsv;
	    SvUTF8_off(sv);
	  } else {
	    RETVAL = &PL_sv_undef;
	  }
	}
      OUTPUT:
	RETVAL

BOOT:
{
#if defined(USE_PERLIO) && !defined(USE_SFIO)
 PerlIO_define_layer(aTHX_ &PerlIO_encode);
#endif
#include "8859_def.h"
#include "EBCDIC_def.h"
#include "Symbols_def.h"
}
