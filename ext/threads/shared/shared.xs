
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


void shared_sv_attach_sv (SV* sv, shared_sv* shared) {
    HV* shared_hv = get_hv("threads::shared::shared", FALSE);
    SV* id = newSViv((IV)shared);
    STRLEN length = sv_len(id);
    SV* tiedobject;
    SV** tiedobject_ = hv_fetch(shared_hv, SvPV(id,length), length, 0);
    if(tiedobject_) {
    	tiedobject = (*tiedobject_);
        SvROK_on(sv);
        SvRV(sv) = SvRV(tiedobject);

    } else {
        croak("die\n");
    }
}


int shared_sv_fetch_mg (pTHX_ SV* sv, MAGIC *mg) {
    shared_sv* shared = (shared_sv*) SvIV(mg->mg_obj);
    SHAREDSvLOCK(shared);
    if(mg->mg_private != shared->index) {
        if(SvROK(SHAREDSvGET(shared))) {
            shared_sv* target = (shared_sv*) SvIV(SvRV(SHAREDSvGET(shared)));
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
    shared_sv* shared = (shared_sv*) SvIV(mg->mg_obj);
    SHAREDSvLOCK(shared);
    if(SvROK(SHAREDSvGET(shared)))
        Perl_sharedsv_thrcnt_dec(aTHX_ (shared_sv*) SvIV(SvRV(SHAREDSvGET(shared))));
    SHAREDSvEDIT(shared);
    if(SvROK(sv)) {
        shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(sv));
        if(!target) {
            SHAREDSvRELEASE(shared);
            sv_setsv(sv,SHAREDSvGET(shared));
            SHAREDSvUNLOCK(shared);            
            Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared scalar");
        }
        Perl_sv_free(PL_sharedsv_space,SHAREDSvGET(shared));
        SHAREDSvGET(shared) = newRV_noinc(newSViv((IV)target));
    } else {
        sv_setsv(SHAREDSvGET(shared), sv);
    }
    shared->index++;
    mg->mg_private = shared->index;
    SHAREDSvRELEASE(shared);
    if(SvROK(SHAREDSvGET(shared)))
       Perl_sharedsv_thrcnt_inc(aTHX_ (shared_sv*) SvIV(SvRV(SHAREDSvGET(shared))));       
    SHAREDSvUNLOCK(shared);
    return 0;
}

int shared_sv_destroy_mg (pTHX_ SV* sv, MAGIC *mg) {
    shared_sv* shared = (shared_sv*) SvIV(mg->mg_obj);
    if(!shared) 
        return 0;
    Perl_sharedsv_thrcnt_dec(aTHX_ shared);
}

MGVTBL svtable = {MEMBER_TO_FPTR(shared_sv_fetch_mg),
		  MEMBER_TO_FPTR(shared_sv_store_mg),
		  0,
		  0,
		  MEMBER_TO_FPTR(shared_sv_destroy_mg)
};

MODULE = threads::shared		PACKAGE = threads::shared		


PROTOTYPES: DISABLE


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
        shared_sv* shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("thrcnt can only be used on shared values");
	SHAREDSvLOCK(shared);
        RETVAL = newSViv(SvREFCNT(SHAREDSvGET(shared)));
        SHAREDSvUNLOCK(shared);
	OUTPUT:
        RETVAL   


void
thrcnt_inc(ref)
        SV* ref
        CODE:
	shared_sv* shared;
        if(SvROK(ref)) 
            ref = SvRV(ref);
        shared = Perl_sharedsv_find(aTHX, ref);
        if(!shared)
           croak("thrcnt can only be used on shared values");
	Perl_sharedsv_thrcnt_inc(aTHX_ shared);


MODULE = threads::shared		PACKAGE = threads::shared::sv		

SV*
new(class, value)
	SV* class
	SV* value
	CODE:
	shared_sv* shared = Perl_sharedsv_new(aTHX);
        MAGIC* shared_magic;
	SV* obj = newSViv((IV)shared);
	SHAREDSvEDIT(shared);
	SHAREDSvGET(shared) = newSVsv(value);
        SHAREDSvRELEASE(shared);
	sv_magic(value, 0, PERL_MAGIC_ext, "threads::shared", 16);
        shared_magic = mg_find(value, PERL_MAGIC_ext);
        shared_magic->mg_virtual = &svtable;
        shared_magic->mg_obj = newSViv((IV)shared);
        shared_magic->mg_flags |= MGf_REFCOUNTED;
        shared_magic->mg_private = 0;
        SvMAGICAL_on(value);
        RETVAL = obj;
        OUTPUT:        	
        RETVAL


