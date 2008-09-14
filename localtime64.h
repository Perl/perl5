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

   SYSTEM_LOCALTIME_MAX
   SYSTEM_LOCALTIME_MIN
   SYSTEM_GMTIME_MAX
   SYSTEM_GMTIME_MIN
   Maximum and minimum values your system's gmtime() and localtime()
   can handle.

   USE_SYSTEM_LOCALTIME
   USE_SYSTEM_GMTIME
   Should we use the system functions if the time is inside their range?
*/
#define SYSTEM_LOCALTIME_MAX     2147483647   /* XXX Replace with LOCALTIME_MAX */
#define SYSTEM_LOCALTIME_MIN    -2147483647  /* XXX Replace with LOCALTIME_MIN */
#define SYSTEM_GMTIME_MAX       GMTIME_MAX
#define SYSTEM_GMTIME_MIN       GMTIME_MIN

/* It'll be faster */
#define USE_SYSTEM_LOCALTIME    1

/* No point risking system bugs, ours works fine */
#define USE_SYSTEM_GMTIME       0


/* 64 bit types.  Set as appropriate for your system. */
typedef Quad_t               Time64_T;
typedef Quad_t               Int64;

struct tm *gmtime64_r    (const Time64_T *, struct tm *);
struct tm *localtime64_r (const Time64_T *, struct tm *);

#endif
