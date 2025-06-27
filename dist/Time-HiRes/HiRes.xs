/*
 *
 * Copyright (c) 1996-2002 Douglas E. Wegscheid.  All rights reserved.
 *
 * Copyright (c) 2002-2010 Jarkko Hietaniemi.
 * All rights reserved.
 *
 * Copyright (C) 2011, 2012, 2013 Andrew Main (Zefram) <zefram@fysh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "reentr.h"
#if !defined(IS_SAFE_PATHNAME) && defined(TIME_HIRES_UTIME) && defined(HAS_UTIMENSAT)
#define NEED_ck_warner
#endif
#include "ppport.h"
#if defined(__CYGWIN__) && defined(HAS_W32API_WINDOWS_H)
#  include <w32api/windows.h>
#  define CYGWIN_WITH_W32API
#endif
#ifdef WIN32
#  include <time.h>
#else
#  include <sys/time.h>
#endif
#ifdef HAS_SELECT
#  ifdef I_SYS_SELECT
#    include <sys/select.h>
#  endif
#endif
#if defined(TIME_HIRES_CLOCK_GETTIME_SYSCALL) || defined(TIME_HIRES_CLOCK_GETRES_SYSCALL)
#  include <syscall.h>
#endif

#ifndef GCC_DIAG_IGNORE
#  define GCC_DIAG_IGNORE(x)
#  define GCC_DIAG_RESTORE
#endif
#ifndef GCC_DIAG_IGNORE_STMT
#  define GCC_DIAG_IGNORE_STMT(x) GCC_DIAG_IGNORE(x) NOOP
#  define GCC_DIAG_RESTORE_STMT GCC_DIAG_RESTORE NOOP
#endif

#ifdef __cplusplus
#  define GCC_DIAG_IGNORE_CPP_COMPAT_STMT NOOP
#  define GCC_DIAG_IGNORE_CPP_COMPAT_RESTORE_STMT NOOP
#else
#  define GCC_DIAG_IGNORE_CPP_COMPAT_STMT GCC_DIAG_IGNORE_STMT(-Wc++-compat)
#  define GCC_DIAG_IGNORE_CPP_COMPAT_RESTORE_STMT GCC_DIAG_RESTORE_STMT
#endif

#ifndef PERL_STATIC_FORCE_INLINE
#  define PERL_STATIC_FORCE_INLINE STATIC
#endif

#if PERL_VERSION_GE(5,7,3) && !PERL_VERSION_GE(5,10,1)
#  undef SAVEOP
#  define SAVEOP() SAVEVPTR(PL_op)
#endif

#if defined(SV_COW_SHARED_HASH_KEYS) && defined(SV_COW_OTHER_PVS)
#  define THR_newSVsv_cow(sv) newSVsv_flags((sv), SV_GMAGIC|SV_NOSTEAL|SV_COW_SHARED_HASH_KEYS|SV_COW_OTHER_PVS)
#elif defined(SV_COW_SHARED_HASH_KEYS)
#  define THR_newSVsv_cow(sv) newSVsv_flags((sv), SV_GMAGIC|SV_NOSTEAL|SV_COW_SHARED_HASH_KEYS)
#elif defined(SV_COW_OTHER_PVS)
#  define THR_newSVsv_cow(sv) newSVsv_flags((sv), SV_GMAGIC|SV_NOSTEAL|SV_COW_OTHER_PVS)
#else
#  define THR_newSVsv_cow(sv) newSVsv_flags((sv), SV_GMAGIC|SV_NOSTEAL)
#endif

#define IV_1E6 1000000
#define IV_1E7 10000000
#define IV_1E9 1000000000

#define NV_1E6 1000000.0
#define NV_1E7 10000000.0
#define NV_1E9 1000000000.0

#ifndef PerlProc_pause
#  define PerlProc_pause() Pause()
#endif

#ifdef HAS_PAUSE
#  define Pause   pause
#else
#  undef Pause /* In case perl.h did it already. */
#  define Pause() sleep(~0) /* Zzz for a long time. */
#endif

/* Though the cpp define ITIMER_VIRTUAL is available the functionality
 * is not supported in Cygwin as of August 2004, ditto for Win32.
 * Neither are ITIMER_PROF or ITIMER_REALPROF implemented.  --jhi
 */
#if defined(__CYGWIN__) || defined(WIN32)
#  undef ITIMER_VIRTUAL
#  undef ITIMER_PROF
#  undef ITIMER_REALPROF
#endif

/* special type used by croak("unimplemented") XSUBs to neutralize */
typedef NV NV_DIE; /* unused dXSTARG/sv_newmortal() calls */
typedef I32 I32_DIE;

#define die_t

#ifndef TIME_HIRES_CLOCKID_T
typedef int clockid_t;
#endif

#if defined(TIME_HIRES_CLOCK_GETTIME) && defined(_STRUCT_ITIMERSPEC)

/* HP-UX has CLOCK_XXX values but as enums, not as defines.
 * The only way to detect these would be to test compile for each. */
#  ifdef __hpux
/* However, it seems that at least in HP-UX 11.31 ia64 there *are*
 * defines for these, so let's try detecting them. */
#    ifndef CLOCK_REALTIME
#      define CLOCK_REALTIME CLOCK_REALTIME
#      define CLOCK_VIRTUAL  CLOCK_VIRTUAL
#      define CLOCK_PROFILE  CLOCK_PROFILE
#    endif
#  endif /* # ifdef __hpux */

#endif /* #if defined(TIME_HIRES_CLOCK_GETTIME) && defined(_STRUCT_ITIMERSPEC) */

#if defined(WIN32) || defined(CYGWIN_WITH_W32API)

#  ifndef HAS_GETTIMEOFDAY
#    define HAS_GETTIMEOFDAY
#  endif

/* shows up in winsock.h?
struct timeval {
    long tv_sec;
    long tv_usec;
}
*/

typedef union {
    unsigned __int64    ft_i64;
    FILETIME            ft_val;
} FT_t;

#  define MY_CXT_KEY "Time::HiRes_" XS_VERSION

typedef struct {
    unsigned __int64 base_ticks;
    FT_t base_systime_as_filetime;
    unsigned __int64 reset_time;
    unsigned long run_count;
} my_cxt_t;

typedef BOOL (WINAPI *pfnQueryPerformanceCounter_T)(LARGE_INTEGER*);

static unsigned __int64 tick_frequency = 0;
static unsigned __int64 qpc_res_ns = 0;
static unsigned __int64 qpc_res_ns_realtime = 0;
static pfnQueryPerformanceCounter_T pfnQueryPerformanceCounter = NULL;

#define S_InterlockedExchange64(_d,_s) \
    InterlockedExchange64((LONG64 volatile *)(_d),(LONG64)(_s))
#define S_InterlockedExchangePointer(_d,_s) \
    InterlockedExchangePointer((PVOID volatile *)(_d),(PVOID)(_s))

#undef QueryPerformanceCounter
#define QueryPerformanceCounter pfnQueryPerformanceCounter

/* Visual C++ 2013 and older don't have the timespec structure.
 * Neither do mingw.org compilers with MinGW runtimes older than 3.22. */
#  if((defined(_MSC_VER) && _MSC_VER < 1900) || \
      (defined(__MINGW32__) && !defined(__MINGW64_VERSION_MAJOR) && \
      defined(__MINGW32_MAJOR_VERSION) && (__MINGW32_MAJOR_VERSION < 3 || \
      (__MINGW32_MAJOR_VERSION == 3 && __MINGW32_MINOR_VERSION < 22))))
struct timespec {
    time_t tv_sec;
    long   tv_nsec;
};
#  endif

START_MY_CXT

/* Number of 100 nanosecond units from 1/1/1601 to 1/1/1970 */
#  ifdef __GNUC__
#    define Const64(x) x##LL
#  else
#    define Const64(x) x##i64
#  endif
#  define EPOCH_BIAS  Const64(116444736000000000)

#  ifdef Const64
#    ifdef __GNUC__
#      define IV_1E6LL  1000000LL /* Needed because of Const64() ##-appends LL (or i64). */
#      define IV_1E7LL  10000000LL
#      define IV_1E9LL  1000000000LL
#    else
#      define IV_1E6i64 1000000i64
#      define IV_1E7i64 10000000i64
#      define IV_1E9i64 1000000000i64
#    endif
#  endif

/* NOTE: This does not compute the timezone info (doing so can be expensive,
 * and appears to be unsupported even by glibc) */

/* dMY_CXT needs a Perl context and we don't want to call PERL_GET_CONTEXT
   for performance reasons */

#  undef gettimeofday
#  define gettimeofday(tp, not_used)  ((*(tp) = _gettimeofday_x(aTHX)), 0)

#  undef GetSystemTimePreciseAsFileTime
#  define GetSystemTimePreciseAsFileTime(out)  (void)(*(out) = _GetSystemTimePreciseAsFileTime(aTHX))

#  undef clock_gettime
#  define clock_gettime(clock_id, tp) _clock_gettime(aTHX_ clock_id, tp)

#  undef clock_getres
#  define clock_getres(clock_id, tp) _clock_getres(clock_id, tp)

#  ifndef CLOCK_REALTIME
#    define CLOCK_REALTIME  1
#    define CLOCK_MONOTONIC 2
#  endif

/* If the performance counter delta drifts more than 0.5 seconds from the
 * system time then we recalibrate to the system time.  This means we may
 * move *backwards* in time! */
#  define MAX_PERF_COUNTER_SKEW Const64(5000000) /* 0.5 seconds */

/* Reset reading from the performance counter every five minutes.
 * Many PC clocks just seem to be so bad. */
#  define MAX_PERF_COUNTER_TICKS Const64(300000000) /* 300 seconds */

/*
 * Windows 8 introduced GetSystemTimePreciseAsFileTime(), but currently we have
 * to support older systems, so for now we provide our own implementation.
 * In the future we will switch to the real deal.
 *
 * FILETIME, switch to "return by copy", vs MS's "return by reference" prototype.
 * We never take the fn ptr of static fn _GetSystemTimePreciseAsFileTime(pTHX).
 * The MS API GetSystemTimePreciseAsFileTime() has a void return type but we
 * have no reason to match ABI compatibility with MS's function symbol.
 * Return by copy, encourages CC optimizations, since the C stack FILETIME var
 * never escaped the function that declared it. This allows the CC, in the
 * caller of _GetSystemTimePreciseAsFileTime(), to keep C stack FILETIME var
 * in CPU registers at all times in its function body, if the CC wants to
 * do that.
 *
 * Note even on Win64 x64, where "return by copy" return types > 8 bytes, become
 * secret C++ "this"-style first arguments, a > 8 bytes "return by copy" retval
 * is still more efficient!!! than explicitly passing a ptr to a C stack alloced
 * temporary C struct in C code. The latter requires the CC to re-read the
 * temporary C struct each time after any child function call, since the CC
 * can't know if SvPV() or GetSystemTimePreciseAsFileTime(), permanently saved
 * the pointer for long term Interlocked or Atomic message passing from an
 * unknown 2nd OS thread running on another CPU Core.
 */

static FILETIME
_GetSystemTimePreciseAsFileTime(pTHX)
{
#define MY_CXTX (*MY_CXT_x)
    unsigned __int64 ticks;

    unsigned __int64 timesys;
/*  If no threads, CC will probably optimize away all MY_CXT_x references
    so they directly access the C static global struct. */
    my_cxt_t * MY_CXT_x;

    {
        unsigned __int64 ticks_mem;
        QueryPerformanceCounter((LARGE_INTEGER*)&ticks_mem);
    /* Inform the CC nothing external or in this fn (ptr aliasing) can ever
       rewrite the value in ticks. Increases chance of CC using registers. */
        ticks = ticks_mem;
    }
    {
        dMY_CXT;
        MY_CXT_x = &(MY_CXT);
    }
    if (MY_CXTX.run_count++ == 0 ||
        MY_CXTX.base_systime_as_filetime.ft_i64 > MY_CXTX.reset_time) {
        MY_CXTX.base_ticks = ticks;
        GetSystemTimeAsFileTime(&MY_CXTX.base_systime_as_filetime.ft_val);
        timesys = MY_CXTX.base_systime_as_filetime.ft_i64;
        MY_CXTX.reset_time = timesys + MAX_PERF_COUNTER_TICKS;
    }
    else {
        __int64 diff;
        ticks -= MY_CXTX.base_ticks;
        timesys = MY_CXTX.base_systime_as_filetime.ft_i64
                    + Const64(IV_1E7) * (ticks / tick_frequency)
                    +(Const64(IV_1E7) * (ticks % tick_frequency)) / tick_frequency;
        diff = timesys - MY_CXTX.base_systime_as_filetime.ft_i64;
        if (diff < -MAX_PERF_COUNTER_SKEW || diff > MAX_PERF_COUNTER_SKEW) {
            MY_CXTX.base_ticks += ticks;
            GetSystemTimeAsFileTime(&MY_CXTX.base_systime_as_filetime.ft_val);
            timesys = MY_CXTX.base_systime_as_filetime.ft_i64;
        }
        /* Note this invisible else {} branch, SKIPS calling GetSystemTimeAsFileTime() */
    }
#undef MY_CXTX
    {
        FT_t ft;
        ft.ft_i64 = timesys;
        return ft.ft_val;
    }
}

/* former prototype: static int _gettimeofday(pTHX_ struct timeval *tp, void *not_used);

   B/c _gettimeofday_x() is not capable of failing, and retval was always
   constant 0, and its a static fn that never leaves this TU, repurpose the
   retval for something better. */

PERL_STATIC_FORCE_INLINE struct timeval
_gettimeofday_x(pTHX)
{
    FT_t ft;
    struct timeval tp;

    GetSystemTimePreciseAsFileTime(&ft.ft_val);

    /* seconds since epoch */
    tp.tv_sec = (long)((ft.ft_i64 - EPOCH_BIAS) / Const64(IV_1E7));

    /* microseconds remaining */
    tp.tv_usec = (long)((ft.ft_i64 / Const64(10)) % Const64(IV_1E6));

    return tp;
}

/* force inline it, because XS_Time__HiRes_clock_gettime() is the only caller */

PERL_STATIC_FORCE_INLINE int
_clock_gettime(pTHX_ clockid_t clock_id, struct timespec *tp)
{
    FT_t ft;
    unsigned __int64 ticks;
    unsigned __int64 time_sys;

    switch (clock_id) {
    case CLOCK_REALTIME:
        GetSystemTimePreciseAsFileTime(&ft.ft_val);
        time_sys = ft.ft_i64;
        tp->tv_sec = (time_t)((time_sys - EPOCH_BIAS) / IV_1E7);
        tp->tv_nsec = (long)((time_sys % IV_1E7) * 100);
        break;
    case CLOCK_MONOTONIC:
        QueryPerformanceCounter((LARGE_INTEGER*)&ft.ft_i64);
        ticks = ft.ft_i64;
        tp->tv_sec = (time_t)(ticks / tick_frequency);
        tp->tv_nsec = (long)((IV_1E9 * (ticks % tick_frequency)) / tick_frequency);
        break;
    default:
        errno = EINVAL;
        return 1;
    }

    return 0;
}

static int
_clock_getres(clockid_t clock_id, struct timespec *tp)
{
    switch (clock_id) {
    case CLOCK_REALTIME:
        tp->tv_sec = 0;
        tp->tv_nsec = (long)qpc_res_ns_realtime;
        break;

    case CLOCK_MONOTONIC:
        tp->tv_sec = 0;
        tp->tv_nsec = (long)qpc_res_ns;
        break;

    default:
        errno = EINVAL;
        return 1;
    }

    return 0;
}

#endif /* #if defined(WIN32) || defined(CYGWIN_WITH_W32API) */

 /* Do not use H A S _ N A N O S L E E P
  * so that Perl Configure doesn't scan for it (and pull in -lrt and
  * the like which are not usually good ideas for the default Perl).
  * (We are part of the core perl now.)
  * The TIME_HIRES_NANOSLEEP is set by Makefile.PL. */
#if !defined(HAS_USLEEP) && defined(TIME_HIRES_NANOSLEEP)
#  define HAS_USLEEP
#  define usleep hrt_usleep  /* could conflict with ncurses for static build */

static void
hrt_usleep(unsigned long usec) /* This is used to emulate usleep. */
{
    struct timespec res;
    res.tv_sec = usec / IV_1E6;
    res.tv_nsec = ( usec - res.tv_sec * IV_1E6 ) * 1000;
    nanosleep(&res, NULL);
}

#endif /* #if !defined(HAS_USLEEP) && defined(TIME_HIRES_NANOSLEEP) */

#if !defined(HAS_USLEEP) && defined(HAS_SELECT)
#  ifndef SELECT_IS_BROKEN
#    define HAS_USLEEP
#    define usleep hrt_usleep  /* could conflict with ncurses for static build */

static void
hrt_usleep(unsigned long usec)
{
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = usec;
    select(0, (Select_fd_set_t)NULL, (Select_fd_set_t)NULL,
        (Select_fd_set_t)NULL, &tv);
}
#  endif
#endif /* #if !defined(HAS_USLEEP) && defined(HAS_SELECT) */

#if !defined(HAS_USLEEP) && defined(WIN32)
#  define HAS_USLEEP
#  define usleep hrt_usleep  /* could conflict with ncurses for static build */

static void
hrt_usleep(unsigned long usec)
{
    long msec;
    msec = usec / 1000;
    Sleep (msec);
}
#endif /* #if !defined(HAS_USLEEP) && defined(WIN32) */

#if !defined(HAS_USLEEP) && defined(HAS_POLL)
#  define HAS_USLEEP
#  define usleep hrt_usleep  /* could conflict with ncurses for static build */

static void
hrt_usleep(unsigned long usec)
{
    int msec = usec / 1000;
    poll(0, 0, msec);
}

#endif /* #if !defined(HAS_USLEEP) && defined(HAS_POLL) */

#if defined(HAS_SETITIMER) && defined(ITIMER_REAL)

static int
hrt_ualarm_itimero(struct itimerval *oitv, int usec, int uinterval)
{
    struct itimerval itv;
    itv.it_value.tv_sec = usec / IV_1E6;
    itv.it_value.tv_usec = usec % IV_1E6;
    itv.it_interval.tv_sec = uinterval / IV_1E6;
    itv.it_interval.tv_usec = uinterval % IV_1E6;
    return setitimer(ITIMER_REAL, &itv, oitv);
}

#endif /* #if !defined(HAS_UALARM) && defined(HAS_SETITIMER) */

#if !defined(HAS_UALARM) && defined(HAS_SETITIMER)
#  define HAS_UALARM
#  define ualarm hrt_ualarm_itimer  /* could conflict with ncurses for static build */
#endif

#if !defined(HAS_UALARM) && defined(VMS)
#  define HAS_UALARM
#  define ualarm vms_ualarm

#  include <lib$routines.h>
#  include <ssdef.h>
#  include <starlet.h>
#  include <descrip.h>
#  include <signal.h>
#  include <jpidef.h>
#  include <psldef.h>

#  define VMSERR(s)   (!((s)&1))

static void
us_to_VMS(useconds_t mseconds, unsigned long v[])
{
    int iss;
    unsigned long qq[2];

    qq[0] = mseconds;
    qq[1] = 0;
    v[0] = v[1] = 0;

    iss = lib$addx(qq,qq,qq);
    if (VMSERR(iss)) lib$signal(iss);
    iss = lib$subx(v,qq,v);
    if (VMSERR(iss)) lib$signal(iss);
    iss = lib$addx(qq,qq,qq);
    if (VMSERR(iss)) lib$signal(iss);
    iss = lib$subx(v,qq,v);
    if (VMSERR(iss)) lib$signal(iss);
    iss = lib$subx(v,qq,v);
    if (VMSERR(iss)) lib$signal(iss);
}

static int
VMS_to_us(unsigned long v[])
{
    int iss;
    unsigned long div=10,quot, rem;

    iss = lib$ediv(&div,v,&quot,&rem);
    if (VMSERR(iss)) lib$signal(iss);

    return quot;
}

typedef unsigned short word;
typedef struct _ualarm {
    int function;
    int repeat;
    unsigned long delay[2];
    unsigned long interval[2];
    unsigned long remain[2];
} Alarm;


static int alarm_ef;
static Alarm *a0, alarm_base;
#  define UAL_NULL   0
#  define UAL_SET    1
#  define UAL_CLEAR  2
#  define UAL_ACTIVE 4
static void ualarm_AST(Alarm *a);

static int
vms_ualarm(int mseconds, int interval)
{
    Alarm *a, abase;
    struct item_list3 {
        word length;
        word code;
        void *bufaddr;
        void *retlenaddr;
    } ;
    static struct item_list3 itmlst[2];
    static int first = 1;
    unsigned long asten;
    int iss, enabled;

    if (first) {
        first = 0;
        itmlst[0].code       = JPI$_ASTEN;
        itmlst[0].length     = sizeof(asten);
        itmlst[0].retlenaddr = NULL;
        itmlst[1].code       = 0;
        itmlst[1].length     = 0;
        itmlst[1].bufaddr    = NULL;
        itmlst[1].retlenaddr = NULL;

        iss = lib$get_ef(&alarm_ef);
        if (VMSERR(iss)) lib$signal(iss);

        a0 = &alarm_base;
        a0->function = UAL_NULL;
    }
    itmlst[0].bufaddr    = &asten;

    iss = sys$getjpiw(0,0,0,itmlst,0,0,0);
    if (VMSERR(iss)) lib$signal(iss);
    if (!(asten&0x08)) return -1;

    a = &abase;
    if (mseconds) {
        a->function = UAL_SET;
    } else {
        a->function = UAL_CLEAR;
    }

    us_to_VMS(mseconds, a->delay);
    if (interval) {
        us_to_VMS(interval, a->interval);
        a->repeat = 1;
    } else
        a->repeat = 0;

    iss = sys$clref(alarm_ef);
    if (VMSERR(iss)) lib$signal(iss);

    iss = sys$dclast(ualarm_AST,a,0);
    if (VMSERR(iss)) lib$signal(iss);

    iss = sys$waitfr(alarm_ef);
    if (VMSERR(iss)) lib$signal(iss);

    if (a->function == UAL_ACTIVE)
        return VMS_to_us(a->remain);
    else
        return 0;
}



static void
ualarm_AST(Alarm *a)
{
    int iss;
    unsigned long now[2];

    iss = sys$gettim(now);
    if (VMSERR(iss)) lib$signal(iss);

    if (a->function == UAL_SET || a->function == UAL_CLEAR) {
        if (a0->function == UAL_ACTIVE) {
            iss = sys$cantim(a0,PSL$C_USER);
            if (VMSERR(iss)) lib$signal(iss);

            iss = lib$subx(a0->remain, now, a->remain);
            if (VMSERR(iss)) lib$signal(iss);

            if (a->remain[1] & 0x80000000)
                a->remain[0] = a->remain[1] = 0;
        }

        if (a->function == UAL_SET) {
            a->function = a0->function;
            a0->function = UAL_ACTIVE;
            a0->repeat = a->repeat;
            if (a0->repeat) {
                a0->interval[0] = a->interval[0];
                a0->interval[1] = a->interval[1];
            }
            a0->delay[0] = a->delay[0];
            a0->delay[1] = a->delay[1];

            iss = lib$subx(now, a0->delay, a0->remain);
            if (VMSERR(iss)) lib$signal(iss);

            iss = sys$setimr(0,a0->delay,ualarm_AST,a0);
            if (VMSERR(iss)) lib$signal(iss);
        } else {
            a->function = a0->function;
            a0->function = UAL_NULL;
        }
        iss = sys$setef(alarm_ef);
        if (VMSERR(iss)) lib$signal(iss);
    } else if (a->function == UAL_ACTIVE) {
        if (a->repeat) {
            iss = lib$subx(now, a->interval, a->remain);
            if (VMSERR(iss)) lib$signal(iss);

            iss = sys$setimr(0,a->interval,ualarm_AST,a);
            if (VMSERR(iss)) lib$signal(iss);
        } else {
            a->function = UAL_NULL;
        }
        iss = sys$wake(0,0);
        if (VMSERR(iss)) lib$signal(iss);
        lib$signal(SS$_ASTFLT);
    } else {
        lib$signal(SS$_BADPARAM);
    }
}

#endif /* #if !defined(HAS_UALARM) && defined(VMS) */

#ifdef HAS_GETTIMEOFDAY

static int
myU2time(pTHX_ UV *ret)
{
    struct timeval Tp;
    int status;
    status = gettimeofday (&Tp, NULL);
    ret[0] = Tp.tv_sec;
    ret[1] = Tp.tv_usec;
    return status;
}

#ifdef PERL_IMPLICIT_CONTEXT
static NV myNVtime_cxt(pTHX);
#endif

static NV
myNVtime()
{
#  ifdef WIN32
    dTHX;
#    ifdef PERL_IMPLICIT_CONTEXT
   return myNVtime_cxt(aTHX);
#    endif
#  endif
    struct timeval Tp;
    int status;
    status = gettimeofday (&Tp, NULL);
    return status == 0 ? Tp.tv_sec + (Tp.tv_usec / NV_1E6) : -1.0;
}

#ifdef PERL_IMPLICIT_CONTEXT

static NV
myNVtime_cxt(pTHX)
{
    struct timeval Tp;
    int status;
    status = gettimeofday (&Tp, NULL);
    return status == 0 ? Tp.tv_sec + (Tp.tv_usec / NV_1E6) : -1.0;
}

#endif

#endif /* #ifdef HAS_GETTIMEOFDAY */

/*  Force inline this because it has only 1 caller:
        XSUB void stat(...) PROTOTYPE: ;$
    Change back to plain "static", if in the future a 2nd call site is added */

PERL_STATIC_FORCE_INLINE void
S_hrstatns(pTHX_ UV *atime_nsec, UV *mtime_nsec, UV *ctime_nsec)
{
#if TIME_HIRES_STAT == 1
    *atime_nsec = PL_statcache.st_atimespec.tv_nsec;
    *mtime_nsec = PL_statcache.st_mtimespec.tv_nsec;
    *ctime_nsec = PL_statcache.st_ctimespec.tv_nsec;
#elif TIME_HIRES_STAT == 2
    *atime_nsec = PL_statcache.st_atimensec;
    *mtime_nsec = PL_statcache.st_mtimensec;
    *ctime_nsec = PL_statcache.st_ctimensec;
#elif TIME_HIRES_STAT == 3
    *atime_nsec = PL_statcache.st_atime_n;
    *mtime_nsec = PL_statcache.st_mtime_n;
    *ctime_nsec = PL_statcache.st_ctime_n;
#elif TIME_HIRES_STAT == 4
    *atime_nsec = PL_statcache.st_atim.tv_nsec;
    *mtime_nsec = PL_statcache.st_mtim.tv_nsec;
    *ctime_nsec = PL_statcache.st_ctim.tv_nsec;
#elif TIME_HIRES_STAT == 5
    *atime_nsec = PL_statcache.st_uatime * 1000;
    *mtime_nsec = PL_statcache.st_umtime * 1000;
    *ctime_nsec = PL_statcache.st_uctime * 1000;
#else /* !TIME_HIRES_STAT */
    *atime_nsec = 0;
    *mtime_nsec = 0;
    *ctime_nsec = 0;
#endif /* !TIME_HIRES_STAT */
}

#define hrstatns(_at,_mt,_ct) S_hrstatns(aTHX_ (_at),(_mt),(_ct))

/* Until Apple implements clock_gettime()
 * (ditto clock_getres() and clock_nanosleep())
 * we will emulate them using the Mach kernel interfaces. */
#if defined(PERL_DARWIN) && \
  (defined(TIME_HIRES_CLOCK_GETTIME_EMULATION)   || \
   defined(TIME_HIRES_CLOCK_GETRES_EMULATION)    || \
   defined(TIME_HIRES_CLOCK_NANOSLEEP_EMULATION))

#  ifndef CLOCK_REALTIME
#    define CLOCK_REALTIME  0x01
#    define CLOCK_MONOTONIC 0x02
#  endif

#  ifndef TIMER_ABSTIME
#    define TIMER_ABSTIME   0x01
#  endif

#  ifdef USE_ITHREADS
#    define PERL_DARWIN_MUTEX
#  endif

#  ifdef PERL_DARWIN_MUTEX
STATIC perl_mutex darwin_time_mutex;
#  endif

#  include <mach/mach_time.h>

static uint64_t absolute_time_init;
static mach_timebase_info_data_t timebase_info;
static struct timespec timespec_init;

static int darwin_time_init() {
    struct timeval tv;
    int success = 1;
#  ifdef PERL_DARWIN_MUTEX
    MUTEX_LOCK(&darwin_time_mutex);
#  endif
    if (absolute_time_init == 0) {
        /* mach_absolute_time() cannot fail */
        absolute_time_init = mach_absolute_time();
        success = mach_timebase_info(&timebase_info) == KERN_SUCCESS;
        if (success) {
            success = gettimeofday(&tv, NULL) == 0;
            if (success) {
                timespec_init.tv_sec  = tv.tv_sec;
                timespec_init.tv_nsec = tv.tv_usec * 1000;
            }
        }
    }
#  ifdef PERL_DARWIN_MUTEX
    MUTEX_UNLOCK(&darwin_time_mutex);
#  endif
    return success;
}

#  ifdef TIME_HIRES_CLOCK_GETTIME_EMULATION
static int th_clock_gettime(clockid_t clock_id, struct timespec *ts) {
    if (darwin_time_init() && timebase_info.denom) {
        switch (clock_id) {
        case CLOCK_REALTIME:
            {
                uint64_t nanos =
                    ((mach_absolute_time() - absolute_time_init) *
                    (uint64_t)timebase_info.numer) / (uint64_t)timebase_info.denom;
                ts->tv_sec  = timespec_init.tv_sec  + nanos / IV_1E9;
                ts->tv_nsec = timespec_init.tv_nsec + nanos % IV_1E9;
                return 0;
            }

        case CLOCK_MONOTONIC:
            {
                uint64_t nanos =
                    (mach_absolute_time() *
                    (uint64_t)timebase_info.numer) / (uint64_t)timebase_info.denom;
                ts->tv_sec  = nanos / IV_1E9;
                ts->tv_nsec = nanos - ts->tv_sec * IV_1E9;
                return 0;
            }

        default:
            break;
        }
    }

    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
}

#    define clock_gettime(clock_id, ts) th_clock_gettime((clock_id), (ts))

#  endif /* TIME_HIRES_CLOCK_GETTIME_EMULATION */

#  ifdef TIME_HIRES_CLOCK_GETRES_EMULATION
static int th_clock_getres(clockid_t clock_id, struct timespec *ts) {
    if (darwin_time_init() && timebase_info.denom) {
        switch (clock_id) {
        case CLOCK_REALTIME:
        case CLOCK_MONOTONIC:
            ts->tv_sec  = 0;
            /* In newer kernels both the numer and denom are one,
             * resulting in conversion factor of one, which is of
             * course unrealistic. */
            ts->tv_nsec = timebase_info.numer / timebase_info.denom;
            return 0;
        default:
            break;
        }
    }

    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
}

#    define clock_getres(clock_id, ts) th_clock_getres((clock_id), (ts))
#  endif /* TIME_HIRES_CLOCK_GETRES_EMULATION */

#  ifdef TIME_HIRES_CLOCK_NANOSLEEP_EMULATION
static int th_clock_nanosleep(clockid_t clock_id, int flags,
                           const struct timespec *rqtp,
                           struct timespec *rmtp) {
    if (darwin_time_init()) {
        switch (clock_id) {
        case CLOCK_REALTIME:
        case CLOCK_MONOTONIC:
            {
                uint64_t nanos = rqtp->tv_sec * IV_1E9 + rqtp->tv_nsec;
                int success;
                if ((flags & TIMER_ABSTIME)) {
                    uint64_t back =
                        timespec_init.tv_sec * IV_1E9 + timespec_init.tv_nsec;
                    nanos = nanos > back ? nanos - back : 0;
                }
                success =
                    mach_wait_until(mach_absolute_time() + nanos) == KERN_SUCCESS;

                /* In the relative sleep, the rmtp should be filled in with
                 * the 'unused' part of the rqtp in case the sleep gets
                 * interrupted by a signal.  But it is unknown how signals
                 * interact with mach_wait_until().  In the absolute sleep,
                 * the rmtp should stay untouched. */
                rmtp->tv_sec  = 0;
                rmtp->tv_nsec = 0;

                return success;
            }

        default:
            break;
        }
    }

    SETERRNO(EINVAL, LIB_INVARG);
    return -1;
}

#    define clock_nanosleep(clock_id, flags, rqtp, rmtp) \
  th_clock_nanosleep((clock_id), (flags), (rqtp), (rmtp))

#  endif /* TIME_HIRES_CLOCK_NANOSLEEP_EMULATION */

#endif /* PERL_DARWIN */

/* The macOS headers warn about using certain interfaces in
 * OS-release-ignorant manner, for example:
 *
 * warning: 'futimens' is only available on macOS 10.13 or newer
 *       [-Wunguarded-availability-new]
 *
 * (ditto for utimensat)
 *
 * There is clang __builtin_available() *runtime* check for this.
 * The gotchas are that neither __builtin_available() nor __has_builtin()
 * are always available.
 */
#ifndef __has_builtin
#  define __has_builtin(x) 0 /* non-clang */
#endif
#ifdef HAS_FUTIMENS
#  if defined(PERL_DARWIN) && __has_builtin(__builtin_available)
#    define FUTIMENS_AVAILABLE __builtin_available(macOS 10.13, *)
#  else
#    define FUTIMENS_AVAILABLE 1
#  endif
#else
#  define FUTIMENS_AVAILABLE 0
#endif
#ifdef HAS_UTIMENSAT
#  if defined(PERL_DARWIN) && __has_builtin(__builtin_available)
#    define UTIMENSAT_AVAILABLE __builtin_available(macOS 10.13, *)
#  else
#    define UTIMENSAT_AVAILABLE 1
#  endif
#else
#  define UTIMENSAT_AVAILABLE 0
#endif

#include "const-c.inc"

#if (defined(TIME_HIRES_NANOSLEEP)) || \
    (defined(TIME_HIRES_CLOCK_NANOSLEEP) && defined(TIMER_ABSTIME))

static void
nanosleep_init(NV nsec,
                    struct timespec *sleepfor,
                    struct timespec *unslept) {
  sleepfor->tv_sec = (Time_t)(nsec / NV_1E9);
  sleepfor->tv_nsec = (long)(nsec - ((NV)sleepfor->tv_sec) * NV_1E9);
  unslept->tv_sec = 0;
  unslept->tv_nsec = 0;
}

static NV
nsec_without_unslept(struct timespec *sleepfor,
                     const struct timespec *unslept) {
    if (sleepfor->tv_sec >= unslept->tv_sec) {
        sleepfor->tv_sec -= unslept->tv_sec;
        if (sleepfor->tv_nsec >= unslept->tv_nsec) {
            sleepfor->tv_nsec -= unslept->tv_nsec;
        } else if (sleepfor->tv_sec > 0) {
            sleepfor->tv_sec--;
            sleepfor->tv_nsec += IV_1E9;
            sleepfor->tv_nsec -= unslept->tv_nsec;
        } else {
            sleepfor->tv_sec = 0;
            sleepfor->tv_nsec = 0;
        }
    } else {
        sleepfor->tv_sec = 0;
        sleepfor->tv_nsec = 0;
    }
    return ((NV)sleepfor->tv_sec) * NV_1E9 + ((NV)sleepfor->tv_nsec);
}

#endif

/* In case Perl and/or Devel::PPPort are too old, minimally emulate
 * IS_SAFE_PATHNAME() (which looks for zero bytes in the pathname). */
#ifndef IS_SAFE_PATHNAME
#  if PERL_VERSION_GE(5,12,0) /* Perl_ck_warner is 5.10.0 -> */
#    ifdef WARN_SYSCALLS
#      define WARNEMUCAT WARN_SYSCALLS /* 5.22.0 -> */
#    else
#      define WARNEMUCAT WARN_MISC
#    endif
#    define WARNEMU(opname) Perl_ck_warner(aTHX_ packWARN(WARNEMUCAT), "Invalid \\0 character in pathname for %s",opname)
#  else
#    define WARNEMU(opname) Perl_warn(aTHX_ "Invalid \\0 character in pathname for %s",opname)
#  endif
#  define IS_SAFE_PATHNAME(pv, len, opname) (((len)>1)&&memchr((pv), 0, (len)-1)?(SETERRNO(ENOENT, LIB_INVARG),WARNEMU(opname),FALSE):(TRUE))
#endif

static void
S_croak_xs_unimplemented(const CV *const cv);

static void
S_croak_xs_unimplemented(const CV *const cv)
{
    dTHX;
    SV* sv = cv_name(cv, NULL, 0);
    Perl_croak_nocontext(
        "%s::%s(): unimplemented in this platform" + (sizeof("%s::")-1), SvPVX(sv));
#if 0 /* former implementation, retired because of machine code bloat */
    char buf[sizeof("CODE(0x%" UVxf ")") + (sizeof(UV)*8)];
    const char * pv1;
    const GV *const gv = CvGV(cv);
    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;
        if (hvname)
            Perl_croak_nocontext("%s::%s(): unimplemented in this platform",
                hvname, gvname);
        else {
            pv1 = gvname;
            goto one_str;
        }
    } else {
        my_sprintf(buf, sizeof(buf), "CODE(0x%" UVxf ")", PTR2UV(cv));
        pv1 = buf;

        one_str:
        Perl_croak_nocontext(
            "%s::%s(): unimplemented in this platform" + (sizeof("%s::")-1),
            pv1);
    }
#endif
}
#define croak_xs_unimplemented        S_croak_xs_unimplemented

MODULE = Time::HiRes            PACKAGE = Time::HiRes

PROTOTYPES: ENABLE

BOOT:
    {
#ifdef MY_CXT_KEY
        MY_CXT_INIT;
#endif
#if defined(WIN32) || defined(CYGWIN_WITH_W32API)
{
    unsigned __int64 l_qpc_res_ns;
    unsigned __int64 l_qpc_res_ns_realtime;
    unsigned __int64 l_tick_frequency = tick_frequency;
    if (l_tick_frequency == 0) { /* no DllMain() in very rare static Perls */
/* from MSDN: >= WinXP, function will always succeed and never return zero */
        unsigned __int64 l_tick_frequency_mem;
        if (!QueryPerformanceFrequency((LARGE_INTEGER*)&l_tick_frequency_mem))
            croak("%s::%s(): unimplemented in this platform" + (sizeof("%s::")-1),
                "QueryPerformanceFrequency");
        l_tick_frequency = l_tick_frequency_mem;
             /* 32-bit CPU anti-sharding paranoia */
        S_InterlockedExchange64(&tick_frequency, l_tick_frequency);
    }
    l_qpc_res_ns = qpc_res_ns;
    if (l_qpc_res_ns == 0) {
        l_qpc_res_ns = IV_1E9 > l_tick_frequency ? IV_1E9 / l_tick_frequency : 1;
        S_InterlockedExchange64(&qpc_res_ns, l_qpc_res_ns);
    }
    l_qpc_res_ns_realtime = qpc_res_ns_realtime;
    if (l_qpc_res_ns_realtime == 0) {
    /* the resolution can't be smaller than 100ns because our implementation
     * of CLOCK_REALTIME is using FILETIME internally */
        l_qpc_res_ns_realtime = l_qpc_res_ns > 100 ? l_qpc_res_ns : 100;
        S_InterlockedExchange64(&qpc_res_ns_realtime, l_qpc_res_ns_realtime);
    }
    {/* Remove a couple jump stub funcs between kernel32->kernelbase->ntdll
        for perf reasons. RtlQueryPerformanceCounter() was added in NT 6.1,
        so a fallback path is still required to QPC()@K32.dll. */
        pfnQueryPerformanceCounter_T QPCfn = pfnQueryPerformanceCounter;
        if (!QPCfn) {
            HMODULE hmod = GetModuleHandleW(L"NTDLL.DLL");
            if (hmod) {
                QPCfn = (pfnQueryPerformanceCounter_T)GetProcAddress(hmod,"RtlQueryPerformanceCounter");
                if (QPCfn)
                    goto QPC_done;
            }
#undef QueryPerformanceCounter
            QPCfn = QueryPerformanceCounter; /* Get the public API fallback sym. */
#undef QueryPerformanceCounter
#QueryPerformanceCounter pfnQueryPerformanceCounter
            QPC_done:
            S_InterlockedExchangePointer(&pfnQueryPerformanceCounter, QPCfn);
        }
    }
}
#endif
#ifdef HAS_GETTIMEOFDAY
        {
            SV* sv = newSV_type(SVt_PVIV);
#ifdef PERL_IMPLICIT_CONTEXT
            static NV (* const pMyNVtime_cxt)(pTHX) = myNVtime_cxt;
#else
            static NV (* const pMyNVtime_cxt)(pTHX) = myNVtime;
#endif
/*          Don't bother making a 5/9 byte struct{void*; char;} just for '\0'.
            It is 8/16 bytes after padding. This SVPV will never be "printed". */
            SvCUR_set(sv, sizeof(pMyNVtime_cxt));
            SvLEN_set(sv, 0);
            SvIV_set(sv, PTR2IV(myNVtime));
            SvPV_set(sv, (char *)(&pMyNVtime_cxt));
            SvPOK_on(sv);
            SvIOK_on(sv);
            SvREADONLY_on(sv);
            {
                HV* const modglobal = PL_modglobal;
                (void)hv_stores(modglobal, "Time::NVtime", sv);
                (void)hv_stores(modglobal, "Time::U2time", newSViv(PTR2IV(myU2time)));
            }
        }
#endif
#if defined(PERL_DARWIN)
#  if defined(USE_ITHREADS) && defined(PERL_DARWIN_MUTEX)
        MUTEX_INIT(&darwin_time_mutex);
#  endif
#endif
    }

#if defined(USE_ITHREADS) && defined(MY_CXT_KEY)

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;

#endif

INCLUDE: const-xs.inc

#if defined(HAS_USLEEP) && defined(HAS_GETTIMEOFDAY)

NV
usleep(useconds)
    NV useconds
    PREINIT:
        struct timeval Ta, Tb;
    CODE:
        gettimeofday(&Ta, NULL);
        if (items > 0) {
            if (useconds >= NV_1E6) {
                IV seconds = (IV) (useconds / NV_1E6);
                /* If usleep() has been implemented using setitimer()
                 * then this contortion is unnecessary-- but usleep()
                 * may be implemented in some other way, so let's contort. */
                if (seconds) {
                    sleep(seconds);
                    useconds -= NV_1E6 * seconds;
                }
            } else if (useconds < 0.0)
                croak("%s(%" NVgf "%s",
                      "Time::HiRes::usleep", useconds,
                      "): negative time not invented yet");
            usleep((U32)useconds);
        } else
            PerlProc_pause();

        gettimeofday(&Tb, NULL);
#  if 0
        printf("[%ld %ld] [%ld %ld]\n", Tb.tv_sec, Tb.tv_usec, Ta.tv_sec, Ta.tv_usec);
#  endif
        RETVAL = NV_1E6*(Tb.tv_sec-Ta.tv_sec)+(NV)((IV)Tb.tv_usec-(IV)Ta.tv_usec);

    OUTPUT:
        RETVAL

#  if defined(TIME_HIRES_NANOSLEEP)

NV
nanosleep(nsec)
    NV nsec
    PREINIT:
        struct timespec sleepfor, unslept;
    CODE:
        if (nsec < 0.0)
            croak("%s(%" NVgf "%s", "Time::HiRes::nanosleep", nsec,
                  "): negative time not invented yet");
        nanosleep_init(nsec, &sleepfor, &unslept);
        if (nanosleep(&sleepfor, &unslept) == 0) {
            RETVAL = nsec;
        } else {
            RETVAL = nsec_without_unslept(&sleepfor, &unslept);
        }
    OUTPUT:
        RETVAL

#  else  /* #if defined(TIME_HIRES_NANOSLEEP) */

NV_DIE
nanosleep(nsec)
    NV_DIE nsec
    CODE:
        PERL_UNUSED_ARG(nsec);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#  endif /* #if defined(TIME_HIRES_NANOSLEEP) */

NV
sleep(...)
    PREINIT:
        struct timeval Ta, Tb;
    CODE:
        gettimeofday(&Ta, NULL);
        if (items > 0) {
            NV seconds  = SvNV(ST(0));
            if (seconds >= 0.0) {
                UV useconds = (UV)(1E6 * (seconds - (UV)seconds));
                if (seconds >= 1.0)
                    sleep((U32)seconds);
                if ((IV)useconds < 0) {
#  if defined(__sparc64__) && defined(__GNUC__)
                    /* Sparc64 gcc 2.95.3 (e.g. on NetBSD) has a bug
                     * where (0.5 - (UV)(0.5)) will under certain
                     * circumstances (if the double is cast to UV more
                     * than once?) evaluate to -0.5, instead of 0.5. */
                    useconds = -(IV)useconds;
#  endif /* #if defined(__sparc64__) && defined(__GNUC__) */
                    if ((IV)useconds < 0)
                        croak("%s(%" NVgf
                              "): internal error: useconds < 0 (unsigned %" UVuf
                              " signed %" IVdf ")", "Time::HiRes::sleep",
                              seconds, useconds, (IV)useconds);
                }
                usleep(useconds);
            } else
                croak("%s(%" NVgf "%s",
                      "Time::HiRes::sleep", seconds,
                      "): negative time not invented yet");
        } else
            PerlProc_pause();

        gettimeofday(&Tb, NULL);
#  if 0
        printf("[%ld %ld] [%ld %ld]\n", Tb.tv_sec, Tb.tv_usec, Ta.tv_sec, Ta.tv_usec);
#  endif
        RETVAL = (NV)(Tb.tv_sec-Ta.tv_sec)+0.000001*(NV)(Tb.tv_usec-Ta.tv_usec);

    OUTPUT:
        RETVAL

#else  /* #if defined(HAS_USLEEP) && defined(HAS_GETTIMEOFDAY) */

NV_DIE
usleep(useconds)
    NV_DIE useconds
    CODE:
        PERL_UNUSED_ARG(useconds);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /* #if defined(HAS_USLEEP) && defined(HAS_GETTIMEOFDAY) */

#ifdef HAS_UALARM

IV
ualarm(useconds,uinterval=0)
    int useconds
    int uinterval
    CODE:
        if (useconds < 0 || uinterval < 0)
            croak("%s(%d, %d%s",
                "Time::HiRes::ualarm", useconds, uinterval,
                "): negative time not invented yet");
#  if defined(HAS_SETITIMER) && defined(ITIMER_REAL)
        {
            struct itimerval itv;
            if (hrt_ualarm_itimero(&itv, useconds, uinterval)) {
                /* To conform to ualarm's interface, we're actually ignoring
                   an error here.  */
                RETVAL = 0;
            } else {
                RETVAL = itv.it_value.tv_sec * IV_1E6 + itv.it_value.tv_usec;
            }
        }
#  else
        if (useconds >= IV_1E6 || uinterval >= IV_1E6)
            croak("Time::HiRes::ualarm(%d, %d): useconds or uinterval"
                  " equal to or more than %" IVdf,
                  useconds, uinterval, IV_1E6);

        RETVAL = ualarm(useconds, uinterval);
#  endif

    OUTPUT:
        RETVAL

NV
alarm(seconds,interval=0)
    NV seconds
    NV interval
    CODE:
        if (seconds < 0.0 || interval < 0.0)
            croak("%s(%" NVgf ", %" NVgf "%s",
                  "Time::HiRes::alarm", seconds, interval,
                  "): negative time not invented yet");
        {
            IV iseconds = (IV)seconds;
            IV iinterval = (IV)interval;
            NV fseconds = seconds - iseconds;
            NV finterval = interval - iinterval;
            IV useconds, uinterval;
            if (fseconds >= 1.0 || finterval >= 1.0)
                croak("Time::HiRes::alarm(%" NVgf ", %" NVgf
                      "): seconds or interval too large to split correctly",
                      seconds, interval);

            useconds = IV_1E6 * fseconds;
            uinterval = IV_1E6 * finterval;
#  if defined(HAS_SETITIMER) && defined(ITIMER_REAL)
            {
                struct itimerval nitv, oitv;
                nitv.it_value.tv_sec = iseconds;
                nitv.it_value.tv_usec = useconds;
                nitv.it_interval.tv_sec = iinterval;
                nitv.it_interval.tv_usec = uinterval;
                if (setitimer(ITIMER_REAL, &nitv, &oitv)) {
                    /* To conform to alarm's interface, we're actually ignoring
                       an error here.  */
                    RETVAL = 0;
                } else {
                    RETVAL = oitv.it_value.tv_sec + ((NV)oitv.it_value.tv_usec) / NV_1E6;
                }
            }
#  else
            if (iseconds || iinterval)
                croak("Time::HiRes::alarm(%" NVgf ", %" NVgf
                      "): seconds or interval equal to or more than 1.0 ",
                      seconds, interval);

            RETVAL = (NV)ualarm( useconds, uinterval ) / NV_1E6;
#  endif
        }

    OUTPUT:
        RETVAL

#else /* #ifdef HAS_UALARM */

int die_t
ualarm(useconds,interval=0)
    int die_t useconds
    int die_t interval
    CODE:
        PERL_UNUSED_ARG(useconds);
        PERL_UNUSED_ARG(interval);
        croak_xs_unimplemented(cv);
        RETVAL = -1;
    OUTPUT:
        RETVAL

NV_DIE
alarm(seconds,interval=0)
    NV_DIE seconds
    NV_DIE interval
    CODE:
        PERL_UNUSED_ARG(seconds);
        PERL_UNUSED_ARG(interval);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /* #ifdef HAS_UALARM */

#ifdef HAS_GETTIMEOFDAY

void
gettimeofday()
    PREINIT:
        struct timeval Tp;
        int status;
        U8 is_G_LIST = GIMME_V == G_LIST;
    PPCODE:
        if (is_G_LIST)
            EXTEND(sp, 2);
        status = gettimeofday (&Tp, NULL);
        if (status == 0) {
            if (is_G_LIST) { /* copy to registers to prove sv_2mortal/newSViv */
                IV sec = Tp.tv_sec; /* can't modify the values */
                IV usec = Tp.tv_usec;
                PUSHs(sv_2mortal(newSViv(sec)));
                PUSHs(sv_2mortal(newSViv(usec)));
            } else {
                NV nv = Tp.tv_sec + (Tp.tv_usec / NV_1E6);
                PUSHs(sv_2mortal(newSVnv(nv)));
            }
        }

NV
time()
    PREINIT:
        struct timeval Tp;
    CODE:
        int status;
        status = gettimeofday (&Tp, NULL);
        if (status == 0) {
            RETVAL = Tp.tv_sec + (Tp.tv_usec / NV_1E6);
        } else {
            RETVAL = -1.0;
        }
    OUTPUT:
        RETVAL

#endif /* #ifdef HAS_GETTIMEOFDAY */

#if defined(HAS_GETITIMER) && defined(HAS_SETITIMER)

#  define TV2NV(tv) ((NV)((tv).tv_sec) + 0.000001 * (NV)((tv).tv_usec))

void
setitimer(which, seconds, interval = 0)
    int which
    NV seconds
    NV interval
    PREINIT:
        struct itimerval newit;
        struct itimerval oldit;
    PPCODE:
        if (seconds < 0.0 || interval < 0.0)
            croak("%s(%" IVdf ", %" NVgf ", %" NVgf "%s",
                  "Time::HiRes::setitimer",
                  (IV)which, seconds, interval,
                  "): negative time not invented yet");
        newit.it_value.tv_sec  = (IV)seconds;
        newit.it_value.tv_usec =
          (IV)((seconds  - (NV)newit.it_value.tv_sec)    * NV_1E6);
        newit.it_interval.tv_sec  = (IV)interval;
        newit.it_interval.tv_usec =
          (IV)((interval - (NV)newit.it_interval.tv_sec) * NV_1E6);
        /* on some platforms the 1st arg to setitimer is an enum, which
         * causes -Wc++-compat to complain about passing an int instead
         */
        GCC_DIAG_IGNORE_CPP_COMPAT_STMT;
        if (setitimer(which, &newit, &oldit) == 0) {
            PUSHs(sv_2mortal(newSVnv(TV2NV(oldit.it_value))));
            if (GIMME_V == G_LIST) {
                PUSHs(sv_2mortal(newSVnv(TV2NV(oldit.it_interval))));
            }
        }
        GCC_DIAG_IGNORE_CPP_COMPAT_RESTORE_STMT;

void
getitimer(which)
    int which
    PREINIT:
        struct itimerval nowit;
    PPCODE:
        /* on some platforms the 1st arg to getitimer is an enum, which
         * causes -Wc++-compat to complain about passing an int instead
         */
        GCC_DIAG_IGNORE_CPP_COMPAT_STMT;
        if (getitimer(which, &nowit) == 0) {
            PUSHs(sv_2mortal(newSVnv(TV2NV(nowit.it_value))));
            if (GIMME_V == G_LIST) {
                EXTEND(sp, 1);
                PUSHs(sv_2mortal(newSVnv(TV2NV(nowit.it_interval))));
            }
        }
        GCC_DIAG_IGNORE_CPP_COMPAT_RESTORE_STMT;

#endif /* #if defined(HAS_GETITIMER) && defined(HAS_SETITIMER) */

#if defined(TIME_HIRES_UTIME)

I32
utime(accessed, modified, ...)
PROTOTYPE: $$@
    PREINIT:
        SV* accessed;
        SV* modified;
        SV* file;

        struct timespec utbuf[2];
        struct timespec *utbufp = utbuf;
        int tot;

    CODE:
        accessed = ST(0);
        modified = ST(1);
        items -= 2;
        tot = 0;

        if ( accessed == &PL_sv_undef && modified == &PL_sv_undef )
            utbufp = NULL;
        else {
            NV modified_nv = SvNV(modified);
            NV accessed_nv = SvNV(accessed);
            if (accessed_nv < 0.0 || modified_nv < 0.0)
                croak("%s(%" NVgf ", %" NVgf "%s", "Time::HiRes::utime",
                          accessed_nv, modified_nv,
                          "): negative time not invented yet");
            Zero(&utbuf, sizeof utbuf, char);

            utbuf[0].tv_sec = (Time_t)accessed_nv;  /* time accessed */
            utbuf[0].tv_nsec = (long)(
                (accessed_nv - (NV)utbuf[0].tv_sec)
                * NV_1E9 + (NV)0.5);

            utbuf[1].tv_sec = (Time_t)modified_nv;  /* time modified */
            utbuf[1].tv_nsec = (long)(
                (modified_nv - (NV)utbuf[1].tv_sec)
                * NV_1E9 + (NV)0.5);
        }

        while (items > 0) {
            PerlIO * pio;
            file = POPs; items--;

            if (SvROK(file) && GvIO(SvRV(file)) && (pio = IoIFP(sv_2io(SvRV(file))))) {
	        int fd =  PerlIO_fileno(pio);
                if (fd < 0) {
                    SETERRNO(EBADF,RMS_IFI);
                } else {
#  ifdef HAS_FUTIMENS
                    if (FUTIMENS_AVAILABLE) {
                        if (futimens(fd, utbufp) == 0) {
                            tot++;
                        }
                    } else {
                        croak("%s unimplemented in this platform", "futimens");
                    }
#  else  /* HAS_FUTIMENS */
                    croak("%s unimplemented in this platform", "futimens");
#  endif /* HAS_FUTIMENS */
                }
            }
            else {
#  ifdef HAS_UTIMENSAT
                if (UTIMENSAT_AVAILABLE) {
                    STRLEN len;
                    const char * name = SvPV_const(file, len);
                    if (IS_SAFE_PATHNAME(name, len, "utime") &&
                        utimensat(AT_FDCWD, name, utbufp, 0) == 0) {

                        tot++;
                    }
                } else {
                    croak("%s unimplemented in this platform", "utimensat");
                }
#  else  /* HAS_UTIMENSAT */
                croak("%s unimplemented in this platform", "utimensat");
#  endif /* HAS_UTIMENSAT */
            }
        } /* while items */
        RETVAL = tot;

    OUTPUT:
        RETVAL

#else  /* #if defined(TIME_HIRES_UTIME) */

I32_DIE
utime(accessed, modified, ...)
    CODE:
        croak_xs_unimplemented(cv);
        RETVAL = 0;
    OUTPUT:
        RETVAL

#endif /* #if defined(TIME_HIRES_UTIME) */

#if defined(TIME_HIRES_CLOCK_GETTIME)

NV
clock_gettime(clock_id = CLOCK_REALTIME)
    clockid_t clock_id
    PREINIT:
        struct timespec ts;
        int status;
    CODE:
#  ifdef TIME_HIRES_CLOCK_GETTIME_SYSCALL
        status = syscall(SYS_clock_gettime, clock_id, &ts);
#  else
        status = clock_gettime(clock_id, &ts);
#  endif
        RETVAL = status == 0 ? ts.tv_sec + (NV) ts.tv_nsec / NV_1E9 : -1;

    OUTPUT:
        RETVAL

#else  /* if defined(TIME_HIRES_CLOCK_GETTIME) */

NV_DIE
clock_gettime(clock_id = 0)
    clockid_t die_t clock_id
    CODE:
        PERL_UNUSED_ARG(clock_id);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /*  #if defined(TIME_HIRES_CLOCK_GETTIME) */

#if defined(TIME_HIRES_CLOCK_GETRES)

NV
clock_getres(clock_id = CLOCK_REALTIME)
    clockid_t clock_id
    PREINIT:
        int status;
        struct timespec ts;
    CODE:
#  ifdef TIME_HIRES_CLOCK_GETRES_SYSCALL
        status = syscall(SYS_clock_getres, clock_id, &ts);
#  else
        status = clock_getres(clock_id, &ts);
#  endif
        RETVAL = status == 0 ? ts.tv_sec + (NV) ts.tv_nsec / NV_1E9 : -1;

    OUTPUT:
        RETVAL

#else  /* if defined(TIME_HIRES_CLOCK_GETRES) */

NV_DIE
clock_getres(clock_id = 0)
    clockid_t die_t clock_id
    CODE:
        PERL_UNUSED_ARG(clock_id);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /*  #if defined(TIME_HIRES_CLOCK_GETRES) */

#if defined(TIME_HIRES_CLOCK_NANOSLEEP) && defined(TIMER_ABSTIME)

NV
clock_nanosleep(clock_id, nsec, flags = 0)
    clockid_t clock_id
    NV  nsec
    int flags
    PREINIT:
        struct timespec sleepfor, unslept;
    CODE:
        if (nsec < 0.0)
            croak("%s(..., %" NVgf "%s",
                  "Time::HiRes::clock_nanosleep", nsec,
                  "): negative time not invented yet");
        nanosleep_init(nsec, &sleepfor, &unslept);
        if (clock_nanosleep(clock_id, flags, &sleepfor, &unslept) == 0) {
            RETVAL = nsec;
        } else {
            RETVAL = nsec_without_unslept(&sleepfor, &unslept);
        }
    OUTPUT:
        RETVAL

#else  /* if defined(TIME_HIRES_CLOCK_NANOSLEEP) && defined(TIMER_ABSTIME) */

NV_DIE
clock_nanosleep(clock_id, nsec, flags = 0)
    clockid_t die_t clock_id
    NV_DIE  nsec
    int die_t flags
    CODE:
        PERL_UNUSED_ARG(clock_id);
        PERL_UNUSED_ARG(nsec);
        PERL_UNUSED_ARG(flags);
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /*  #if defined(TIME_HIRES_CLOCK_NANOSLEEP) && defined(TIMER_ABSTIME) */

#if defined(TIME_HIRES_CLOCK) && defined(CLOCKS_PER_SEC)

NV
clock()
    PREINIT:
        clock_t clocks;
    CODE:
        clocks = clock();
        RETVAL = clocks == (clock_t) -1 ? (clock_t) -1 : (NV)clocks / (NV)CLOCKS_PER_SEC;

    OUTPUT:
        RETVAL

#else  /* if defined(TIME_HIRES_CLOCK) && defined(CLOCKS_PER_SEC) */

NV_DIE
clock()
    CODE:
        croak_xs_unimplemented(cv);
        RETVAL = 0.0;
    OUTPUT:
        RETVAL

#endif /*  #if defined(TIME_HIRES_CLOCK) && defined(CLOCKS_PER_SEC) */

void
stat(...)
PROTOTYPE: ;$
    PREINIT:
        SSize_t nret;
        SV* sv_arg;
        SV** SPBASE;
        U32 op_type = (U32)ix;
    ALIAS:
        Time::HiRes::stat = OP_STAT
        Time::HiRes::lstat = OP_LSTAT
    PPCODE:
        EXTEND(SP, 13);
        sv_arg = items == 1 ? ST(0) : DEFSV;
        /* XXX will pp_stat()/pp_lstat() really modify $_[0] ? */
        PUSHs(sv_2mortal(THR_newSVsv_cow(sv_arg)));
        PUTBACK;
        ENTER;
        PL_laststatval = -1;
        SAVEOP();
        {
            OP* (*ppaddr)(pTHX);
            U8 gimme = GIMME_V; /* ILP */
/* extern "C" memset() doesn't know struct OP's alignment. ISO C doesn't
   promise Zero(); and memset(); will inline.  But this does. Now the CC can
   detangle for us, what OP fields will get a 0/NULL, or our values. */
            OP fakeop = {0};
            fakeop.op_flags = gimme == G_LIST ? OPf_WANT_LIST :
                gimme == G_SCALAR ? OPf_WANT_SCALAR : OPf_WANT_VOID; /* ILP */
            ppaddr = PL_ppaddr[op_type];
            fakeop.op_type = (U16)op_type;
            fakeop.op_ppaddr = ppaddr; /* ILP */
            PL_op = &fakeop;
            (void)ppaddr(aTHX);
        }
        LEAVE;
        SPAGAIN;
        SPBASE = &ST(0);
        nret = SP+1 - SPBASE;
        if (nret == 13) {
            UV atime_nsec;
            UV mtime_nsec;
            UV ctime_nsec;
            hrstatns(&atime_nsec, &mtime_nsec, &ctime_nsec);
            if (atime_nsec) { /* on certain configs hrstatns() is a NOOP */
                UV atime = SvUV(SPBASE[ 8]);
                SPBASE[ 8] = sv_2mortal(newSVnv(atime + (NV) atime_nsec / NV_1E9));
            }
            if (mtime_nsec) {
                UV mtime = SvUV(SPBASE[ 9]);
                SPBASE[ 9] = sv_2mortal(newSVnv(mtime + (NV) mtime_nsec / NV_1E9));
            }
            if (ctime_nsec) {
                UV ctime = SvUV(SPBASE[10]);
                SPBASE[10] = sv_2mortal(newSVnv(ctime + (NV) ctime_nsec / NV_1E9));
            }
        }
        XSRETURN(nret);
