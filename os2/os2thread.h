#include <sys/builtin.h>
#include <sys/fmutex.h>
#include <sys/rmutex.h>
typedef int pthread_t;
typedef _rmutex pthread_mutex_t;
/*typedef HEV pthread_cond_t;*/
typedef unsigned long pthread_cond_t;
typedef int pthread_key_t;
typedef unsigned long pthread_attr_t;
#define PTHREADS_INCLUDED
