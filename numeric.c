/*    numeric.c
 *
 *    Copyright (c) 2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "That only makes eleven (plus one mislaid) and not fourteen, unless
 * wizards count differently to other people."
 */

#include "EXTERN.h"
#define PERL_IN_NUMERIC_C
#include "perl.h"

U32
Perl_cast_ulong(pTHX_ NV f)
{
  if (f < 0.0)
    return f < I32_MIN ? (U32) I32_MIN : (U32)(I32) f;
  if (f < U32_MAX_P1) {
#if CASTFLAGS & 2
    if (f < U32_MAX_P1_HALF)
      return (U32) f;
    f -= U32_MAX_P1_HALF;
    return ((U32) f) | (1 + U32_MAX >> 1);
#else
    return (U32) f;
#endif
  }
  return f > 0 ? U32_MAX : 0 /* NaN */;
}

I32
Perl_cast_i32(pTHX_ NV f)
{
  if (f < I32_MAX_P1)
    return f < I32_MIN ? I32_MIN : (I32) f;
  if (f < U32_MAX_P1) {
#if CASTFLAGS & 2
    if (f < U32_MAX_P1_HALF)
      return (I32)(U32) f;
    f -= U32_MAX_P1_HALF;
    return (I32)(((U32) f) | (1 + U32_MAX >> 1));
#else
    return (I32)(U32) f;
#endif
  }
  return f > 0 ? (I32)U32_MAX : 0 /* NaN */;
}

IV
Perl_cast_iv(pTHX_ NV f)
{
  if (f < IV_MAX_P1)
    return f < IV_MIN ? IV_MIN : (IV) f;
  if (f < UV_MAX_P1) {
#if CASTFLAGS & 2
    /* For future flexibility allowing for sizeof(UV) >= sizeof(IV)  */
    if (f < UV_MAX_P1_HALF)
      return (IV)(UV) f;
    f -= UV_MAX_P1_HALF;
    return (IV)(((UV) f) | (1 + UV_MAX >> 1));
#else
    return (IV)(UV) f;
#endif
  }
  return f > 0 ? (IV)UV_MAX : 0 /* NaN */;
}

UV
Perl_cast_uv(pTHX_ NV f)
{
  if (f < 0.0)
    return f < IV_MIN ? (UV) IV_MIN : (UV)(IV) f;
  if (f < UV_MAX_P1) {
#if CASTFLAGS & 2
    if (f < UV_MAX_P1_HALF)
      return (UV) f;
    f -= UV_MAX_P1_HALF;
    return ((UV) f) | (1 + UV_MAX >> 1);
#else
    return (UV) f;
#endif
  }
  return f > 0 ? UV_MAX : 0 /* NaN */;
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

NV
Perl_scan_bin(pTHX_ char *start, STRLEN len, STRLEN *retlen)
{
    register char *s = start;
    register NV rnv = 0.0;
    register UV ruv = 0;
    register bool seenb = FALSE;
    register bool overflowed = FALSE;

    for (; len-- && *s; s++) {
	if (!(*s == '0' || *s == '1')) {
	    if (*s == '_' && len && *retlen
		&& (s[1] == '0' || s[1] == '1'))
	    {
		--len;
		++s;
	    }
	    else if (seenb == FALSE && *s == 'b' && ruv == 0) {
		/* Disallow 0bbb0b0bbb... */
		seenb = TRUE;
		continue;
	    }
	    else {
		if (ckWARN(WARN_DIGIT))
		    Perl_warner(aTHX_ WARN_DIGIT,
				"Illegal binary digit '%c' ignored", *s);
		break;
	    }
	}
	if (!overflowed) {
	    register UV xuv = ruv << 1;

	    if ((xuv >> 1) != ruv) {
		overflowed = TRUE;
		rnv = (NV) ruv;
		if (ckWARN_d(WARN_OVERFLOW))
		    Perl_warner(aTHX_ WARN_OVERFLOW,
				"Integer overflow in binary number");
	    }
	    else
		ruv = xuv | (*s - '0');
	}
	if (overflowed) {
	    rnv *= 2;
	    /* If an NV has not enough bits in its mantissa to
	     * represent an UV this summing of small low-order numbers
	     * is a waste of time (because the NV cannot preserve
	     * the low-order bits anyway): we could just remember when
	     * did we overflow and in the end just multiply rnv by the
	     * right amount. */
	    rnv += (*s - '0');
	}
    }
    if (!overflowed)
	rnv = (NV) ruv;
    if (   ( overflowed && rnv > 4294967295.0)
#if UVSIZE > 4
	|| (!overflowed && ruv > 0xffffffff  )
#endif
	) {
	if (ckWARN(WARN_PORTABLE))
	    Perl_warner(aTHX_ WARN_PORTABLE,
			"Binary number > 0b11111111111111111111111111111111 non-portable");
    }
    *retlen = s - start;
    return rnv;
}

NV
Perl_scan_oct(pTHX_ char *start, STRLEN len, STRLEN *retlen)
{
    register char *s = start;
    register NV rnv = 0.0;
    register UV ruv = 0;
    register bool overflowed = FALSE;

    for (; len-- && *s; s++) {
	if (!(*s >= '0' && *s <= '7')) {
	    if (*s == '_' && len && *retlen
		&& (s[1] >= '0' && s[1] <= '7'))
	    {
		--len;
		++s;
	    }
	    else {
		/* Allow \octal to work the DWIM way (that is, stop scanning
		 * as soon as non-octal characters are seen, complain only iff
		 * someone seems to want to use the digits eight and nine). */
		if (*s == '8' || *s == '9') {
		    if (ckWARN(WARN_DIGIT))
			Perl_warner(aTHX_ WARN_DIGIT,
				    "Illegal octal digit '%c' ignored", *s);
		}
		break;
	    }
	}
	if (!overflowed) {
	    register UV xuv = ruv << 3;

	    if ((xuv >> 3) != ruv) {
		overflowed = TRUE;
		rnv = (NV) ruv;
		if (ckWARN_d(WARN_OVERFLOW))
		    Perl_warner(aTHX_ WARN_OVERFLOW,
				"Integer overflow in octal number");
	    }
	    else
		ruv = xuv | (*s - '0');
	}
	if (overflowed) {
	    rnv *= 8.0;
	    /* If an NV has not enough bits in its mantissa to
	     * represent an UV this summing of small low-order numbers
	     * is a waste of time (because the NV cannot preserve
	     * the low-order bits anyway): we could just remember when
	     * did we overflow and in the end just multiply rnv by the
	     * right amount of 8-tuples. */
	    rnv += (NV)(*s - '0');
	}
    }
    if (!overflowed)
	rnv = (NV) ruv;
    if (   ( overflowed && rnv > 4294967295.0)
#if UVSIZE > 4
	|| (!overflowed && ruv > 0xffffffff  )
#endif
	) {
	if (ckWARN(WARN_PORTABLE))
	    Perl_warner(aTHX_ WARN_PORTABLE,
			"Octal number > 037777777777 non-portable");
    }
    *retlen = s - start;
    return rnv;
}

NV
Perl_scan_hex(pTHX_ char *start, STRLEN len, STRLEN *retlen)
{
    register char *s = start;
    register NV rnv = 0.0;
    register UV ruv = 0;
    register bool overflowed = FALSE;
    char *hexdigit;

    if (len > 2) {
	if (s[0] == 'x') {
	    s++;
	    len--;
	}
	else if (len > 3 && s[0] == '0' && s[1] == 'x') {
	    s+=2;
	    len-=2;
	}
    }

    for (; len-- && *s; s++) {
	hexdigit = strchr((char *) PL_hexdigit, *s);
	if (!hexdigit) {
	    if (*s == '_' && len && *retlen && s[1]
		&& (hexdigit = strchr((char *) PL_hexdigit, s[1])))
	    {
		--len;
		++s;
	    }
	    else {
		if (ckWARN(WARN_DIGIT))
		    Perl_warner(aTHX_ WARN_DIGIT,
				"Illegal hexadecimal digit '%c' ignored", *s);
		break;
	    }
	}
	if (!overflowed) {
	    register UV xuv = ruv << 4;

	    if ((xuv >> 4) != ruv) {
		overflowed = TRUE;
		rnv = (NV) ruv;
		if (ckWARN_d(WARN_OVERFLOW))
		    Perl_warner(aTHX_ WARN_OVERFLOW,
				"Integer overflow in hexadecimal number");
	    }
	    else
		ruv = xuv | ((hexdigit - PL_hexdigit) & 15);
	}
	if (overflowed) {
	    rnv *= 16.0;
	    /* If an NV has not enough bits in its mantissa to
	     * represent an UV this summing of small low-order numbers
	     * is a waste of time (because the NV cannot preserve
	     * the low-order bits anyway): we could just remember when
	     * did we overflow and in the end just multiply rnv by the
	     * right amount of 16-tuples. */
	    rnv += (NV)((hexdigit - PL_hexdigit) & 15);
	}
    }
    if (!overflowed)
	rnv = (NV) ruv;
    if (   ( overflowed && rnv > 4294967295.0)
#if UVSIZE > 4
	|| (!overflowed && ruv > 0xffffffff  )
#endif
	) {
	if (ckWARN(WARN_PORTABLE))
	    Perl_warner(aTHX_ WARN_PORTABLE,
			"Hexadecimal number > 0xffffffff non-portable");
    }
    *retlen = s - start;
    return rnv;
}

/*
=for apidoc grok_numeric_radix

Scan and skip for a numeric decimal separator (radix).

=cut
 */
bool
Perl_grok_numeric_radix(pTHX_ const char **sp, const char *send)
{
#ifdef USE_LOCALE_NUMERIC
    if (PL_numeric_radix_sv && IN_LOCALE) { 
        STRLEN len;
        char* radix = SvPV(PL_numeric_radix_sv, len);
        if (*sp + len <= send && memEQ(*sp, radix, len)) {
            *sp += len;
            return TRUE; 
        }
    }
    /* always try "." if numeric radix didn't match because
     * we may have data from different locales mixed */
#endif
    if (*sp < send && **sp == '.') {
        ++*sp;
        return TRUE;
    }
    return FALSE;
}

/*
=for apidoc grok_number

Recognise (or not) a number.  The type of the number is returned
(0 if unrecognised), otherwise it is a bit-ORed combination of
IS_NUMBER_IN_UV, IS_NUMBER_GREATER_THAN_UV_MAX, IS_NUMBER_NOT_INT,
IS_NUMBER_NEG, IS_NUMBER_INFINITY, IS_NUMBER_NAN (defined in perl.h).

If the value of the number can fit an in UV, it is returned in the *valuep
IS_NUMBER_IN_UV will be set to indicate that *valuep is valid, IS_NUMBER_IN_UV
will never be set unless *valuep is valid, but *valuep may have been assigned
to during processing even though IS_NUMBER_IN_UV is not set on return.
If valuep is NULL, IS_NUMBER_IN_UV will be set for the same cases as when
valuep is non-NULL, but no actual assignment (or SEGV) will occur.

IS_NUMBER_NOT_INT will be set with IS_NUMBER_IN_UV if trailing decimals were
seen (in which case *valuep gives the true value truncated to an integer), and
IS_NUMBER_NEG if the number is negative (in which case *valuep holds the
absolute value).  IS_NUMBER_IN_UV is not set if e notation was used or the
number is larger than a UV.

=cut
 */
int
Perl_grok_number(pTHX_ const char *pv, STRLEN len, UV *valuep)
{
  const char *s = pv;
  const char *send = pv + len;
  const UV max_div_10 = UV_MAX / 10;
  const char max_mod_10 = UV_MAX % 10;
  int numtype = 0;
  int sawinf = 0;
  int sawnan = 0;

  while (s < send && isSPACE(*s))
    s++;
  if (s == send) {
    return 0;
  } else if (*s == '-') {
    s++;
    numtype = IS_NUMBER_NEG;
  }
  else if (*s == '+')
  s++;

  if (s == send)
    return 0;

  /* next must be digit or the radix separator or beginning of infinity */
  if (isDIGIT(*s)) {
    /* UVs are at least 32 bits, so the first 9 decimal digits cannot
       overflow.  */
    UV value = *s - '0';
    /* This construction seems to be more optimiser friendly.
       (without it gcc does the isDIGIT test and the *s - '0' separately)
       With it gcc on arm is managing 6 instructions (6 cycles) per digit.
       In theory the optimiser could deduce how far to unroll the loop
       before checking for overflow.  */
    if (++s < send) {
      int digit = *s - '0';
      if (digit >= 0 && digit <= 9) {
        value = value * 10 + digit;
        if (++s < send) {
          digit = *s - '0';
          if (digit >= 0 && digit <= 9) {
            value = value * 10 + digit;
            if (++s < send) {
              digit = *s - '0';
              if (digit >= 0 && digit <= 9) {
                value = value * 10 + digit;
		if (++s < send) {
                  digit = *s - '0';
                  if (digit >= 0 && digit <= 9) {
                    value = value * 10 + digit;
                    if (++s < send) {
                      digit = *s - '0';
                      if (digit >= 0 && digit <= 9) {
                        value = value * 10 + digit;
                        if (++s < send) {
                          digit = *s - '0';
                          if (digit >= 0 && digit <= 9) {
                            value = value * 10 + digit;
                            if (++s < send) {
                              digit = *s - '0';
                              if (digit >= 0 && digit <= 9) {
                                value = value * 10 + digit;
                                if (++s < send) {
                                  digit = *s - '0';
                                  if (digit >= 0 && digit <= 9) {
                                    value = value * 10 + digit;
                                    if (++s < send) {
                                      /* Now got 9 digits, so need to check
                                         each time for overflow.  */
                                      digit = *s - '0';
                                      while (digit >= 0 && digit <= 9
                                             && (value < max_div_10
                                                 || (value == max_div_10
                                                     && digit <= max_mod_10))) {
                                        value = value * 10 + digit;
                                        if (++s < send)
                                          digit = *s - '0';
                                        else
                                          break;
                                      }
                                      if (digit >= 0 && digit <= 9
                                          && (s < send)) {
                                        /* value overflowed.
                                           skip the remaining digits, don't
                                           worry about setting *valuep.  */
                                        do {
                                          s++;
                                        } while (s < send && isDIGIT(*s));
                                        numtype |=
                                          IS_NUMBER_GREATER_THAN_UV_MAX;
                                        goto skip_value;
                                      }
                                    }
                                  }
				}
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
	}
      }
    }
    numtype |= IS_NUMBER_IN_UV;
    if (valuep)
      *valuep = value;

  skip_value:
    if (GROK_NUMERIC_RADIX(&s, send)) {
      numtype |= IS_NUMBER_NOT_INT;
      while (s < send && isDIGIT(*s))  /* optional digits after the radix */
        s++;
    }
  }
  else if (GROK_NUMERIC_RADIX(&s, send)) {
    numtype |= IS_NUMBER_NOT_INT | IS_NUMBER_IN_UV; /* valuep assigned below */
    /* no digits before the radix means we need digits after it */
    if (s < send && isDIGIT(*s)) {
      do {
        s++;
      } while (s < send && isDIGIT(*s));
      if (valuep) {
        /* integer approximation is valid - it's 0.  */
        *valuep = 0;
      }
    }
    else
      return 0;
  } else if (*s == 'I' || *s == 'i') {
    s++; if (s == send || (*s != 'N' && *s != 'n')) return 0;
    s++; if (s == send || (*s != 'F' && *s != 'f')) return 0;
    s++; if (s < send && (*s == 'I' || *s == 'i')) {
      s++; if (s == send || (*s != 'N' && *s != 'n')) return 0;
      s++; if (s == send || (*s != 'I' && *s != 'i')) return 0;
      s++; if (s == send || (*s != 'T' && *s != 't')) return 0;
      s++; if (s == send || (*s != 'Y' && *s != 'y')) return 0;
      s++;
    }
    sawinf = 1;
  } else if (*s == 'N' || *s == 'n') {
    /* XXX TODO: There are signaling NaNs and quiet NaNs. */
    s++; if (s == send || (*s != 'A' && *s != 'a')) return 0;
    s++; if (s == send || (*s != 'N' && *s != 'n')) return 0;
    s++;
    sawnan = 1;
  } else
    return 0;

  if (sawinf) {
    numtype &= IS_NUMBER_NEG; /* Keep track of sign  */
    numtype |= IS_NUMBER_INFINITY | IS_NUMBER_NOT_INT;
  } else if (sawnan) {
    numtype &= IS_NUMBER_NEG; /* Keep track of sign  */
    numtype |= IS_NUMBER_NAN | IS_NUMBER_NOT_INT;
  } else if (s < send) {
    /* we can have an optional exponent part */
    if (*s == 'e' || *s == 'E') {
      /* The only flag we keep is sign.  Blow away any "it's UV"  */
      numtype &= IS_NUMBER_NEG;
      numtype |= IS_NUMBER_NOT_INT;
      s++;
      if (s < send && (*s == '-' || *s == '+'))
        s++;
      if (s < send && isDIGIT(*s)) {
        do {
          s++;
        } while (s < send && isDIGIT(*s));
      }
      else
      return 0;
    }
  }
  while (s < send && isSPACE(*s))
    s++;
  if (s >= send)
    return numtype;
  if (len == 10 && memEQ(pv, "0 but true", 10)) {
    if (valuep)
      *valuep = 0;
    return IS_NUMBER_IN_UV;
  }
  return 0;
}

NV
S_mulexp10(NV value, I32 exponent)
{
    NV result = 1.0;
    NV power = 10.0;
    bool negative = 0;
    I32 bit;

    if (exponent == 0)
	return value;
    else if (exponent < 0) {
	negative = 1;
	exponent = -exponent;
    }
    for (bit = 1; exponent; bit <<= 1) {
	if (exponent & bit) {
	    exponent ^= bit;
	    result *= power;
	}
	/* Floating point exceptions are supposed to be turned off. */
	power *= power;
    }
    return negative ? value / result : value * result;
}

NV
Perl_my_atof(pTHX_ const char* s)
{
    NV x = 0.0;
#ifdef USE_LOCALE_NUMERIC
    if (PL_numeric_local && IN_LOCALE) {
	NV y;

	/* Scan the number twice; once using locale and once without;
	 * choose the larger result (in absolute value). */
	Perl_atof2(aTHX_ s, &x);
	SET_NUMERIC_STANDARD();
	Perl_atof2(aTHX_ s, &y);
	SET_NUMERIC_LOCAL();
	if ((y < 0.0 && y < x) || (y > 0.0 && y > x))
	    return y;
    }
    else
	Perl_atof2(aTHX_ s, &x);
#else
    Perl_atof2(aTHX_ s, &x);
#endif
    return x;
}

char*
Perl_my_atof2(pTHX_ const char* orig, NV* value)
{
    NV result = 0.0;
    bool negative = 0;
    char* s = (char*)orig;
    char* send = s + strlen(orig) - 1;
    bool seendigit = 0;
    I32 expextra = 0;
    I32 exponent = 0;
    I32 i;
/* this is arbitrary */
#define PARTLIM 6
/* we want the largest integers we can usefully use */
#if defined(HAS_QUAD) && defined(USE_64_BIT_INT)
#   define PARTSIZE ((int)TYPE_DIGITS(U64)-1)
    U64 part[PARTLIM];
#else
#   define PARTSIZE ((int)TYPE_DIGITS(U32)-1)
    U32 part[PARTLIM];
#endif
    I32 ipart = 0;	/* index into part[] */
    I32 offcount;	/* number of digits in least significant part */

    /* leading whitespace */
    while (isSPACE(*s))
	++s;

    /* sign */
    switch (*s) {
	case '-':
	    negative = 1;
	    /* fall through */
	case '+':
	    ++s;
    }

    part[0] = offcount = 0;
    if (isDIGIT(*s)) {
	seendigit = 1;	/* get this over with */

	/* skip leading zeros */
	while (*s == '0')
	    ++s;
    }

    /* integer digits */
    while (isDIGIT(*s)) {
	if (++offcount > PARTSIZE) {
	    if (++ipart < PARTLIM) {
		part[ipart] = 0;
		offcount = 1;	/* ++0 */
	    }
	    else {
		/* limits of precision reached */
		--ipart;
		--offcount;
		if (*s >= '5')
		    ++part[ipart];
		while (isDIGIT(*s)) {
		    ++expextra;
		    ++s;
		}
		/* warn of loss of precision? */
		break;
	    }
	}
	part[ipart] = part[ipart] * 10 + (*s++ - '0');
    }

    /* decimal point */
    if (GROK_NUMERIC_RADIX((const char **)&s, send)) {
	if (isDIGIT(*s))
	    seendigit = 1;	/* get this over with */

	/* decimal digits */
	while (isDIGIT(*s)) {
	    if (++offcount > PARTSIZE) {
		if (++ipart < PARTLIM) {
		    part[ipart] = 0;
		    offcount = 1;	/* ++0 */
		}
		else {
		    /* limits of precision reached */
		    --ipart;
		    --offcount;
		    if (*s >= '5')
			++part[ipart];
		    while (isDIGIT(*s))
			++s;
		    /* warn of loss of precision? */
		    break;
		}
	    }
	    --expextra;
	    part[ipart] = part[ipart] * 10 + (*s++ - '0');
	}
    }

    /* combine components of mantissa */
    for (i = 0; i <= ipart; ++i)
	result += S_mulexp10((NV)part[ipart - i],
		i ? offcount + (i - 1) * PARTSIZE : 0);

    if (seendigit && (*s == 'e' || *s == 'E')) {
	bool expnegative = 0;

	++s;
	switch (*s) {
	    case '-':
		expnegative = 1;
		/* fall through */
	    case '+':
		++s;
	}
	while (isDIGIT(*s))
	    exponent = exponent * 10 + (*s++ - '0');
	if (expnegative)
	    exponent = -exponent;
    }

    /* now apply the exponent */
    exponent += expextra;
    result = S_mulexp10(result, exponent);

    /* now apply the sign */
    if (negative)
	result = -result;
    *value = result;
    return s;
}

