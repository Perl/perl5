#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
# Devel::DProf - a Perl code profiler
#  5apr95
#  Dean Roehrich
#
# changes/bugs fixed since 2apr95 version:
#  -now mallocing an extra byte for the \0 :)
# changes/bugs fixed since 01mar95 version:
#  -stringified code ref is used for name of anonymous sub.
#  -include stash name with stringified code ref.
#  -use perl.c's DBsingle and DBsub.
#  -now using croak() and warn().
#  -print "timer is on" before turning timer on.
#  -use safefree() instead of free().
#  -rely on PM to provide full path name to tmon.out.
#  -print errno if unable to write tmon.out.
# changes/bugs fixed since 03feb95 version:
#  -comments
# changes/bugs fixed since 31dec94 version:
#  -added patches from Andy.
#
*/

/*#define DBG_SUB 1	/* */
/*#define DBG_TIMER 1	/* */

#ifdef DBG_SUB
#  define DBG_SUB_NOTIFY(A,B) warn( A, B )
#else
#  define DBG_SUB_NOTIFY(A,B)  /* nothing */
#endif

#ifdef DBG_TIMER
#  define DBG_TIMER_NOTIFY(A) warn( A )
#else
#  define DBG_TIMER_NOTIFY(A)  /* nothing */
#endif

/* HZ == clock ticks per second */
#ifndef HZ
#define HZ 60
#endif

static SV * Sub;	/* pointer to $DB::sub */
static char *Tmon;	/* name of tmon.out */

/* Everything is built on times(2).  See its manpage for a description
 * of the timings.
 */

static
struct tms	prof_start,
		prof_end;

static
clock_t		rprof_start, /* elapsed real time, in ticks */
		rprof_end;

union prof_any {
	clock_t tms_utime;  /* cpu time spent in user space */
	clock_t tms_stime;  /* cpu time spent in system */
	clock_t realtime;   /* elapsed real time, in ticks */
	char *name;
	opcode ptype;
};

typedef union prof_any PROFANY;

static PROFANY	*profstack;
static int	profstack_max = 128;
static int	profstack_ix = 0;


static void
prof_mark( ptype )
opcode ptype;
{
	struct tms t;
	clock_t realtime;
	char *name, *pv;
	char *hvname;
	STRLEN len;
	SV *sv;

	if( profstack_ix + 5 > profstack_max ){
		profstack_max = profstack_max * 3 / 2;
		Renew( profstack, profstack_max, PROFANY );
	}

	realtime = times(&t);
	pv = SvPV( Sub, len );

	if( SvROK(Sub) ){
		/* Attempt to make CODE refs identifiable by
		 * including their package name.
		 */
		sv = (SV*)SvRV(Sub);
		if( sv && SvTYPE(sv) == SVt_PVCV ){
			hvname = HvNAME(CvSTASH(sv));
			len += strlen( hvname ) + 2;  /* +2 for more ::'s */

		}
		else {
			croak( "DProf prof_mark() lost on supposed CODE ref %s.\n", pv );
		}
		name = (char *)safemalloc( len * sizeof(char) + 1 );
		strcpy( name, hvname );
		strcat( name, "::" );
		strcat( name, pv );
	}
	else{
		name = (char *)safemalloc( len * sizeof(char) + 1 );
		strcpy( name, pv );
	}

	profstack[profstack_ix++].ptype = ptype;
	profstack[profstack_ix++].tms_utime = t.tms_utime;
	profstack[profstack_ix++].tms_stime = t.tms_stime;
	profstack[profstack_ix++].realtime = realtime;
	profstack[profstack_ix++].name = name;
}

static void
prof_record(){
	FILE *fp;
	char *name;
	int base = 0;
	opcode ptype;
	clock_t tms_utime;
	clock_t tms_stime;
	clock_t realtime;

	if( (fp = fopen( Tmon, "w" )) == NULL ){
		warn("DProf: unable to write %s, errno = %d\n", Tmon, errno );
		return;
	}

	fprintf(fp, "#fOrTyTwO\n" );
	fprintf(fp, "$hz=%d;\n", HZ );
	fprintf(fp, "# All values are given in HZ\n" );
	fprintf(fp, "$rrun_utime=%ld; $rrun_stime=%ld; $rrun_rtime=%ld\n",
		prof_end.tms_utime - prof_start.tms_utime,
		prof_end.tms_stime - prof_start.tms_stime,
		rprof_end - rprof_start );
	fprintf(fp, "PART2\n" );

	while( base < profstack_ix ){
		ptype = profstack[base++].ptype;
		tms_utime = profstack[base++].tms_utime;
		tms_stime = profstack[base++].tms_stime;
		realtime = profstack[base++].realtime;
		name = profstack[base++].name;

		switch( ptype ){
		case OP_LEAVESUB:
			fprintf(fp,"- %ld %ld %ld %s\n",
				tms_utime, tms_stime, realtime, name );
			break;
		case OP_ENTERSUB:
			fprintf(fp,"+ %ld %ld %ld %s\n",
				tms_utime, tms_stime, realtime, name );
			break;
		default:
			fprintf(fp,"Profiler unknown prof code %d\n", ptype);
		}
	}
	fclose( fp );
}

#define for_real
#ifdef for_real

XS(XS_DB_sub)
{
	dXSARGS;
	dORIGMARK;
	SP -= items;

	DBG_SUB_NOTIFY( "XS DBsub(%s)\n", SvPV(Sub, na) );

	sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */

	prof_mark( OP_ENTERSUB );
	PUSHMARK( ORIGMARK );

	perl_call_sv( Sub, GIMME );

	prof_mark( OP_LEAVESUB );
	SPAGAIN;
	PUTBACK;
	return;
}

#endif /* for_real */

#ifdef testing

	MODULE = Devel::DProf		PACKAGE = DB

	void
	sub(...)
		PPCODE:

		dORIGMARK;
		/* SP -= items;  added by xsubpp */
		DBG_SUB_NOTIFY( "XS DBsub(%s)\n", SvPV(Sub, na) );

		sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */

		prof_mark( OP_ENTERSUB );
		PUSHMARK( ORIGMARK );

		perl_call_sv( Sub, GIMME );

		prof_mark( OP_LEAVESUB );
		SPAGAIN;
		/* PUTBACK;  added by xsubpp */

#endif /* testing */


MODULE = Devel::DProf		PACKAGE = Devel::DProf

void
END()
	PPCODE:
	rprof_end = times(&prof_end);
	DBG_TIMER_NOTIFY("Profiler timer is off.\n");
	prof_record();

BOOT:
	newXS("DB::sub", XS_DB_sub, file);
	Sub = GvSV(DBsub);	 /* name of current sub */
	sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */
	{ /* obtain name of tmon.out file */
	 SV *sv;
	 sv = perl_get_sv( "DB::tmon", FALSE );
	 Tmon = (char *)safemalloc( SvCUR(sv) * sizeof(char) );
	 strcpy( Tmon, SvPVX(sv) );
	}
	New( 0, profstack, profstack_max, PROFANY );
	DBG_TIMER_NOTIFY("Profiler timer is on.\n");
	rprof_start = times(&prof_start);
