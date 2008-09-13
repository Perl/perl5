#include <time.h>

#ifndef LOCALTIME64_H
#    define LOCALTIME64_H

typedef Quad_t Time64_T;

struct tm *gmtime64_r    (const Time64_T *in_time, struct tm *p);
struct tm *localtime64_r (const Time64_T *time, struct tm *local_tm);

#endif
