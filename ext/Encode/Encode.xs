#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Encode		PACKAGE = Encode

PROTOTYPES: ENABLE

SV *
_bytes_to_utf8(sv, ...)
	SV *	sv
      CODE:
	{
	  SV * encoding = 2 ? ST(1) : Nullsv;
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

SV *
_utf8_to_bytes(sv, ...)
	SV *	sv
      CODE:
	{
	  SV * to    = items > 1 ? ST(1) : Nullsv;
	  SV * check = items > 2 ? ST(2) : Nullsv;
	  RETVAL = &PL_sv_undef;
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
	    sv_2mortal(rsv);
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
	    sv_2mortal(rsv);
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

