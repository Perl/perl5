#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define U8 U8
#include "encode.h"
#include "def_t.h"

#define FBCHAR			0xFFFd
#define FBCHAR_UTF8		"\xEF\xBF\xBD"
#define BOM_BE			0xFeFF
#define BOM16LE			0xFFFe
#define BOM32LE			0xFFFe0000
#define issurrogate(x)		(0xD800 <= (x)  && (x) <= 0xDFFF )
#define isHiSurrogate(x)	(0xD800 <= (x)  && (x) <  0xDC00 )
#define isLoSurrogate(x)	(0xDC00 <= (x)  && (x) <= 0xDFFF )
#define invalid_ucs2(x)         ( issurrogate(x) || 0xFFFF < (x) )

static UV
enc_unpack(pTHX_ U8 **sp,U8 *e,STRLEN size,U8 endian)
{
    U8 *s = *sp;
    UV v = 0;
    if (s+size > e) {
	croak("Partial character %c",(char) endian);
    }
    switch(endian) {
	case 'N':
	    v = *s++;
	    v = (v << 8) | *s++;
	case 'n':
	    v = (v << 8) | *s++;
	    v = (v << 8) | *s++;
	    break;
	case 'V':
	case 'v':
	    v |= *s++;
	    v |= (*s++ << 8);
	    if (endian == 'v')
		break;
	    v |= (*s++ << 16);
	    v |= (*s++ << 24);
	    break;
	default:
	    croak("Unknown endian %c",(char) endian);
	    break;
    }
    *sp = s;
    return v;
}

void
enc_pack(pTHX_ SV *result,STRLEN size,U8 endian,UV value)
{
    U8 *d = (U8 *)SvGROW(result,SvCUR(result)+size);
    switch(endian) {
	case 'v':
	case 'V':
	    d += SvCUR(result);
	    SvCUR_set(result,SvCUR(result)+size);
	    while (size--) {
		*d++ = value & 0xFF;
		value >>= 8;
	    }
	    break;
	case 'n':
	case 'N':
	    SvCUR_set(result,SvCUR(result)+size);
	    d += SvCUR(result);
	    while (size--) {
		*--d = value & 0xFF;
		value >>= 8;
	    }
	    break;
	default:
	    croak("Unknown endian %c",(char) endian);
	    break;
    }
}

#define ENCODE_XS_PROFILE 0 /* set 1 or more to profile.
			       t/encoding.t dumps core because of
			       Perl_warner and PerlIO don't work well */

#define ENCODE_XS_USEFP   1 /* set 0 to disable floating point to calculate
			       buffer size for encode_method().
			       1 is recommended. 2 restores NI-S original  */

#define UNIMPLEMENTED(x,y) y x (SV *sv, char *encoding) {dTHX;   \
                         Perl_croak(aTHX_ "panic_unimplemented"); \
			 return (y)0; /* fool picky compilers */ \
                         }
UNIMPLEMENTED(_encoded_utf8_to_bytes, I32)
    UNIMPLEMENTED(_encoded_bytes_to_utf8, I32)

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
 /* Exists for breakpointing */
}

static SV *
encode_method(pTHX_ encode_t * enc, encpage_t * dir, SV * src,
			 int check)
{
    STRLEN slen;
    U8 *s = (U8 *) SvPV(src, slen);
    STRLEN tlen  = slen;
    STRLEN ddone = 0;
    STRLEN sdone = 0;

    /* We allocate slen+1.
        PerlIO dumps core if this value is smaller than this. */
    SV *dst = sv_2mortal(newSV(slen+1));
    if (slen) {
	U8 *d = (U8 *) SvPVX(dst);
	STRLEN dlen = SvLEN(dst)-1;
	int code;
	while ((code = do_encode(dir, s, &slen, d, dlen, &dlen, !check))) {
	    SvCUR_set(dst, dlen+ddone);
	    SvPOK_only(dst);

#if ENCODE_XS_PROFILE >= 3
	    Perl_warn(aTHX_ "code=%d @ s=%d/%d/%d d=%d/%d/%d\n",code,slen,sdone,tlen,dlen,ddone,SvLEN(dst)-1);
#endif
	
	    if (code == ENCODE_FALLBACK || code == ENCODE_PARTIAL)
		break;

	    switch (code) {
	    case ENCODE_NOSPACE:
	    {	
		    STRLEN more = 0; /* make sure you initialize! */
		    STRLEN sleft;
		    sdone += slen;
		    ddone += dlen;
		    sleft = tlen - sdone;
#if ENCODE_XS_PROFILE >= 2
		  Perl_warn(aTHX_
		  "more=%d, sdone=%d, sleft=%d, SvLEN(dst)=%d\n",
			    more, sdone, sleft, SvLEN(dst));
#endif
		    if (sdone != 0) { /* has src ever been processed ? */
#if   ENCODE_XS_USEFP == 2
			    more = (1.0*tlen*SvLEN(dst)+sdone-1)/sdone
				    - SvLEN(dst);
#elif ENCODE_XS_USEFP
			    more = (1.0*SvLEN(dst)+1)/sdone * sleft;
#else
			    /* safe until SvLEN(dst) == MAX_INT/16 */
			    more = (16*SvLEN(dst)+1)/sdone/16 * sleft;
#endif
		    }
		    more += UTF8_MAXLEN; /* insurance policy */
#if ENCODE_XS_PROFILE >= 2
		  Perl_warn(aTHX_
		  "more=%d, sdone=%d, sleft=%d, SvLEN(dst)=%d\n",
			    more, sdone, sleft, SvLEN(dst));
#endif
		    d = (U8 *) SvGROW(dst, SvLEN(dst) + more);
		    /* dst need to grow need MORE bytes! */
		    if (ddone >= SvLEN(dst)) {
			Perl_croak(aTHX_ "Destination couldn't be grown.");
		    }
		    dlen = SvLEN(dst)-ddone-1;
		    d   += ddone;
		    s   += slen;
		    slen = tlen-sdone;
		    continue;
	    }

	    case ENCODE_NOREP:
		if (dir == enc->f_utf8) {
		    STRLEN clen;
		    UV ch =
			utf8n_to_uvuni(s + slen, (SvCUR(src) - slen),
				       &clen, 0);
		    if (!check) { /* fallback char */
			sdone += slen + clen;
		        ddone += dlen + enc->replen; 
		        sv_catpvn(dst, enc->rep, enc->replen); 
		    }
                    else if (check == -1){ /* perlqq */
		        SV* perlqq = 
			    sv_2mortal(newSVpvf("\\x{%x}", ch));
  		       sdone += slen + clen;
		       ddone += dlen + SvLEN(perlqq);
  		       sv_catsv(dst, perlqq);
		    }			
                    else { 
			  Perl_croak(aTHX_ 
				     "\"\\N{U+%" UVxf
				     "}\" does not map to %s", ch,
					enc->name[0]);
		    }
	    }
	    else {
		if (!check){  /* fallback char */
		    sdone += slen + 1;
		    ddone += dlen + strlen(FBCHAR_UTF8); 
		    sv_catpv(dst, FBCHAR_UTF8); 
		}
                else if (check == -1){ /* perlqq */
		    SV* perlqq = 
			    sv_2mortal(newSVpvf("\\x%02X", s[slen]));
                     sdone += slen + 1;
		     ddone += dlen + SvLEN(perlqq);
  		     sv_catsv(dst, perlqq);
                }
		else {
		    /* UTF-8 is supposed to be "Universal" so should not
		happen for real characters, but some encodings
		    have non-assigned codes which may occur. */
			Perl_croak(aTHX_ "%s \"\\x%02X\" "
					   "does not map to Unicode (%d)",
					   enc->name[0], (U8) s[slen], code);
		}
	    }
	    dlen = SvCUR(dst); 
	    d   = SvPVX(dst) + dlen; 
	    s   = SvPVX(src) + sdone; 
	    slen = tlen - sdone;
	    break;

	    default:
		Perl_croak(aTHX_ "Unexpected code %d converting %s %s",
			   code, (dir == enc->f_utf8) ? "to" : "from",
			   enc->name[0]);
		return &PL_sv_undef;
	    }
	}
	SvCUR_set(dst, dlen+ddone);
	SvPOK_only(dst);
	if (check) {
	    sdone = SvCUR(src) - (slen+sdone);
	    if (sdone) {
#if 1
		/* FIXME: A Move() is dangerous - PV could be mmap'ed readonly
		   SvOOK would be ideal - but sv_backoff does not understand SvLEN == 0
		   type SVs and sv_clear() calls it ...
		 */
		 sv_setpvn(src, (char*)s+slen, sdone);
#else
		Move(s + slen, SvPVX(src), sdone , U8);
#endif
	    }
	    SvCUR_set(src, sdone);
	}
    }
    else {
	SvCUR_set(dst, 0);
	SvPOK_only(dst);
    }
#if ENCODE_XS_PROFILE
    if (SvCUR(dst) > SvCUR(src)){
	    Perl_warn(aTHX_
		      "SvLEN(dst)=%d, SvCUR(dst)=%d. "
		      "%d bytes unused(%f %%)\n",
		      SvLEN(dst), SvCUR(dst), SvLEN(dst) - SvCUR(dst),
		      (SvLEN(dst) - SvCUR(dst))*1.0/SvLEN(dst)*100.0);
	
    }
#endif
    *SvEND(dst) = '\0';
    return dst;
}

MODULE = Encode		PACKAGE = Encode::XS	PREFIX = Method_

PROTOTYPES: ENABLE

void
Method_name(obj)
SV *	obj
CODE:
 {
  encode_t *enc = INT2PTR(encode_t *, SvIV(SvRV(obj)));
  ST(0) = sv_2mortal(newSVpvn(enc->name[0],strlen(enc->name[0])));
  XSRETURN(1);
 }

void
Method_decode(obj,src,check = 0)
SV *	obj
SV *	src
int	check
CODE:
 {
  encode_t *enc = INT2PTR(encode_t *, SvIV(SvRV(obj)));
  ST(0) = encode_method(aTHX_ enc, enc->t_utf8, src, check);
  SvUTF8_on(ST(0));
  XSRETURN(1);
 }

void
Method_encode(obj,src,check = 0)
SV *	obj
SV *	src
int	check
CODE:
 {
  encode_t *enc = INT2PTR(encode_t *, SvIV(SvRV(obj)));
  sv_utf8_upgrade(src);
  ST(0) = encode_method(aTHX_ enc, enc->f_utf8, src, check);
  XSRETURN(1);
 }

MODULE = Encode		PACKAGE = Encode::Unicode

void
decode_xs(obj, str, chk = &PL_sv_undef)
SV *	obj
SV *	str
SV *	chk
CODE:
{
    int size    = SvIV(*hv_fetch((HV *)SvRV(obj),"size",4,0));
    U8 endian   = *((U8 *)SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"endian",6,0)));
    int ucs2    = SvTRUE(*hv_fetch((HV *)SvRV(obj),"ucs2",4,0));
    SV *result = newSVpvn("",0);
    STRLEN ulen;
    U8 *s = (U8 *)SvPVbyte(str,ulen);
    U8 *e = (U8 *)SvEND(str);
    ST(0) = sv_2mortal(result);
    SvUTF8_on(result);

    if (!endian && s+size <= e) {
	UV bom;
	endian = (size == 4) ? 'N' : 'n';
	bom = enc_unpack(aTHX_ &s,e,size,endian);
        if (bom != BOM_BE) {
	    if (bom == BOM16LE) {
		endian = 'v';
	    }
	    else if (bom == BOM32LE) {
		endian = 'V';
	    }
	    else {
		croak("%s:Unregognised BOM %"UVxf,
                      SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)),bom);
	    }
	}
#if 0
	/* Update endian for this sequence */
	hv_store((HV *)SvRV(obj),"endian",6,newSVpv((char *)&endian,1),0);
#endif
    }
    while (s < e && s+size <= e) {
	UV ord = enc_unpack(aTHX_ &s,e,size,endian);
	U8 *d;
       if (size != 4 && invalid_ucs2(ord)) {
	    if (ucs2) {
		if (SvTRUE(chk)) {
		    croak("%s:no surrogates allowed %"UVxf,
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)),ord);
		}
		if (s+size <= e) {
		     enc_unpack(aTHX_ &s,e,size,endian); /* skip the next one as well */
		}
		ord = FBCHAR;
	    }
	    else {
		UV lo;
		if (!isHiSurrogate(ord)) {
		    croak("%s:Malformed HI surrogate %"UVxf,
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)),ord);
		}
		if (s+size > e) {
		    /* Partial character */
		    s -= size;   /* back up to 1st half */
		    break;       /* And exit loop */
		}
		lo = enc_unpack(aTHX_ &s,e,size,endian);
		if (!isLoSurrogate(lo)){
		    croak("%s:Malformed LO surrogate %"UVxf,
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)),ord);
		}
		ord = 0x10000 + ((ord - 0xD800) << 10) + (lo - 0xDC00);
	    }
	}
	d = (U8 *) SvGROW(result,SvCUR(result)+UTF8_MAXLEN+1);
	d = uvuni_to_utf8_flags(d+SvCUR(result), ord, 0);
	SvCUR_set(result,d - (U8 *)SvPVX(result));
    }
    if (SvTRUE(chk)) {
	if (s < e) {
	     Perl_warner(aTHX_ packWARN(WARN_UTF8),"%s:Partial character",
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)));
	     Move(s,SvPVX(str),e-s,U8);
	     SvCUR_set(str,(e-s));
	}
	else {
	    SvCUR_set(str,0);
	}
	*SvEND(str) = '\0';
    }
    XSRETURN(1);
}

void
encode_xs(obj, utf8, chk = &PL_sv_undef)
SV *	obj
SV *	utf8
SV *	chk
CODE:
{
    int size   = SvIV(*hv_fetch((HV *)SvRV(obj),"size",4,0));
    U8 endian = *((U8 *)SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"endian",6,0)));
    int ucs2   = SvTRUE(*hv_fetch((HV *)SvRV(obj),"ucs2",4,0));
    SV *result = newSVpvn("",0);
    STRLEN ulen;
    U8 *s = (U8 *)SvPVutf8(utf8,ulen);
    U8 *e = (U8 *)SvEND(utf8);
    ST(0) = sv_2mortal(result);
    if (!endian) {
	endian = (size == 4) ? 'N' : 'n';
	enc_pack(aTHX_ result,size,endian,BOM_BE);
#if 0
	/* Update endian for this sequence */
	hv_store((HV *)SvRV(obj),"endian",6,newSVpv((char *)&endian,1),0);
#endif
    }
    while (s < e && s+UTF8SKIP(s) <= e) {
	STRLEN len;
	UV ord = utf8n_to_uvuni(s, e-s, &len, 0);
        s += len;
       if (size != 4 && invalid_ucs2(ord)) {
	    if (!issurrogate(ord)){
		if (ucs2) {
		    if (SvTRUE(chk)) {
			croak("%s:code point \"\\x{"UVxf"}\" too high",
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)),ord);
		    }
		    enc_pack(aTHX_ result,size,endian,FBCHAR);
		}else{
		    UV hi = ((ord - 0x10000) >> 10)   + 0xD800;
		    UV lo = ((ord - 0x10000) & 0x3FF) + 0xDC00;
		    enc_pack(aTHX_ result,size,endian,hi);
		    enc_pack(aTHX_ result,size,endian,lo);
		}
	    }
	    else {
		/* not supposed to happen */
		enc_pack(aTHX_ result,size,endian,FBCHAR);
	    }
	}
	else {
	    enc_pack(aTHX_ result,size,endian,ord);
	}
    }
    if (SvTRUE(chk)) {
	if (s < e) {
	     Perl_warner(aTHX_ packWARN(WARN_UTF8),"%s:Partial character",
			  SvPV_nolen(*hv_fetch((HV *)SvRV(obj),"Name",4,0)));
	     Move(s,SvPVX(utf8),e-s,U8);
	     SvCUR_set(utf8,(e-s));
	}
	else {
	    SvCUR_set(utf8,0);
	}
	*SvEND(utf8) = '\0';
    }
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
is_utf8(sv, check = 0)
SV *	sv
int	check
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
/* PerlIO_define_layer(aTHX_ &PerlIO_encode); */
#endif
#include "def_t.exh"
}
