/*    sharedsv.c
 *
 *    Copyright (c) 2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
* Contributed by Arthur Bergman arthur@contiller.se
*
* "Hand any two wizards a piece of rope and they would instinctively pull in
* opposite directions."
*                         --Sourcery
*
*/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

PerlInterpreter	*PL_sharedsv_space;		/* The shared sv space */
perl_mutex	 PL_sharedsv_space_mutex;	/* Mutex protecting the shared sv space */

typedef struct {
    SV                 *sv;             /* The actual SV */
    perl_mutex          mutex;          /* Our mutex */
    perl_cond           cond;           /* Our condition variable */
    perl_cond           user_cond;      /* For user-level conditions */
    IV                  locks;          /* Number of locks held */
    PerlInterpreter    *owner;          /* Who owns the lock? */
    U16                 index;          /* Update index */
} shared_sv;

#define SHAREDSvGET(a)      (a->sv)
#define SHAREDSvLOCK(a)     Perl_sharedsv_lock(aTHX_ a)
#define SHAREDSvUNLOCK(a)   Perl_sharedsv_unlock(aTHX_ a)

#define SHAREDSvEDIT(a)     STMT_START {                                \
                                MUTEX_LOCK(&PL_sharedsv_space_mutex);   \
                                SHAREDSvLOCK((a));                      \
                                PERL_SET_CONTEXT(PL_sharedsv_space);    \
                            } STMT_END

#define SHAREDSvRELEASE(a)  STMT_START {                                \
                                PERL_SET_CONTEXT((a)->owner);           \
                                SHAREDSvUNLOCK((a));                    \
                                MUTEX_UNLOCK(&PL_sharedsv_space_mutex); \
                            } STMT_END

extern void	Perl_sharedsv_init(pTHX);
extern shared_sv*	Perl_sharedsv_new(pTHX);
extern shared_sv*	Perl_sharedsv_find(pTHX_ SV* sv);
extern void	Perl_sharedsv_lock(pTHX_ shared_sv* ssv);
extern void	Perl_sharedsv_unlock(pTHX_ shared_sv* ssv);
extern void	Perl_sharedsv_unlock_scope(pTHX_ shared_sv* ssv);
extern void	Perl_sharedsv_thrcnt_inc(pTHX_ shared_sv* ssv);
extern void	Perl_sharedsv_thrcnt_dec(pTHX_ shared_sv* ssv);

/*
  Shared SV

  Shared SV is a structure for keeping the backend storage
  of shared svs.

*/

/*

 =head1 Shared SV Functions

 =for apidoc sharedsv_init 

Saves a space for keeping SVs wider than an interpreter,
currently only stores a pointer to the first interpreter.

 =cut

*/

void
Perl_sharedsv_init(pTHX)
{
  PerlInterpreter* old_context = PERL_GET_CONTEXT;
  PL_sharedsv_space = perl_alloc();
  perl_construct(PL_sharedsv_space);
  PERL_SET_CONTEXT(old_context);
  MUTEX_INIT(&PL_sharedsv_space_mutex);
}

/*
 =for apidoc sharedsv_new

Allocates a new shared sv struct, you must yourself create the SV/AV/HV.
 =cut
*/

shared_sv *
Perl_sharedsv_new(pTHX)
{
    shared_sv* ssv;
    New(2555,ssv,1,shared_sv);
    MUTEX_INIT(&ssv->mutex);
    COND_INIT(&ssv->cond);
    COND_INIT(&ssv->user_cond);
    ssv->owner = 0;
    ssv->locks = 0;
    ssv->index = 0;
    return ssv;
}


/*
 =for apidoc sharedsv_find

Tries to find if a given SV has a shared backend, either by
looking at magic, or by checking if it is tied again threads::shared.

 =cut
*/

shared_sv *
Perl_sharedsv_find(pTHX_ SV* sv)
{
  /* does all it can to find a shared_sv struct, returns NULL otherwise */
    shared_sv* ssv = NULL;
    switch (SvTYPE(sv)) {
        case SVt_PVMG:
        case SVt_PVAV:
        case SVt_PVHV: {
            MAGIC* mg = mg_find(sv, PERL_MAGIC_ext);
            if(mg) {
	        if(strcmp(mg->mg_ptr,"threads::shared"))
                    break;
                ssv = INT2PTR(shared_sv *, SvIV(mg->mg_obj));
	        break;
             }
	
	     mg = mg_find(sv,PERL_MAGIC_tied);
             if(mg) {
                 SV* obj = SvTIED_obj(sv,mg);
	         if(sv_derived_from(obj, "threads::shared"))
                     ssv = INT2PTR(shared_sv *, SvIV(SvRV(obj)));
                 break;
             }
	}
    }
    return ssv;
}

/*
 =for apidoc sharedsv_lock

Recursive locks on a sharedsv.
Locks are dynamically scoped at the level of the first lock.
 =cut
*/
void
Perl_sharedsv_lock(pTHX_ shared_sv* ssv)
{
    if(!ssv)
        return;
    MUTEX_LOCK(&ssv->mutex);
    if(ssv->owner && ssv->owner == my_perl) {
        ssv->locks++;
	MUTEX_UNLOCK(&ssv->mutex);
        return;
    }
    while(ssv->owner)
      COND_WAIT(&ssv->cond,&ssv->mutex);
    ssv->locks++;
    ssv->owner = my_perl;
    if(ssv->locks == 1)
        SAVEDESTRUCTOR_X(Perl_sharedsv_unlock_scope,ssv);
    MUTEX_UNLOCK(&ssv->mutex);
}

/*
 =for apidoc sharedsv_unlock

Recursively unlocks a shared sv.

 =cut
*/

void
Perl_sharedsv_unlock(pTHX_ shared_sv* ssv)
{
    MUTEX_LOCK(&ssv->mutex);
    if(ssv->owner != my_perl) {
        Perl_croak(aTHX_ "panic: Perl_sharedsv_unlock unlocking mutex that we don't own");
        MUTEX_UNLOCK(&ssv->mutex);
        return;
    }

    if(--ssv->locks == 0) {
        ssv->owner = NULL;
	COND_SIGNAL(&ssv->cond);
    }
    MUTEX_UNLOCK(&ssv->mutex);
 }

void
Perl_sharedsv_unlock_scope(pTHX_ shared_sv* ssv)
{
    MUTEX_LOCK(&ssv->mutex);
    if(ssv->owner != my_perl) {
        MUTEX_UNLOCK(&ssv->mutex);
        return;
    }
    ssv->locks = 0;
    ssv->owner = NULL;
    COND_SIGNAL(&ssv->cond);
    MUTEX_UNLOCK(&ssv->mutex);
}

/*
 =for apidoc sharedsv_thrcnt_inc

Increments the threadcount of a sharedsv.
 =cut
*/
void
Perl_sharedsv_thrcnt_inc(pTHX_ shared_sv* ssv)
{
  SHAREDSvLOCK(ssv);
  SvREFCNT_inc(ssv->sv);
  SHAREDSvUNLOCK(ssv);
}

/*
 =for apidoc sharedsv_thrcnt_dec

Decrements the threadcount of a shared sv. When a threads frontend is freed
this function should be called.

 =cut
*/

void
Perl_sharedsv_thrcnt_dec(pTHX_ shared_sv* ssv)
{
    SV* sv;
    SHAREDSvLOCK(ssv);
    sv = SHAREDSvGET(ssv);
    if (SvREFCNT(sv) == 1) {
        switch (SvTYPE(sv)) {
        case SVt_RV:
            if (SvROK(sv))
            Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv *, SvIV(SvRV(sv))));
            break;
        case SVt_PVAV: {
            SV **src_ary  = AvARRAY((AV *)sv);
            SSize_t items = AvFILLp((AV *)sv) + 1;

            while (items-- > 0) {
            if(SvTYPE(*src_ary))
                Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv *, SvIV(*src_ary)));
                src_ary++;
            }
            break;
        }
        case SVt_PVHV: {
            HE *entry;
            (void)hv_iterinit((HV *)sv);
            while ((entry = hv_iternext((HV *)sv)))
                Perl_sharedsv_thrcnt_dec(
                    aTHX_ INT2PTR(shared_sv *, SvIV(hv_iterval((HV *)sv, entry)))
                );
            break;
        }
        }
    }
    Perl_sv_free(PL_sharedsv_space,SHAREDSvGET(ssv));
    SHAREDSvUNLOCK(ssv);
}


MGVTBL svtable;

SV* Perl_shared_sv_attach_sv (pTHX_ SV* sv, shared_sv* shared) {
    HV* shared_hv = get_hv("threads::shared::shared", FALSE);
    SV* id = newSViv(PTR2IV(shared));
    STRLEN length = sv_len(id);
    SV* tiedobject;
    SV** tiedobject_ = hv_fetch(shared_hv, SvPV(id,length), length, 0);
    if(tiedobject_) {
    	tiedobject = (*tiedobject_);
	if(sv) {
            SvROK_on(sv);
            SvRV(sv) = SvRV(tiedobject);
	} else {
	    sv = newRV(SvRV(tiedobject));
	}
    } else {
	switch(SvTYPE(SHAREDSvGET(shared))) {
	    case SVt_PVAV: {
		SV* weakref;
		SV* obj_ref = newSViv(0);
		SV* obj = newSVrv(obj_ref,"threads::shared::av");
		AV* hv = newAV();
		sv_setiv(obj,PTR2IV(shared));
		weakref = newRV((SV*)hv);
		sv = newRV_noinc((SV*)hv);
		sv_rvweaken(weakref);
		sv_magic((SV*) hv, obj_ref, PERL_MAGIC_tied, Nullch, 0);
		hv_store(shared_hv, SvPV(id,length), length, weakref, 0);
	        Perl_sharedsv_thrcnt_inc(aTHX_ shared);		
	    }
	    break;
	    case SVt_PVHV: {
		SV* weakref;
		SV* obj_ref = newSViv(0);
		SV* obj = newSVrv(obj_ref,"threads::shared::hv");
		HV* hv = newHV();
		sv_setiv(obj,PTR2IV(shared));
		weakref = newRV((SV*)hv);
		sv = newRV_noinc((SV*)hv);
		sv_rvweaken(weakref);
		sv_magic((SV*) hv, obj_ref, PERL_MAGIC_tied, Nullch, 0);
		hv_store(shared_hv, SvPV(id,length), length, weakref, 0);
	        Perl_sharedsv_thrcnt_inc(aTHX_ shared);		
	    }
	    break;
	    default: {
	        MAGIC* shared_magic;
		SV* value = newSVsv(SHAREDSvGET(shared));
	        SV* obj = newSViv(PTR2IV(shared));
        	sv_magic(value, 0, PERL_MAGIC_ext, "threads::shared", 16);
        	shared_magic = mg_find(value, PERL_MAGIC_ext);
        	shared_magic->mg_virtual = &svtable;
        	shared_magic->mg_obj = newSViv(PTR2IV(shared));
        	shared_magic->mg_flags |= MGf_REFCOUNTED;
        	shared_magic->mg_private = 0;
        	SvMAGICAL_on(value);
	        sv = newRV_noinc(value);
	        value = newRV(value);
 		sv_rvweaken(value);
	        hv_store(shared_hv, SvPV(id,length),length, value, 0);
		Perl_sharedsv_thrcnt_inc(aTHX_ shared);
	    }
	    	
	}
    }
    return sv;
}


int shared_sv_fetch_mg (pTHX_ SV* sv, MAGIC *mg) {
    shared_sv* shared = INT2PTR(shared_sv*, SvIV(mg->mg_obj));
    SHAREDSvLOCK(shared);
    if(mg->mg_private != shared->index) {
        if(SvROK(SHAREDSvGET(shared))) {
            shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(shared))));
	    shared_sv_attach_sv(sv, target);
        } else {
            sv_setsv(sv, SHAREDSvGET(shared));
        }
        mg->mg_private = shared->index;
    }
    SHAREDSvUNLOCK(shared);

    return 0;
}

int shared_sv_store_mg (pTHX_ SV* sv, MAGIC *mg) {
    shared_sv* shared = INT2PTR(shared_sv*, SvIV(mg->mg_obj));
    SHAREDSvLOCK(shared);
    if(SvROK(SHAREDSvGET(shared)))
        Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(shared)))));
    if(SvROK(sv)) {
        shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(sv));
        if(!target) {
            sv_setsv(sv,SHAREDSvGET(shared));
            SHAREDSvUNLOCK(shared);
            Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared scalar");
        }
        SHAREDSvEDIT(shared);
        Perl_sv_free(PL_sharedsv_space,SHAREDSvGET(shared));
        SHAREDSvGET(shared) = newRV_noinc(newSViv(PTR2IV(target)));
    } else {
            SHAREDSvEDIT(shared);
	sv_setsv(SHAREDSvGET(shared), sv);
    }
    shared->index++;
    mg->mg_private = shared->index;
    SHAREDSvRELEASE(shared);
    if(SvROK(SHAREDSvGET(shared)))
       Perl_sharedsv_thrcnt_inc(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(shared)))));
    SHAREDSvUNLOCK(shared);
    return 0;
}

int shared_sv_destroy_mg (pTHX_ SV* sv, MAGIC *mg) {
    shared_sv* shared = INT2PTR(shared_sv*, SvIV(mg->mg_obj));
    if(!shared)
        return 0;
    {
	HV* shared_hv = get_hv("threads::shared::shared", FALSE);
        SV* id = newSViv(PTR2IV(shared));
        STRLEN length = sv_len(id);
        hv_delete(shared_hv, SvPV(id,length), length,0);
    }
    Perl_sharedsv_thrcnt_dec(aTHX_ shared);
}

MGVTBL svtable = {MEMBER_TO_FPTR(shared_sv_fetch_mg),
		  MEMBER_TO_FPTR(shared_sv_store_mg),
		  0,
		  0,
		  MEMBER_TO_FPTR(shared_sv_destroy_mg)
};

MODULE = threads::shared		PACKAGE = threads::shared		


PROTOTYPES: ENABLE


SV*
ptr(ref)
	SV* ref
	CODE:
	RETVAL = newSViv(SvIV(SvRV(ref)));
	OUTPUT:
	RETVAL


SV*
_thrcnt(ref)
        SV* ref
	CODE:
        shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("thrcnt can only be used on shared values");
	SHAREDSvLOCK(shared);
        RETVAL = newSViv(SvREFCNT(SHAREDSvGET(shared)));
        SHAREDSvUNLOCK(shared);
	OUTPUT:
        RETVAL


void
thrcnt_inc(ref,perl)
        SV* ref
	SV* perl
        CODE:
	shared_sv* shared;
	PerlInterpreter* origperl = INT2PTR(PerlInterpreter*, SvIV(perl));
	PerlInterpreter* oldperl = PERL_GET_CONTEXT;
        if(SvROK(ref))
            ref = SvRV(ref);
        shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("thrcnt can only be used on shared values");
	PERL_SET_CONTEXT(origperl);
	Perl_sharedsv_thrcnt_inc(aTHX_ shared);
	PERL_SET_CONTEXT(oldperl);	

void
_thrcnt_dec(ref)
        SV* ref
        CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(ref));
        if(!shared)
           croak("thrcnt can only be used on shared values");
	Perl_sharedsv_thrcnt_dec(aTHX_ shared);

void
unlock_enabled(ref)
	SV* ref
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("unlock can only be used on shared values");
	SHAREDSvUNLOCK(shared);

void
lock_enabled(ref)
        SV* ref
        CODE:
        shared_sv* shared;
        if(SvROK(ref))
            ref = SvRV(ref);
        shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("lock can only be used on shared values");
        SHAREDSvLOCK(shared);


void
cond_wait_enabled(ref)
	SV* ref
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	int locks;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_wait can only be used on shared values");
	if(shared->owner != PERL_GET_CONTEXT)
	    croak("You need a lock before you can cond_wait");
	MUTEX_LOCK(&shared->mutex);
	shared->owner = NULL;
	locks = shared->locks = 0;
	COND_WAIT(&shared->user_cond, &shared->mutex);
	shared->owner = PERL_GET_CONTEXT;
	shared->locks = locks;
	MUTEX_UNLOCK(&shared->mutex);

void cond_signal_enabled(ref)
	SV* ref
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_signal can only be used on shared values");
	COND_SIGNAL(&shared->user_cond);


void cond_broadcast_enabled(ref)
	SV* ref
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_broadcast can only be used on shared values");
	COND_BROADCAST(&shared->user_cond);

MODULE = threads::shared		PACKAGE = threads::shared::sv		

SV*
new(class, value)
	SV* class
	SV* value
	CODE:
	shared_sv* shared = Perl_sharedsv_new(aTHX);
        MAGIC* shared_magic;
	SV* obj = newSViv(PTR2IV(shared));
	SHAREDSvEDIT(shared);
	SHAREDSvGET(shared) = newSVsv(value);
        SHAREDSvRELEASE(shared);
	sv_magic(value, 0, PERL_MAGIC_ext, "threads::shared", 16);
        shared_magic = mg_find(value, PERL_MAGIC_ext);
        shared_magic->mg_virtual = &svtable;
        shared_magic->mg_obj = newSViv(PTR2IV(shared));
        shared_magic->mg_flags |= MGf_REFCOUNTED;
        shared_magic->mg_private = 0;
        SvMAGICAL_on(value);
        RETVAL = obj;
        OUTPUT:        	
        RETVAL


MODULE = threads::shared		PACKAGE = threads::shared::av

SV*
new(class, value)
	SV* class
	SV* value
	CODE:
	shared_sv* shared = Perl_sharedsv_new(aTHX);
	SV* obj = newSViv(PTR2IV(shared));
        SHAREDSvEDIT(shared);
        SHAREDSvGET(shared) = (SV*) newAV();
        SHAREDSvRELEASE(shared);
        RETVAL = obj;
        OUTPUT:
        RETVAL

void
STORE(self, index, value)
        SV* self
	SV* index
        SV* value
        CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        shared_sv* slot;
        SV* aentry;
	SV** aentry_;
	if(SvROK(value)) {
	    shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(value));
	    if(!target) {
	         Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared array");
	    }
            value = newRV_noinc(newSViv(PTR2IV(target)));
        }
	SHAREDSvLOCK(shared);
	aentry_ = av_fetch((AV*) SHAREDSvGET(shared), SvIV(index), 0);
	if(aentry_ && SvIV((*aentry_))) {
	    aentry = (*aentry_);
            slot = INT2PTR(shared_sv*, SvIV(aentry));
            if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));
            SHAREDSvEDIT(slot);
            sv_setsv(SHAREDSvGET(slot), value);
            SHAREDSvRELEASE(slot);
	} else {
            slot = Perl_sharedsv_new(aTHX);
            SHAREDSvEDIT(shared);
            SHAREDSvGET(slot) = newSVsv(value);
            aentry = newSViv(PTR2IV(slot));
            av_store((AV*) SHAREDSvGET(shared), SvIV(index), aentry);
            SHAREDSvRELEASE(shared);
	}
        if(SvROK(SHAREDSvGET(slot)))
            Perl_sharedsv_thrcnt_inc(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));

        SHAREDSvUNLOCK(shared);

SV*
FETCH(self, index)
        SV* self
	SV* index
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
	SV* aentry;
	SV** aentry_;
	SV* retval;
	SHAREDSvLOCK(shared);
 	aentry_ = av_fetch((AV*) SHAREDSvGET(shared), SvIV(index),0);
	if(aentry_) {
	    aentry = (*aentry_);
            if(SvTYPE(aentry) == SVt_NULL) {
	        retval = &PL_sv_undef;
	    } else {
	        slot = INT2PTR(shared_sv*, SvIV(aentry));
		if(SvROK(SHAREDSvGET(slot))) {
		     shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
		     retval = Perl_shared_sv_attach_sv(aTHX_ NULL,target);
		} else {
	             retval = newSVsv(SHAREDSvGET(slot));
		}
            }
	} else {
	    retval = &PL_sv_undef;
	}
        SHAREDSvUNLOCK(shared);	
        RETVAL = retval;
        OUTPUT:
        RETVAL

void
PUSH(self, ...)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        int i;
        SHAREDSvLOCK(shared);
	for(i = 1; i < items; i++) {
    	    shared_sv* slot = Perl_sharedsv_new(aTHX);
	    SV* tmp = ST(i);
	    if(SvROK(tmp)) {
                 shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(tmp));
                 if(!target) {
                     Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared array");
                 }
                 tmp = newRV_noinc(newSViv(PTR2IV(target)));
            }
            SHAREDSvEDIT(slot);
	    SHAREDSvGET(slot) = newSVsv(tmp);
	    av_push((AV*) SHAREDSvGET(shared), newSViv(PTR2IV(slot)));
	    SHAREDSvRELEASE(slot);
	    if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_inc(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));
	}
        SHAREDSvUNLOCK(shared);

void
UNSHIFT(self, ...)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        int i;
        SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	av_unshift((AV*)SHAREDSvGET(shared), items - 1);
	SHAREDSvRELEASE(shared);
	for(i = 1; i < items; i++) {
    	    shared_sv* slot = Perl_sharedsv_new(aTHX);
	    SV* tmp = ST(i);
	    if(SvROK(tmp)) {
                 shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(tmp));
                 if(!target) {
                     Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared array");
                 }
                 tmp = newRV_noinc(newSViv(PTR2IV(target)));
            }
            SHAREDSvEDIT(slot);
	    SHAREDSvGET(slot) = newSVsv(tmp);
	    av_store((AV*) SHAREDSvGET(shared), i - 1, newSViv(PTR2IV(slot)));
	    SHAREDSvRELEASE(slot);
	    if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_inc(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));
	}
        SHAREDSvUNLOCK(shared);

SV*
POP(self)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
	SV* retval;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	retval = av_pop((AV*)SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	if(retval && SvIV(retval)) {
	    slot = INT2PTR(shared_sv*, SvIV(retval));
	    if(SvROK(SHAREDSvGET(slot))) {
		 shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
		 retval = Perl_shared_sv_attach_sv(aTHX_ NULL,target);
	    } else {
	         retval = newSVsv(SHAREDSvGET(slot));
            }
            Perl_sharedsv_thrcnt_dec(aTHX_ slot);
	} else {
            retval = &PL_sv_undef;
	}
	SHAREDSvUNLOCK(shared);
	RETVAL = retval;
	OUTPUT:
	RETVAL


SV*
SHIFT(self)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
	SV* retval;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	retval = av_shift((AV*)SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	if(retval && SvIV(retval)) {
	    slot = INT2PTR(shared_sv*, SvIV(retval));
            if(SvROK(SHAREDSvGET(slot))) {
                 shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
                 retval = Perl_shared_sv_attach_sv(aTHX_ NULL,target);
            } else {
                 retval = newSVsv(SHAREDSvGET(slot));
            }
            Perl_sharedsv_thrcnt_dec(aTHX_ slot);
	} else {
            retval = &PL_sv_undef;
	}
	SHAREDSvUNLOCK(shared);
	RETVAL = retval;
	OUTPUT:
	RETVAL

void
CLEAR(self)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
	SV** svp;
	I32 i;
	SHAREDSvLOCK(shared);
	svp = AvARRAY((AV*)SHAREDSvGET(shared));
	i   = AvFILLp((AV*)SHAREDSvGET(shared));
	while ( i >= 0) {
	    if(SvIV(svp[i])) {
	        Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv*, SvIV(svp[i])));
	    }
	    i--;
	}
	SHAREDSvEDIT(shared);
	av_clear((AV*)SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	SHAREDSvUNLOCK(shared);
	
void
EXTEND(self, count)
	SV* self
	SV* count
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	SHAREDSvEDIT(shared);
	av_extend((AV*)SHAREDSvGET(shared), (I32) SvIV(count));
	SHAREDSvRELEASE(shared);




SV*
EXISTS(self, index)
	SV* self
	SV* index
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	I32 exists;
	SHAREDSvLOCK(shared);
	exists = av_exists((AV*) SHAREDSvGET(shared), (I32) SvIV(index));
	if(exists) {
	    RETVAL = &PL_sv_yes;
	} else {
	    RETVAL = &PL_sv_no;
	}
	SHAREDSvUNLOCK(shared);

void
STORESIZE(self,count)
	SV* self
	SV* count
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	SHAREDSvEDIT(shared);
	av_fill((AV*) SHAREDSvGET(shared), (I32) SvIV(count));
	SHAREDSvRELEASE(shared);

SV*
FETCHSIZE(self)
	SV* self
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	SHAREDSvLOCK(shared);
	RETVAL = newSViv(av_len((AV*) SHAREDSvGET(shared)) + 1);
	SHAREDSvUNLOCK(shared);
	OUTPUT:
	RETVAL

SV*
DELETE(self,index)
	SV* self
	SV* index
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
	SHAREDSvLOCK(shared);
	if(av_exists((AV*) SHAREDSvGET(shared), (I32) SvIV(index))) {
	    SV* tmp;
	    SHAREDSvEDIT(shared);
	    tmp = av_delete((AV*)SHAREDSvGET(shared), (I32) SvIV(index),0);
	    SHAREDSvRELEASE(shared);
	    if(SvIV(tmp)) {
		slot = INT2PTR(shared_sv*, SvIV(tmp));
                if(SvROK(SHAREDSvGET(slot))) {
                   shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
                   RETVAL = Perl_shared_sv_attach_sv(aTHX_ NULL,target);
                } else {
                   RETVAL = newSVsv(SHAREDSvGET(slot));
                }
                Perl_sharedsv_thrcnt_dec(aTHX_ slot);
	    } else {
                RETVAL = &PL_sv_undef;
	    }	
	} else {
	    RETVAL = &PL_sv_undef;
	}	
	SHAREDSvUNLOCK(shared);
	OUTPUT:
	RETVAL

AV*
SPLICE(self, offset, length, ...)
	SV* self
	SV* offset
	SV* length
	CODE:
	croak("Splice is not implmented for shared arrays");
	
MODULE = threads::shared		PACKAGE = threads::shared::hv

SV*
new(class, value)
	SV* class
	SV* value
	CODE:
	shared_sv* shared = Perl_sharedsv_new(aTHX);
	SV* obj = newSViv(PTR2IV(shared));
        SHAREDSvEDIT(shared);
        SHAREDSvGET(shared) = (SV*) newHV();
        SHAREDSvRELEASE(shared);
        RETVAL = obj;
        OUTPUT:
        RETVAL

void
STORE(self, key, value)
        SV* self
        SV* key
        SV* value
        CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        shared_sv* slot;
        SV* hentry;
        SV** hentry_;
	STRLEN len;
	char* ckey = SvPV(key, len);
        SHAREDSvLOCK(shared);
	if(SvROK(value)) {
	    shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(value));
	    if(!target) {
		Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared hash");
            }
	    SHAREDSvEDIT(shared);
	    value = newRV_noinc(newSViv(PTR2IV(target)));
	    SHAREDSvRELEASE(shared);
	}
        hentry_ = hv_fetch((HV*) SHAREDSvGET(shared), ckey, len, 0);
        if(hentry_ && SvIV((*hentry_))) {
            hentry = (*hentry_);
            slot = INT2PTR(shared_sv*, SvIV(hentry));
            if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));
            SHAREDSvEDIT(slot);
            sv_setsv(SHAREDSvGET(slot), value);
            SHAREDSvRELEASE(slot);
        } else {
            slot = Perl_sharedsv_new(aTHX);
            SHAREDSvEDIT(shared);
            SHAREDSvGET(slot) = newSVsv(value);
            hentry = newSViv(PTR2IV(slot));
            hv_store((HV*) SHAREDSvGET(shared), ckey,len , hentry, 0);
            SHAREDSvRELEASE(shared);
        }
	if(SvROK(SHAREDSvGET(slot)))
	    Perl_sharedsv_thrcnt_inc(aTHX_ INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot)))));
        SHAREDSvUNLOCK(shared);


SV*
FETCH(self, key)
        SV* self
        SV* key
        CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        shared_sv* slot;
        SV* hentry;
        SV** hentry_;
        SV* retval;
	STRLEN len;
	char* ckey = SvPV(key, len);
        SHAREDSvLOCK(shared);
        hentry_ = hv_fetch((HV*) SHAREDSvGET(shared), ckey, len,0);
        if(hentry_) {
            hentry = (*hentry_);
            if(SvTYPE(hentry) == SVt_NULL) {
                retval = &PL_sv_undef;
            } else {
                slot = INT2PTR(shared_sv*, SvIV(hentry));
		if(SvROK(SHAREDSvGET(slot))) {
		    shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
		    retval = Perl_shared_sv_attach_sv(aTHX_ NULL, target);
		} else {
	            retval = newSVsv(SHAREDSvGET(slot));
		}
            }
        } else {
            retval = &PL_sv_undef;
        }
        SHAREDSvUNLOCK(shared);
        RETVAL = retval;
        OUTPUT:
        RETVAL

void
CLEAR(self)
	SV* self
	CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        shared_sv* slot;
	HE* entry;
	SHAREDSvLOCK(shared);
	Perl_hv_iterinit(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
	entry = Perl_hv_iternext(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
	while(entry) {
		slot = INT2PTR(shared_sv*, SvIV(Perl_hv_iterval(PL_sharedsv_space, (HV*) SHAREDSvGET(shared), entry)));
		Perl_sharedsv_thrcnt_dec(aTHX_ slot);
		entry = Perl_hv_iternext(PL_sharedsv_space,(HV*) SHAREDSvGET(shared));
	}
	SHAREDSvEDIT(shared);
	hv_clear((HV*) SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	SHAREDSvUNLOCK(shared);

SV*
FIRSTKEY(self)
	SV* self
	CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	char* key = NULL;
	I32 len;
	HE* entry;
	SHAREDSvLOCK(shared);
        Perl_hv_iterinit(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
        entry = Perl_hv_iternext(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
	if(entry) {
                key = Perl_hv_iterkey(PL_sharedsv_space, entry,&len);
		RETVAL = newSVpv(key, len);
        } else {
	     RETVAL = &PL_sv_undef;
	}
        SHAREDSvUNLOCK(shared);
	OUTPUT:
	RETVAL


SV*
NEXTKEY(self, oldkey)
        SV* self
	SV* oldkey
        CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
        char* key = NULL;
        I32 len;
        HE* entry;
        SHAREDSvLOCK(shared);
        entry = Perl_hv_iternext(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
        if(entry) {
                key = Perl_hv_iterkey(PL_sharedsv_space, entry,&len);
                RETVAL = newSVpv(key, len);
        } else {
             RETVAL = &PL_sv_undef;
        }
        SHAREDSvUNLOCK(shared);
        OUTPUT:
        RETVAL


SV*
EXISTS(self, key)
	SV* self
	SV* key
	CODE:
	shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	STRLEN len;
	char* ckey = SvPV(key, len);
	SHAREDSvLOCK(shared);
	if(hv_exists((HV*)SHAREDSvGET(shared), ckey, len)) {
		RETVAL = &PL_sv_yes;
	} else {
		RETVAL = &PL_sv_no;
	}
	SHAREDSvUNLOCK(shared);
	OUTPUT:
	RETVAL

SV*
DELETE(self, key)
        SV* self
        SV* key
        CODE:
        shared_sv* shared = INT2PTR(shared_sv*, SvIV(SvRV(self)));
	shared_sv* slot;
        STRLEN len;
        char* ckey = SvPV(key, len);
        SV* tmp;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	tmp = hv_delete((HV*) SHAREDSvGET(shared), ckey, len,0);
	SHAREDSvRELEASE(shared);
	if(tmp) {
		slot = INT2PTR(shared_sv*, SvIV(tmp));
		if(SvROK(SHAREDSvGET(slot))) {
		    shared_sv* target = INT2PTR(shared_sv*, SvIV(SvRV(SHAREDSvGET(slot))));
		    RETVAL = Perl_shared_sv_attach_sv(aTHX_ NULL, target);
		} else {
		    RETVAL = newSVsv(SHAREDSvGET(slot));
		}
		Perl_sharedsv_thrcnt_dec(aTHX_ slot);
	} else {
		RETVAL = &PL_sv_undef;
	}
        SHAREDSvUNLOCK(shared);
        OUTPUT:
        RETVAL

BOOT:
{
     Perl_sharedsv_init(aTHX);
}
