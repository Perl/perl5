#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define UNIMPLEMENTED(x,y) y x (SV *sv, char *encoding) {   \
                         Perl_croak(aTHX_ "panic_unimplemented"); \
			 return (y)0; /* fool picky compilers */ \
                         }
UNIMPLEMENTED(_encoded_utf8_to_bytes, I32)
UNIMPLEMENTED(_encoded_bytes_to_utf8, I32)

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
	    RETVAL = SvUTF8(sv);
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

