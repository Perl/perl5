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

#include "EXTERN.h"
#define PERL_IN_SHAREDSV_C
#include "perl.h"

#ifdef USE_ITHREADS



/*
  Shared SV

  Shared SV is a structure for keeping the backend storage
  of shared svs.

 */

/*
=for apidoc sharedsv_init

Saves a space for keeping SVs wider than an interpreter,
currently only stores a pointer to the first interpreter.

=cut
*/

void
Perl_sharedsv_init(pTHX)
{
    PL_sharedsv_space = PERL_GET_CONTEXT;
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
    return ssv;
}

/*
=for apidoc sharedsv_lock

Recursive locks on a sharedsv.
Locks are dynamicly scoped at the level of the first lock.
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
  SHAREDSvEDIT(ssv);
  SvREFCNT_inc(ssv->sv);
  SHAREDSvRELEASE(ssv);
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
    SHAREDSvEDIT(ssv);
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
                Perl_sharedsv_thrcnt_dec(aTHX_ INT2PTR(shared_sv *, SvIV(*src_ary++)));
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
    SvREFCNT_dec(sv);
    SHAREDSvRELEASE(ssv);
}

#endif /* USE_ITHREADS */

