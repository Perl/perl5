/*    sharedsv.c
 *
 *    Copyright (c) 2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *
 * "Hand any two wizards a piece of rope and they would instinctively pull in
 * opposite directions."
 *                         --Sourcery
 *
 * Contributed by Arthur Bergman arthur@contiller.se
 * pulled in the (an)other direction by Nick Ing-Simmons nick@ing-simmons.net
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SHAREDSvPTR(a)      ((a)->sv)

/*
 * The shared things need an intepreter to live in ...
 */
PerlInterpreter *PL_sharedsv_space;             /* The shared sv space */
/* To access shared space we fake aTHX in this scope and thread's context */
#define SHARED_CONTEXT 	    PERL_SET_CONTEXT((aTHX = PL_sharedsv_space))

/* So we need a way to switch back to the caller's context... */
/* So we declare _another_ copy of the aTHX variable ... */
#define dTHXc PerlInterpreter *caller_perl = aTHX
/* and use it to switch back */
#define CALLER_CONTEXT      PERL_SET_CONTEXT((aTHX = caller_perl))

/*
 * Only one thread at a time is allowed to mess with shared space.
 */
perl_mutex       PL_sharedsv_space_mutex;       /* Mutex protecting the shared sv space */

#define SHARED_LOCK         MUTEX_LOCK(&PL_sharedsv_space_mutex)
#define SHARED_UNLOCK       MUTEX_UNLOCK(&PL_sharedsv_space_mutex)

/* A common idiom is to acquire access and switch in ... */
#define SHARED_EDIT	    STMT_START {	\
				SHARED_LOCK;	\
				SHARED_CONTEXT;	\
			    } STMT_END

/* then switch out and release access. */
#define SHARED_RELEASE     STMT_START {	\
		                CALLER_CONTEXT;	\
				SHARED_UNLOCK;	\
			    } STMT_END
			

/*

  Shared SV

  Shared SV is a structure for keeping the backend storage
  of shared svs.

  Shared-ness really only needs the SV * - the rest is for locks.
  (Which suggests further space optimization ... )

*/

typedef struct {
    SV                 *sv;             /* The actual SV - in shared space */
    perl_mutex          mutex;          /* Our mutex */
    perl_cond           cond;           /* Our condition variable */
    perl_cond           user_cond;      /* For user-level conditions */
    IV                  locks;          /* Number of locks held */
    PerlInterpreter    *owner;          /* Who owns the lock? */
} shared_sv;

/* The SV in shared-space has a back-pointer to the shared_sv
   struct associated with it PERL_MAGIC_ext.

   The vtable used has just one entry - when the SV goes away
   we free the memory for the above.

 */

int
sharedsv_shared_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    if (shared) {
	PerlMemShared_free(shared);
	mg->mg_ptr = NULL;
    }
    return 0;
}


MGVTBL sharedsv_shared_vtbl = {
 0,				/* get */
 0,				/* set */
 0,				/* len */
 0,				/* clear */
 sharedsv_shared_mg_free,	/* free */
 0,				/* copy */
 0,				/* dup */
};

/* Access to shared things is heavily based on MAGIC - in mg.h/mg.c/sv.c sense */

/* In any thread that has access to a shared thing there is a "proxy"
   for it in its own space which has 'MAGIC' associated which accesses
   the shared thing.
 */

MGVTBL sharedsv_scalar_vtbl;    /* scalars have this vtable */
MGVTBL sharedsv_array_vtbl;     /* hashes and arrays have this - like 'tie' */
MGVTBL sharedsv_elem_vtbl;      /* elements of hashes and arrays have this
				   _AS WELL AS_ the scalar magic */

/* The sharedsv_elem_vtbl associates the element with the array/hash and
   the sharedsv_scalar_vtbl associates it with the value
 */

=for apidoc sharedsv_find

Given a private side SV tries to find if a given SV has a shared backend,
by looking for the magic.

=cut

shared_sv *
Perl_sharedsv_find(pTHX_ SV *sv)
{
    MAGIC *mg;
    switch(SvTYPE(sv)) {
    case SVt_PVAV:
    case SVt_PVHV:
	if ((mg = mg_find(sv, PERL_MAGIC_tied))
	    	&& mg->mg_virtual == &sharedsv_array_vtbl) {
		return (shared_sv *) mg->mg_ptr;
	    }
	    break;
    default:
	if ((mg = mg_find(sv, PERL_MAGIC_shared_scalar))
	    	&& mg->mg_virtual == &sharedsv_scalar_vtbl) {
		return (shared_sv *) mg->mg_ptr;
	}
    }
    return NULL;
}

/*
 *  Almost all the pain is in this routine.
 *
 */

shared_sv *
Perl_sharedsv_associate(pTHX_ SV **psv, SV *ssv, shared_sv *data)
{
    /* First try and get global data structure */
    dTHXc;
    MAGIC *mg;
    SV *sv;
    if (aTHX == PL_sharedsv_space) {
	croak("panic:Cannot associate from within shared space");
    }
    SHARED_LOCK;

    /* Try shared SV as 1st choice */
    if (!data && ssv) {
	if (mg = mg_find(ssv, PERL_MAGIC_ext)) {
	    data = (shared_sv *) mg->mg_ptr;
	}
    }
    /* Next try private SV */
    if (!data && psv && *psv) {
	data = Perl_sharedsv_find(aTHX_ *psv);
    }
    /* If neither of those then create a new one */
    if (!data) {
	    data = PerlMemShared_malloc(sizeof(shared_sv));
	    Zero(data,1,shared_sv);
	    MUTEX_INIT(&data->mutex);
	    COND_INIT(&data->cond);
	    COND_INIT(&data->user_cond);
	    data->owner = 0;
	    data->locks = 0;
    }

    if (!ssv)
	ssv = SHAREDSvPTR(data);
	
    /* If we know type allocate shared side SV */
    if (psv && *psv && !ssv) {
	SHARED_CONTEXT;
	ssv = newSV(0);
	sv_upgrade(ssv, SvTYPE(*psv));
	/* Tag shared side SV with data pointer */
	sv_magicext(ssv, ssv, PERL_MAGIC_ext, &sharedsv_shared_vtbl,
		   (char *)data, 0);
	CALLER_CONTEXT;
    }

    if (!SHAREDSvPTR(data))
	SHAREDSvPTR(data) = ssv;

    /* Now if requested allocate private SV */
    if (psv && !*psv && ssv) {
	sv = newSV(0);
	sv_upgrade(sv, SvTYPE(SHAREDSvPTR(data)));
	*psv = sv;
    }

    /* Finally if private SV exists check and add magic */
    if (psv && *psv) {
	SV *sv = *psv;
	MAGIC *mg;
	switch(SvTYPE(sv)) {
	case SVt_PVAV:
	case SVt_PVHV:
	    if (!(mg = mg_find(sv, PERL_MAGIC_tied))
	        || mg->mg_virtual != &sharedsv_array_vtbl) {
		if (mg)
		    sv_unmagic(sv, PERL_MAGIC_tied);
		mg = sv_magicext(sv, sv, PERL_MAGIC_tied, &sharedsv_array_vtbl,
				(char *) data, 0);
		mg->mg_flags |= (MGf_COPY|MGf_DUP);
	    }
	    break;

	default:
	    if (!(mg = mg_find(sv, PERL_MAGIC_shared_scalar)) ||
		mg->mg_virtual != &sharedsv_scalar_vtbl) {
		if (mg)
		    sv_unmagic(sv, PERL_MAGIC_shared_scalar);
		mg = sv_magicext(sv, Nullsv, PERL_MAGIC_shared_scalar,
				&sharedsv_scalar_vtbl, (char *)data, 0);
		mg->mg_flags |= (MGf_COPY|MGf_DUP);
	    }
	    break;
	}
    }
    SHARED_UNLOCK;
    return data;
}

void
Perl_sharedsv_free(pTHX_ shared_sv *shared)
{
    if (shared) {
	dTHXc;
	SHARED_EDIT;
	SvREFCNT_dec(SHAREDSvPTR(shared));
	SHARED_RELEASE;
    }
}

void
Perl_sharedsv_share(pTHX_ SV *sv)
{
    switch(SvTYPE(sv)) {
    case SVt_PVGV:
	Perl_croak(aTHX_ "Cannot share globs yet");
	break;

    case SVt_PVCV:
	Perl_croak(aTHX_ "Cannot share subs yet");
	break;
	
    default:
	Perl_sharedsv_associate(aTHX_ &sv, 0, 0);
    }
}

/* MAGIC (in mg.h sense) hooks */

int
sharedsv_scalar_mg_get(pTHX_ SV *sv, MAGIC *mg)
{
    shared_sv *shared = (shared_sv *) mg->mg_ptr;

    SHARED_LOCK;
    SvOK_off(sv);
    if (SHAREDSvPTR(shared)) {
	if (SvROK(SHAREDSvPTR(shared))) {
	    SV *rv = newRV(Nullsv);
	    Perl_sharedsv_associate(aTHX_ &SvRV(rv), SvRV(SHAREDSvPTR(shared)), NULL);
	    sv_setsv(sv, rv);
	}
	else {
	    sv_setsv(sv, SHAREDSvPTR(shared));
	}
    }
    SHARED_UNLOCK;
    return 0;
}

int
sharedsv_scalar_mg_set(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = Perl_sharedsv_associate(aTHX_ &sv, Nullsv,
    			(shared_sv *) mg->mg_ptr);
    bool allowed = TRUE;

    SHARED_EDIT;
    if (SvROK(sv)) {
	shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(sv));
	if (target) {
	    SV *tmp = newRV(SHAREDSvPTR(target));
	    sv_setsv(SHAREDSvPTR(shared), tmp);
	    SvREFCNT_dec(tmp);
	}
	else {
	    allowed = FALSE;
	}
    }
    else {
	sv_setsv(SHAREDSvPTR(shared), sv);
    }
    SHARED_RELEASE;

    if (!allowed) {
	Perl_croak(aTHX_ "Invalid value for shared scalar");
    }
    return 0;
}

int
sharedsv_scalar_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    Perl_sharedsv_free(aTHX_ (shared_sv *) mg->mg_ptr);
    return 0;
}

/*
 * Called during cloning of new threads
 */
int
sharedsv_scalar_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    if (shared) {
	SvREFCNT_inc(SHAREDSvPTR(shared));
    }
    return 0;
}

MGVTBL sharedsv_scalar_vtbl = {
 sharedsv_scalar_mg_get,	/* get */
 sharedsv_scalar_mg_set,	/* set */
 0,				/* len */
 0,				/* clear */
 sharedsv_scalar_mg_free,	/* free */
 0,				/* copy */
 sharedsv_scalar_mg_dup		/* dup */
};

/* Now the arrays/hashes stuff */

int
sharedsv_elem_mg_FETCH(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = Perl_sharedsv_find(aTHX_ mg->mg_obj);
    shared_sv *target = Perl_sharedsv_find(aTHX_ sv);
    SV** svp;

    SHARED_EDIT;
    if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	    svp = av_fetch((AV*) SHAREDSvPTR(shared), mg->mg_len, 0);
    }
    else {
	svp = hv_fetch((HV*) SHAREDSvPTR(shared), mg->mg_ptr, mg->mg_len, 0);
    }

    if (svp) {
	if (SHAREDSvPTR(target) != *svp) {
	    if (SHAREDSvPTR(target)) {
		SvREFCNT_dec(SHAREDSvPTR(target));
	    }
	    SHAREDSvPTR(target) = SvREFCNT_inc(*svp);
	}
    }
    else {
	if (SHAREDSvPTR(target)) {
	    SvREFCNT_dec(SHAREDSvPTR(target));
	}
	SHAREDSvPTR(target) = Nullsv;
    }
    SHARED_RELEASE;
    return 0;
}

int
sharedsv_elem_mg_STORE(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = Perl_sharedsv_find(aTHX_ mg->mg_obj);
    shared_sv *target = Perl_sharedsv_associate(aTHX_ &sv, Nullsv, 0);
    /* Theory - SV itself is magically shared - and we have ordered the
       magic such that by the time we get here it has been stored
       to its shared counterpart
     */
    SHARED_EDIT;
    if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	av_store((AV*) SHAREDSvPTR(shared), mg->mg_len, SHAREDSvPTR(target));
    }
    else {
	hv_store((HV*) SHAREDSvPTR(shared), mg->mg_ptr, mg->mg_len,
	               SHAREDSvPTR(target), 0);
    }
    SHARED_RELEASE;
    return 0;
}

int
sharedsv_elem_mg_DELETE(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = Perl_sharedsv_find(aTHX_ mg->mg_obj);
    SV* ssv;
    SHARED_EDIT;
    if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	ssv = av_delete((AV*) SHAREDSvPTR(shared), mg->mg_len, 0);
    }
    else {
	ssv = hv_delete((HV*) SHAREDSvPTR(shared), mg->mg_ptr, mg->mg_len, 0);
    }
    SHARED_RELEASE;
    /* It is no longer in the array - so remove that magic */
    sv_unmagic(sv, PERL_MAGIC_tiedelem);
    Perl_sharedsv_associate(aTHX_ &sv, ssv, 0);
    return 0;
}


int
sharedsv_elem_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    Perl_sharedsv_free(aTHX_ Perl_sharedsv_find(aTHX_ mg->mg_obj));
    return 0;
}

int
sharedsv_elem_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    shared_sv *shared = Perl_sharedsv_find(aTHX_ mg->mg_obj);
    SvREFCNT_inc(SHAREDSvPTR(shared));
    mg->mg_flags |= MGf_DUP;
    return 0;
}

MGVTBL sharedsv_elem_vtbl = {
 sharedsv_elem_mg_FETCH,	/* get */
 sharedsv_elem_mg_STORE,	/* set */
 0,				/* len */
 sharedsv_elem_mg_DELETE,	/* clear */
 sharedsv_elem_mg_free,		/* free */
 0,				/* copy */
 sharedsv_elem_mg_dup		/* dup */
};

U32
sharedsv_array_mg_FETCHSIZE(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    U32 val;
    SHARED_EDIT;
    if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	val = av_len((AV*) SHAREDSvPTR(shared));
    }
    else {
	/* not actually defined by tie API but ... */
	val = HvKEYS((HV*) SHAREDSvPTR(shared));
    }
    SHARED_RELEASE;
    return val;
}

int
sharedsv_array_mg_CLEAR(pTHX_ SV *sv, MAGIC *mg)
{
    dTHXc;
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    SHARED_EDIT;
    if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	av_clear((AV*) SHAREDSvPTR(shared));
    }
    else {
	hv_clear((HV*) SHAREDSvPTR(shared));
    }
    SHARED_RELEASE;
    return 0;
}

int
sharedsv_array_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    Perl_sharedsv_free(aTHX_ (shared_sv *) mg->mg_ptr);
    return 0;
}

/*
 * This is called when perl is about to access an element of
 * the array -
 */
int
sharedsv_array_mg_copy(pTHX_ SV *sv, MAGIC* mg,
		       SV *nsv, const char *name, int namlen)
{
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    MAGIC *nmg = sv_magicext(nsv,mg->mg_obj,
			    toLOWER(mg->mg_type),&sharedsv_elem_vtbl,
			    name, namlen);
    nmg->mg_flags |= MGf_DUP;
#if 0
    /* Maybe do this to associate shared value immediately ? */
    sharedsv_elem_FIND(aTHX_ nsv, nmg);
#endif
    return 1;
}

int
sharedsv_array_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    shared_sv *shared = (shared_sv *) mg->mg_ptr;
    SvREFCNT_inc(SHAREDSvPTR(shared));
    mg->mg_flags |= MGf_DUP;
    return 0;
}

MGVTBL sharedsv_array_vtbl = {
 0,				/* get */
 0,				/* set */
 sharedsv_array_mg_FETCHSIZE,	/* len */
 sharedsv_array_mg_CLEAR,	/* clear */
 sharedsv_array_mg_free,	/* free */
 sharedsv_array_mg_copy,	/* copy */
 sharedsv_array_mg_dup		/* dup */
};

=for apidoc sharedsv_unlock

Recursively unlocks a shared sv.

=cut

void
Perl_sharedsv_unlock(pTHX_ shared_sv* ssv)
{
    MUTEX_LOCK(&ssv->mutex);
    if (ssv->owner != aTHX) {
	Perl_croak(aTHX_ "panic: Perl_sharedsv_unlock unlocking mutex that we don't own");
	MUTEX_UNLOCK(&ssv->mutex);
	return;
    }

    if (--ssv->locks == 0) {
	ssv->owner = NULL;
	COND_SIGNAL(&ssv->cond);
    }
    MUTEX_UNLOCK(&ssv->mutex);
 }

void
Perl_sharedsv_unlock_scope(pTHX_ shared_sv* ssv)
{
    MUTEX_LOCK(&ssv->mutex);
    if (ssv->owner != aTHX) {
	MUTEX_UNLOCK(&ssv->mutex);
	return;
    }
    ssv->locks = 0;
    ssv->owner = NULL;
    COND_SIGNAL(&ssv->cond);
    MUTEX_UNLOCK(&ssv->mutex);
}

=for apidoc sharedsv_lock

Recursive locks on a sharedsv.
Locks are dynamically scoped at the level of the first lock.

=cut

void
Perl_sharedsv_lock(pTHX_ shared_sv* ssv)
{
    if (!ssv)
	return;
    MUTEX_LOCK(&ssv->mutex);
    if (ssv->owner && ssv->owner == aTHX) {
	ssv->locks++;
	MUTEX_UNLOCK(&ssv->mutex);
	return;
    }
    while (ssv->owner)
      COND_WAIT(&ssv->cond,&ssv->mutex);
    ssv->locks++;
    ssv->owner = aTHX;
    if (ssv->locks == 1)
	SAVEDESTRUCTOR_X(Perl_sharedsv_unlock_scope,ssv);
    MUTEX_UNLOCK(&ssv->mutex);
}

void
Perl_sharedsv_locksv(pTHX_ SV *sv)
{
    Perl_sharedsv_lock(aTHX_ Perl_sharedsv_find(aTHX_ sv));
}

=head1 Shared SV Functions

=for apidoc sharedsv_init

Saves a space for keeping SVs wider than an interpreter,
currently only stores a pointer to the first interpreter.

=cut

void
Perl_sharedsv_init(pTHX)
{
  dTHXc;
  /* This pair leaves us in shared context ... */
  PL_sharedsv_space = perl_alloc();
  perl_construct(PL_sharedsv_space);
  CALLER_CONTEXT;
  MUTEX_INIT(&PL_sharedsv_space_mutex);
  PL_lockhook = &Perl_sharedsv_locksv;
  PL_sharehook = &Perl_sharedsv_share;
}

/* Accessor to convert threads::shared::tie objects back shared_sv * */
shared_sv *
SV_to_sharedsv(pTHX_ SV *sv)
{
    shared_sv *shared = 0;
    if (SvROK(sv))
     {
      shared = INT2PTR(shared_sv *, SvIV(SvRV(sv)));
     }
    return shared;
}

MODULE = threads::shared	PACKAGE = threads::shared::tie

PROTOTYPES: DISABLE

void
PUSH(shared_sv *shared, ...)
CODE:
	dTHXc;
	int i;
	SHARED_LOCK;
	for(i = 1; i < items; i++) {
	    SV* tmp = newSVsv(ST(i));
	    shared_sv *target = Perl_sharedsv_associate(aTHX_ &tmp, Nullsv, 0);
	    SHARED_CONTEXT;
	    av_push((AV*) SHAREDSvPTR(shared), SHAREDSvPTR(target));
	    CALLER_CONTEXT;
	    SvREFCNT_dec(tmp);
	}
	SHARED_UNLOCK;

void
UNSHIFT(shared_sv *shared, ...)
CODE:
	dTHXc;
	int i;
	SHARED_LOCK;
	SHARED_CONTEXT;
	av_unshift((AV*)SHAREDSvPTR(shared), items - 1);
	CALLER_CONTEXT;
	for(i = 1; i < items; i++) {
	    SV* tmp = newSVsv(ST(i));
	    shared_sv *target = Perl_sharedsv_associate(aTHX_ &tmp, Nullsv, 0);
	    SHARED_CONTEXT;
	    av_store((AV*) SHAREDSvPTR(shared), i - 1, SHAREDSvPTR(target));
	    CALLER_CONTEXT;
	    SvREFCNT_dec(tmp);
	}
	SHARED_UNLOCK;

void
POP(shared_sv *shared)
CODE:
	dTHXc;
	SV* sv;
	SHARED_LOCK;
	SHARED_CONTEXT;
	sv = av_pop((AV*)SHAREDSvPTR(shared));
	CALLER_CONTEXT;
	ST(0) = Nullsv;
	Perl_sharedsv_associate(aTHX_ &ST(0), sv, 0);
	SHARED_UNLOCK;
	XSRETURN(1);

void
SHIFT(shared_sv *shared)
CODE:
	dTHXc;
	SV* sv;
	SHARED_LOCK;
	SHARED_CONTEXT;
	sv = av_shift((AV*)SHAREDSvPTR(shared));
	CALLER_CONTEXT;
	ST(0) = Nullsv;
	Perl_sharedsv_associate(aTHX_ &ST(0), sv, 0);
	SHARED_UNLOCK;
	XSRETURN(1);

void
EXTEND(shared_sv *shared, IV count)
CODE:
	dTHXc;
	SHARED_EDIT;
	av_extend((AV*)SHAREDSvPTR(shared), count);
	SHARED_RELEASE;

void
EXISTS(shared_sv *shared, SV *index)
CODE:
	dTHXc;
	bool exists;
	SHARED_EDIT;
	if (SvTYPE(SHAREDSvPTR(shared)) == SVt_PVAV) {
	    exists = av_exists((AV*) SHAREDSvPTR(shared), SvIV(index));
	}
	else {
	    exists = hv_exists_ent((HV*) SHAREDSvPTR(shared), index, 0);
	}
	SHARED_RELEASE;
	ST(0) = (exists) ? &PL_sv_yes : &PL_sv_no;
	XSRETURN(1);

void
STORESIZE(shared_sv *shared,IV count)
CODE:
	dTHXc;
	SHARED_EDIT;
	av_fill((AV*) SHAREDSvPTR(shared), count);
	SHARED_RELEASE;

void
FIRSTKEY(shared_sv *shared)
CODE:
	dTHXc;
	char* key = NULL;
	I32 len = 0;
	HE* entry;
	SHARED_LOCK;
	SHARED_CONTEXT;
	hv_iterinit((HV*) SHAREDSvPTR(shared));
	entry = hv_iternext((HV*) SHAREDSvPTR(shared));
	if (entry) {
		key = hv_iterkey(entry,&len);
		CALLER_CONTEXT;
		ST(0) = sv_2mortal(newSVpv(key, len));
	} else {
	     CALLER_CONTEXT;
	     ST(0) = &PL_sv_undef;
	}
	SHARED_UNLOCK;
	XSRETURN(1);

void
NEXTKEY(shared_sv *shared, SV *oldkey)
CODE:
	dTHXc;
	char* key = NULL;
	I32 len = 0;
	HE* entry;
	SHARED_LOCK;
	SHARED_CONTEXT;
	entry = hv_iternext((HV*) SHAREDSvPTR(shared));
	if(entry) {
		key = hv_iterkey(entry,&len);
		CALLER_CONTEXT;
		ST(0) = sv_2mortal(newSVpv(key, len));
	} else {
	     CALLER_CONTEXT;
	     ST(0) = &PL_sv_undef;
	}
	SHARED_UNLOCK;
	XSRETURN(1);

MODULE = threads::shared                PACKAGE = threads::shared

PROTOTYPES: ENABLE

void
lock_enabled(SV *ref)
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX, ref);
	if(!shared)
	   croak("lock can only be used on shared values");
	Perl_sharedsv_lock(aTHX_ shared);

void
cond_wait_enabled(SV *ref)
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	int locks;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_wait can only be used on shared values");
	if(shared->owner != aTHX)
	    croak("You need a lock before you can cond_wait");
	MUTEX_LOCK(&shared->mutex);
	shared->owner = NULL;
	locks = shared->locks = 0;
	COND_WAIT(&shared->user_cond, &shared->mutex);
	shared->owner = aTHX;
	shared->locks = locks;
	MUTEX_UNLOCK(&shared->mutex);

void
cond_signal_enabled(SV *ref)
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_signal can only be used on shared values");
	COND_SIGNAL(&shared->user_cond);

void
cond_broadcast_enabled(SV *ref)
	PROTOTYPE: \[$@%]
	CODE:
	shared_sv* shared;
	if(SvROK(ref))
	    ref = SvRV(ref);
	shared = Perl_sharedsv_find(aTHX_ ref);
	if(!shared)
	    croak("cond_broadcast can only be used on shared values");
	COND_BROADCAST(&shared->user_cond);

BOOT:
{
     Perl_sharedsv_init(aTHX);
}
