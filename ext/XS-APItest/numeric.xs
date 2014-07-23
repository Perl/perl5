MODULE = XS::APItest		PACKAGE = XS::APItest::numeric

void
grok_number(number)
	SV *number
    PREINIT:
	STRLEN len;
	const char *pv = SvPV(number, len);
	UV value;
	int result;
    PPCODE:
	EXTEND(SP,2);
	result = grok_number(pv, len, &value);
	PUSHs(sv_2mortal(newSViv(result)));
	if (result & IS_NUMBER_IN_UV)
	    PUSHs(sv_2mortal(newSVuv(value)));

void
grok_number_flags(number, flags)
	SV *number
	U32 flags
    PREINIT:
	STRLEN len;
	const char *pv = SvPV(number, len);
	UV value;
	int result;
    PPCODE:
	EXTEND(SP,2);
	result = grok_number_flags(pv, len, &value, flags);
	PUSHs(sv_2mortal(newSViv(result)));
	if (result & IS_NUMBER_IN_UV)
	    PUSHs(sv_2mortal(newSVuv(value)));

void
grok_atou(number, endsv)
	SV *number
	SV *endsv
    PREINIT:
	STRLEN len;
	const char *pv = SvPV(number, len);
	UV result;
	const char* endptr;
    PPCODE:
	EXTEND(SP,2);
	if (endsv == &PL_sv_undef) {
          result = grok_atou(pv, NULL);
        } else {
          result = grok_atou(pv, &endptr);
        }
	PUSHs(sv_2mortal(newSVuv(result)));
	if (endsv == &PL_sv_undef) {
          PUSHs(sv_2mortal(newSVpvn(NULL, 0)));
	} else {
	  if (endptr) {
	    PUSHs(sv_2mortal(newSViv(endptr - pv)));
	  } else {
	    PUSHs(sv_2mortal(newSViv(0)));
	  }
	}
