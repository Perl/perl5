/* generate_uudmap.c:

   Create three .h files, whose names are specified as argv[1..3],
   but are usually uudmap.h, bitcount.h and mg_data.h.

   It uses mg_raw.h as input, plus it relies on the C compiler knowing
   the ord value of character literals under EBCDIC, to generate output
   tables on an order which are platform-specific.

   The outputs are:

     uudmap.h:
         The values which will populate PL_uumap[], as used by
         unpack('u').

     bitcount.h
          The values which will populate PL_bitcount[]:
          this is a count of bits for each U8 value 0..255.
          (I'm not sure why this has to be generated - surely it's
          platform-independent - DAPM.)

     mg_data.h
          Takes the input from mg_raw.h and sorts by it magic char;
          the values will populate PL_magic_data[]: this is an array of
          per-magic U8 values containing an index into PL_magic_vtables[]
          plus two flags:
             PERL_MAGIC_READONLY_ACCEPTABLE
             PERL_MAGIC_VALUE_MAGIC

   Originally this program just generated uudmap.h
   However, when we later wanted to generate bitcount.h, it was easier to
   refactor it and keep the same name, than either alternative - rename it,
   or duplicate all of the Makefile logic for a second program.
   Ditto when mg_data.h was added.
*/

#include <stdio.h>
#include <stdlib.h>
/* If it turns out that we need to make this conditional on config.sh derived
   values, it might be easier just to rip out the use of strerrer().  */
#include <string.h>
/* If a platform doesn't support errno.h, it's probably so strange that
   "hello world" won't port easily to it.  */
#include <errno.h>

#define xstrputc(_ch) *p++ = _ch
#define xstrputs(_str) do {p2 = p; p += sizeof(_str)-1; \
    memcpy((void *)p2, (void *)_str, sizeof(_str)-1);} while(0)

static const char * progname;

static void
output_zeros(FILE *out, unsigned int count) {
  char buf [sizeof("  0,   \n")+80]; /* tiny oversize */
  char * start = buf;
  char * p = start;
  char * p2;

  if(count) {
    const unsigned int max0 = sizeof("0, ")-1;
    const unsigned int maxln = 80-sizeof("  \n")-1;

    xstrputs("  ");
    while(count) {
      xstrputc('0');
      count--;
      if(count) {
        if(p < start+maxln) {
          xstrputs(", ");
          continue;
        }
        else
          xstrputs(",\n  ");
      }
      p2 = p;
      p = start;
      fwrite(start, sizeof(char), p2-start, out);
    }
  }
}

struct mg_data_raw_t {
    unsigned char type;
    const char *value;
    const char *comment;
};

static const struct mg_data_raw_t mg_data_raw[] = {
#ifdef WIN32
#  include "..\mg_raw.h"
#else
#  include "mg_raw.h"
#endif
    {0, 0, 0}
};

struct mg_data_t {
    const char *value;
    const char *comment;
};

static void
format_mg_data(FILE *out, const void *thing, unsigned int count) {
  const struct mg_data_t *p = (const struct mg_data_t *)thing;
  unsigned int zero = 0;

  while (1) {
      if (p->value) {
          unsigned int zero2 = zero;
          if (zero2) {
            zero = 0;
            output_zeros(out, zero2);
            fputs(",\n", out);
          }
          fprintf(out, "  %s\n  %s,\n", p->comment, p->value);
      } else {
          zero++;
      }
      ++p;
      if (!--count)
          break;
  }
}

static void
format_char_block(FILE *out, const void *thing, unsigned int count) {
  char buf [(sizeof("-255,\n  ")-1) * 256]; /* 2048, oversized vs ~900 */
  char * start = buf;
  char * p = start;
  char * p2;
  const char *block = (const char *)thing;

  xstrputs("  ");
  while (count--) {
    const char * fmt;
    char c = *block;
    block++;
    if (count) {
      if (!(count & 15))
        fmt = "%d,\n  ";
      else
        fmt = "%d, ";
    }
    else
      fmt = "%d";
    p += sprintf(p, fmt, c);
  }
  xstrputc('\n');
  fwrite(start, sizeof(char), p-start, out);
}

static void
output_to_file(const char *filename,
               void (format_function)(FILE *out, const void *thing,
                                      unsigned int count),
               const void *thing, unsigned int count,
               const char *header
) {
  FILE *const out = fopen(filename, "w");

  if (!out) {
    fprintf(stderr, "%s: Could not open '%s': %s\n", progname, filename,
            strerror(errno));
    exit(1);
  }

  fprintf(out,
    "/* %s:\n"
    " * THIS FILE IS AUTO-GENERATED DURING THE BUILD by: %s\n"
    " *\n%s\n*/\n{\n",
    filename, progname, header);
  format_function(out, thing, count);
  fputs("}\n", out);

  if (fclose(out)) {
    fprintf(stderr, "%s: Could not close '%s': %s\n", progname, filename,
            strerror(errno));
    exit(1);
  }
}

static const char PL_uuemap[]
= "`!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";

typedef unsigned char U8;

int main(int argc, char **argv) {
  unsigned int i;

  progname = argv[0];
  if (argc < 4 || argv[1][0] == '\0' || argv[2][0] == '\0'
      || argv[3][0] == '\0') {
    fprintf(stderr, "Usage: %s uudemap.h bitcount.h mg_data.h\n", progname);
    return 1;
  }

  do {
    char PL_uudmap[256] = {0};
    for (i = 0; i < sizeof(PL_uuemap) - 1; ++i)
      PL_uudmap[(U8)PL_uuemap[i]] = (char)i;
    /*
     * Because ' ' and '`' map to the same value,
     * we need to decode them both the same.
     */
    PL_uudmap[(U8)' '] = 0;
    output_to_file(argv[1], &format_char_block,
                   (const void *)PL_uudmap, sizeof(PL_uudmap),
          " * These values will populate PL_uumap[], as used by unpack('u')"
    );
  } while(0);

  do {
    char PL_bitcount[256] = {0};
    int bits;
    for (bits = 1; bits < 256; bits++) {
      if (bits & 1)	PL_bitcount[bits]++;
      if (bits & 2)	PL_bitcount[bits]++;
      if (bits & 4)	PL_bitcount[bits]++;
      if (bits & 8)	PL_bitcount[bits]++;
      if (bits & 16)	PL_bitcount[bits]++;
      if (bits & 32)	PL_bitcount[bits]++;
      if (bits & 64)	PL_bitcount[bits]++;
      if (bits & 128)	PL_bitcount[bits]++;
    }

    output_to_file(argv[2], &format_char_block,
                   (const void *)PL_bitcount, sizeof(PL_bitcount),
       " * These values will populate PL_bitcount[]:\n"
       " * this is a count of bits for each U8 value 0..255"
    );
  } while(0);

  do {
    struct mg_data_t mg_data[256] = {{NULL,NULL}};
    const struct mg_data_raw_t *p = mg_data_raw;
    while (p->value) {
        mg_data[p->type].value = p->value;
        mg_data[p->type].comment = p->comment;
        ++p;
    }

    output_to_file(argv[3], &format_mg_data,
                   (const void *)mg_data, sizeof(mg_data)/sizeof(mg_data[0]),
       " * These values will populate PL_magic_data[]: this is an array of\n"
       " * per-magic U8 values containing an index into PL_magic_vtables[]\n"
       " * plus two flags:\n"
       " *    PERL_MAGIC_READONLY_ACCEPTABLE\n"
       " *    PERL_MAGIC_VALUE_MAGIC"
    );
  } while (0);

  return 0;
}
