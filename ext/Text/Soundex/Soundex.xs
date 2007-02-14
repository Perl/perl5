/* -*- c -*- */

/* (c) Copyright 1998-2003 by Mark Mielke
 *
 * Freedom to use these sources for whatever you want, as long as credit
 * is given where credit is due, is hereby granted. You may make modifications
 * where you see fit but leave this copyright somewhere visible. As well try
 * to initial any changes you make so that if i like the changes i can
 * incorporate them into any later versions of mine.
 *
 *      - Mark Mielke <mark@mielke.cc>
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SOUNDEX_ACCURACY (4)	/* The maximum code length... (should be>=2) */

#if !(PERL_REVISION >= 5 && PERL_VERSION >= 8)
#  define utf8n_to_uvchr utf8_to_uv
#endif

static char *soundex_table =
  /*ABCDEFGHIJKLMNOPQRSTUVWXYZ*/
   "01230120022455012623010202";

static SV *sv_soundex (SV *source)
{
  char *source_p;
  char *source_end;

  {
    STRLEN source_len;
    source_p = SvPV(source, source_len);
    source_end = &source_p[source_len];
  }

  while (source_p != source_end)
    {
      if ((*source_p & ~((UV) 0x7F)) == 0 && isalpha(*source_p))
        {
          SV   *code     = newSV(SOUNDEX_ACCURACY);
          char *code_p   = SvPVX(code);
          char *code_end = &code_p[SOUNDEX_ACCURACY];
          char  code_last;

          SvCUR_set(code, SOUNDEX_ACCURACY);
          SvPOK_only(code);

          code_last = soundex_table[(*code_p++ = toupper(*source_p++)) - 'A'];

          while (source_p != source_end && code_p != code_end)
            {
              char c = *source_p++;

              if ((c & ~((UV) 0x7F)) == 0 && isalpha(c))
                {
                  *code_p = soundex_table[toupper(c) - 'A'];
                  if (*code_p != code_last && (code_last = *code_p) != '0')
                    code_p++;
                }
            }

          while (code_p != code_end)
            *code_p++ = '0';

          *code_end = '\0';

          return code;
        }

      source_p++;
    }

  return SvREFCNT_inc(perl_get_sv("Text::Soundex::nocode", FALSE));
}

static SV *sv_soundex_utf8 (SV* source)
{
  U8 *source_p;
  U8 *source_end;

  {
    STRLEN source_len;
    source_p = (U8 *) SvPV(source, source_len);
    source_end = &source_p[source_len];
  }

  while (source_p < source_end)
    {
      STRLEN offset;
      UV c = utf8n_to_uvchr(source_p, source_end-source_p, &offset, 0);
      source_p = (offset >= 1) ? &source_p[offset] : source_end;

      if ((c & ~((UV) 0x7F)) == 0 && isalpha(c))
        {
          SV   *code     = newSV(SOUNDEX_ACCURACY);
          char *code_p   = SvPVX(code);
          char *code_end = &code_p[SOUNDEX_ACCURACY];
          char  code_last;

          SvCUR_set(code, SOUNDEX_ACCURACY);
          SvPOK_only(code);

          code_last = soundex_table[(*code_p++ = toupper(c)) - 'A'];

          while (source_p != source_end && code_p != code_end)
            {
              c = utf8n_to_uvchr(source_p, source_end-source_p, &offset, 0);
              source_p = (offset >= 1) ? &source_p[offset] : source_end;

              if ((c & ~((UV) 0x7F)) == 0 && isalpha(c))
                {
                  *code_p = soundex_table[toupper(c) - 'A'];
                  if (*code_p != code_last && (code_last = *code_p) != '0')
                    code_p++;
                }
            }

          while (code_p != code_end)
            *code_p++ = '0';

          *code_end = '\0';

          return code;
        }

      source_p++;
    }

  return SvREFCNT_inc(perl_get_sv("Text::Soundex::nocode", FALSE));
}

MODULE = Text::Soundex				PACKAGE = Text::Soundex

PROTOTYPES: DISABLE

void
soundex_xs (...)
PPCODE:
{
  int i;
  for (i = 0; i < items; i++)
    {
      SV *sv = ST(i);

      if (DO_UTF8(sv))
        sv = sv_soundex_utf8(sv);
      else
        sv = sv_soundex(sv);

      PUSHs(sv_2mortal(sv));
    }
}
