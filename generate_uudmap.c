#include <stdio.h>
#include <stdlib.h>
/* If it turns out that we need to make this conditional on config.sh derived
   values, it might be easier just to rip out the use of strerrer().  */
#include <string.h>
/* If a platform doesn't support errno.h, it's probably so strange that
   "hello world" won't port easily to it.  */
#include <errno.h>

void output_block_to_file(const char *progname, const char *filename,
			  const char *block, size_t count) {
  FILE *const out = fopen(filename, "w");

  if (!out) {
    fprintf(stderr, "%s: Could not open '%s': %s\n", progname, filename,
	    strerror(errno));
    exit(1);
  }

  fputs("{\n    ", out);
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
  fputs("\n}\n", out);

  if (fclose(out)) {
    fprintf(stderr, "%s: Could not close '%s': %s\n", progname, filename,
	    strerror(errno));
    exit(1);
  }
}


static const char PL_uuemap[]
= "`!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";

typedef unsigned char U8;

/* This will ensure it is all zeros.  */
static char PL_uudmap[256];

int main(int argc, char **argv) {
  size_t i;

  if (argc < 2 || argv[1][0] == '\0') {
    fprintf(stderr, "Usage: %s uudemap.h\n", argv[0]);
    return 1;
  }

  for (i = 0; i < sizeof(PL_uuemap) - 1; ++i)
    PL_uudmap[(U8)PL_uuemap[i]] = (char)i;
  /*
   * Because ' ' and '`' map to the same value,
   * we need to decode them both the same.
   */
  PL_uudmap[(U8)' '] = 0;

  output_block_to_file(argv[0], argv[1], PL_uudmap, sizeof(PL_uudmap));

  return 0;
}

  
