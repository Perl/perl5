#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <time.h>

#define    DAYS_PER_YEAR    365
#define    DAYS_PER_QYEAR    (4*DAYS_PER_YEAR+1)
#define    DAYS_PER_CENT    (25*DAYS_PER_QYEAR-1)
#define    DAYS_PER_QCENT    (4*DAYS_PER_CENT+1)
#define    SECS_PER_HOUR    (60*60)
#define    SECS_PER_DAY    (24*SECS_PER_HOUR)
/* parentheses deliberately absent on these two, otherwise they don't work */
#define    MONTH_TO_DAYS    153/5
#define    DAYS_TO_MONTH    5/153
/* offset to bias by March (month 4) 1st between month/mday & year finding */
#define    YEAR_ADJUST    (4*MONTH_TO_DAYS+1)
/* as used here, the algorithm leaves Sunday as day 1 unless we adjust it */
#define    WEEKDAY_BIAS    6    /* (1+6)%7 makes Sunday 0 again */
#define    TP_BUF_SIZE     160

#  ifndef MIN
#    define MIN(a,b) ((a) < (b) ? (a) : (b))
#  endif

#ifdef HAVE_TIMEGM

#    define my_timegm timegm

#elif defined(WIN32)

#    define my_timegm _mkgmtime

#else
/* Fallback for platforms without timegm() (AIX, HP-UX, QNX, old Solaris) */
/* Howard Hinnant's algorithm - public domain */
static int days_from_civil(int y, int m, int d) {
	y -= m <= 2;
	const int era = (y >= 0 ? y : y-399) / 400;
	const int yoe = y - era * 400;
	const int doy = (153*(m + (m > 2 ? -3 : 9)) + 2)/5 + d-1;
	const int doe = yoe * 365 + yoe/4 - yoe/100 + doy;
	return era * 146097 + doe - 719468;
}

static time_t my_timegm(struct tm *tm) {
	int year = tm->tm_year + 1900;
	int month = tm->tm_mon;

	/* Normalize month */
	if (month > 11) {
		year += month / 12;
		month %= 12;
	} else if (month < 0) {
		const int years_diff = (11 - month) / 12;
		year -= years_diff;
		month += 12 * years_diff;
	}

	const int days_since_epoch = days_from_civil(year, month + 1, tm->tm_mday);

	return 60 * (60 * (24L * days_since_epoch + tm->tm_hour) + tm->tm_min) + tm->tm_sec;
}

#endif

#ifdef WIN32

/*
 * (1) The CRT maintains its own copy of the environment, separate from
 * the Win32API copy.
 *
 * (2) CRT getenv() retrieves from this copy. CRT putenv() updates this
 * copy, and then calls SetEnvironmentVariableA() to update the Win32API
 * copy.
 *
 * (3) win32_getenv() and win32_putenv() call GetEnvironmentVariableA() and
 * SetEnvironmentVariableA() directly, bypassing the CRT copy of the
 * environment.
 *
 * (4) The CRT strftime() "%Z" implementation calls __tzset(). That
 * calls CRT tzset(), but only the first time it is called, and in turn
 * that uses CRT getenv("TZ") to retrieve the timezone info from the CRT
 * local copy of the environment and hence gets the original setting as
 * perl never updates the CRT copy when assigning to $ENV{TZ}.
 *
 * Therefore, we need to retrieve the value of $ENV{TZ} and call CRT
 * putenv() to update the CRT copy of the environment (if it is different)
 * whenever we're about to call tzset().
 *
 * In addition to all that, when perl is built with PERL_IMPLICIT_SYS
 * defined:
 *
 * (a) Each interpreter has its own copy of the environment inside the
 * perlhost structure. That allows applications that host multiple
 * independent Perl interpreters to isolate environment changes from
 * each other. (This is similar to how the perlhost mechanism keeps a
 * separate working directory for each Perl interpreter, so that calling
 * chdir() will not affect other interpreters.)
 *
 * (b) Only the first Perl interpreter instantiated within a process will
 * "write through" environment changes to the process environment.
 *
 * (c) Even the primary Perl interpreter won't update the CRT copy of the
 * the environment, only the Win32API copy (it calls win32_putenv()).
 *
 * As with CPerlHost::Getenv() and CPerlHost::Putenv() themselves, it makes
 * sense to only update the process environment when inside the main
 * interpreter, but we don't have access to CPerlHost's m_bTopLevel member
 * from here so we'll just have to check PL_curinterp instead.
 *
 * Therefore, we can simply #undef getenv() and putenv() so that those names
 * always refer to the CRT functions, and explicitly call win32_getenv() to
 * access perl's %ENV.
 *
 * We also #undef malloc() and free() to be sure we are using the CRT
 * functions otherwise under PERL_IMPLICIT_SYS they are redefined to calls
 * into VMem::Malloc() and VMem::Free() and all allocations will be freed
 * when the Perl interpreter is being destroyed so we'd end up with a pointer
 * into deallocated memory in environ[] if a program embedding a Perl
 * interpreter continues to operate even after the main Perl interpreter has
 * been destroyed.
 *
 * Note that we don't free() the malloc()ed memory unless and until we call
 * malloc() again ourselves because the CRT putenv() function simply puts its
 * pointer argument into the environ[] array (it doesn't make a copy of it)
 * so this memory must otherwise be leaked.
 */

#undef getenv
#undef putenv
#  ifdef UNDER_CE
#    define getenv xcegetenv
#    define putenv xceputenv
#  endif
#undef malloc
#undef free

static void
fix_win32_tzenv(void)
{
    static char* oldenv = NULL;
    char* newenv;
    const char* perl_tz_env = win32_getenv("TZ");
    const char* crt_tz_env = getenv("TZ");
    if (perl_tz_env == NULL)
        perl_tz_env = "";
    if (crt_tz_env == NULL)
        crt_tz_env = "";
    if (strcmp(perl_tz_env, crt_tz_env) != 0) {
        STRLEN perl_tz_env_len = strlen(perl_tz_env);
        newenv = (char*)malloc(perl_tz_env_len + 4);
        if (newenv != NULL) {
/* putenv with old MS CRTs will cause a double free internally if you delete
   an env var with the CRT env that doesn't exist in Win32 env (perl %ENV only
   modifies the Win32 env, not CRT env), so always create the env var in Win32
   env before deleting it with CRT env api, so the error branch never executes
   in __crtsetenv after SetEnvironmentVariableA executes inside __crtsetenv.

   VC 9/2008 and up dont have this bug, older VC (msvcrt80.dll and older) and
   mingw (msvcrt.dll) have it see [perl #125529]
*/
#if !(_MSC_VER >= 1500)
            if(!perl_tz_env_len)
                SetEnvironmentVariableA("TZ", "");
#endif
            sprintf(newenv, "TZ=%s", perl_tz_env);
            putenv(newenv);
            if (oldenv != NULL)
                free(oldenv);
            oldenv = newenv;
        }
    }
}

#endif

/*
 * my_tzset - wrapper to tzset() with a fix to make it work (better) on Win32.
 * This code is duplicated in the POSIX module, so any changes made here
 * should be made there too.
 */
static void
my_tzset(pTHX)
{
#ifdef WIN32
#if defined(USE_ITHREADS) && defined(PERL_IMPLICIT_SYS)
    if (PL_curinterp == aTHX)
#endif
        fix_win32_tzenv();
#endif
    tzset();
}

/*
 * my_mini_mktime - normalise struct tm values without the localtime()
 * semantics (and overhead) of mktime(). Stolen shamelessly from Perl's
 * Perl_mini_mktime() in util.c - for details on the algorithm, see that
 * file.
 */
static void
my_mini_mktime(struct tm *ptm)
{
    int yearday;
    int secs;
    int month, mday, year, jday;
    int odd_cent, odd_year;

    year = 1900 + ptm->tm_year;
    month = ptm->tm_mon;
    mday = ptm->tm_mday;
    /* allow given yday with no month & mday to dominate the result */
    if (ptm->tm_yday >= 0 && mday <= 0 && month <= 0) {
        month = 0;
        mday = 0;
        jday = 1 + ptm->tm_yday;
    }
    else {
        jday = 0;
    }
    if (month >= 2)
        month+=2;
    else
        month+=14, year--;

    yearday = DAYS_PER_YEAR * year + year/4 - year/100 + year/400;
    yearday += month*MONTH_TO_DAYS + mday + jday;
    /*
     * Note that we don't know when leap-seconds were or will be,
     * so we have to trust the user if we get something which looks
     * like a sensible leap-second.  Wild values for seconds will
     * be rationalised, however.
     */
    if ((unsigned) ptm->tm_sec <= 60) {
        secs = 0;
    }
    else {
        secs = ptm->tm_sec;
        ptm->tm_sec = 0;
    }
    secs += 60 * ptm->tm_min;
    secs += SECS_PER_HOUR * ptm->tm_hour;
    if (secs < 0) {
        if (secs-(secs/SECS_PER_DAY*SECS_PER_DAY) < 0) {
            /* got negative remainder, but need positive time */
            /* back off an extra day to compensate */
            yearday += (secs/SECS_PER_DAY)-1;
            secs -= SECS_PER_DAY * (secs/SECS_PER_DAY - 1);
        }
        else {
            yearday += (secs/SECS_PER_DAY);
            secs -= SECS_PER_DAY * (secs/SECS_PER_DAY);
        }
    }
    else if (secs >= SECS_PER_DAY) {
        yearday += (secs/SECS_PER_DAY);
        secs %= SECS_PER_DAY;
    }
    ptm->tm_hour = secs/SECS_PER_HOUR;
    secs %= SECS_PER_HOUR;
    ptm->tm_min = secs/60;
    secs %= 60;
    ptm->tm_sec += secs;
    /* done with time of day effects */
    /*
     * The algorithm for yearday has (so far) left it high by 428.
     * To avoid mistaking a legitimate Feb 29 as Mar 1, we need to
     * bias it by 123 while trying to figure out what year it
     * really represents.  Even with this tweak, the reverse
     * translation fails for years before A.D. 0001.
     * It would still fail for Feb 29, but we catch that one below.
     */
    jday = yearday;    /* save for later fixup vis-a-vis Jan 1 */
    yearday -= YEAR_ADJUST;
    year = (yearday / DAYS_PER_QCENT) * 400;
    yearday %= DAYS_PER_QCENT;
    odd_cent = yearday / DAYS_PER_CENT;
    year += odd_cent * 100;
    yearday %= DAYS_PER_CENT;
    year += (yearday / DAYS_PER_QYEAR) * 4;
    yearday %= DAYS_PER_QYEAR;
    odd_year = yearday / DAYS_PER_YEAR;
    year += odd_year;
    yearday %= DAYS_PER_YEAR;
    if (!yearday && (odd_cent==4 || odd_year==4)) { /* catch Feb 29 */
        month = 1;
        yearday = 29;
    }
    else {
        yearday += YEAR_ADJUST;    /* recover March 1st crock */
        month = yearday*DAYS_TO_MONTH;
        yearday -= month*MONTH_TO_DAYS;
        /* recover other leap-year adjustment */
        if (month > 13) {
            month-=14;
            year++;
        }
        else {
            month-=2;
        }
    }
    ptm->tm_year = year - 1900;
    if (yearday) {
      ptm->tm_mday = yearday;
      ptm->tm_mon = month;
    }
    else {
      ptm->tm_mday = 31;
      ptm->tm_mon = month - 1;
    }
    /* re-build yearday based on Jan 1 to get tm_yday */
    year--;
    yearday = year*DAYS_PER_YEAR + year/4 - year/100 + year/400;
    yearday += 14*MONTH_TO_DAYS + 1;
    ptm->tm_yday = jday - yearday;
    /* fix tm_wday if not overridden by caller */
    ptm->tm_wday = (jday + WEEKDAY_BIAS) % 7;
}

static struct tm
safe_localtime(pTHX_ const time_t *tp)
{
    struct tm *result = localtime(tp);
    if (!result) {
        croak("localtime failed for invalid time value");
    }
    return *result;
}

static struct tm
safe_gmtime(pTHX_ const time_t *tp)
{
    struct tm *result = gmtime(tp);
    if (!result) {
        croak("gmtime failed for invalid time value");
    }
    return *result;
}

#   if defined(WIN32) || (defined(__QNX__) && defined(__WATCOMC__))
#       define strncasecmp(x,y,n) strnicmp(x,y,n)
#   endif

/* strptime.c    0.1 (Powerdog) 94/03/27 */
/* strptime copied from freebsd with the following copyright: */
/*
 * Copyright (c) 1994 Powerdog Industries.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY POWERDOG INDUSTRIES ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE POWERDOG INDUSTRIES BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation
 * are those of the authors and should not be interpreted as representing
 * official policies, either expressed or implied, of Powerdog Industries.
 */

static char * _strptime(pTHX_ const char *, const char *, struct tm *,
			int *got_GMT, HV *locales);


static char *
_strptime(pTHX_ const char *buf, const char *fmt, struct tm *tm, int *got_GMT, HV *locales)
{
	char c;
	const char *ptr;
	int i;
	size_t len = 0;
	int Ealternative, Oalternative;

    /* There seems to be a slightly improved version at
     * http://www.opensource.apple.com/source/Libc/Libc-583/stdtime/strptime-fbsd.c
     * which we may end up borrowing more from
     */
	ptr = fmt;
	while (*ptr != 0) {
		if (*buf == 0)
			break;

		c = *ptr++;
		
		if (c != '%') {
			if (isSPACE((unsigned char)c))
				while (*buf != 0 && isSPACE((unsigned char)*buf))
					buf++;
			else if (c != *buf++) {
				warn("Time string mismatches format string");
				return NULL;
			}
			continue;
		}

		Ealternative = 0;
		Oalternative = 0;
label:
		c = *ptr++;
		switch (c) {
		case 0:
		case '%':
			if (*buf++ != '%')
				return NULL;
			break;

		case '+':
			buf = _strptime(aTHX_ buf, "%c", tm, got_GMT, locales);
			if (buf == 0)
				return NULL;
			break;

		case 'C':
			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			/* XXX This will break for 3-digit centuries. */
                        len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (i < 19)
				return NULL;

			tm->tm_year = i * 100 - 1900;
			break;

		case 'D':
			buf = _strptime(aTHX_ buf, "%m/%d/%y", tm, got_GMT, locales);
			if (buf == 0)
				return NULL;
			break;

		case 'E':
			if (Ealternative || Oalternative)
				break;
			Ealternative++;
			goto label;

		case 'O':
			if (Ealternative || Oalternative)
				break;
			Oalternative++;
			goto label;

		case 'F':
			buf = _strptime(aTHX_ buf, "%Y-%m-%d", tm, got_GMT, locales);
			if (buf == 0)
				return NULL;
			break;

		case 'R':
			buf = _strptime(aTHX_ buf, "%H:%M", tm, got_GMT, locales);
			if (buf == 0)
				return NULL;
			break;

		case 'r':
			{
				SV** am_sv = hv_fetchs(locales, "AM", 0);
				if (am_sv && SvPOK(*am_sv) && SvCUR(*am_sv) > 0) {
					buf = _strptime(aTHX_ buf, "%I:%M:%S %p", tm, got_GMT, locales);
				} else {
					buf = _strptime(aTHX_ buf, "%H:%M:%S", tm, got_GMT, locales);
				}
			}
			if (buf == 0)
				return NULL;
			break;

		case 'n': /* whitespace */
		case 't':
			if (!isSPACE((unsigned char)*buf))
				return NULL;
			while (isSPACE((unsigned char)*buf))
				buf++;
			break;
		
		case 'T':
			buf = _strptime(aTHX_ buf, "%H:%M:%S", tm, got_GMT, locales);
			if (buf == 0)
				return NULL;
			break;

		case 'j':
			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 3;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (i < 1 || i > 366)
				return NULL;

			tm->tm_yday = i - 1;
			tm->tm_mday = 0;
			break;

		case 'M':
		case 'S':
			if (*buf == 0 || isSPACE((unsigned char)*buf))
				break;

			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}

			if (c == 'M') {
				if (i > 59)
					return NULL;
				tm->tm_min = i;
			} else {
				if (i > 60)
					return NULL;
				tm->tm_sec = i;
			}

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'H':
		case 'I':
		case 'k':
		case 'l':
			/*
			 * Of these, %l is the only specifier explicitly
			 * documented as not being zero-padded.  However,
			 * there is no harm in allowing zero-padding.
			 *
			 * XXX The %l specifier may gobble one too many
			 * digits if used incorrectly.
			 */
            if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (c == 'H' || c == 'k') {
				if (i > 23)
					return NULL;
			} else if (i > 12) {
					warn("Hour cannot be >12 with %%I or %%l");
				return NULL;
			}

			tm->tm_hour = i;

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'p':
		case 'P':
			/*
			 * XXX This is bogus if parsed before hour-related
			 * specifiers.
			 */
			{
				SV** am_sv = hv_fetchs(locales, "am", 0);
				SV** AM_sv = hv_fetchs(locales, "AM", 0);
				if (am_sv && SvPOK(*am_sv) && AM_sv && SvPOK(*AM_sv)) {
					char* am_str = SvPV_nolen(*am_sv);
					char* AM_str = SvPV_nolen(*AM_sv);
					len = MIN(strlen(am_str),strlen(AM_str));
					if ((strncasecmp(buf, am_str, len) == 0) ||
							strncasecmp(buf, AM_str, len) == 0) {
						if (tm->tm_hour > 12) {
							warn("Hour cannot be >12 with %%p");
							return NULL;
						}

						if (tm->tm_hour == 12)
							tm->tm_hour = 0;
						buf += len;
						break;
					}
				}

				SV** pm_sv = hv_fetchs(locales, "pm", 0);
				SV** PM_sv = hv_fetchs(locales, "PM", 0);
				if (pm_sv && SvPOK(*pm_sv) && PM_sv && SvPOK(*PM_sv)) {
					char* pm_str = SvPV_nolen(*pm_sv);
					char* PM_str = SvPV_nolen(*PM_sv);
					len = MIN(strlen(pm_str),strlen(PM_str));
					if ((strncasecmp(buf, pm_str, len) == 0) ||
							strncasecmp(buf, PM_str, len) == 0) {
						if (tm->tm_hour > 12) {
							warn("Hour cannot be >12 with %%p");
							return NULL;
						}
						if (tm->tm_hour != 12)
							tm->tm_hour += 12;
						buf += len;
						break;
					}
				}
			}

			warn("Failed parsing %%p");
			return NULL;

		case 'A':
		case 'a':
			{
			SV** weekday_sv = hv_fetchs(locales, "weekday", 0);
			SV** wday_sv = hv_fetchs(locales, "wday", 0);
			if (!weekday_sv || !wday_sv || !SvROK(*weekday_sv) || !SvROK(*wday_sv))
				return NULL;

			AV* weekday_av = (AV*)SvRV(*weekday_sv);
			AV* wday_av = (AV*)SvRV(*wday_sv);

			/* Use longest-match to handle ambiguous prefixes
				(e.g., "Cuma" vs "Cumartesi" in Turkish) */
			int best_match = -1;
			size_t best_len = 0;

			for (i = 0; i <= av_len(weekday_av); i++) {
				SV** day_sv;

				/* Try full weekday name */
				day_sv = av_fetch(weekday_av, i, 0);
				if (day_sv && SvPOK(*day_sv)) {
					char* day_str = SvPV(*day_sv, len);
					if (len > best_len && strncasecmp(buf, day_str, len) == 0) {
						best_match = i;
						best_len = len;
					}
				}

				/* Try abbreviated weekday name */
				day_sv = av_fetch(wday_av, i, 0);
				if (day_sv && SvPOK(*day_sv)) {
					char* day_str = SvPV(*day_sv, len);
					if (len > best_len && strncasecmp(buf, day_str, len) == 0) {
						best_match = i;
						best_len = len;
					}
				}
			}

			if (best_match < 0) {
				warn("Failed parsing weekday names");
				return NULL;
			}

			tm->tm_wday = best_match;
			buf += best_len;
			}
			break;

		case 'U':
		case 'V':
		case 'W':
			/*
			 * XXX This is bogus, as we can not assume any valid
			 * information present in the tm structure at this
			 * point to calculate a real value, so just check the
			 * range for now.
			 */
            if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (i > 53)
				return NULL;

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'u':
		case 'w':
			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			i = *buf - '0';
			if (i > 6 + (c == 'u'))
				return NULL;
			if (i == 7)
				i = 0;

			tm->tm_wday = i;

			buf++;
			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'd':
		case 'e':
			/*
			 * The %e specifier is explicitly documented as not
			 * being zero-padded but there is no harm in allowing
			 * such padding.
			 *
			 * XXX The %e specifier may gobble one too many
			 * digits if used incorrectly.
			 */
                        if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (i > 31)
				return NULL;

			tm->tm_mday = i;

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'B':
		case 'b':
		case 'h':
			{
			SV** month_sv = hv_fetchs(locales, "month", 0);
			SV** mon_sv = hv_fetchs(locales, "mon", 0);
			if (!month_sv || !mon_sv || !SvROK(*month_sv) || !SvROK(*mon_sv))
				return NULL;

			AV* month_av = (AV*)SvRV(*month_sv);
			AV* mon_av = (AV*)SvRV(*mon_sv);

			/* Use longest-match to handle ambiguous prefixes
				(e.g., "1" vs "10" in Japanese) */
			int best_match = -1;
			size_t best_len = 0;

			for (i = 0; i <= av_len(month_av); i++) {
				SV** month_sv_item;

				/* Try full month name */
				month_sv_item = av_fetch(month_av, i, 0);
				if (month_sv_item && SvPOK(*month_sv_item)) {
					char* month_str = SvPV(*month_sv_item, len);
					if (len > best_len && strncasecmp(buf, month_str, len) == 0) {
						best_match = i;
						best_len = len;
					}
				}

				/* Try abbreviated month name */
				month_sv_item = av_fetch(mon_av, i, 0);
				if (month_sv_item && SvPOK(*month_sv_item)) {
					char* month_str = SvPV(*month_sv_item, len);
					if (len > best_len && strncasecmp(buf, month_str, len) == 0) {
						best_match = i;
						best_len = len;
					}
				}
			}

			if (best_match < 0) {
				warn("Failed parsing month name");
				return NULL;
			}

			tm->tm_mon = best_match;
			buf += best_len;
			}
			break;

		case 'm':
			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (i < 1 || i > 12)
				return NULL;

			tm->tm_mon = i - 1;

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 's':
			{
			char *cp;
			int sverrno;
			long n;
			time_t t;
            struct tm mytm;

			sverrno = errno;
			errno = 0;
			n = Strtol(buf, &cp, 10);
			if (errno == ERANGE || (long)(t = n) != n) {
				errno = sverrno;
				return NULL;
			}
			errno = sverrno;
			buf = cp;
			Zero(&mytm, 1, struct tm);

			mytm = safe_gmtime(aTHX_ &t);
			*got_GMT = 1;

            tm->tm_sec    = mytm.tm_sec;
            tm->tm_min    = mytm.tm_min;
            tm->tm_hour   = mytm.tm_hour;
            tm->tm_mday   = mytm.tm_mday;
            tm->tm_mon    = mytm.tm_mon;
            tm->tm_year   = mytm.tm_year;
            tm->tm_wday   = mytm.tm_wday;
            tm->tm_yday   = mytm.tm_yday;
            tm->tm_isdst  = mytm.tm_isdst;
			}
			break;

		case 'Y':
		case 'y':
			if (*buf == 0 || isSPACE((unsigned char)*buf))
				break;

			if (!isDIGIT((unsigned char)*buf))
				return NULL;

			len = (c == 'Y') ? 4 : 2;
			for (i = 0; len && *buf != 0 && isDIGIT((unsigned char)*buf); buf++) {
				i *= 10;
				i += *buf - '0';
				len--;
			}
			if (c == 'Y')
				i -= 1900;
			if (c == 'y' && i < 69)
				i += 100;

			tm->tm_year = i;

			if (*buf != 0 && isSPACE((unsigned char)*buf))
				while (*ptr != 0 && !isSPACE((unsigned char)*ptr))
					ptr++;
			break;

		case 'Z':
			{
			const char *cp;
			char *zonestr;

			for (cp = buf; *cp && isUPPER((unsigned char)*cp); ++cp)
                            {/*empty*/}
			if (cp - buf) {
				zonestr = (char *)safemalloc((size_t) (cp - buf + 1));
				if (!zonestr) {
					Safefree(zonestr);
				    errno = ENOMEM;
				    return NULL;
				}
				my_strlcpy(zonestr, buf,(size_t) (cp - buf)+1);
				/* my_tzset(aTHX); */
				if (strEQ(zonestr, "GMT") || strEQ(zonestr, "UTC")) {
				    *got_GMT = 1;
				}
				Safefree(zonestr);
				buf += cp - buf;
			}
			}
			break;

		case 'z':
			{
			int sign = 1;

			if (*buf != '+') {
				if (*buf == '-')
					sign = -1;
				else {
					warn("%%z must contain '-' or '+'");
					return NULL;
				}
			}

			buf++;
			i = 0;
			for (len = 4; len > 0; len--) {
				if (isDIGIT((unsigned char)*buf)) {
					i *= 10;
					i += *buf - '0';
					buf++;
				} else if (len == 2) {
					/* Support ISO 8601 HH:MM format in addition to RFC 822 HHMM */
					if (*buf == ':') {
						buf++;
						len++;
					} else {
						i *= 100;
						break;
					}
				} else {
					warn("%%z format mismatch");
					return NULL;
				}
			}

			/* Valid if between UTC+14 and UTC-12 and minutes <= 60 */
			if (i > 1400 || (sign == -1 && i > 1200) || (i % 100) >= 60)
				return NULL;

			tm->tm_hour -= sign * (i / 100);
			tm->tm_min  -= sign * (i % 100);
			*got_GMT = 1;
			}
			break;
		}
	}
	return (char *)buf;
}

/* Saves alot of machine code.
   Takes a (auto) SP, which may or may not have been PUSHed before, puts
   tm struct members on Perl stack, then returns new, advanced, SP to caller.
   Assign the return of push_common_tm to your SP, so you can continue to PUSH
   or do a PUTBACK and return eventually.
   !!!! push_common_tm does not touch PL_stack_sp !!!!
   !!!! do not use PUTBACK then SPAGAIN semantics around push_common_tm !!!!
   !!!! You must mortalize whatever push_common_tm put on stack yourself to
        avoid leaking !!!!
*/
static SV **
push_common_tm(pTHX_ SV ** SP, struct tm *mytm)
{
	PUSHs(newSViv(mytm->tm_sec));
	PUSHs(newSViv(mytm->tm_min));
	PUSHs(newSViv(mytm->tm_hour));
	PUSHs(newSViv(mytm->tm_mday));
	PUSHs(newSViv(mytm->tm_mon));
	PUSHs(newSViv(mytm->tm_year));
	PUSHs(newSViv(mytm->tm_wday));
	PUSHs(newSViv(mytm->tm_yday));
	PUSHs(newSViv(mytm->tm_isdst));
	return SP;
}

/* specialized common end of 2 XSUBs
  SV ** SP -- pass your (auto) SP, which has not been PUSHed before, but was
              reset to 0 (PPCODE only or SP -= items or XSprePUSH)
  tm *mytm -- a tm *, will be proprocessed with my_mini_mktime
  return   -- none, after calling return_11part_tm, you must call "return;"
              no exceptions
*/
static void
return_11part_tm(pTHX_ SV ** SP, struct tm *mytm)
{
       my_mini_mktime(mytm);

  /* warn("tm: %d-%d-%d %d:%d:%d\n", mytm->tm_year, mytm->tm_mon, mytm->tm_mday, mytm->tm_hour, mytm->tm_min, mytm->tm_sec); */
       EXTEND(SP, 11);
       SP = push_common_tm(aTHX_ SP, mytm);
       /* epoch */
       PUSHs(newSViv(0));
       /* islocal */
       PUSHs(newSViv(0));
       PUTBACK;
       {
            SV ** endsp = SP; /* the SV * under SP needs to be mortaled */
            SP -= (11 - 1); /* subtract 0 based count of SVs to mortal */
/* mortal target of SP, then increment before function call
   so SP is already calculated before next comparison to not stall CPU */
            do {
                sv_2mortal(*SP++);
            } while(SP <= endsp);
       }
       return;
}



MODULE = Time::Piece     PACKAGE = Time::Piece

PROTOTYPES: ENABLE

void
_strftime(fmt, epoch, islocal = 1)
    char *      fmt
    time_t      epoch
    int         islocal
    CODE:
    {
        char tmpbuf[TP_BUF_SIZE];
        struct tm mytm;
        size_t len;

        if(islocal == 1)
            mytm = safe_localtime(aTHX_ &epoch);
        else
            mytm = safe_gmtime(aTHX_ &epoch);

        len = strftime(tmpbuf, TP_BUF_SIZE, fmt, &mytm);
        /*
        ** The following is needed to handle to the situation where
        ** tmpbuf overflows.  Basically we want to allocate a buffer
        ** and try repeatedly.  The reason why it is so complicated
        ** is that getting a return value of 0 from strftime can indicate
        ** one of the following:
        ** 1. buffer overflowed,
        ** 2. illegal conversion specifier, or
        ** 3. the format string specifies nothing to be returned(not
        **      an error).  This could be because format is an empty string
        **    or it specifies %p that yields an empty string in some locale.
        ** If there is a better way to make it portable, go ahead by
        ** all means.
        */
        if ((len > 0 && len < TP_BUF_SIZE) || (len == 0 && *fmt == '\0'))
        ST(0) = sv_2mortal(newSVpv(tmpbuf, len));
        else {
        /* Possibly buf overflowed - try again with a bigger buf */
        size_t fmtlen = strlen(fmt);
        size_t bufsize = fmtlen + TP_BUF_SIZE;
        char*     buf;
        size_t    buflen;

        New(0, buf, bufsize, char);
        while (buf) {
            buflen = strftime(buf, bufsize, fmt, &mytm);
            if (buflen > 0 && buflen < bufsize)
            break;
            /* heuristic to prevent out-of-memory errors */
            if (bufsize > 100*fmtlen) {
            Safefree(buf);
            buf = NULL;
            break;
            }
            bufsize *= 2;
            Renew(buf, bufsize, char);
        }
        if (buf) {
            ST(0) = sv_2mortal(newSVpv(buf, buflen));
            Safefree(buf);
        }
        else
            ST(0) = sv_2mortal(newSVpv(tmpbuf, len));
        }
    }

void
_tzset()
  PPCODE:
    PUTBACK; /* makes rest of this function tailcall friendly */
    my_tzset(aTHX);
    return; /* skip XSUBPP's PUTBACK */

void
_strptime ( string, format, islocal, localization, defaults_ref )
	char * string
	char * format
	int    islocal
	SV   * localization
	SV   * defaults_ref
  PREINIT:
       struct tm mytm;
	   int    got_GMT = 0;
       char * remainder;
       HV   * locales;
       AV   * defaults_av;
  PPCODE:
       Zero(&mytm, 1, struct tm);

       /* sensible defaults. */
       mytm.tm_mday = 1;
       mytm.tm_year = 70;
       mytm.tm_wday = 4;
       mytm.tm_isdst = -1; /* -1 means we don't know */

       if( SvTYPE(SvRV( localization )) == SVt_PVHV ){
           locales = (HV *)SvRV(localization);
       }
       else{
            croak("_strptime requires a Hash Reference of locales");
       }

       /* Check if defaults array was passed and apply them now */
       if (SvOK(defaults_ref) && SvROK(defaults_ref) && SvTYPE(SvRV(defaults_ref)) == SVt_PVAV) {
           defaults_av = (AV*)SvRV(defaults_ref);
           if (av_len(defaults_av)+1 >= 8) {

               SV** elem;
               elem = av_fetch(defaults_av, 0, 0);
               if (elem && SvOK(*elem)) mytm.tm_sec = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 1, 0);
               if (elem && SvOK(*elem)) mytm.tm_min = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 2, 0);
               if (elem && SvOK(*elem)) mytm.tm_hour = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 3, 0);
               if (elem && SvOK(*elem)) mytm.tm_mday = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 4, 0);
               if (elem && SvOK(*elem)) mytm.tm_mon = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 5, 0);
               if (elem && SvOK(*elem)) mytm.tm_year = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 6, 0);
               if (elem && SvOK(*elem)) mytm.tm_wday = (int)SvIV(*elem);
               elem = av_fetch(defaults_av, 7, 0);
               if (elem && SvOK(*elem)) mytm.tm_yday = (int)SvIV(*elem);
           }
       }

       remainder = (char *)_strptime(aTHX_ string, format, &mytm, &got_GMT, locales);
       if (remainder == NULL) {
           croak("Error parsing time");
       }
       if (*remainder != '\0') {
           warn("Garbage at end of string in strptime: %s", remainder);
           warn("Perhaps a format flag did not match the actual input?");
       }

       /* convert if we have a tm in GMT but were called from a localized object */
       if (got_GMT == 1 && islocal == 1) {
           time_t t;
           t = my_timegm(&mytm);
           mytm = safe_localtime(aTHX_ &t);
       }

       return_11part_tm(aTHX_ SP, &mytm);
       return;

void
_mini_mktime(int sec, int min, int hour, int mday, int mon, int year)
  PREINIT:
       struct tm mytm;
       time_t t;
  PPCODE:
       t = 0;
       mytm = safe_gmtime(aTHX_ &t);

       mytm.tm_sec = sec;
       mytm.tm_min = min;
       mytm.tm_hour = hour;
       mytm.tm_mday = mday;
       mytm.tm_mon = mon;
       mytm.tm_year = year;

       return_11part_tm(aTHX_ SP, &mytm);
       return;

void
_crt_localtime(time_t sec)
    ALIAS:
        _crt_gmtime = 1
    PREINIT:
        struct tm mytm;
    PPCODE:
        if(ix) mytm = safe_gmtime(aTHX_ &sec);
        else mytm = safe_localtime(aTHX_ &sec);
        /* Need to get: $s,$n,$h,$d,$m,$y */

        EXTEND(SP, 10);
        SP = push_common_tm(aTHX_ SP, &mytm);
        PUSHs(newSViv(mytm.tm_isdst));
        PUTBACK;
        {
            SV ** endsp = SP; /* the SV * under SP needs to be mortaled */
            SP -= (10 - 1); /* subtract 0 based count of SVs to mortal */
/* mortal target of SP, then increment before function call
   so SP is already calculated before next comparison to not stall CPU */
            do {
                sv_2mortal(*SP++);
            } while(SP <= endsp);
        }
        return;

SV*
_get_localization()
    INIT:
        HV* locales = newHV();
        AV* wdays = newAV();
        AV* weekdays = newAV();
        AV* mons = newAV();
        AV* months = newAV();
        size_t len;
        char buf[TP_BUF_SIZE];
        size_t i;
        time_t t = 1325386800; /*1325386800 = Sun, 01 Jan 2012 03:00:00 GMT*/
        struct tm mytm = safe_gmtime(aTHX_ &t);
     CODE:

        for(i = 0; i < 7; ++i){

            len = strftime(buf, TP_BUF_SIZE, "%a", &mytm);
            av_push(wdays, (SV *) newSVpvn(buf, len));

            len = strftime(buf, TP_BUF_SIZE, "%A", &mytm);
            av_push(weekdays, (SV *) newSVpvn(buf, len));

            ++mytm.tm_wday;
        }

        for(i = 0; i < 12; ++i){

            len = strftime(buf, TP_BUF_SIZE, "%b", &mytm);
            av_push(mons, (SV *) newSVpvn(buf, len));

            len = strftime(buf, TP_BUF_SIZE, "%B", &mytm);
            av_push(months, (SV *) newSVpvn(buf, len));

            ++mytm.tm_mon;
        }

        hv_stores(locales, "wday", newRV_noinc((SV *) wdays));
        hv_stores(locales, "weekday", newRV_noinc((SV *) weekdays));
        hv_stores(locales, "mon", newRV_noinc((SV *) mons));
        hv_stores(locales, "month", newRV_noinc((SV *) months));


        len = strftime(buf, TP_BUF_SIZE, "%p", &mytm);
        hv_stores(locales, "AM", newSVpvn(buf,len));
#  ifndef WIN32
        len = strftime(buf, TP_BUF_SIZE, "%P", &mytm);
        hv_stores(locales, "am", newSVpvn(buf,len));
#  endif
        mytm.tm_hour = 18;
        len = strftime(buf, TP_BUF_SIZE, "%p", &mytm);
        hv_stores(locales, "PM", newSVpvn(buf,len));
#  ifndef WIN32
        len = strftime(buf, TP_BUF_SIZE, "%P", &mytm);
        hv_stores(locales, "pm", newSVpvn(buf,len));
#  endif
        RETVAL = newRV_noinc((SV *)locales);
    OUTPUT:
        RETVAL
