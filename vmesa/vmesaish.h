#ifndef _VMESA_INCLUDED
# define _VMESA_INCLUDED 1
# include <string.h>
# include <ctype.h>
# include <vmsock.h>
 void * dlopen(const char *);
 void * dlsym(void *, const char *);
 void * dlerror(void);
# ifdef YIELD
#  undef YIELD
# endif
# define YIELD pthread_yield(NULL)
# define pthread_mutexattr_default NULL
# define pthread_condattr_default NULL
#endif
