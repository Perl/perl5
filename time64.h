#include <time.h>

#ifndef LOCALTIME64_H
#    define LOCALTIME64_H

/* Configuration. */
/* Define as appropriate for your system */
/*
   HAS_GMTIME_R
   Defined if your system has gmtime_r()

   HAS_LOCALTIME_R
   Defined if your system has localtime_r()

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

   USE_TM64
   Should we use a 64 bit safe tm struct which can handle a
   year range greater than 2 billion?
*/

#define SYSTEM_LOCALTIME_MAX    LOCALTIME_MAX
#define SYSTEM_LOCALTIME_MIN    LOCALTIME_MIN
#define SYSTEM_GMTIME_MAX       GMTIME_MAX
#define SYSTEM_GMTIME_MIN       GMTIME_MIN

/* It'll be faster */
#define USE_SYSTEM_LOCALTIME    1
#define USE_SYSTEM_GMTIME       1

/* Let's get all the time */
#define USE_TM64

#ifdef USE_TM64
#define TM      TM64
#else
#define TM      tm
#endif

/* 64 bit types.  Set as appropriate for your system. */
typedef Quad_t               Time64_T;
typedef Quad_t               Int64;
typedef Int64                Year;

struct TM *gmtime64_r    (const Time64_T *, struct TM *);
struct TM *localtime64_r (const Time64_T *, struct TM *);
Time64_T   timegm64      (struct TM *);

/* A copy of the tm struct but with a 64 bit year */
struct TM64 {
        int     tm_sec;
        int     tm_min;
        int     tm_hour;
        int     tm_mday;
        int     tm_mon;
        Year    tm_year;
        int     tm_wday;
        int     tm_yday;
        int     tm_isdst;

#ifdef HAS_TM_TM_GMTOFF
        long    tm_gmtoff;
#endif

#ifdef HAS_TM_TM_ZONE
        char    *tm_zone;
#endif
};


/* Not everyone has gm/localtime_r() */
#ifdef HAS_LOCALTIME_R
#    define LOCALTIME_R(clock, result) localtime_r(clock, result)
#else
#    define LOCALTIME_R(clock, result) fake_localtime_r(clock, result)
#endif
#ifdef HAS_GMTIME_R
#    define GMTIME_R(clock, result)    gmtime_r(clock, result)
#else
#    define GMTIME_R(clock, result)    fake_gmtime_r(clock, result)
#endif

#endif
