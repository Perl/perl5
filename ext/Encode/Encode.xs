#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define UNIMPLEMENTED(x,y) y x (SV *sv, char *encoding) {   \
                         Perl_croak(aTHX_ "panic_unimplemented"); \
			 return (y)0; /* fool picky compilers */ \
                         }
UNIMPLEMENTED(_encoded_utf8_to_bytes, I32)
UNIMPLEMENTED(_encoded_bytes_to_utf8, I32)

#ifdef USE_PERLIO
#include "perliol.h"

typedef struct
{
 PerlIOBuf	base;         /* PerlIOBuf stuff */
 SV *		bufsv;
 SV *		enc;
} PerlIOEncode;


IV
PerlIOEncode_pushed(PerlIO *f, const char *mode,const char *arg,STRLEN len)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 dSP;
 IV code;
 code = PerlIOBuf_pushed(f,mode,Nullch,0);
 ENTER;
 SAVETMPS;
 PUSHMARK(sp);
 XPUSHs(sv_2mortal(newSVpv("Encode",0)));
 XPUSHs(sv_2mortal(newSVpvn(arg,len)));
 PUTBACK;
 if (perl_call_method("getEncoding",G_SCALAR) != 1)
  return -1;
 SPAGAIN;
 e->enc = POPs;
 PUTBACK;
 if (!SvROK(e->enc))
  return -1;
 SvREFCNT_inc(e->enc);
 FREETMPS;
 LEAVE;
 PerlIOBase(f)->flags |= PERLIO_F_UTF8;
 return code;
}

IV
PerlIOEncode_popped(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 if (e->enc)
  {
   SvREFCNT_dec(e->enc);
   e->enc = Nullsv;
  }
 if (e->bufsv)
  {
   SvREFCNT_dec(e->bufsv);
   e->bufsv = Nullsv;
  }
 return 0;
}

STDCHAR *
PerlIOEncode_get_base(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 if (!e->base.bufsiz)
  e->base.bufsiz = 1024;
 if (!e->bufsv)
  {
   e->bufsv = newSV(e->base.bufsiz);
   sv_setpvn(e->bufsv,"",0);
  }
 e->base.buf = SvPVX(e->bufsv);
 if (!e->base.ptr)
  e->base.ptr = e->base.buf;
 if (!e->base.end)
  e->base.end = e->base.buf;
 if (e->base.ptr < e->base.buf || e->base.ptr > e->base.buf+SvLEN(e->bufsv))
  {
   Perl_warn(aTHX_ " ptr %p(%p)%p",
             e->base.buf,e->base.ptr,e->base.buf+SvLEN(e->bufsv));
   abort();
  }
 if (SvLEN(e->bufsv) < e->base.bufsiz)
  {
   SSize_t poff = e->base.ptr - e->base.buf;
   SSize_t eoff = e->base.end - e->base.buf;
   e->base.buf  = SvGROW(e->bufsv,e->base.bufsiz);
   e->base.ptr  = e->base.buf + poff;
   e->base.end  = e->base.buf + eoff;
  }
 if (e->base.ptr < e->base.buf || e->base.ptr > e->base.buf+SvLEN(e->bufsv))
  {
   Perl_warn(aTHX_ " ptr %p(%p)%p",
             e->base.buf,e->base.ptr,e->base.buf+SvLEN(e->bufsv));
   abort();
  }
 return e->base.buf;
}

static void
Break(void)
{

}

IV
PerlIOEncode_fill(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 dSP;
 IV code;
 Break();
 code = PerlIOBuf_fill(f);
 if (code == 0)
  {
   SV *uni;
   SvCUR_set(e->bufsv, e->base.end - e->base.buf);
   SvUTF8_off(e->bufsv);
   ENTER;
   SAVETMPS;
   PUSHMARK(sp);
   XPUSHs(e->enc);
   XPUSHs(e->bufsv);
   XPUSHs(&PL_sv_yes);
   PUTBACK;
   if (perl_call_method("toUnicode",G_SCALAR) != 1)
    code = -1;
   SPAGAIN;
   uni = POPs;
   PUTBACK;
   sv_setsv(e->bufsv,uni);
   sv_utf8_upgrade(e->bufsv);
   e->base.buf    = SvPVX(e->bufsv);
   e->base.end    = e->base.buf+SvCUR(e->bufsv);
   e->base.ptr    = e->base.buf;
   FREETMPS;
   LEAVE;
  }
 return code;
}

IV
PerlIOEncode_flush(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 IV code = 0;
 dTHX;
 if (e->bufsv && (PerlIOBase(f)->flags & (PERLIO_F_RDBUF|PERLIO_F_WRBUF)))
  {
   dSP;
   SV *str;
   char *s;
   STRLEN len;
   ENTER;
   SAVETMPS;
   PUSHMARK(sp);
   XPUSHs(e->enc);
   SvCUR_set(e->bufsv, e->base.end - e->base.buf);
   SvUTF8_on(e->bufsv);
   XPUSHs(e->bufsv);
   XPUSHs(&PL_sv_yes);
   PUTBACK;
   if (perl_call_method("fromUnicode",G_SCALAR) != 1)
    code = -1;
   SPAGAIN;
   str = POPs;
   PUTBACK;
   sv_setsv(e->bufsv,str);
   SvUTF8_off(e->bufsv);
   e->base.buf = SvPVX(e->bufsv);
   e->base.ptr = e->base.buf+SvCUR(e->bufsv);
   FREETMPS;
   LEAVE;
   if (PerlIOBuf_flush(f) != 0)
    code = -1;
  }
 return code;
}

IV
PerlIOEncode_close(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 IV code = PerlIOBase_close(f);
 dTHX;
 if (e->bufsv)
  {
   SvREFCNT_dec(e->bufsv);
   e->bufsv = Nullsv;
  }
 e->base.buf = NULL;
 e->base.ptr = NULL;
 e->base.end = NULL;
 PerlIOBase(f)->flags &= ~(PERLIO_F_RDBUF|PERLIO_F_WRBUF);
 return code;
}

PerlIO_funcs PerlIO_encode = {
 "encode",
 sizeof(PerlIOEncode),
 PERLIO_K_BUFFERED,
 PerlIOBase_fileno,
 PerlIOBuf_fdopen,
 PerlIOBuf_open,
 PerlIOBuf_reopen,
 PerlIOEncode_pushed,
 PerlIOEncode_popped,
 PerlIOBuf_read,
 PerlIOBuf_unread,
 PerlIOBuf_write,
 PerlIOBuf_seek,
 PerlIOBuf_tell,
 PerlIOEncode_close,
 PerlIOEncode_flush,
 PerlIOEncode_fill,
 PerlIOBase_eof,
 PerlIOBase_error,
 PerlIOBase_clearerr,
 PerlIOBuf_setlinebuf,
 PerlIOEncode_get_base,
 PerlIOBuf_bufsiz,
 PerlIOBuf_get_ptr,
 PerlIOBuf_get_cnt,
 PerlIOBuf_set_ptrcnt,
};
#endif

void call_failure (SV *routine, U8* done, U8* dest, U8* orig) {}

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

SV *
_chars_to_utf8(sv, from, ...)
	SV *	sv
	SV *	from
      CODE:
	{
	  SV * check = items == 3 ? ST(2) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_utf8_to_chars(sv, to, ...)
	SV *	sv
	SV *	to
      CODE:
	{
	  SV * check = items == 3 ? ST(2) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_utf8_to_chars_check(sv, ...)
	SV *	sv
      CODE:
	{
	  SV * check = items == 2 ? ST(1) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_bytes_to_chars(sv, from, ...)
	SV *	sv
	SV *	from
      CODE:
	{
	  SV * check = items == 3 ? ST(2) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_chars_to_bytes(sv, to, ...)
	SV *	sv
	SV *	to
      CODE:
	{
	  SV * check = items == 3 ? ST(2) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_from_to(sv, from, to, ...)
	SV *	sv
	SV *	from
	SV *	to
      CODE:
	{
	  SV * check = items == 4 ? ST(3) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

bool
_is_utf8(sv, ...)
	SV *	sv
      CODE:
	{
	  SV *	check = items == 2 ? ST(1) : Nullsv;
	  if (SvPOK(sv)) {
	    RETVAL = SvUTF8(sv) ? 1 : 0;
	    if (RETVAL &&
		SvTRUE(check) &&
		!is_utf8_string((U8*)SvPVX(sv), SvCUR(sv)))
	      RETVAL = FALSE;
	  } else {
	    RETVAL = FALSE;
	  }
	}
      OUTPUT:
	RETVAL

SV *
_on_utf8(sv)
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
_off_utf8(sv)
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

SV *
_utf_to_utf(sv, from, to, ...)
	SV *	sv
	SV *	from
	SV *	to
      CODE:
	{
	  SV * check = items == 4 ? ST(3) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

BOOT:
{
#ifdef USE_PERLIO
 PerlIO_define_layer(&PerlIO_encode);
#endif
}
