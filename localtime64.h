#include <time.h>

#ifndef LOCALTIME64_H
#    define LOCALTIME64_H

/* Configuration. */
/* Define as appropriate for your system */
/*
   HAS_TIMEGM
   Defined if your system has timegm()

   HAS_TM_TM_GMTOFF
   Defined if your tm struct has a "tm_gmtoff" element.

   HAS_TM_TM_ZONE
   Defined if your tm struct has a "tm_zone" element.
*/


/* 64 bit types.  Set as appropriate for your system. */
typedef Quad_t               Time64_T;
typedef Quad_t               Int64;

struct tm *gmtime64_r    (const Time64_T *, struct tm *);
struct tm *localtime64_r (const Time64_T *, struct tm *);

#endif
