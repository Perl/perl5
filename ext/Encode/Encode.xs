#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define U8 U8
#include "encode.h"
#include "iso8859.h"
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

typedef struct
{
 PerlIOBuf	base;         /* PerlIOBuf stuff */
 SV *		bufsv;
 SV *		enc;
} PerlIOEncode;

SV *
PerlIOEncode_getarg(PerlIO *f)
{
 dTHX;
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 SV *sv = &PL_sv_undef;
 if (e->enc)
  {
   dSP;
   ENTER;
   SAVETMPS;
   PUSHMARK(sp);
   XPUSHs(e->enc);
   PUTBACK;
   if (perl_call_method("name",G_SCALAR) == 1)
    {
     SPAGAIN;
     sv = newSVsv(POPs);
     PUTBACK;
    }
  }
 return sv;
}

IV
PerlIOEncode_pushed(PerlIO *f, const char *mode, SV *arg)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 dSP;
 IV code;
 code = PerlIOBuf_pushed(f,mode,Nullsv);
 ENTER;
 SAVETMPS;
 PUSHMARK(sp);
 XPUSHs(arg);
 PUTBACK;
 if (perl_call_pv("Encode::find_encoding",G_SCALAR) != 1)
  {
   /* should never happen */
   Perl_die(aTHX_ "Encode::find_encoding did not return a value");
   return -1;
  }
 SPAGAIN;
 e->enc = POPs;
 PUTBACK;
 if (!SvROK(e->enc))
  {
   e->enc = Nullsv;
   errno  = EINVAL;
   Perl_warner(aTHX_ WARN_IO, "Cannot find encoding \"%"SVf"\"", arg);
   return -1;
  }
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
 e->base.buf = (STDCHAR *)SvPVX(e->bufsv);
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
   e->base.buf  = (STDCHAR *)SvGROW(e->bufsv,e->base.bufsiz);
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

IV
PerlIOEncode_fill(PerlIO *f)
{
 PerlIOEncode *e = PerlIOSelf(f,PerlIOEncode);
 dTHX;
 dSP;
 IV code;
 code = PerlIOBuf_fill(f);
 if (code == 0)
  {
   SV *uni;
   STRLEN len;
   char *s;
   /* Set SV that is the buffer to be buf..ptr */
   SvCUR_set(e->bufsv, e->base.end - e->base.buf);
   SvUTF8_off(e->bufsv);
   ENTER;
   SAVETMPS;
   PUSHMARK(sp);
   XPUSHs(e->enc);
   XPUSHs(e->bufsv);
   XPUSHs(&PL_sv_yes);
   PUTBACK;
   if (perl_call_method("decode",G_SCALAR) != 1)
    code = -1;
   SPAGAIN;
   uni = POPs;
   PUTBACK;
   /* Now get translated string (forced to UTF-8) and copy back to buffer
      don't use sv_setsv as that may "steal" PV from returned temp
      and so free() our known-large-enough buffer.
      sv_setpvn() should do but let us do it long hand.
    */
   s = SvPVutf8(uni,len);
   if (s != SvPVX(e->bufsv))
    {
     e->base.buf = (STDCHAR *)SvGROW(e->bufsv,len);
     Move(s,e->base.buf,len,char);
     SvCUR_set(e->bufsv,len);
    }
   SvUTF8_on(e->bufsv);
   e->base.end    = e->base.buf+len;
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
 if (e->bufsv && (PerlIOBase(f)->flags & (PERLIO_F_RDBUF|PERLIO_F_WRBUF))
     &&(e->base.ptr > e->base.buf)
    )
  {
   dTHX;
   dSP;
   SV *str;
   char *s;
   STRLEN len;
   SSize_t left = 0;
   if (PerlIOBase(f)->flags & PERLIO_F_RDBUF)
    {
     /* This is really just a flag to see if we took all the data, if
        we did PerlIOBase_flush avoids a seek to lower layer.
        Need to revisit if we start getting clever with unreads or seeks-in-buffer
      */
     left = e->base.end - e->base.ptr;
    }
   ENTER;
   SAVETMPS;
   PUSHMARK(sp);
   XPUSHs(e->enc);
   SvCUR_set(e->bufsv, e->base.ptr - e->base.buf);
   SvUTF8_on(e->bufsv);
   XPUSHs(e->bufsv);
   XPUSHs(&PL_sv_yes);
   PUTBACK;
   if (perl_call_method("encode",G_SCALAR) != 1)
    code = -1;
   SPAGAIN;
   str = POPs;
   PUTBACK;
   s = SvPV(str,len);
   if (s != SvPVX(e->bufsv))
    {
     e->base.buf = (STDCHAR *)SvGROW(e->bufsv,len);
     Move(s,e->base.buf,len,char);
     SvCUR_set(e->bufsv,len);
    }
   SvUTF8_off(e->bufsv);
   e->base.ptr = e->base.buf+len;
   /* restore end != ptr as inequality is used by PerlIOBuf_flush in read case */
   e->base.end = e->base.ptr + left;
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

Off_t
PerlIOEncode_tell(PerlIO *f)
{
 dTHX;
 PerlIOBuf *b = PerlIOSelf(f,PerlIOBuf);
 /* Unfortunately the only way to get a postion is to back-translate,
    the UTF8-bytes we have buf..ptr and adjust accordingly.
    But we will try and save any unread data in case stream
    is un-seekable.
  */
 if ((PerlIOBase(f)->flags & PERLIO_F_RDBUF) && b->ptr < b->end)
  {
   Size_t count = b->end - b->ptr;
   PerlIO_push(aTHX_ f,&PerlIO_pending,"r",Nullsv);
   /* Save what we have left to read */
   PerlIOSelf(f,PerlIOBuf)->bufsiz = count;
   PerlIO_unread(f,b->ptr,count);
   /* There isn't any unread data - we just saved it - so avoid the lower seek */
   b->end = b->ptr;
   /* Flush ourselves - now one layer down,
      this does the back translate and adjusts position
    */
   PerlIO_flush(PerlIONext(f));
   /* Set position of the saved data */
   PerlIOSelf(f,PerlIOBuf)->posn = b->posn;
  }
 else
  {
   PerlIO_flush(f);
  }
 return b->posn;
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
#endif /* encode layer */

void
Encode_Define(pTHX_ encode_t *enc)
{
 dSP;
 HV *stash = gv_stashpv("Encode::XS", TRUE);
 SV *sv    = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))),stash);
 int i = 0;
 PUSHMARK(sp);
 XPUSHs(sv);
 while (enc->name[i])
  {
   const char *name = enc->name[i++];
   XPUSHs(sv_2mortal(newSVpvn(name,strlen(name))));
  }
 PUTBACK;
 call_pv("Encode::define_encoding",G_DISCARD);
 SvREFCNT_dec(sv);
}

void call_failure (SV *routine, U8* done, U8* dest, U8* orig) {}

static SV *
encode_method(pTHX_ encode_t *enc, encpage_t *dir, SV *src, int check)
{
 STRLEN slen;
 U8 *s = (U8 *) SvPV(src,slen);
 SV *dst = sv_2mortal(newSV(2*slen+1));
 if (slen)
  {
   U8 *d = (U8 *) SvGROW(dst, 2*slen+1);
   STRLEN dlen = SvLEN(dst);
   int code;
   while ((code = do_encode(dir,s,&slen,d,dlen,&dlen,!check)))
    {
     SvCUR_set(dst,dlen);
     SvPOK_on(dst);

     if (code == ENCODE_FALLBACK)
      break;

     switch(code)
      {
       case ENCODE_NOSPACE:
        {
         STRLEN need = (slen) ? (SvLEN(dst)*SvCUR(src)/slen) : (dlen + UTF8_MAXLEN);
         if (need <= SvLEN(dst))
          need += UTF8_MAXLEN;
         d = (U8 *) SvGROW(dst, need);
         dlen = SvLEN(dst);
         slen = SvCUR(src);
         break;
        }

       case ENCODE_NOREP:
        if (dir == enc->f_utf8)
         {
          if (!check && ckWARN_d(WARN_UTF8))
           {
            STRLEN clen;
            UV ch = utf8n_to_uvuni(s+slen,(SvCUR(src)-slen),&clen,0);
            Perl_warner(aTHX_ WARN_UTF8, "\"\\N{U+%"UVxf"}\" does not map to %s", ch, enc->name[0]);
            /* FIXME: Skip over the character, copy in replacement and continue
             * but that is messy so for now just fail.
             */
            return &PL_sv_undef;
           }
          else
           {
            return &PL_sv_undef;
           }
         }
        else
         {
          /* UTF-8 is supposed to be "Universal" so should not happen */
          Perl_croak(aTHX_ "%s '%.*s' does not map to UTF-8",
                 enc->name[0], (int)(SvCUR(src)-slen),s+slen);
         }
        break;

       case ENCODE_PARTIAL:
         if (!check && ckWARN_d(WARN_UTF8))
          {
           Perl_warner(aTHX_ WARN_UTF8, "Partial %s character",
                       (dir == enc->f_utf8) ? "UTF-8" : enc->name[0]);
          }
         return &PL_sv_undef;

       default:
        Perl_croak(aTHX_ "Unexpected code %d converting %s %s",
                 code, (dir == enc->f_utf8) ? "to" : "from",enc->name[0]);
        return &PL_sv_undef;
      }
    }
   SvCUR_set(dst,dlen);
   SvPOK_on(dst);
   if (check)
    {
     if (slen < SvCUR(src))
      {
       Move(s+slen,s,SvCUR(src)-slen,U8);
      }
     SvCUR_set(src,SvCUR(src)-slen);
    }
  }
 else
  {
   SvCUR_set(dst,slen);
   SvPOK_on(dst);
  }
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
	  if (SvPOK(sv)) {
	    RETVAL = SvUTF8(sv) ? TRUE : FALSE;
	    if (RETVAL &&
		check  &&
		!is_utf8_string((U8*)SvPVX(sv), SvCUR(sv)))
	      RETVAL = FALSE;
	  } else {
	    RETVAL = FALSE;
	  }
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
#include "iso8859.def"
#include "EBCDIC.def"
#include "Symbols.def"
}
