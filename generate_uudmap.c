/* Originally this program just generated uudmap.h
   However, when we later wanted to generate bitcount.h, it was easier to
   refactor it and keep the same name, than either alternative - rename it,
   or duplicate all of the Makefile logic for a second program.  */

#define PERLIO_NOT_STDIO 0
#define PERL_REENTR_API 0
#define WIN32IO_IS_STDIO

#include "EXTERN.h"
#include "perl.h"

#ifdef WIN32
#  undef strerror
#endif

static void
format_char_block(FILE *out, const void *thing, size_t count) {
  const char *block = (const char *)thing;

  fputs("    ", out);
  while (count--) {
    fprintf(out, "%d", *block);
    block++;
    if (count) {
      fputs(", ", out);
      if (!(count & 15)) {
	fputs("\n    ", out);
      }
    }
  }
  fputc('\n', out);
}

static void
output_to_file(const char *progname, const char *filename,
	       void (format_function)(FILE *out, const void *thing, size_t count),
	       const void *thing, size_t count) {
  FILE *const out = fopen(filename, "w");

  if (!out) {
    fprintf(stderr, "%s: Could not open '%s': %s\n", progname, filename,
	    strerror(errno));
    exit(1);
  }

  fputs("{\n", out);
  format_function(out, thing, count);
  fputs("}\n", out);

  if (fclose(out)) {
    fprintf(stderr, "%s: Could not close '%s': %s\n", progname, filename,
	    strerror(errno));
    exit(1);
  }
}


static const char my_uuemap[]
= "`!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";

/* This will ensure it is all zeros.  */
static char my_uudmap[256];
static char my_bitcount[256];

int main(int argc, char **argv) {
  size_t i;
  int bits;

  if (argc < 3 || argv[1][0] == '\0' || argv[2][0] == '\0') {
    fprintf(stderr, "Usage: %s uudemap.h bitcount.h\n", argv[0]);
    return 1;
  }

  for (i = 0; i < sizeof(my_uuemap) - 1; ++i)
    my_uudmap[(U8)my_uuemap[i]] = (char)i;
  /*
   * Because ' ' and '`' map to the same value,
   * we need to decode them both the same.
   */
  my_uudmap[(U8)' '] = 0;

  output_to_file(argv[0], argv[1], &format_char_block,
		 (const void *)my_uudmap, sizeof(my_uudmap));

  for (bits = 1; bits < 256; bits++) {
    if (bits & 1)	my_bitcount[bits]++;
    if (bits & 2)	my_bitcount[bits]++;
    if (bits & 4)	my_bitcount[bits]++;
    if (bits & 8)	my_bitcount[bits]++;
    if (bits & 16)	my_bitcount[bits]++;
    if (bits & 32)	my_bitcount[bits]++;
    if (bits & 64)	my_bitcount[bits]++;
    if (bits & 128)	my_bitcount[bits]++;
  }

  output_to_file(argv[0], argv[2], &format_char_block,
		 (const void *)my_bitcount, sizeof(my_bitcount));

  return 0;
}
