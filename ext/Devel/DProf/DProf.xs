/* XXX DProf could use some cleanups for PERL_IMPLICIT_CONTEXT */

#define PERL_POLLUTE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* For older Perls */
#ifndef dTHR
#  define dTHR int dummy_thr
#endif	/* dTHR */ 

/*#define DBG_SUB 1      */
/*#define DBG_TIMER 1    */

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

static U32 dprof_ticks;

/* HZ == clock ticks per second */
#ifdef VMS
#  define HZ ((I32)CLK_TCK)
#  define DPROF_HZ HZ
#  include <starlet.h>  /* prototype for sys$gettim() */
   clock_t dprof_times(struct tms *bufptr) {
        clock_t retval;
	dTHX;
        /* Get wall time and convert to 10 ms intervals to
         * produce the return value dprof expects */
#  if defined(__DECC) && defined (__ALPHA)
#    include <ints.h>
        uint64 vmstime;
        _ckvmssts(sys$gettim(&vmstime));
        vmstime /= 100000;
        retval = vmstime & 0x7fffffff;
#  else
        /* (Older hw or ccs don't have an atomic 64-bit type, so we
         * juggle 32-bit ints (and a float) to produce a time_t result
         * with minimal loss of information.) */
        long int vmstime[2],remainder,divisor = 100000;
        _ckvmssts(sys$gettim((unsigned long int *)vmstime));
        vmstime[1] &= 0x7fff;  /* prevent overflow in EDIV */
        _ckvmssts(lib$ediv(&divisor,vmstime,(long int *)&retval,&remainder));
#  endif
        /* Fill in the struct tms using the CRTL routine . . .*/
        times((tbuffer_t *)bufptr);
        return (clock_t) retval;
   }
#  define Times(ptr) (dprof_times(ptr))
#else
#  ifndef HZ
#    ifdef CLK_TCK
#      define HZ ((I32)CLK_TCK)
#    else
#      define HZ 60
#    endif
#  endif
#  ifdef OS2				/* times() has significant overhead */
#    define Times(ptr) (dprof_times(ptr))
#    define INCL_DOSPROFILE
#    define INCL_DOSERRORS
#    include <os2.h>
#    define toLongLong(arg) (*(long long*)&(arg))
#    define DPROF_HZ dprof_ticks

static ULONG frequ;
static long long start_cnt;
clock_t
dprof_times(struct tms *t)
{
    ULONG rc;
    QWORD cnt;
    
    if (!frequ) {
	if (CheckOSError(DosTmrQueryFreq(&frequ)))
	    croak("DosTmrQueryFreq: %s", SvPV(perl_get_sv("!",TRUE),na));
	else
	    frequ = frequ/DPROF_HZ;	/* count per tick */
	if (CheckOSError(DosTmrQueryTime(&cnt)))
	    croak("DosTmrQueryTime: %s",
		  SvPV(perl_get_sv("!",TRUE),na));
	start_cnt = toLongLong(cnt);
    }

    if (CheckOSError(DosTmrQueryTime(&cnt)))
	    croak("DosTmrQueryTime: %s", SvPV(perl_get_sv("!",TRUE),na));
    t->tms_stime = 0;
    return (t->tms_utime = (toLongLong(cnt) - start_cnt)/frequ);
}
#  else
#    define Times(ptr) (times(ptr))
#    define DPROF_HZ HZ
#  endif 
#endif

XS(XS_Devel__DProf_END);        /* used by prof_mark() */

static PerlIO *fp;      /* pointer to tmon.out file */

/* Added -JH */
static long TIMES_LOCATION=42;/* Where in the file to store the time totals */
static int SAVE_STACK = 1<<14;		/* How much data to buffer until */
					/* end of run */

static int prof_pid;    /* pid of profiled process */

/* Everything is built on times(2).  See its manpage for a description
 * of the timings.
 */

static
struct tms      prof_start,
                prof_end;

static
clock_t         rprof_start, /* elapsed real time, in ticks */
                rprof_end,
		wprof_u, wprof_s, wprof_r;

union prof_any {
        clock_t tms_utime;  /* cpu time spent in user space */
        clock_t tms_stime;  /* cpu time spent in system */
        clock_t realtime;   /* elapsed real time, in ticks */
        char *name;
        U32 id;
        opcode ptype;
};

typedef union prof_any PROFANY;

static PROFANY  *profstack;
static int      profstack_max = 128;
static int      profstack_ix = 0;

static void
prof_dump(opcode ptype, char *name)
{
    if(ptype == OP_LEAVESUB){
	PerlIO_printf(fp,"- & %s\n", name );
    } else if(ptype == OP_ENTERSUB) {
	PerlIO_printf(fp,"+ & %s\n", name );
    } else if(ptype == OP_DIE) {
	PerlIO_printf(fp,"/ & %s\n", name );
    } else {
	PerlIO_printf(fp,"Profiler unknown prof code %d\n", ptype);
    }
    safefree(name);
}   

static void
prof_dumpa(opcode ptype, U32 id)
{
    if(ptype == OP_LEAVESUB){
	PerlIO_printf(fp,"- %"UVxf"\n", (UV)id );
    } else if(ptype == OP_ENTERSUB) {
	PerlIO_printf(fp,"+ %"UVxf"\n", (UV)id );
    } else if(ptype == OP_GOTO) {
	PerlIO_printf(fp,"* %"UVxf"\n", (UV)id );
    } else if(ptype == OP_DIE) {
	PerlIO_printf(fp,"/ %"UVxf"\n", (UV)id );
    } else {
	PerlIO_printf(fp,"Profiler unknown prof code %d\n", ptype);
    }
}   

static void
prof_dumps(U32 id, char *pname, char *gname)
{
    PerlIO_printf(fp,"& %"UVxf" %s %s\n", (UV)id, pname, gname);
}   

static clock_t otms_utime, otms_stime, orealtime;

static void
prof_dumpt(long tms_utime, long tms_stime, long realtime)
{
    PerlIO_printf(fp,"@ %ld %ld %ld\n", tms_utime, tms_stime, realtime);
}   

static void
prof_dump_until(long ix)
{
    long base = 0;
    struct tms t1, t2;
    clock_t realtime1, realtime2;

    realtime1 = Times(&t1);

    while( base < ix ){
	opcode ptype = profstack[base++].ptype;
	if (ptype == OP_TIME) {
	    long tms_utime = profstack[base++].tms_utime;
	    long tms_stime = profstack[base++].tms_stime;
	    long realtime = profstack[base++].realtime;

	    prof_dumpt(tms_utime, tms_stime, realtime);
	} else if (ptype == OP_GV) {
	    U32 id = profstack[base++].id;
	    char *pname = profstack[base++].name;
	    char *gname = profstack[base++].name;

	    prof_dumps(id, pname, gname);
	} else {
#ifdef PERLDBf_NONAME
	    U32 id = profstack[base++].id;
	    prof_dumpa(ptype, id);
#else
	    char *name = profstack[base++].name;
	    prof_dump(ptype, name);
#endif 
	}
    }
    PerlIO_flush(fp);
    realtime2 = Times(&t2);
    if (realtime2 != realtime1 || t1.tms_utime != t2.tms_utime
	|| t1.tms_stime != t2.tms_stime) {
	wprof_r += realtime2 - realtime1;
	wprof_u += t2.tms_utime - t1.tms_utime;
	wprof_s += t2.tms_stime - t1.tms_stime;

	PerlIO_printf(fp,"+ & Devel::DProf::write\n" );
	PerlIO_printf(fp,"@ %"IVdf" %"IVdf" %"IVdf"\n", 
		      /* The (IV) casts are one possibility:
		       * the Painfully Correct Way would be to
		       * have Clock_t_f. */
		      (IV)(t2.tms_utime - t1.tms_utime),
		      (IV)(t2.tms_stime - t1.tms_stime), 
		      (IV)(realtime2 - realtime1));
	PerlIO_printf(fp,"- & Devel::DProf::write\n" );
	otms_utime = t2.tms_utime;
	otms_stime = t2.tms_stime;
	orealtime = realtime2;
	PerlIO_flush(fp);
    }
}

static HV* cv_hash;
static U32 total = 0;

static void
prof_mark( opcode ptype )
{
        struct tms t;
        clock_t realtime, rdelta, udelta, sdelta;
        char *name, *pv;
        char *hvname;
        STRLEN len;
        SV *sv;
	U32 id;
	SV *Sub = GvSV(DBsub);       /* name of current sub */

        if( SAVE_STACK ){
                if( profstack_ix + 5 > profstack_max ){
                        profstack_max = profstack_max * 3 / 2;
                        Renew( profstack, profstack_max, PROFANY );
                }
        }

        realtime = Times(&t);
	rdelta = realtime - orealtime;
	udelta = t.tms_utime - otms_utime;
	sdelta = t.tms_stime - otms_stime;
	if (rdelta || udelta || sdelta) {
	    if (SAVE_STACK) {
		profstack[profstack_ix++].ptype = OP_TIME;
		profstack[profstack_ix++].tms_utime = udelta;
		profstack[profstack_ix++].tms_stime = sdelta;
		profstack[profstack_ix++].realtime = rdelta;
	    } else { /* Write it to disk now so's not to eat up core */
		if (prof_pid == (int)getpid()) {
		    prof_dumpt(udelta, sdelta, rdelta);
		    PerlIO_flush(fp);
		}
	    }
	    orealtime = realtime;
	    otms_stime = t.tms_stime;
	    otms_utime = t.tms_utime;
	}

#ifdef PERLDBf_NONAME
	{
	    dTHX;
	    SV **svp;
	    char *gname, *pname;
	    static U32 lastid;
	    CV *cv;

	    cv = INT2PTR(CV*,SvIVX(Sub));
	    svp = hv_fetch(cv_hash, (char*)&cv, sizeof(CV*), TRUE);
	    if (!SvOK(*svp)) {
		GV *gv = CvGV(cv);
		    
		sv_setiv(*svp, id = ++lastid);
		pname = ((GvSTASH(gv) && HvNAME(GvSTASH(gv))) 
			 ? HvNAME(GvSTASH(gv)) 
			 : "(null)");
		gname = GvNAME(gv);
		if (CvXSUB(cv) == XS_Devel__DProf_END)
		    return;
		if (SAVE_STACK) { /* Store it for later recording  -JH */
		    profstack[profstack_ix++].ptype = OP_GV;
		    profstack[profstack_ix++].id = id;
		    profstack[profstack_ix++].name = pname;
		    profstack[profstack_ix++].name = gname;
		} else { /* Write it to disk now so's not to eat up core */

		    /* Only record the parent's info */
		    if (prof_pid == (int)getpid()) {
			prof_dumps(id, pname, gname);
			PerlIO_flush(fp);
		    } else
			perldb = 0;		/* Do not debug the kid. */
		}
	    } else {
		id = SvIV(*svp);
	    }
	}
#else
	pv = SvPV( Sub, len );

        if( SvROK(Sub) ){
                /* Attempt to make CODE refs slightly identifiable by
                 * including their package name.
                 */
                sv = (SV*)SvRV(Sub);
                if( sv && SvTYPE(sv) == SVt_PVCV ){
                        if( CvSTASH(sv) ){
                                hvname = HvNAME(CvSTASH(sv));
                        }
                        else if( CvXSUB(sv) == &XS_Devel__DProf_END ){
                                /*warn( "prof_mark() found dprof::end");*/
                                return; /* don't profile Devel::DProf::END */
                        }
                        else{
                    croak( "DProf prof_mark() lost on CODE ref %s\n", pv );
                        }
                        len += strlen( hvname ) + 2;  /* +2 for ::'s */

                }
                else{
        croak( "DProf prof_mark() lost on supposed CODE ref %s.\n", pv );
                }
                name = (char *)safemalloc( len * sizeof(char) + 1 );
                strcpy( name, hvname );
                strcat( name, "::" );
                strcat( name, pv );
        }
        else{
                if( *(pv+len-1) == 'D' ){
                        /* It could be an &AUTOLOAD. */

                        /* I measured a bunch of *.pl and *.pm (from Perl
                         * distribution and other misc things) and found
                         * 780 fully-qualified names.  They averaged
                         * about 19 chars each.  Only 1 of those names
                         * ended with 'D' and wasn't an &AUTOLOAD--it
                         * was &overload::OVERLOAD.
                         *    --dmr 2/19/96
                         */

                        if( strcmp( pv+len-9, ":AUTOLOAD" ) == 0 ){
                                /* The sub name is in $AUTOLOAD */
                                sv = perl_get_sv( pv, 0 );
                                if( sv == NULL ){
                croak("DProf prof_mark() lost on AUTOLOAD (%s).\n", pv );
                                }
                                pv = SvPV( sv, na );
                                DBG_SUB_NOTIFY( "  AUTOLOAD(%s)\n", pv );
                        }
                }
                name = savepv( pv );
        }
#endif /* PERLDBf_NONAME */

	total++;
        if (SAVE_STACK) { /* Store it for later recording  -JH */
	    profstack[profstack_ix++].ptype = ptype;
#ifdef PERLDBf_NONAME
	    profstack[profstack_ix++].id = id;
#else
	    profstack[profstack_ix++].name = name;
#endif 
            /* Only record the parent's info */
	    if (SAVE_STACK < profstack_ix) {
		if (prof_pid == (int)getpid())
		    prof_dump_until(profstack_ix);
		else
		    perldb = 0;		/* Do not debug the kid. */
		profstack_ix = 0;
	    }
        } else { /* Write it to disk now so's not to eat up core */

            /* Only record the parent's info */
            if (prof_pid == (int)getpid()) {
#ifdef PERLDBf_NONAME
		prof_dumpa(ptype, id);
#else
		prof_dump(ptype, name);
#endif 
                PerlIO_flush(fp);
            } else
		perldb = 0;		/* Do not debug the kid. */
        }
}

static U32 default_perldb;

#ifdef PL_NEEDED
#  define defstash PL_defstash
#endif

/* Counts overhead of prof_mark and extra XS call. */
static void
test_time(clock_t *r, clock_t *u, clock_t *s)
{
    dTHR;
    dTHX;
    CV *cv = perl_get_cv("Devel::DProf::NONESUCH_noxs", FALSE);
    int i, j, k = 0;
    HV *oldstash = curstash;
    struct tms t1, t2;
    clock_t realtime1, realtime2;
    U32 ototal = total;
    U32 ostack = SAVE_STACK;
    U32 operldb = perldb;

    SAVE_STACK = 1000000;
    realtime1 = Times(&t1);
    
    while (k < 2) {
	i = 0;
	    /* Disable debugging of perl_call_sv on second pass: */
	curstash = (k == 0 ? defstash : debstash);
	perldb = default_perldb;
	while (++i <= 100) {
	    j = 0;
	    profstack_ix = 0;		/* Do not let the stack grow */
	    while (++j <= 100) {
/* 		prof_mark( OP_ENTERSUB ); */

		PUSHMARK( stack_sp );
		perl_call_sv( (SV*)cv, G_SCALAR );
		stack_sp--;
/* 		prof_mark( OP_LEAVESUB ); */
	    }
	}
	curstash = oldstash;
	if (k == 0) {			/* Put time with debugging */
	    realtime2 = Times(&t2);
	    *r = realtime2 - realtime1;
	    *u = t2.tms_utime - t1.tms_utime;
	    *s = t2.tms_stime - t1.tms_stime;
	} else {			/* Subtract time without debug */
	    realtime1 = Times(&t1);
	    *r -= realtime1 - realtime2;
	    *u -= t1.tms_utime - t2.tms_utime;
	    *s -= t1.tms_stime - t2.tms_stime;	    
	}
	k++;
    }
    total = ototal;
    SAVE_STACK = ostack;
    perldb = operldb;
}

static void
prof_recordheader(void)
{
	clock_t r, u, s;

        /* fp is opened in the BOOT section */
        PerlIO_printf(fp, "#fOrTyTwO\n" );
        PerlIO_printf(fp, "$hz=%"IVdf";\n", (IV)DPROF_HZ );
        PerlIO_printf(fp, "$XS_VERSION='DProf %s';\n", XS_VERSION );
        PerlIO_printf(fp, "# All values are given in HZ\n" );
	test_time(&r, &u, &s);
        PerlIO_printf(fp,
		      "$over_utime=%"IVdf"; $over_stime=%"IVdf"; $over_rtime=%"IVdf";\n",
		      /* The (IV) casts are one possibility:
		       * the Painfully Correct Way would be to
		       * have Clock_t_f. */
		      (IV)u, (IV)s, (IV)r);
        PerlIO_printf(fp, "$over_tests=10000;\n");

        TIMES_LOCATION = PerlIO_tell(fp);

        /* Pad with whitespace. */
        /* This should be enough even for very large numbers. */
        PerlIO_printf(fp, "%*s\n", 240 , "");

        PerlIO_printf(fp, "\n");
        PerlIO_printf(fp, "PART2\n" );

        PerlIO_flush(fp);
}

static void
prof_record(void)
{
        /* fp is opened in the BOOT section */

        /* Now that we know the runtimes, fill them in at the recorded
           location -JH */

	clock_t r, u, s;
    
        if(SAVE_STACK){
	    prof_dump_until(profstack_ix);
        }
        PerlIO_seek(fp, TIMES_LOCATION, SEEK_SET);
	/* Write into reserved 240 bytes: */
        PerlIO_printf(fp,
		      "$rrun_utime=%"IVdf"; $rrun_stime=%"IVdf"; $rrun_rtime=%"IVdf";",
		      /* The (IV) casts are one possibility:
		       * the Painfully Correct Way would be to
		       * have Clock_t_f. */
		      (IV)(prof_end.tms_utime-prof_start.tms_utime-wprof_u),
		      (IV)(prof_end.tms_stime-prof_start.tms_stime-wprof_s),
		      (IV)(rprof_end-rprof_start-wprof_r) );
        PerlIO_printf(fp, "\n$total_marks=%"IVdf, (IV)total);
	
        PerlIO_close( fp );
}

#define NONESUCH()

static U32 depth = 0;

static void
check_depth(pTHX_ void *foo)
{
    U32 need_depth = (U32)foo;
    if (need_depth != depth) {
	if (need_depth > depth) {
	    warn("garbled call depth when profiling");
	} else {
	    I32 marks = depth - need_depth;

/* 	    warn("Check_depth: got %d, expected %d\n", depth, need_depth); */
	    while (marks--) {
		prof_mark( OP_DIE );
	    }
	    depth = need_depth;
	}
    }
}

#define for_real
#ifdef for_real

XS(XS_DB_sub)
{
        dXSARGS;
        dORIGMARK;
        HV *oldstash = curstash;
	SV *Sub = GvSV(DBsub);       /* name of current sub */

        SP -= items;

        DBG_SUB_NOTIFY( "XS DBsub(%s)\n", SvPV(Sub, na) );

#ifndef PERLDBf_NONAME			/* Was needed on older Perls */
        sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */
#endif 

	SAVEDESTRUCTOR_X(check_depth, (void*)depth);
	depth++;

        prof_mark( OP_ENTERSUB );
        PUSHMARK( ORIGMARK );

#ifdef G_NODEBUG
        perl_call_sv( INT2PTR(SV*,SvIV(Sub)), GIMME | G_NODEBUG);
#else
        curstash = debstash;    /* To disable debugging of perl_call_sv */
#ifdef PERLDBf_NONAME
        perl_call_sv( (SV*)SvIV(Sub), GIMME );
#else
        perl_call_sv( Sub, GIMME );
#endif 
        curstash = oldstash;
#endif 

        prof_mark( OP_LEAVESUB );
	depth--;

        SPAGAIN;
        PUTBACK;
        return;
}

XS(XS_DB_goto)
{
        prof_mark( OP_GOTO );
        return;
}

#endif /* for_real */

#ifdef testing

        MODULE = Devel::DProf           PACKAGE = DB

        void
        sub(...)
                PPCODE:

                dORIGMARK;
                HV *oldstash = curstash;
		SV *Sub = GvSV(DBsub);       /* name of current sub */
                /* SP -= items;  added by xsubpp */
                DBG_SUB_NOTIFY( "XS DBsub(%s)\n", SvPV(Sub, na) );

                sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */

                prof_mark( OP_ENTERSUB );
                PUSHMARK( ORIGMARK );

                curstash = debstash;    /* To disable debugging of perl_call_sv
*/
                perl_call_sv( Sub, GIMME );
                curstash = oldstash;

                prof_mark( OP_LEAVESUB );
                SPAGAIN;
                /* PUTBACK;  added by xsubpp */

#endif /* testing */

MODULE = Devel::DProf           PACKAGE = Devel::DProf

void
END()
        PPCODE:
        if( DBsub ){
                /* maybe the process forked--we want only
                 * the parent's profile.
                 */
                if( prof_pid == (int)getpid() ){
                        rprof_end = Times(&prof_end);
                        DBG_TIMER_NOTIFY("Profiler timer is off.\n");
                        prof_record();
                }
        }

void
NONESUCH()

BOOT:
        /* Before we go anywhere make sure we were invoked
         * properly, else we'll dump core.
         */
        if( ! DBsub )
                croak("DProf: run perl with -d to use DProf.\n");

        /* When we hook up the XS DB::sub we'll be redefining
         * the DB::sub from the PM file.  Turn off warnings
         * while we do this.
         */
        {
                I32 warn_tmp = dowarn;
                dowarn = 0;
                newXS("DB::sub", XS_DB_sub, file);
                newXS("DB::goto", XS_DB_goto, file);
                dowarn = warn_tmp;
        }

        sv_setiv( DBsingle, 0 ); /* disable DB single-stepping */

	{
	    char *buffer = getenv("PERL_DPROF_BUFFER");

	    if (buffer) {
		SAVE_STACK = atoi(buffer);
	    }

	    buffer = getenv("PERL_DPROF_TICKS");

	    if (buffer) {
		dprof_ticks = atoi(buffer); /* Used under OS/2 only */
	    } else {
		dprof_ticks = HZ;
	    }
	}

        if( (fp = PerlIO_open( "tmon.out", "w" )) == NULL )
                croak("DProf: unable to write tmon.out, errno = %d\n", errno );
#ifdef PERLDBf_NONAME
	default_perldb = PERLDBf_NONAME | PERLDBf_SUB; /* no name needed. */
#ifdef PERLDBf_GOTO
	default_perldb = default_perldb | PERLDBf_GOTO;
#endif 
	cv_hash = newHV();
#else
#  ifdef PERLDBf_SUB
	default_perldb = PERLDBf_SUB;		/* debug subroutines only. */
#  endif
#endif
        prof_pid = (int)getpid();

	New( 0, profstack, profstack_max, PROFANY );

        prof_recordheader();

        DBG_TIMER_NOTIFY("Profiler timer is on.\n");
        orealtime = rprof_start = Times(&prof_start);
	otms_utime = prof_start.tms_utime;
	otms_stime = prof_start.tms_stime;
	perldb = default_perldb;
