#ifndef H_PERLMEM
#define H_PERLMEM 1

#ifdef PERL_OBJECT
#else
#define PerlMem_malloc(size) malloc((size))
#define PerlMem_realloc(buf, size) realloc((buf), (size))
#define PerlMem_free(buf) free((buf))

#endif	/* PERL_OBJECT */

#endif /* Include guard */

