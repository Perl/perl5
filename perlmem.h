#ifndef H_PERLMEM
#define H_PERLMEM 1

#ifdef PERL_OBJECT

#include "ipmem.h"

#define PerlMem_malloc(size) piMem->Malloc((size))
#define PerlMem_realloc(buf, size) piMem->Realloc((buf), (size))
#define PerlMem_free(buf) piMem->Free((buf))
#else
#define PerlMem_malloc(size) malloc((size))
#define PerlMem_realloc(buf, size) realloc((buf), (size))
#define PerlMem_free(buf) free((buf))

#endif	/* PERL_OBJECT */

#endif /* Include guard */

