#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef WIN32
#include <time.h>
#else
#include <sys/time.h>
#endif
#ifdef __cplusplus
}
#endif

static IV
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'I':
      if (strEQ(name, "ITIMER_REAL"))
#ifdef ITIMER_REAL
	return ITIMER_REAL;
#else
	goto not_there;
#endif
      if (strEQ(name, "ITIMER_REALPROF"))
#ifdef ITIMER_REALPROF
	return ITIMER_REALPROF;
#else
	goto not_there;
#endif
      if (strEQ(name, "ITIMER_VIRTUAL"))
#ifdef ITIMER_VIRTUAL
	return ITIMER_VIRTUAL;
#else
	goto not_there;
#endif
      if (strEQ(name, "ITIMER_PROF"))
#ifdef ITIMER_PROF
	return ITIMER_PROF;
#else
	goto not_there;
#endif
      break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#if !defined(HAS_GETTIMEOFDAY) && defined(WIN32)
#define HAS_GETTIMEOFDAY

/* shows up in winsock.h?
struct timeval {
 long tv_sec;
 long tv_usec;
}
*/

int
gettimeofday (struct timeval *tp, int nothing)
{
 SYSTEMTIME st;
 time_t tt;
 struct tm tmtm;
 /* mktime converts local to UTC */
 GetLocalTime (&st);
 tmtm.tm_sec = st.wSecond;
 tmtm.tm_min = st.wMinute;
 tmtm.tm_hour = st.wHour;
 tmtm.tm_mday = st.wDay;
 tmtm.tm_mon = st.wMonth - 1;
 tmtm.tm_year = st.wYear - 1900;
 tmtm.tm_isdst = -1;
 tt = mktime (&tmtm);
 tp->tv_sec = tt;
 tp->tv_usec = st.wMilliseconds * 1000;
 return 0;
}
#endif

#if !defined(HAS_GETTIMEOFDAY) && defined(VMS)
#define HAS_GETTIMEOFDAY

#include <time.h> /* gettimeofday */
#include <stdlib.h> /* qdiv */
#include <starlet.h> /* sys$gettim */
#include <descrip.h>

/*
        VMS binary time is expressed in 100 nano-seconds since
        system base time which is 17-NOV-1858 00:00:00.00
*/

#define DIV_100NS_TO_SECS  10000000L
#define DIV_100NS_TO_USECS 10L

/* 
        gettimeofday is supposed to return times since the epoch
        so need to determine this in terms of VMS base time
*/
static $DESCRIPTOR(dscepoch,"01-JAN-1970 00:00:00.00");

static __int64 base_adjust=0;

int
gettimeofday (struct timeval *tp, void *tpz)
{
 long ret;
 __int64 quad;
 __qdiv_t ans1,ans2;

/*
        In case of error, tv_usec = 0 and tv_sec = VMS condition code.
        The return from function is also set to -1.
        This is not exactly as per the manual page.
*/

 tp->tv_usec = 0;

 if (base_adjust==0) { /* Need to determine epoch adjustment */
        ret=sys$bintim(&dscepoch,&base_adjust);
        if (1 != (ret &&1)) {
                tp->tv_sec = ret;
                return -1;
        }
 }

 ret=sys$gettim(&quad); /* Get VMS system time */
 if ((1 && ret) == 1) {
        quad -= base_adjust; /* convert to epoch offset */
        ans1=qdiv(quad,DIV_100NS_TO_SECS);
        ans2=qdiv(ans1.rem,DIV_100NS_TO_USECS);
        tp->tv_sec = ans1.quot; /* Whole seconds */
        tp->tv_usec = ans2.quot; /* Micro-seconds */
 } else {
        tp->tv_sec = ret;
        return -1;
 }
 return 0;
}
#endif

#if !defined(HAS_USLEEP) && defined(HAS_SELECT)
#ifndef SELECT_IS_BROKEN
#define HAS_USLEEP
#define usleep hrt_usleep  /* could conflict with ncurses for static build */

void
hrt_usleep(unsigned long usec)
{
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = usec;
    select(0, (Select_fd_set_t)NULL, (Select_fd_set_t)NULL,
		(Select_fd_set_t)NULL, &tv);
}
#endif
#endif

#if !defined(HAS_USLEEP) && defined(WIN32)
#define HAS_USLEEP
#define usleep hrt_usleep  /* could conflict with ncurses for static build */

void
hrt_usleep(unsigned long usec)
{
    long msec;
    msec = usec / 1000;
    Sleep (msec);
}
#endif


#if !defined(HAS_UALARM) && defined(HAS_SETITIMER)
#define HAS_UALARM
#define ualarm hrt_ualarm  /* could conflict with ncurses for static build */

int
hrt_ualarm(int usec, int interval)
{
   struct itimerval itv;
   itv.it_value.tv_sec = usec / 1000000;
   itv.it_value.tv_usec = usec % 1000000;
   itv.it_interval.tv_sec = interval / 1000000;
   itv.it_interval.tv_usec = interval % 1000000;
   return setitimer(ITIMER_REAL, &itv, 0);
}
#endif

#ifdef HAS_GETTIMEOFDAY

static void
myU2time(UV *ret)
{
  struct timeval Tp;
  int status;
  status = gettimeofday (&Tp, NULL);
  ret[0] = Tp.tv_sec;
  ret[1] = Tp.tv_usec;
}

static NV
myNVtime()
{
  struct timeval Tp;
  int status;
  status = gettimeofday (&Tp, NULL);
  return Tp.tv_sec + (Tp.tv_usec / 1000000.);
}

#endif

MODULE = Time::HiRes            PACKAGE = Time::HiRes

PROTOTYPES: ENABLE

BOOT:
#ifdef HAS_GETTIMEOFDAY
  hv_store(PL_modglobal, "Time::NVtime", 12, newSViv((IV) myNVtime), 0);
  hv_store(PL_modglobal, "Time::U2time", 12, newSViv((IV) myU2time), 0);
#endif

IV
constant(name, arg)
	char *		name
	int		arg

#ifdef HAS_USLEEP

void
usleep(useconds)
        int useconds 

void
sleep(fseconds)
        NV fseconds 
	CODE:
	int useconds = fseconds * 1000000;
	usleep (useconds);

#endif

#ifdef HAS_UALARM

int
ualarm(useconds,interval=0)
	int useconds
	int interval

int
alarm(fseconds,finterval=0)
	NV fseconds
	NV finterval
	PREINIT:
	int useconds, uinterval;
	CODE:
	useconds = fseconds * 1000000;
	uinterval = finterval * 1000000;
	RETVAL = ualarm (useconds, uinterval);

#endif

#ifdef HAS_GETTIMEOFDAY

void
gettimeofday()
        PREINIT:
        struct timeval Tp;
        PPCODE:
	int status;
        status = gettimeofday (&Tp, NULL);
        if (GIMME == G_ARRAY) {
	     EXTEND(sp, 2);
             PUSHs(sv_2mortal(newSViv(Tp.tv_sec)));
             PUSHs(sv_2mortal(newSViv(Tp.tv_usec)));
        } else {
             EXTEND(sp, 1);
             PUSHs(sv_2mortal(newSVnv(Tp.tv_sec + (Tp.tv_usec / 1000000.0))));
        }

NV
time()
        PREINIT:
        struct timeval Tp;
        CODE:
	int status;
        status = gettimeofday (&Tp, NULL);
        RETVAL = Tp.tv_sec + (Tp.tv_usec / 1000000.);
	OUTPUT:
	RETVAL

#endif

#if defined(HAS_GETITIMER) && defined(HAS_SETITIMER)

#define TV2NV(tv) ((NV)((tv).tv_sec) + 0.000001 * (NV)((tv).tv_usec))

void
setitimer(which, seconds, interval = 0)
	int which
	NV seconds
	NV interval
    PREINIT:
	struct itimerval newit;
	struct itimerval oldit;
    PPCODE:
	newit.it_value.tv_sec  = seconds;
	newit.it_value.tv_usec =
	  (seconds  - (NV)newit.it_value.tv_sec)    * 1000000.0;
	newit.it_interval.tv_sec  = interval;
	newit.it_interval.tv_usec =
	  (interval - (NV)newit.it_interval.tv_sec) * 1000000.0;
	if (setitimer(which, &newit, &oldit) == 0) {
	  EXTEND(sp, 1);
	  PUSHs(sv_2mortal(newSVnv(TV2NV(oldit.it_value))));
	  if (GIMME == G_ARRAY) {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSVnv(TV2NV(oldit.it_interval))));
	  }
	}

void
getitimer(which)
	int which
    PREINIT:
	struct itimerval nowit;
    PPCODE:
	if (getitimer(which, &nowit) == 0) {
	  EXTEND(sp, 1);
	  PUSHs(sv_2mortal(newSVnv(TV2NV(nowit.it_value))));
	  if (GIMME == G_ARRAY) {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSVnv(TV2NV(nowit.it_interval))));
	  }
	}

#endif

# $Id: HiRes.xs,v 1.11 1999/03/16 02:27:38 wegscd Exp wegscd $

# $Log: HiRes.xs,v $
# Revision 1.11  1999/03/16 02:27:38  wegscd
# Add U2time, NVtime. Fix symbols for static link.
#
# Revision 1.10  1998/09/30 02:36:25  wegscd
# Add VMS changes.
#
# Revision 1.9  1998/07/07 02:42:06  wegscd
# Win32 usleep()
#
# Revision 1.8  1998/07/02 01:47:26  wegscd
# Add Win32 code for gettimeofday.
#
# Revision 1.7  1997/11/13 02:08:12  wegscd
# Add missing EXTEND in gettimeofday() scalar code.
#
# Revision 1.6  1997/11/11 02:32:35  wegscd
# Do something useful when calling gettimeofday() in a scalar context.
# The patch is courtesy of Gisle Aas.
#
# Revision 1.5  1997/11/06 03:10:47  wegscd
# Fake ualarm() if we have setitimer.
#
# Revision 1.4  1997/11/05 05:41:23  wegscd
# Turn prototypes ON (suggested by Gisle Aas)
#
# Revision 1.3  1997/10/13 20:56:15  wegscd
# Add PROTOTYPES: DISABLE
#
# Revision 1.2  1997/05/23 01:01:38  wegscd
# Conditional compilation, depending on what the OS gives us.
#
# Revision 1.1  1996/09/03 18:26:35  wegscd
# Initial revision
#
#
