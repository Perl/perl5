/*    numeric.c
 *
 *    Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001,
 *    2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "That only makes eleven (plus one mislaid) and not fourteen,
 *  unless wizards count differently to other people."  --Beorn
 *
 *     [p.115 of _The Hobbit_: "Queer Lodgings"]
 */

/*

This file contains all the stuff needed by perl for manipulating numeric
values, including such things as replacements for the OS's atof() function

*/

#include "EXTERN.h"
#define PERL_IN_NUMERIC_C
#include "perl.h"

#ifdef Perl_strtod

PERL_STATIC_INLINE NV
S_strtod(pTHX_ const char * const s, char ** e)
{
    DECLARATION_FOR_LC_NUMERIC_MANIPULATION;
    NV result;

    STORE_LC_NUMERIC_SET_TO_NEEDED();

#  ifdef USE_QUADMATH

    result = strtoflt128(s, e);

#  elif defined(HAS_STRTOLD) && defined(HAS_LONG_DOUBLE)    \
                             && defined(USE_LONG_DOUBLE)
#    if defined(__MINGW64_VERSION_MAJOR)
      /***********************************************
       We are unable to use strtold because of
        https://sourceforge.net/p/mingw-w64/bugs/711/
        &
        https://sourceforge.net/p/mingw-w64/bugs/725/

       but __mingw_strtold is fine.
      ***********************************************/

    result = __mingw_strtold(s, e);

#    else

    result = strtold(s, e);

#    endif
#  elif defined(HAS_STRTOD)

    result = strtod(s, e);

#  else
#    error No strtod() equivalent found
#  endif

    RESTORE_LC_NUMERIC();

    return result;
}

#endif  /* #ifdef Perl_strtod */

/*

=for apidoc      my_strtod
=for apidoc_item Strtod

These are identical.

They act like the libc C<L<strtod(3)>> function, with three exceptions:

=over

=item 1.

Their return value is an NV.  Plain C<strod> returns a double precision value.

=item 2.

Plain C<strtod> always is expecting the radix character (or string) to be the
one specified by the underlying locale the program is executing in.  This is
almost universally a dot (U+002E) or a comma (U+002C).

In contrast, these expect the radix to be a dot, except when called from within
the scope of S<C<use locale>>, in which case they act like plain C<strtod>,
expecting the radix to be that specified by the current locale.

=item 3.

These are are available even on platforms that lack plain strtod().

=back

=cut

*/

NV
Perl_my_strtod(const char * const s, char **e)
{
    PERL_ARGS_ASSERT_MY_STRTOD;

    dTHX;

#ifdef Perl_strtod

    return S_strtod(aTHX_ s, e);

#else

    {
        NV result;
        char * end_ptr;

        end_ptr = my_atof2(s, &result);
        if (e) {
            *e = end_ptr;
        }

        if (! end_ptr) {
            result = 0.0;
        }

        return result;
    }

#endif

}


U32
Perl_cast_ulong(NV f)
{
    PERL_ARGS_ASSERT_CAST_ULONG;

  if (f < 0.0)
    return f < I32_MIN ? (U32) I32_MIN : (U32)(I32) f;
  if (f < U32_MAX_P1) {
#if CASTFLAGS & 2
    if (f < U32_MAX_P1_HALF)
      return (U32) f;
    f -= U32_MAX_P1_HALF;
    return ((U32) f) | (1 + (U32_MAX >> 1));
#else
    return (U32) f;
#endif
  }
  return f > 0 ? U32_MAX : 0 /* NaN */;
}

I32
Perl_cast_i32(NV f)
{
    PERL_ARGS_ASSERT_CAST_I32;

  if (f < I32_MAX_P1)
    return f < I32_MIN ? I32_MIN : (I32) f;
  if (f < U32_MAX_P1) {
#if CASTFLAGS & 2
    if (f < U32_MAX_P1_HALF)
      return (I32)(U32) f;
    f -= U32_MAX_P1_HALF;
    return (I32)(((U32) f) | (1 + (U32_MAX >> 1)));
#else
    return (I32)(U32) f;
#endif
  }
  return f > 0 ? (I32)U32_MAX : 0 /* NaN */;
}

IV
Perl_cast_iv(NV f)
{
    PERL_ARGS_ASSERT_CAST_IV;

  if (f < IV_MAX_P1)
    return f < IV_MIN ? IV_MIN : (IV) f;
  if (f < UV_MAX_P1) {
#if CASTFLAGS & 2
    /* For future flexibility allowing for sizeof(UV) >= sizeof(IV)  */
    if (f < UV_MAX_P1_HALF)
      return (IV)(UV) f;
    f -= UV_MAX_P1_HALF;
    return (IV)(((UV) f) | (1 + (UV_MAX >> 1)));
#else
    return (IV)(UV) f;
#endif
  }
  return f > 0 ? (IV)UV_MAX : 0 /* NaN */;
}

UV
Perl_cast_uv(NV f)
{
    PERL_ARGS_ASSERT_CAST_UV;

  if (f < 0.0)
    return f < IV_MIN ? (UV) IV_MIN : (UV)(IV) f;
  if (f < UV_MAX_P1) {
#if CASTFLAGS & 2
    if (f < UV_MAX_P1_HALF)
      return (UV) f;
    f -= UV_MAX_P1_HALF;
    return ((UV) f) | (1 + (UV_MAX >> 1));
#else
    return (UV) f;
#endif
  }
  return f > 0 ? UV_MAX : 0 /* NaN */;
}

void
Perl_output_non_portable(pTHX_ const U8 base)
{
    PERL_ARGS_ASSERT_OUTPUT_NON_PORTABLE;

    /* Display the proper message for a number in the given input base not
     * fitting in 32 bits */
    const char * which;
    switch (base) {
      case 2:
        which = "Binary number > 0b11111111111111111111111111111111";
        break;
      case 8:
        which = "Octal number > 037777777777";
        break;
      case 10:
        return;
        /* Historically no warnings of this type have been output for decimals
         * which = "Decimal number > 4294967295 (0xffff_ffff)";
         */
        break;
      case 16:
        which = "Hexadecimal number > 0xffffffff";
        break;
      default:
        croak("panic: Unexpected numeric base %d", base);
    }

    /* Also there are diag listings for the others.  That's because, since
     * %s is the first thing in the message, it would be hard for a user to
     * find them there */
    /* diag_listed_as: Hexadecimal number > 0xffffffff non-portable */
    ck_warner(packWARN(WARN_PORTABLE), "%s non-portable", which);
}

UV
Perl_grok_bin_hex(pTHX_ const char * const start,
                        STRLEN *len_p,
                        I32 *flags,
                        NV *approximation,
                        uint_fast8_t base,  /* 2 or 16 */
                        const U32 lookup_bit,
                        const char prefix       /* 'b' or 'x' */
                 )
{
    PERL_ARGS_ASSERT_GROK_BIN_HEX;
    assert(base == 2 || base == 16);

    /* Parse an optional 0b or 0x prefix to the number if the flags don't
     * forbid these, then call grok_bin_oct_hex() with the parse set to beyond
     * these prefixes */

    uint_fast8_t offset = 0;

    if (!(*flags & PERL_SCAN_DISALLOW_PREFIX)) {
        const char * e = start + *len_p;

        /* strip off leading b or 0b; x or 0x.
           for compatibility silently suffer "b" and "0b" as valid binary; "x"
           and "0x" as valid hex numbers. */
        if (e - start > 1) {
            if (isALPHA_FOLD_EQ(start[0], prefix)) {
                offset = 1;
            }
            else if (   e - start > 2
                     && start[0] == '0'
                     && (isALPHA_FOLD_EQ(start[1], prefix)))
            {
                offset = 2;
            }
        }
    }

    return grok_uint_by_base(start, len_p, flags, approximation,
                            base, lookup_bit, offset);
}

/* An acceptable underscore must not be trailing, which also implies there
 * must be a legal digit after it */
#define underscore_valid(s, e, lookup_bit)                                  \
                            (s < e - 1 && Perl_isCC_by_bit(s[1], lookup_bit))


UV
Perl_grok_uint_by_base(pTHX_ const char * const start,
                        STRLEN *len_p,
                        I32 *flags,
                        NV *approximation,
                        uint_fast8_t base,
                        const U32 lookup_bit,
                        uint_fast8_t offset /* parse starting at start+offset */
                     )

{
    PERL_ARGS_ASSERT_GROK_UINT_BY_BASE;
    ASSUME(   base == 10
           || (isPOWER_OF_2(base) && inRANGE(base, 2, 16) && base != 4));

/*

=for apidoc      grok_uint_by_base

Parses a string purportedly containing ASCII digit characters in the numeric
base passed in as 'base', and translates it to a non-negative integer, if
possible, which it returns.  The base is any of 2, 8, 10, or 16.  The string
to be parsed starts at 'start' and has length *len_p bytes.  If *len_p is 0, 0
is returned without complaint.

It stops parsing when it reaches *len_p bytes, or at the first illegal
character.  Legal characters include any digit in the given base and, if
permitted by flags, underscores in restricted positions. It returns in
*len_p the actual number of bytes parsed.  If it stopped parsing early,
it raises a warning unless the caller has set the PERL_SCAN_SILENT_ILLDIGIT
bit in *flags.  The flag is cleared if no illegal character is found,
otherwise it will remain set on output.

If the resultant integer won't fit in a UV, UV_MAX is returned, and *flags
will contain the PERL_SCAN_NUMBER_OVERFLOWED bit. If 'approximation' is not
NULL, an NV approximation to the full integer will be placed into
*approximation.  And for bases 2, 8, 16, it raises a warning unless the
caller has set the PERL_SCAN_SILENT_OVERFLOW bit in *flags.

Note that *approximation is not changed unless overflow occurs.

For non-base10 operations, by default, a warning is raised for numbers
that don't overflow but exceed 32 bits in width.  This is suppressed if
the caller has set the PERL_SCAN_SILENT_NON_PORTABLE bit in *flags.

The function can silently accept (and otherwise ignore) underscores as well as
digits if the caller has set the PERL_SCAN_ALLOW_UNDERSCORES bit in *flags.
These are a single underscore between any two digits, and additionally an
initial underscore.

The function takes great care to make any overflowing approximation as
accurate as possible given the platform's limitations.

Attention has been paid to maximizing performance, but some compromises
have been made because it is the unification of grok_bin, grok_oct,
grok_hex and grok_decimal (if that existed).  The unification was done
because over time, patches had been applied to one or another of the
individual functions, causing them to drift apart.  Another solution
would be to have a regen script that starts with a single template and
customizes each one.  Here are the compromises that could matter.

=over

=item *

Each digit calculation uses XDIGIT_VALUE(), which, to accomodate hex values,
has extra bit operations not otherwise needed.  This macro replaces a
subtraction with 2 shifts, 2 additions, and 3 masks

=item *

To accommodate base 10, each digit calculation uses an integer multiply and an
addition instead of a bitwise shift and 'or'.

=item *

The main switch() statement could have more case statements for non-hex bases.

=back

There is a special mode that functions as an alternative to overflowing.  It
is triggered by the caller setting PERL_SCAN_DISCARD_INSTEAD_OF_OVERFLOW into
*flags.  Should overflow otherwise occur, subsequent digits are instead simply
discarded, while rounding the result towards even.  *approximation is not
changed if this flag is set.

=cut

Other compromises kick in only when the result is within a digit of overflowing.

*/

#if UVSIZE > 4
    I32 input_flags = *flags;
#else
    /* Only overflow can be non-portable on this platform, and that turns off
     * this flag unconditionally */
    I32 input_flags = *flags | PERL_SCAN_SILENT_NON_PORTABLE;
#endif

    /* Clear output flags; unlikely to find a problem that sets them */
    *flags = 0;

    const bool allow_underscores =
             cBOOL(input_flags & ( PERL_SCAN_ALLOW_UNDERSCORES
                                  |PERL_SCAN_ALLOW_MEDIAL_UNDERSCORES_ONLY));
    const char * s = start + offset;
    const char * e = start + *len_p;

    const char * const s0 = s;  /* Where the significant digits start */
    UV accumulated = 0;         /* Running total */

    /* Highest value where one more hex digit will still fit and not overflow.
     * */
    const UV base16_max_div = UV_MAX / 16;

    /* MULTIPLY_BY_BASE(value) multiplies 'value' by the input base */
#define MULTIPLY_BY_BASE(value)  (((value) * base))

    /* Unroll the loop so that numbers with 8 or fewer digits can be handled
     * with the minimum amount of work.  Anything higher would require extra
     * overhead to deal with the possibility of generating portability
     * warnings for numbers above 32 bits, which is reached at 8 hex digits */
  redo_switch:
    switch (e - s) {
      default:

        /* Leading zeros are common enough to deserve a special case when
         * there are more digits than we handle in the switch.  Strip them
         * off, and try again */
        if (UNLIKELY(*s == '0')) {
            do {
                s++;
            } while (s < e && *s == '0');
            goto redo_switch;
        }

        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = XDIGIT_VALUE(*s);
        s++;
        goto loop;

      case 8:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 7:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 6:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 5:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 4:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 3:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 2:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 1:
        if (! LIKELY(Perl_isCC_by_bit(*s, lookup_bit)))  break;
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
        /* FALLTHROUGH */
      case 0:
        return accumulated;
    }   /* End of switch on the first so-many characters */

    /* To get here, there was an unexpected character in the input (including
     * an underscore, which is optionally acceptable). */
    if (*s != '_' || ! allow_underscores) {
        goto done_parse;
    }

    /* An acceptable initial underscore has to have the right flag */
    if (s == s0 && (input_flags & PERL_SCAN_ALLOW_MEDIAL_UNDERSCORES_ONLY)) {
        goto done_parse;
    }

    if (! underscore_valid(s, e, lookup_bit)) {
        goto done_parse;
    }

    /* underscore_valid() succeeds only if the next char is a legal digit */
    s++;

    /* If we haven't seen any non-zero digits yet, we can jump back in to the
     * switch() without fear of exceeding the portability limits */
    if (UNLIKELY(accumulated == 0)) {
        goto redo_switch;
    }

    /* Here s points to a legal digit.  We can save some operations by
     * accumulating it now, and positioning the loop to start on the next
     * character (whose value is unknown here). */
    accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
    s++;

  loop: ;

    /* Here, 'accumulated' contains the running total so far in the input,
     * and 's' points to the next character.
     *
     * The loop below accumulates the integral running total of the result,
     * digit by digit.
     *
     * As long as the running total is less than this, the next digit will
     * fit. */
    UV max_div;
    max_div = base16_max_div;
    U32 valid_digit_or_underscore_bits;

    valid_digit_or_underscore_bits = (lookup_bit|CC_mask_(CC_UNDERSCORE_));

    /* Loop through the characters */
    while (s < e && Perl_isCC_by_bit(*s, valid_digit_or_underscore_bits)) {

        /* Handle non-trailing underscores when those are accepted */
        if (UNLIKELY(*s == '_')) {
            if (   ! allow_underscores
                || ! underscore_valid(s, e, lookup_bit))
            {
                break;
            }

            /* underscore_valid() succeeds only if the next char is a legal
             * digit */
            ++s;
        }

      check_overflow:
        if (UNLIKELY(accumulated >= max_div)) {

            /* Here we have reached overflowing or nearly overflowing for at
             * least base 16, which has the lowest such threshold of the bases
             * we handle.  For the other bases, we now set the proper upper
             * limit and try again.  (It's comparatively rare for a number to
             * be this large, so doing it here means this code won't get
             * commonly executed.) */
            if (max_div == base16_max_div) {
                switch (base) {
                  case 16: break;
                  case 10: max_div = UV_MAX / 10; goto check_overflow;
                  case 8:  max_div = UV_MAX >> 3; goto check_overflow;
                  case 2:  max_div = UV_MAX >> 1; goto check_overflow;
                  default: goto bad_base;
                }
            }

            /* If we've exceeded 'max_div' this digit is going to overflow,
             * but if equal, for all the power-of-two bases, this digit is
             * guaranteed to not overflow.  For base 10, some larger digits
             * will overflow, so have to check explicitly */
            if (   accumulated > max_div
                || (   base == 10
                    && (unsigned) XDIGIT_VALUE(*s) >
                                          UV_MAX - MULTIPLY_BY_BASE(max_div)))
            {
                goto overflowed;
            }
        }

        /* Otherwise, there is room for this digit; accumulate it and repeat
         *
         * Note XDIGIT_VALUE() is branchless, works on binary and octal as
         * well, so can be used here, without noticeably slowing those down.
         * (It does have unnecessary shifts, ANDSs, and additions for those.)
         * */
        accumulated = MULTIPLY_BY_BASE(accumulated) + XDIGIT_VALUE(*s);
        s++;
    }   /* End of parsing loop */

  done_parse:

#if UVSIZE > 4
    if (UNLIKELY(accumulated <= 0xffffffff)) {
        /* Fits in 32 bits; no warning necessary */
        input_flags |= PERL_SCAN_SILENT_NON_PORTABLE;
    }
    else {
        /* Doesn't fit; return that to caller */
        *flags |= PERL_SCAN_SILENT_NON_PORTABLE;

        /* If caller doesn't want warning raised, turn it off */
        if (! (input_flags & PERL_SCAN_SILENT_NON_PORTABLE)) {
            input_flags &= ~PERL_SCAN_SILENT_NON_PORTABLE;
        }
    }
#endif

  finish:
    if (s < e && *s) {  /* *s is to keep a terminating NUL from warning */
        if (! (input_flags & PERL_SCAN_SILENT_ILLDIGIT) && ckWARN(WARN_DIGIT))
        {
            const char * base_name;

            switch (base) {
              default: goto bad_base;
              case 2:  base_name = "binary";      break;
              case 16: base_name = "hexadecimal"; break;
              case 10: /* Base 10 historically has not raised warnings here */
                goto illegal_warning_done;
              case 8:

                /* Allow \octal to work the DWIM way (that is, stop scanning
                 * as soon as non-octal characters are seen, complain only if
                 * someone seems to want to use the digits eight and nine.
                 * Since we know it is not octal, then if isDIGIT, must be an
                 * 8 or 9). khw: XXX why not DWIM for other bases as well? */
                if (! isDIGIT(*s)) {
                    goto illegal_warning_done;
                }

                base_name = "octal";
                break;
            }

            warner(packWARN(WARN_DIGIT), "Illegal %s digit '%c' ignored",
                                         base_name, *s);
          illegal_warning_done: ;
        }

        if (input_flags & PERL_SCAN_NOTIFY_ILLDIGIT) {
            *flags |= PERL_SCAN_NOTIFY_ILLDIGIT;
        }
    }

    if (! LIKELY(input_flags & PERL_SCAN_SILENT_NON_PORTABLE)) {
        output_non_portable(base);
    }

    /* s here points to e or to the first illegal character */
    *len_p = s - start;
    return accumulated;

  bad_base:
    croak("panic: Unexpected numeric base %d", base);

  overflowed: ;

    /* Bah. We are about to overflow.  The caller may want an approximation to
     * the correct value (by passing a pointer to an NV, 'approximation'); or
     * may not want to actually overflow, but instead return the highest,
     * non-overflowing value (rounded, a flag indicates to do this, which
     * overrides also passing 'approximation').
     *
     * 's' points to the first overflowing digit. */
    UV high_order_batch;
    if (UNLIKELY(input_flags & PERL_SCAN_DISCARD_INSTEAD_OF_OVERFLOW)) {

        /* Return that it actually happened */
        *flags |= PERL_SCAN_DISCARD_INSTEAD_OF_OVERFLOW;

        /* Override this */
        approximation = NULL;
    }
    else {
        /* Here, does want overflow to happen.  Set up return, and do
         * warnings. */
        *flags |= PERL_SCAN_GREATER_THAN_UV_MAX
               |  PERL_SCAN_SILENT_NON_PORTABLE;

        if (input_flags & PERL_SCAN_SILENT_OVERFLOW) {
            *flags |= PERL_SCAN_SILENT_OVERFLOW;
        }
        else if (ckWARN_d(WARN_OVERFLOW)) {
            const char * base_name;

            switch (base) {
              default: goto bad_base;
              case 2:  base_name = "binary";      break;
              case 8:  base_name = "octal";       break;
              case 16: base_name = "hexadecimal"; break;
              case 10: /* Base 10 historically has not raised a warning here */
                goto overflow_warning_done;
            }

            warner(packWARN(WARN_OVERFLOW), "Integer overflow in %s number",
                                            base_name);
          overflow_warning_done: ;
        }

        high_order_batch = accumulated;
        accumulated = UV_MAX;
        input_flags &= ~PERL_SCAN_SILENT_NON_PORTABLE;
    }

    /* We always have to keep parsing to find the end of the intended number.
     * If we don't need to compute an approximation, we don't have to pay much
     * attention to the values */
    if (approximation == NULL) {

        /* When discarding, we round the undiscarded result to even.  In some
         * cases, whether to round isn't known until the final discarded digit
         * is processed.  This enum keeps track of that */
        enum {
                dont_round,
                yes_round_up,
                round_to_even_if_half
        } to_round = dont_round;

        if (accumulated < UV_MAX) { /* Can't round up if already at max */
            uint_fast8_t this_digit_value = XDIGIT_VALUE(*s);
            to_round = (this_digit_value < base / 2) ? dont_round
                     : (this_digit_value > base / 2) ? yes_round_up
                     : round_to_even_if_half; /* Exactly half */
        }

        /* Find end of input, seeing if need to round */
        s++;
        while (s < e && Perl_isCC_by_bit(*s, valid_digit_or_underscore_bits)) {
            if (   UNLIKELY(*s == '_')
                && (   ! allow_underscores
                    || ! underscore_valid(s, e, lookup_bit)))
            {
                break;
            }

            /* If the result is no longer exactly half, set to round up */
            if (to_round == round_to_even_if_half && *s != '0') {
                to_round = yes_round_up;
            }

            s++;
        }

        if (   to_round == yes_round_up
                /* When the final non-zero digit was exactly half the base, we
                 * round towards even, meaning don't change if already even */
            || (to_round == round_to_even_if_half && isODD(accumulated)))
        {
            accumulated++;
        }

        goto finish;
    }

    /* Here, the caller wants an approximation to the overflowed value.
     *
     * It turns out that there is less precision loss if we start at the low
     * order digits of the string and build up the number from there.  This is
     * because if we overflow multiple times, the low order digits will be so
     * small in comparison to the larger ones that they are completely
     * disregarded.  But going the other way allows them to contribute
     * whatever bits they have to offer.
     *
     * So, find the end of the string */
    const char * s1 = s;    /* Save our place */
    s++;
    while (s < e && Perl_isCC_by_bit(*s, valid_digit_or_underscore_bits)) {
        if (   UNLIKELY(*s == '_')
            && (   ! allow_underscores
                || ! underscore_valid(s, e, lookup_bit)))
        {
            break;
        }

        s++;
    }

    /* Here we got to the end of the string; either we encountered an illegal
     * character, which ends it, or got to the final position in it.  's'
     * points to the position just after the final legal character.
     *
     * Accumulate the value starting at the lowest order digit and going
     * backwards */
    const char * t = s - 1;
    NV accumulated_nv = 0;
    NV accumulated_factor = 1;

    UV this_batch_accumulated = 0;
    UV this_batch_factor = 1;

    /* To minimize precision loss, we do integer arithmetic on batches that
     * don't overflow.  When one does, the final integer that didn't overflow
     * is factored in to the running total, and a new batch is started */
    while (t >= s1) {

        /* Any underscores were already determined to be valid */
        if (UNLIKELY(*t == '_')) {
            t--;
            continue;
        }

        /* If will fit, accumulate it and repeat.  Each digit has to be
         * multiplied by the position it occupies, like 1, 8, 8-squared,
         * 8-cubed, etc */
        if (   LIKELY(this_batch_accumulated <= max_div)
            && LIKELY(this_batch_factor <= max_div))
        {
            U8 this_digit_value = XDIGIT_VALUE(*t);
            this_batch_accumulated += this_digit_value * this_batch_factor;
            this_batch_factor = MULTIPLY_BY_BASE(this_batch_factor);
            t--;
            continue;
        }

        /* Bah. We are about to overflow again.  Instead, accumulate this
         * batch into the running total for all low order batches, and start a
         * new batch. */
        accumulated_nv += this_batch_accumulated * accumulated_factor;
        accumulated_factor *= this_batch_factor;

        this_batch_accumulated = 0;
        this_batch_factor = 1;
    }

    /* Here have accumulated everything.  Combine the low order bits with the
     * high order that we have saved in 'high_order_batch'.  Those must be
     * shifted left to account for the low order ones */
    accumulated_nv += this_batch_accumulated * accumulated_factor;
    accumulated_factor *= this_batch_factor;
    accumulated_nv += high_order_batch * accumulated_factor;

    *approximation = accumulated_nv;
    goto finish;
}

/*
=for apidoc scan_bin

For backwards compatibility.  Use C<grok_bin> instead.

=for apidoc scan_hex

For backwards compatibility.  Use C<grok_hex> instead.

=for apidoc scan_oct

For backwards compatibility.  Use C<grok_oct> instead.

=cut
 */

NV
Perl_scan_bin(pTHX_ const char *start, STRLEN len, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_SCAN_BIN;

    NV rnv;
    I32 flags = *retlen ? PERL_SCAN_ALLOW_UNDERSCORES : 0;
    const UV ruv = grok_bin (start, &len, &flags, &rnv);

    *retlen = len;
    return (flags & PERL_SCAN_GREATER_THAN_UV_MAX) ? rnv : (NV)ruv;
}

NV
Perl_scan_oct(pTHX_ const char *start, STRLEN len, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_SCAN_OCT;

    NV rnv;
    I32 flags = *retlen ? PERL_SCAN_ALLOW_UNDERSCORES : 0;
    const UV ruv = grok_oct (start, &len, &flags, &rnv);

    *retlen = len;
    return (flags & PERL_SCAN_GREATER_THAN_UV_MAX) ? rnv : (NV)ruv;
}

NV
Perl_scan_hex(pTHX_ const char *start, STRLEN len, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_SCAN_HEX;

    NV rnv;
    I32 flags = *retlen ? PERL_SCAN_ALLOW_UNDERSCORES : 0;
    const UV ruv = grok_hex (start, &len, &flags, &rnv);

    *retlen = len;
    return (flags & PERL_SCAN_GREATER_THAN_UV_MAX) ? rnv : (NV)ruv;
}

/*
=for apidoc      grok_numeric_radix
=for apidoc_item GROK_NUMERIC_RADIX

These are identical.

Scan and skip for a numeric decimal separator (radix).

=cut
 */
bool
Perl_grok_numeric_radix(pTHX_ const char **sp, const char *send)
{
    PERL_ARGS_ASSERT_GROK_NUMERIC_RADIX;

#ifdef USE_LOCALE_NUMERIC

    if (IN_LC(LC_NUMERIC)) {
        STRLEN len;
        char * radix;
        bool matches_radix = FALSE;
        DECLARATION_FOR_LC_NUMERIC_MANIPULATION;

        STORE_LC_NUMERIC_FORCE_TO_UNDERLYING();

        radix = SvPV(PL_numeric_radix_sv, len);
        radix = savepvn(radix, len);

        RESTORE_LC_NUMERIC();

        if (*sp + len <= send) {
            matches_radix = memEQ(*sp, radix, len);
        }

        Safefree(radix);

        if (matches_radix) {
            *sp += len;
            return TRUE;
        }
    }

#endif

    /* always try "." if numeric radix didn't match because
     * we may have data from different locales mixed */
    if (*sp < send && **sp == '.') {
        ++*sp;
        return TRUE;
    }

    return FALSE;
}

/*
=for apidoc grok_infnan
=for apidoc_flag IS_NUMBER_GREATER_THAN_UV_MAX
=for apidoc_flag IS_NUMBER_INFINITY
=for apidoc_flag IS_NUMBER_IN_UV
=for apidoc_flag IS_NUMBER_NAN
=for apidoc_flag IS_NUMBER_NEG
=for apidoc_flag IS_NUMBER_NOT_INT

Helper for C<grok_number()>, accepts various ways of spelling "infinity"
or "not a number", and returns one of the following flag combinations:

  IS_NUMBER_INFINITY
  IS_NUMBER_NAN
  IS_NUMBER_INFINITY | IS_NUMBER_NEG
  IS_NUMBER_NAN | IS_NUMBER_NEG
  0

possibly |-ed with C<IS_NUMBER_TRAILING>.

If an infinity or a not-a-number is recognized, C<*sp> will point to
one byte past the end of the recognized string.  If the recognition fails,
zero is returned, and C<*sp> will not move.

=cut
*/

int
Perl_grok_infnan(pTHX_ const char** sp, const char* send)
{
    PERL_ARGS_ASSERT_GROK_INFNAN;

    const char* s = *sp;

    if (UNLIKELY(s >= send)) {
        return 0;
    }

    int flags = 0;
#if defined(NV_INF) || defined(NV_NAN)
    bool odh = FALSE; /* one-dot-hash: 1.#INF */

    if (*s == '+') {
        s++; if (s == send) return 0;
    }
    else if (*s == '-') {
        flags |= IS_NUMBER_NEG; /* Yes, -NaN happens. Incorrect but happens. */
        s++; if (s == send) return 0;
    }

    if (*s == '1') {
        /* Visual C: 1.#SNAN, -1.#QNAN, 1#INF, 1.#IND (maybe also 1.#NAN)
         * Let's keep the dot optional. */
        s++; if (s == send) return 0;
        if (*s == '.') {
            s++; if (s == send) return 0;
        }
        if (*s == '#') {
            s++; if (s == send) return 0;
        } else
            return 0;
        odh = TRUE;
    }

    if (isALPHA_FOLD_EQ(*s, 'I')) {
        /* INF or IND (1.#IND is "indeterminate", a certain type of NAN) */

        s++; if (s == send || isALPHA_FOLD_NE(*s, 'N')) return 0;
        s++; if (s == send) return 0;
        if (isALPHA_FOLD_EQ(*s, 'F')) {
            flags |= IS_NUMBER_INFINITY | IS_NUMBER_NOT_INT;
            *sp = ++s;
            if (s < send && (isALPHA_FOLD_EQ(*s, 'I'))) {
                int trail = flags | IS_NUMBER_TRAILING;
                s++; if (s == send || isALPHA_FOLD_NE(*s, 'N')) return trail;
                s++; if (s == send || isALPHA_FOLD_NE(*s, 'I')) return trail;
                s++; if (s == send || isALPHA_FOLD_NE(*s, 'T')) return trail;
                s++; if (s == send || isALPHA_FOLD_NE(*s, 'Y')) return trail;
                *sp = ++s;
            } else if (odh) {
                while (s < send && *s == '0') { /* 1.#INF00 */
                    s++;
                }
            }
            goto ok_check_space;
        }
        else if (isALPHA_FOLD_EQ(*s, 'D') && odh) { /* 1.#IND */
            s++;
            flags |= IS_NUMBER_NAN | IS_NUMBER_NOT_INT;
            while (s < send && *s == '0') { /* 1.#IND00 */
                s++;
            }
            goto ok_check_space;
        } else
            return 0;
    }
    else {
        /* Maybe NAN of some sort */

        if (isALPHA_FOLD_EQ(*s, 'S') || isALPHA_FOLD_EQ(*s, 'Q')) {
            /* snan, qNaN */
            /* XXX do something with the snan/qnan difference */
            s++; if (s == send) return 0;
        }

        if (isALPHA_FOLD_EQ(*s, 'N')) {
            s++; if (s == send || isALPHA_FOLD_NE(*s, 'A')) return 0;
            s++; if (s == send || isALPHA_FOLD_NE(*s, 'N')) return 0;
            flags |= IS_NUMBER_NAN | IS_NUMBER_NOT_INT;
            *sp = ++s;

            if (s == send) {
                return flags;
            }

            /* NaN can be followed by various stuff (NaNQ, NaNS), but
             * there are also multiple different NaN values, and some
             * implementations output the "payload" values,
             * e.g. NaN123, NAN(abc), while some legacy implementations
             * have weird stuff like NaN%. */
            if (isALPHA_FOLD_EQ(*s, 'q') ||
                isALPHA_FOLD_EQ(*s, 's')) {
                /* "nanq" or "nans" are ok, though generating
                 * these portably is tricky. */
                *sp = ++s;
                if (s == send) {
                    return flags;
                }
            }
            if (*s == '(') {
                /* C99 style "nan(123)" or Perlish equivalent "nan($uv)". */
                const char *t;
                int trail = flags | IS_NUMBER_TRAILING;
                s++;
                if (s == send) { return trail; }
                t = s + 1;
                while (t < send && *t && *t != ')') {
                    t++;
                }
                if (t == send) { return trail; }
                if (*t == ')') {
                    int nantype;
                    UV nanval;
                    if (s[0] == '0' && s + 2 < t &&
                        isALPHA_FOLD_EQ(s[1], 'x') &&
                        isXDIGIT(s[2])) {
                        STRLEN len = t - s;
                        I32 flags = PERL_SCAN_ALLOW_UNDERSCORES;
                        nanval = grok_hex(s, &len, &flags, NULL);
                        if ((flags & PERL_SCAN_GREATER_THAN_UV_MAX)) {
                            nantype = 0;
                        } else {
                            nantype = IS_NUMBER_IN_UV;
                        }
                        s += len;
                    } else if (s[0] == '0' && s + 2 < t &&
                               isALPHA_FOLD_EQ(s[1], 'b') &&
                               (s[2] == '0' || s[2] == '1')) {
                        STRLEN len = t - s;
                        I32 flags = PERL_SCAN_ALLOW_UNDERSCORES;
                        nanval = grok_bin(s, &len, &flags, NULL);
                        if ((flags & PERL_SCAN_GREATER_THAN_UV_MAX)) {
                            nantype = 0;
                        } else {
                            nantype = IS_NUMBER_IN_UV;
                        }
                        s += len;
                    } else {
                        const char *u;
                        nantype =
                            grok_number_flags(s, t - s, &nanval,
                                              PERL_SCAN_TRAILING |
                                              PERL_SCAN_ALLOW_UNDERSCORES);
                        /* Unfortunately grok_number_flags() doesn't
                         * tell how far we got and the ')' will always
                         * be "trailing", so we need to double-check
                         * whether we had something dubious. */
                        for (u = s; u < t; u++) {
                            if (!isDIGIT(*u))
                                break;
                        }
                        s = u;
                    }

                    /* XXX Doesn't do octal: nan("0123").
                     * Probably not a big loss. */

                    /* XXX the nanval is currently unused, that is,
                     * not inserted as the NaN payload of the NV.
                     * But the above code already parses the C99
                     * nan(...)  format.  See below, and see also
                     * the nan() in POSIX.xs.
                     *
                     * Certain configuration combinations where
                     * NVSIZE is greater than UVSIZE mean that
                     * a single UV cannot contain all the possible
                     * NaN payload bits.  There would need to be
                     * some more generic syntax than "nan($uv)".
                     *
                     * Issues to keep in mind:
                     *
                     * (1) In most common cases there would
                     * not be an integral number of bytes that
                     * could be set, only a certain number of bits.
                     * For example for the common case of
                     * NVSIZE == UVSIZE == 8 there is room for 52
                     * bits in the payload, but the most significant
                     * bit is commonly reserved for the
                     * signaling/quiet bit, leaving 51 bits.
                     * Furthermore, the C99 nan() is supposed
                     * to generate quiet NaNs, so it is doubtful
                     * whether it should be able to generate
                     * signaling NaNs.  For the x86 80-bit doubles
                     * (if building a long double Perl) there would
                     * be 62 bits (s/q bit being the 63rd).
                     *
                     * (2) Endianness of the payload bits. If the
                     * payload is specified as an UV, the low-order
                     * bits of the UV are naturally little-endianed
                     * (rightmost) bits of the payload.  The endianness
                     * of UVs and NVs can be different. */

                    if ((nantype & IS_NUMBER_NOT_INT) ||
                        !(nantype & IS_NUMBER_IN_UV)) {
                        /* treat "NaN(invalid)" the same as "NaNgarbage" */
                        return trail;
                    }
                    else {
                        /* allow whitespace between valid payload and ')' */
                        while (s < t && isSPACE(*s))
                            s++;
                        /* but on anything else treat the whole '(...)' chunk
                         * as trailing garbage */
                        if (s < t)
                            return trail;
                        s = t + 1;
                        goto ok_check_space;
                    }
                } else {
                    /* Looked like nan(...), but no close paren. */
                    return trail;
                }
            } else {
                /* Note that we here implicitly accept (parse as
                 * "nan", but with warnings) also any other weird
                 * trailing stuff for "nan".  In the above we just
                 * check that if we got the C99-style "nan(...)",
                 * the "..."  looks sane.
                 * If in future we accept more ways of specifying
                 * the nan payload, the accepting would happen around
                 * here. */
                goto ok_check_space;
            }
        }
        else
            return 0;
    }
    NOT_REACHED; /* NOTREACHED */

    /* We parsed something valid, s points after it, flags describes it */
  ok_check_space:
    while (s < send && isSPACE(*s))
        s++;
    *sp = s;
    return flags | (s < send ? IS_NUMBER_TRAILING : 0);

#else
    PERL_UNUSED_ARG(send);
    *sp = s;
    return flags;
#endif /* #if defined(NV_INF) || defined(NV_NAN) */
}

/*

=for apidoc      grok_number
=for apidoc_item grok_number_flags
=for apidoc_flag IS_NUMBER_GREATER_THAN_UV_MAX
=for apidoc_flag IS_NUMBER_INFINITY
=for apidoc_flag IS_NUMBER_IN_UV
=for apidoc_flag IS_NUMBER_NAN
=for apidoc_flag IS_NUMBER_NEG
=for apidoc_flag IS_NUMBER_NOT_INT
=for apidoc_flag IS_NUMBER_TRAILING
=for apidoc_flag PERL_SCAN_TRAILING

Look for a base 10 number in the C<len> bytes starting at C<pv>.  If one isn't
found, return 0; otherwise return its type (and optionally its value).  In
C<grok_number> all C<len> bytes must be either leading C<L</isSPACE>>
characters or part of the number.  The same is true in C<grok_number_flags>
unless C<flags> contains the C<PERL_SCAN_TRAILING> bit, which allows for
trailing non-numeric text.  (This is the only difference between the two
functions.)

The returned type is the ORing of various bits (#defined in F<perl.h>) as
described below:

If the number is negative, the returned type will include the C<IS_NUMBER_NEG>
bit.

If the absolute value of the integral portion of the found number fits in a UV,
the returned type will include the C<IS_NUMBER_IN_UV> bit.  If it won't fit,
instead the C<IS_NUMBER_GREATER_THAN_UV_MAX> bit will be included.

If the found number is not an integer, the returned type will include
the C<IS_NUMBER_NOT_INT> bit. This happens either if the number
is expressed in exponential C<e> notation, or if it includes a decimal
point (radix) character.  If exponential notation is used, then neither
IS_NUMBER_IN_UV nor IS_NUMBER_GREATER_THAN_UV_MAX bits are set.
Otherwise, the integer part of the number is used to determine the
C<IS_NUMBER_IN_UV> and C<IS_NUMBER_GREATER_THAN_UV_MAX> bits.

If the found number is a string indicating it is infinity, the
C<IS_NUMBER_INFINITY> and C<IS_NUMBER_NOT_INT> bits are included in the
returned type.

If the found number is a string indicating it is not a number, the
C<IS_NUMBER_NAN> and C<IS_NUMBER_NOT_INT> bits are included in the
returned type.

You can get the number's absolute integral value returned to you by calling
these functions with a non-NULL C<valuep> argument.  If the returned type
includes the C<IS_NUMBER_IN_UV> bit, C<*valuep> will be set to the correct
value.  Otherwise, it could well have been zapped with garbage.

In C<grok_number_flags> when C<flags> contains the C<PERL_SCAN_TRAILING>
bit, and trailing non-numeric text was found, the returned type will include
the C<IS_NUMBER_TRAILING> bit.

=cut
 */
int
Perl_grok_number(pTHX_ const char *pv, STRLEN len, UV *valuep)
{
    PERL_ARGS_ASSERT_GROK_NUMBER;

    return grok_number_flags(pv, len, valuep, 0);
}

static const UV uv_max_div_10 = UV_MAX / 10;
static const U8 uv_max_mod_10 = UV_MAX % 10;

int
Perl_grok_number_flags(pTHX_ const char *pv, STRLEN len, UV *valuep, U32 flags)
{
  PERL_ARGS_ASSERT_GROK_NUMBER_FLAGS;

  const char *s = pv;
  const char * const send = pv + len;
  const char *d;
  int numtype = 0;

  if (UNLIKELY(isSPACE(*s))) {
      s++;
      while (s < send) {
        if (LIKELY(! isSPACE(*s))) goto non_space;
        s++;
      }
      return 0;
    non_space: ;
  }

  /* See if signed.  This assumes it is more likely to be unsigned, so
   * penalizes signed by an extra conditional; rewarding unsigned by one fewer
   * (because we detect '+' and '-' with a single test and then add a
   * conditional to determine which) */
  if (UNLIKELY((*s & ~('+' ^ '-')) == ('+' & '-') )) {

    /* Here, on ASCII platforms, *s is one of: 0x29 = ')', 2B = '+', 2D = '-',
     * 2F = '/'.  That is, it is either a sign, or a character that doesn't
     * belong in a number at all (unless it's a radix character in a weird
     * locale).  Given this, it's far more likely to be a minus than the
     * others.  (On EBCDIC it is one of 42, 44, 46, 48, 4A, 4C, 4E,  (not 40
     * because can't be a space)    60, 62, 64, 66, 68, 6A, 6C, 6E.  Again,
     * only potentially a weird radix character, or 4E='+', or 60='-') */
    if (LIKELY(*s == '-')) {
        s++;
        numtype = IS_NUMBER_NEG;
    }
    else if (LIKELY(*s == '+'))
        s++;
    else  /* Can't just return failure here, as it could be a weird radix
             character */
        goto done_sign;

    if (UNLIKELY(s == send))
        return 0;
  done_sign: ;
    }

  /* The first digit (after optional sign): note that might
   * also point to "infinity" or "nan", or "1.#INF". */
  d = s;

  /* next must be digit or the radix separator or beginning of infinity/nan */
  if (LIKELY(isDIGIT(*s))) {
    STRLEN len = send - s;
    I32 grok_int_flags = PERL_SCAN_SILENT_ILLDIGIT
                       | PERL_SCAN_SILENT_NON_PORTABLE
                       | PERL_SCAN_DISCARD_INSTEAD_OF_OVERFLOW
              ;
    UV value = grok_uint_by_base(s, &len, &grok_int_flags, NULL,
                                 10, CC_mask_(CC_DIGIT_), 0);
    s += len;

    if (grok_int_flags & PERL_SCAN_DISCARD_INSTEAD_OF_OVERFLOW) {
        numtype |= IS_NUMBER_GREATER_THAN_UV_MAX;
    }
    else {
        // dent XXX

    numtype |= IS_NUMBER_IN_UV;

    if (valuep) {
        *valuep = value;
    }

    if (s >= send) {
        return numtype;
    }
    }

    if (GROK_NUMERIC_RADIX(&s, send)) {
      numtype |= IS_NUMBER_NOT_INT;
      while (s < send && isDIGIT(*s))  /* optional digits after the radix */
        s++;
    }
  } /* End of *s is a digit */
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
  }

  if (LIKELY(s > d) && s < send) {
    /* we can have an optional exponent part */
    if (UNLIKELY(isALPHA_FOLD_EQ(*s, 'e'))) {
      s++;
      if (s < send && (*s == '-' || *s == '+'))
        s++;
      if (s < send && isDIGIT(*s)) {
        do {
          s++;
        } while (s < send && isDIGIT(*s));
      }
      else if (flags & PERL_SCAN_TRAILING)
        return numtype | IS_NUMBER_TRAILING;
      else
        return 0;

      /* The only flag we keep is sign.  Blow away any "it's UV"  */
      numtype &= IS_NUMBER_NEG;
      numtype |= IS_NUMBER_NOT_INT;
    }
  }

  while (s < send) {
    if (LIKELY(! isSPACE(*s))) goto end_space;
    s++;
  }
  return numtype;

 end_space:

  if (UNLIKELY(memEQs(pv, len, "0 but true"))) {
    if (valuep)
      *valuep = 0;
    return IS_NUMBER_IN_UV;
  }

  /* We could be e.g. at "Inf" or "NaN", or at the "#" of "1.#INF". */
  if ((s + 2 < send) && UNLIKELY(memCHRs("inqs#", toFOLD(*s)))) {
      /* Really detect inf/nan. Start at d, not s, since the above
       * code might have already consumed the "1." or "1". */
      const int infnan = grok_infnan(&d, send);

      if ((infnan & IS_NUMBER_TRAILING) && !(flags & PERL_SCAN_TRAILING)) {
          return 0;
      }
      if ((infnan & IS_NUMBER_INFINITY)) {
          return (numtype | infnan); /* Keep sign for infinity. */
      }
      else if ((infnan & IS_NUMBER_NAN)) {
          return (numtype | infnan) & ~IS_NUMBER_NEG; /* Clear sign for nan. */
      }
  }
  else if (flags & PERL_SCAN_TRAILING) {
    return numtype | IS_NUMBER_TRAILING;
  }

  return 0;
}

/*
=for apidoc grok_atoUV

parse a string, looking for a decimal unsigned integer.

On entry, C<pv> points to the beginning of the string;
C<valptr> points to a UV that will receive the converted value, if found;
C<endptr> is either NULL or points to a variable that points to one byte
beyond the point in C<pv> that this routine should examine.
If C<endptr> is NULL, C<pv> is assumed to be NUL-terminated.

Returns FALSE if C<pv> doesn't represent a valid unsigned integer value (with
no leading zeros).  Otherwise it returns TRUE, and sets C<*valptr> to that
value.

If you constrain the portion of C<pv> that is looked at by this function (by
passing a non-NULL C<endptr>), and if the initial bytes of that portion form a
valid value, it will return TRUE, setting C<*endptr> to the byte following the
final digit of the value.  But if there is no constraint at what's looked at,
all of C<pv> must be valid in order for TRUE to be returned.  C<*endptr> is
unchanged from its value on input if FALSE is returned;

The only characters this accepts are the decimal digits '0'..'9'.

As opposed to L<atoi(3)> or L<strtol(3)>, C<grok_atoUV> does NOT allow optional
leading whitespace, nor negative inputs.  If such features are required, the
calling code needs to explicitly implement those.

Note that this function returns FALSE for inputs that would overflow a UV,
or have leading zeros.  Thus a single C<0> is accepted, but not C<00> nor
C<01>, C<002>, I<etc>.

Background: C<atoi> has severe problems with illegal inputs, it cannot be
used for incremental parsing, and therefore should be avoided
C<atoi> and C<strtol> are also affected by locale settings, which can also be
seen as a bug (global state controlled by user environment).

=cut

*/

bool
Perl_grok_atoUV(const char *pv, UV *valptr, const char** endptr)
{
    const char* s = pv;
    const char** eptr;
    const char* end2; /* Used in case endptr is NULL. */
    UV val = 0; /* The parsed value. */

    PERL_ARGS_ASSERT_GROK_ATOUV;

    if (endptr) {
        eptr = endptr;
    }
    else {
        end2 = s + strlen(s);
        eptr = &end2;
    }

    if (   *eptr <= s
        || ! isDIGIT(*s))
    {
        return FALSE;
    }

    /* Single-digit inputs are quite common. */
    val = *s++ - '0';
    if (s < *eptr && isDIGIT(*s)) {
        /* Fail on extra leading zeros. */
        if (val == 0)
            return FALSE;
        while (s < *eptr && isDIGIT(*s)) {
            /* This could be unrolled like in grok_number(), but
                * the expected uses of this are not speed-needy, and
                * unlikely to need full 64-bitness. */
            const U8 digit = *s++ - '0';
            if (val < uv_max_div_10 ||
                (val == uv_max_div_10 && digit <= uv_max_mod_10)) {
                val = val * 10 + digit;
            } else {
                return FALSE;
            }
        }
    }

    if (endptr == NULL) {
        if (*s) {
            return FALSE; /* If endptr is NULL, no trailing non-digits allowed. */
        }
    }
    else {
        *endptr = s;
    }

    *valptr = val;
    return TRUE;
}

#ifndef Perl_strtod
static NV
S_mulexp10(NV value, I32 exponent)
{
    NV result = 1.0;
    NV power = 10.0;
    bool negative = 0;
    I32 bit;

    if (exponent == 0)
        return value;
    if (value == 0)
        return (NV)0;

    /* On OpenVMS VAX we by default use the D_FLOAT double format,
     * and that format does not have *easy* capabilities [1] for
     * overflowing doubles 'silently' as IEEE fp does.  We also need
     * to support G_FLOAT on both VAX and Alpha, and though the exponent
     * range is much larger than D_FLOAT it still doesn't do silent
     * overflow.  Therefore we need to detect early whether we would
     * overflow (this is the behaviour of the native string-to-float
     * conversion routines, and therefore of native applications, too).
     *
     * [1] Trying to establish a condition handler to trap floating point
     *     exceptions is not a good idea. */

    /* In UNICOS and in certain Cray models (such as T90) there is no
     * IEEE fp, and no way at all from C to catch fp overflows gracefully.
     * There is something you can do if you are willing to use some
     * inline assembler: the instruction is called DFI-- but that will
     * disable *all* floating point interrupts, a little bit too large
     * a hammer.  Therefore we need to catch potential overflows before
     * it's too late. */

#if ((defined(VMS) && !defined(_IEEE_FP)) || defined(_UNICOS) || defined(DOUBLE_IS_VAX_FLOAT)) && defined(NV_MAX_10_EXP)
    STMT_START {
        const NV exp_v = log10(value);
        if (exponent >= NV_MAX_10_EXP || exponent + exp_v >= NV_MAX_10_EXP)
            return NV_MAX;
        if (exponent < 0) {
            if (-(exponent + exp_v) >= NV_MAX_10_EXP)
                return 0.0;
            while (-exponent >= NV_MAX_10_EXP) {
                /* combination does not overflow, but 10^(-exponent) does */
                value /= 10;
                ++exponent;
            }
        }
    } STMT_END;
#endif

    if (exponent < 0) {
        negative = 1;
        exponent = -exponent;
#ifdef NV_MAX_10_EXP
        /* for something like 1234 x 10^-309, the action of calculating
         * the intermediate value 10^309 then returning 1234 / (10^309)
         * will fail, since 10^309 becomes infinity. In this case try to
         * refactor it as 123 / (10^308) etc.
         */
        while (value && exponent > NV_MAX_10_EXP) {
            exponent--;
            value /= 10;
        }
        if (value == 0.0)
            return value;
#endif
    }
#if defined(__osf__)
    /* Even with cc -ieee + ieee_set_fp_control(IEEE_TRAP_ENABLE_INV)
     * Tru64 fp behavior on inf/nan is somewhat broken. Another way
     * to do this would be ieee_set_fp_control(IEEE_TRAP_ENABLE_OVF)
     * but that breaks another set of infnan.t tests. */
#  define FP_OVERFLOWS_TO_ZERO
#endif
    for (bit = 1; exponent; bit <<= 1) {
        if (exponent & bit) {
            exponent ^= bit;
            result *= power;
#ifdef FP_OVERFLOWS_TO_ZERO
            if (result == 0)
# ifdef NV_INF
                return value < 0 ? -NV_INF : NV_INF;
# else
                return value < 0 ? -FLT_MAX : FLT_MAX;
# endif
#endif
            /* Floating point exceptions are supposed to be turned off,
             *  but if we're obviously done, don't risk another iteration.
             */
             if (exponent == 0) break;
        }
        power *= power;
    }
    return negative ? value / result : value * result;
}
#endif /* #ifndef Perl_strtod */

#ifdef Perl_strtod
#  define ATOF(s, x) my_atof2(s, &x)
#else
#  define ATOF(s, x) Perl_atof2(s, x)
#endif

NV
Perl_my_atof(pTHX_ const char* s)
{
    PERL_ARGS_ASSERT_MY_ATOF;

/*
=for apidoc      my_atof
=for apidoc_item Atof

These each are C<L<atof(3)>>, but properly work with Perl locale handling,
accepting a dot radix character always, but also the current locale's radix
character if and only if called from within the lexical scope of a Perl C<use
locale> statement.

N.B. C<s> must be NUL terminated.

=cut
*/

    NV x = 0.0;

#if ! defined(USE_LOCALE_NUMERIC)

    ATOF(s, x);

#else

    {
        DECLARATION_FOR_LC_NUMERIC_MANIPULATION;
        STORE_LC_NUMERIC_SET_TO_NEEDED();
        if (! IN_LC(LC_NUMERIC)) {
            ATOF(s,x);
        }
        else {

            /* Look through the string for the first thing that looks like a
             * decimal point: either the value in the current locale or the
             * standard fallback of '.'. The one which appears earliest in the
             * input string is the one that we should have atof look for. Note
             * that we have to determine this beforehand because on some
             * systems, Perl_atof2 is just a wrapper around the system's atof.
             * */
            const char * const standard_pos = strchr(s, '.');
            const char * const local_pos
                                  = strstr(s, SvPV_nolen(PL_numeric_radix_sv));
            const bool use_standard_radix
                    = standard_pos && (!local_pos || standard_pos < local_pos);

            if (use_standard_radix) {
                SET_NUMERIC_STANDARD();
                LOCK_LC_NUMERIC_STANDARD();
            }

            ATOF(s,x);

            if (use_standard_radix) {
                UNLOCK_LC_NUMERIC_STANDARD();
                SET_NUMERIC_UNDERLYING();
            }
        }
        RESTORE_LC_NUMERIC();
    }

#endif

    return x;
}

#if defined(NV_INF) || defined(NV_NAN)

static char*
S_my_atof_infnan(pTHX_ const char* s, bool negative, const char* send, NV* value)
{
    const char *p0 = negative ? s - 1 : s;
    const char *p = p0;
    const int infnan = grok_infnan(&p, send);
    /* We act like PERL_SCAN_TRAILING here to permit trailing garbage,
     * it is not clear if that is desirable.
     */
    if (infnan && p != p0) {
        /* If we can generate inf/nan directly, let's do so. */
#ifdef NV_INF
        if ((infnan & IS_NUMBER_INFINITY)) {
            *value = (infnan & IS_NUMBER_NEG) ? -NV_INF: NV_INF;
            return (char*)p;
        }
#endif
#ifdef NV_NAN
        if ((infnan & IS_NUMBER_NAN)) {
            *value = NV_NAN;
            return (char*)p;
        }
#endif
#ifdef Perl_strtod
        /* If still here, we didn't have either NV_INF or NV_NAN,
         * and can try falling back to native strtod/strtold.
         *
         * The native interface might not recognize all the possible
         * inf/nan strings Perl recognizes.  What we can try
         * is to try faking the input.  We will try inf/-inf/nan
         * as the most promising/portable input. */
        {
            const char* fake = "silence compiler warning";
            char* endp;
            NV nv;
#ifdef NV_INF
            if ((infnan & IS_NUMBER_INFINITY)) {
                fake = ((infnan & IS_NUMBER_NEG)) ? "-inf" : "inf";
            }
#endif
#ifdef NV_NAN
            if ((infnan & IS_NUMBER_NAN)) {
                fake = "nan";
            }
#endif
            assert(strNE(fake, "silence compiler warning"));
            nv = S_strtod(aTHX_ fake, &endp);
            if (fake != endp) {
#ifdef NV_INF
                if ((infnan & IS_NUMBER_INFINITY)) {
#  ifdef Perl_isinf
                    if (Perl_isinf(nv))
                        *value = nv;
#  else
                    /* last resort, may generate SIGFPE */
                    *value = Perl_exp((NV)1e9);
                    if ((infnan & IS_NUMBER_NEG))
                        *value = -*value;
#  endif
                    return (char*)p; /* p, not endp */
                }
#endif
#ifdef NV_NAN
                if ((infnan & IS_NUMBER_NAN)) {
#  ifdef Perl_isnan
                    if (Perl_isnan(nv))
                        *value = nv;
#  else
                    /* last resort, may generate SIGFPE */
                    *value = Perl_log((NV)-1.0);
#  endif
                    return (char*)p; /* p, not endp */
#endif
                }
            }
        }
#endif /* #ifdef Perl_strtod */
    }
    return NULL;
}

#endif /* if defined(NV_INF) || defined(NV_NAN) */

char*
Perl_my_atof2(pTHX_ const char* orig, NV* value)
{
    PERL_ARGS_ASSERT_MY_ATOF2;
    return my_atof3(orig, value, 0);
}

char*
Perl_my_atof3(pTHX_ const char* orig, NV* value, const STRLEN len)
{
    PERL_ARGS_ASSERT_MY_ATOF3;

    const char* s = orig;
    NV result[3] = {0.0, 0.0, 0.0};
#if defined(USE_PERL_ATOF) || defined(Perl_strtod)
    const char* send = s + ((len != 0)
                           ? len
                           : strlen(orig)); /* one past the last */
#endif
#if defined(USE_PERL_ATOF) && !defined(Perl_strtod)
    bool negative = 0;
    UV accumulator[2] = {0,0};	/* before/after dp */
    bool seen_digit = 0;
    I32 exp_adjust[2] = {0,0};
    I32 exp_acc[2] = {-1, -1};
    /* the current exponent adjust for the accumulators */
    I32 exponent = 0;
    I32	seen_dp  = 0;
    I32 digit = 0;
    I32 old_digit = 0;
    I32 sig_digits = 0; /* noof significant digits seen so far */
#endif

#if defined(USE_PERL_ATOF) || defined(Perl_strtod)

    /* leading whitespace */
    while (s < send && isSPACE(*s))
        ++s;

#  if defined(NV_INF) || defined(NV_NAN)
    {
        char* endp;
        if ((endp = S_my_atof_infnan(aTHX_ s, FALSE, send, value)))
            return endp;
    }
#  endif

    /* sign */
    switch (*s) {
        case '-':
#  if !defined(Perl_strtod)
            negative = 1;
#  endif
            /* FALLTHROUGH */
        case '+':
            ++s;
    }
#endif

#ifdef Perl_strtod
    {
        char* endp;
        char* copy = NULL;

        /* strtold() accepts 0x-prefixed hex and in POSIX implementations,
           0b-prefixed binary numbers, which is backward incompatible
        */
        if ((len == 0 || len - (s-orig) >= 2) && *s == '0' &&
            (isALPHA_FOLD_EQ(s[1], 'x') || isALPHA_FOLD_EQ(s[1], 'b'))) {
            *value = 0;
            return (char *)s+1;
        }

        /* We do not want strtod to parse whitespace after the sign, since
         * that would give backward-incompatible results. So we rewind and
         * let strtod handle the whitespace and sign character itself. */
        s = orig;

        /* If the length is passed in, the input string isn't NUL-terminated,
         * and in it turns out the function below assumes it is; therefore we
         * create a copy and NUL-terminate that */
        if (len) {
            Newx(copy, len + 1, char);
            Copy(orig, copy, len, char);
            copy[len] = '\0';
            s = copy;
        }

        result[2] = S_strtod(aTHX_ s, &endp);

        /* If we created a copy, 'endp' is in terms of that.  Convert back to
         * the original */
        if (copy) {
            s = (s - copy) + (char *) orig;
            endp = (endp - copy) + (char *) orig;
            Safefree(copy);
        }

        if (s != endp) {
            /* Note that negation is handled by strtod. */
            *value = result[2];
            return endp;
        }
        return NULL;
    }
#elif defined(USE_PERL_ATOF)

/* There is no point in processing more significant digits
 * than the NV can hold. Note that NV_DIG is a lower-bound value,
 * while we need an upper-bound value. We add 2 to account for this;
 * since it will have been conservative on both the first and last digit.
 * For example a 32-bit mantissa with an exponent of 4 would have
 * exact values in the set
 *               4
 *               8
 *              ..
 *     17179869172
 *     17179869176
 *     17179869180
 *
 * where for the purposes of calculating NV_DIG we would have to discount
 * both the first and last digit, since neither can hold all values from
 * 0..9; but for calculating the value we must examine those two digits.
 */
#  ifdef MAX_SIG_DIG_PLUS
    /* It is not necessarily the case that adding 2 to NV_DIG gets all the
       possible digits in a NV, especially if NVs are not IEEE compliant
       (e.g., long doubles on IRIX) - Allen <allens@cpan.org> */
#   define MAX_SIG_DIGITS (NV_DIG+MAX_SIG_DIG_PLUS)
#  else
#   define MAX_SIG_DIGITS (NV_DIG+2)
#  endif

/* the max number we can accumulate in a UV, and still safely do 10*N+9 */
#  define MAX_ACCUMULATE ( (UV) ((UV_MAX - 9)/10))

    /* we accumulate digits into an integer; when this becomes too
     * large, we add the total to NV and start again */

    while (s < send) {
        if (isDIGIT(*s)) {
            seen_digit = 1;
            old_digit = digit;
            digit = *s++ - '0';
            if (seen_dp)
                exp_adjust[1]++;

            /* don't start counting until we see the first significant
             * digit, eg the 5 in 0.00005... */
            if (!sig_digits && digit == 0)
                continue;

            if (++sig_digits > MAX_SIG_DIGITS) {
                /* limits of precision reached */
                if (digit > 5) {
                    ++accumulator[seen_dp];
                } else if (digit == 5) {
                    if (old_digit % 2) { /* round to even - Allen */
                        ++accumulator[seen_dp];
                    }
                }
                if (seen_dp) {
                    exp_adjust[1]--;
                } else {
                    exp_adjust[0]++;
                }
                /* skip remaining digits */
                while (s < send && isDIGIT(*s)) {
                    ++s;
                    if (! seen_dp) {
                        exp_adjust[0]++;
                    }
                }
                /* warn of loss of precision? */
            }
            else {
                if (accumulator[seen_dp] > MAX_ACCUMULATE) {
                    /* add accumulator to result and start again */
                    result[seen_dp] = S_mulexp10(result[seen_dp],
                                                 exp_acc[seen_dp])
                        + (NV)accumulator[seen_dp];
                    accumulator[seen_dp] = 0;
                    exp_acc[seen_dp] = 0;
                }
                accumulator[seen_dp] = accumulator[seen_dp] * 10 + digit;
                ++exp_acc[seen_dp];
            }
        }
        else if (!seen_dp && GROK_NUMERIC_RADIX(&s, send)) {
            seen_dp = 1;
            if (sig_digits > MAX_SIG_DIGITS) {
                while (s < send && isDIGIT(*s)) {
                    ++s;
                }
                break;
            }
        }
        else {
            break;
        }
    }

    result[0] = S_mulexp10(result[0], exp_acc[0]) + (NV)accumulator[0];
    if (seen_dp) {
        result[1] = S_mulexp10(result[1], exp_acc[1]) + (NV)accumulator[1];
    }

    if (s < send && seen_digit && (isALPHA_FOLD_EQ(*s, 'e'))) {
        bool expnegative = 0;

        ++s;
        switch (*s) {
            case '-':
                expnegative = 1;
                /* FALLTHROUGH */
            case '+':
                ++s;
        }
        while (s < send && isDIGIT(*s))
            exponent = exponent * 10 + (*s++ - '0');
        if (expnegative)
            exponent = -exponent;
    }

    /* now apply the exponent */

    if (seen_dp) {
        result[2] = S_mulexp10(result[0],exponent+exp_adjust[0])
                + S_mulexp10(result[1],exponent-exp_adjust[1]);
    } else {
        result[2] = S_mulexp10(result[0],exponent+exp_adjust[0]);
    }

    /* now apply the sign */
    if (negative)
        result[2] = -result[2];
    *value = result[2];
    return (char *)s;
#else  /* USE_PERL_ATOF */
    /* If you see this error you both don't have strtod (or configured -Ud_strtod or
       or it's long double/quadmath equivalent) and disabled USE_PERL_ATOF, thus
       removing any way for perl to convert strings to floating point numbers.
    */
#  error No mechanism to convert strings to numbers available
#endif
}

/*
=for apidoc isinfnan

C<Perl_isinfnan()> is a utility function that returns true if the NV
argument is either an infinity or a C<NaN>, false otherwise.  To test
in more detail, use C<Perl_isinf()> and C<Perl_isnan()>.

This is also the logical inverse of Perl_isfinite().

=cut
*/
bool
Perl_isinfnan(NV nv)
{
    PERL_ARGS_ASSERT_ISINFNAN;

  PERL_UNUSED_ARG(nv);
#ifdef Perl_isinf
    if (Perl_isinf(nv))
        return TRUE;
#endif
#ifdef Perl_isnan
    if (Perl_isnan(nv))
        return TRUE;
#endif
    return FALSE;
}

/*
=for apidoc isinfnansv

Checks whether the argument would be either an infinity or C<NaN> when used
as a number, but is careful not to trigger non-numeric or uninitialized
warnings.  it assumes the caller has done C<SvGETMAGIC(sv)> already.

Note that this always accepts trailing garbage (similar to C<grok_number_flags>
with C<PERL_SCAN_TRAILING>), so C<"inferior"> and C<"NAND gates"> will
return true.

=cut
*/

bool
Perl_isinfnansv(pTHX_ SV *sv)
{
    PERL_ARGS_ASSERT_ISINFNANSV;
    if (!SvOK(sv))
        return FALSE;
    if (SvNOKp(sv))
        return Perl_isinfnan(SvNVX(sv));
    if (SvIOKp(sv))
        return FALSE;
    {
        STRLEN len;
        const char *s = SvPV_nomg_const(sv, len);
        return cBOOL(grok_infnan(&s, s+len));
    }
}

#ifndef HAS_MODFL
/* C99 has truncl, pre-C99 Solaris had aintl.  We can use either with
 * copysignl to emulate modfl, which is in some platforms missing or
 * broken. */
#  if defined(HAS_TRUNCL) && defined(HAS_COPYSIGNL)
long double
Perl_my_modfl(long double x, long double *ip)
{
    *ip = truncl(x);
    return (x == *ip ? copysignl(0.0L, x) : x - *ip);
}
#  elif defined(HAS_AINTL) && defined(HAS_COPYSIGNL)
long double
Perl_my_modfl(long double x, long double *ip)
{
    *ip = aintl(x);
    return (x == *ip ? copysignl(0.0L, x) : x - *ip);
}
#  endif
#endif

/* Similarly, with ilogbl and scalbnl we can emulate frexpl. */
#if ! defined(HAS_FREXPL) && defined(HAS_ILOGBL) && defined(HAS_SCALBNL)
long double
Perl_my_frexpl(long double x, int *e)
{
    *e = x == 0.0L ? 0 : ilogbl(x) + 1;
    return (scalbnl(x, -*e));
}
#endif

/*
=for apidoc Perl_signbit

Return a non-zero integer if the sign bit on an NV is set, and 0 if
it is not.

If F<Configure> detects this system has a C<signbit()> that will work with
our NVs, then we just use it via the C<#define> in F<perl.h>.  Otherwise,
fall back on this implementation.  The main use of this function
is catching C<-0.0>.

C<Configure> notes:  This function is called C<'Perl_signbit'> instead of a
plain C<'signbit'> because it is easy to imagine a system having a C<signbit()>
function or macro that doesn't happen to work with our particular choice
of NVs.  We shouldn't just re-C<#define> C<signbit> as C<Perl_signbit> and expect
the standard system headers to be happy.  Also, this is a no-context
function (no C<pTHX_>) because C<Perl_signbit()> is usually re-C<#defined> in
F<perl.h> as a simple macro call to the system's C<signbit()>.
Users should just always call C<Perl_signbit()>.

=cut
*/
#if !defined(HAS_SIGNBIT)
int
Perl_signbit(NV x)
{
    PERL_ARGS_ASSERT_PERL_SIGNBIT;

#  ifdef Perl_fp_class_nzero
    return Perl_fp_class_nzero(x);
    /* Try finding the high byte, and assume it's highest bit
     * is the sign.  This assumption is probably wrong somewhere. */
#  elif defined(USE_LONG_DOUBLE) && LONG_DOUBLEKIND == LONG_DOUBLE_IS_X86_80_BIT_LITTLE_ENDIAN
    return (((unsigned char *)&x)[9] & 0x80);
#  elif defined(NV_LITTLE_ENDIAN)
    /* Note that NVSIZE is sizeof(NV), which would make the below be
     * wrong if the end bytes are unused, which happens with the x86
     * 80-bit long doubles, which is why take care of that above. */
    return (((unsigned char *)&x)[NVSIZE - 1] & 0x80);
#  elif defined(NV_BIG_ENDIAN)
    return (((unsigned char *)&x)[0] & 0x80);
#  else
    /* This last resort fallback is wrong for the negative zero. */
    return (x < 0.0) ? 1 : 0;
#  endif
}
#endif

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
