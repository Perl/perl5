#ifndef TIME_H
#define TIME_H 1

#include <celib_defs.h>
#include <sys/types.h>

#ifdef  __cplusplus
extern "C" {
#endif

extern long _timezone;
extern int _daylight;
extern long _dstbias;
extern char *_tzname[];
extern const char __dnames[];
extern const char __mnames[];
extern int _days[];
extern int _lpdays[];

#define _DAY_SEC           (24L * 60L * 60L)    /* secs in a day */
#define _YEAR_SEC          (365L * _DAY_SEC)    /* secs in a year */
#define _FOUR_YEAR_SEC     (1461L * _DAY_SEC)   /* secs in a 4 year interval */
#define _DEC_SEC           315532800L           /* secs in 1970-1979 */
#define _BASE_YEAR         70L                  /* 1970 is the base year */
#define _BASE_DOW          4                    /* 01-01-70 was a Thursday */
#define _LEAP_YEAR_ADJUST  17L                  /* Leap years 1900 - 1970 */
#define _MAX_YEAR          138L                 /* 2038 is the max year */

struct tm {
  int tm_sec;     /* seconds after the minute - [0,59] */
  int tm_min;     /* minutes after the hour - [0,59] */
  int tm_hour;    /* hours since midnight - [0,23] */
  int tm_mday;    /* day of the month - [1,31] */
  int tm_mon;     /* months since January - [0,11] */
  int tm_year;    /* years since 1900 */
  int tm_wday;    /* days since Sunday - [0,6] */
  int tm_yday;    /* days since January 1 - [0,365] */
  int tm_isdst;   /* daylight savings time flag */
};

XCE_EXPORT struct tm * xcegmtime(const time_t *timp);
XCE_EXPORT struct tm *xcelocaltime (const time_t *ptime);
XCE_EXPORT char *xceasctime (const struct tm *tb);
XCE_EXPORT int xceutime (const char *fname, struct _utimbuf *times);
XCE_EXPORT int xcefutime (int fh, struct _utimbuf *times);
XCE_EXPORT void xceftime (struct _timeb *tp);
XCE_EXPORT void xcegettimeofday (struct timeval *tv, struct timezone *tz);
XCE_EXPORT char *xcectime(const time_t *timp);
XCE_EXPORT void xceftime (struct _timeb *tp);
XCE_EXPORT time_t xcemktime (struct tm *tb);
XCE_EXPORT time_t xcetime (time_t *timeptr);
XCE_EXPORT void _xcetzset(void);

#ifdef  __cplusplus
};
#endif

#endif
