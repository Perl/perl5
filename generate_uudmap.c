#include <stdio.h>
#include <stdlib.h>
/* If it turns out that we need to make this conditional on config.sh derived
   values, it might be easier just to rip out the use of strerrer().  */
#include <string.h>
/* If a platform doesn't support errno.h, it's probably so strange that
   "hello world" won't port easily to it.  */
#include <errno.h>

static const char PL_uuemap[]
= "`!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";

typedef unsigned char U8;

/* This will ensure it is all zeros.  */
static char PL_uudmap[256];

int main(int argc, char **argv) {
  size_t i;
  char *p;
  FILE *uudmap_out;

  if (argc < 2 || argv[1][0] == '\0') {
    fprintf(stderr, "Usage: %s uudemap.h\n", argv[0]);
    return 1;
  }

  if (!(uudmap_out = fopen(argv[1], "w"))) {
    fprintf(stderr, "%s: Could not open '%s': %s\n", argv[0], argv[1],
	    strerror(errno));
    return 1;
  }

  for (i = 0; i < sizeof(PL_uuemap) - 1; ++i)
    PL_uudmap[(U8)PL_uuemap[i]] = (char)i;
  /*
   * Because ' ' and '`' map to the same value,
   * we need to decode them both the same.
   */
  PL_uudmap[(U8)' '] = 0;

  i = sizeof(PL_uudmap);
  p = PL_uudmap;

  fputs("{\n    ", uudmap_out);
  while (i--) {
    fprintf(uudmap_out, "%d", *p);
    p++;
    if (i) {
      fputs(", ", uudmap_out);
      if (!(i & 15)) {
	fputs("\n    ", uudmap_out);
      }
    }
  }
  fputs("\n}\n", uudmap_out);

  if (fclose(uudmap_out)) {
    fprintf(stderr, "%s: Could not close '%s': %s\n", argv[0], argv[1],
	    strerror(errno));
    return 1;
  }

  return 0;
}

  
