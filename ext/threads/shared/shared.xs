
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
    if(SvROK(sv)) {
        shared_sv* target = Perl_sharedsv_find(aTHX_ SvRV(sv));
        if(!target) {
            sv_setsv(sv,SHAREDSvGET(shared));
            SHAREDSvUNLOCK(shared);            
            Perl_croak(aTHX_ "You cannot assign a non shared reference to a shared scalar");
        }
        SHAREDSvEDIT(shared);
        Perl_sv_free(PL_sharedsv_space,SHAREDSvGET(shared));
        SHAREDSvGET(shared) = newRV_noinc(newSViv((IV)target));
    } else {
            SHAREDSvEDIT(shared);
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


MODULE = threads::shared		PACKAGE = threads::shared::av

SV* 
new(class, value)
	SV* class
	SV* value
	CODE:
	shared_sv* shared = Perl_sharedsv_new(aTHX);
	SV* obj = newSViv((IV)shared);
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
        shared_sv* slot;
        SV* aentry;
	SV** aentry_;
	SHAREDSvLOCK(shared);
	aentry_ = av_fetch((AV*) SHAREDSvGET(shared), SvIV(index), 0);
	if(aentry_ && SvIV((*aentry_))) {
	    aentry = (*aentry_);
            slot = (shared_sv*) SvIV(aentry);
            if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_dec(aTHX_ (shared_sv*) SvIV(SvRV(SHAREDSvGET(slot))));
            SHAREDSvEDIT(slot);
            sv_setsv(SHAREDSvGET(slot), value);
            SHAREDSvRELEASE(slot);
	} else {
            slot = Perl_sharedsv_new(aTHX);
            SHAREDSvEDIT(shared);
            SHAREDSvGET(slot) = newSVsv(value);
            aentry = newSViv((IV)slot);
            av_store((AV*) SHAREDSvGET(shared), SvIV(index), aentry);
            SHAREDSvRELEASE(shared);
	}
        SHAREDSvUNLOCK(shared);

SV*
FETCH(self, index)
        SV* self
	SV* index
	CODE:
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
	        slot = (shared_sv*) SvIV(aentry);
                retval = newSVsv(SHAREDSvGET(slot));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
        int i;
        SHAREDSvLOCK(shared);
	for(i = 1; i < items; i++) {
    	    shared_sv* slot = Perl_sharedsv_new(aTHX);
	    SV* tmp = ST(i);
            SHAREDSvEDIT(slot);
	    SHAREDSvGET(slot) = newSVsv(tmp);
	    av_push((AV*) SHAREDSvGET(shared), newSViv((IV)slot));	    
	    SHAREDSvRELEASE(slot);
	}
        SHAREDSvUNLOCK(shared);

void
UNSHIFT(self, ...)
	SV* self
	CODE:
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
        int i;
        SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	av_unshift((AV*)SHAREDSvGET(shared), items - 1);
	SHAREDSvRELEASE(shared);
	for(i = 1; i < items; i++) {
    	    shared_sv* slot = Perl_sharedsv_new(aTHX);
	    SV* tmp = ST(i);
            SHAREDSvEDIT(slot);
	    SHAREDSvGET(slot) = newSVsv(tmp);
	    av_store((AV*) SHAREDSvGET(shared), i - 1, newSViv((IV)slot));
	    SHAREDSvRELEASE(slot);
	}
        SHAREDSvUNLOCK(shared);

SV*
POP(self)
	SV* self
	CODE:
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	shared_sv* slot;
	SV* retval;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	retval = av_pop((AV*)SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	if(retval && SvIV(retval)) {
	    slot = (shared_sv*) SvIV(retval);
	    retval = newSVsv(SHAREDSvGET(slot));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	shared_sv* slot;
	SV* retval;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	retval = av_shift((AV*)SHAREDSvGET(shared));
	SHAREDSvRELEASE(shared);
	if(retval && SvIV(retval)) {
	    slot = (shared_sv*) SvIV(retval);
	    retval = newSVsv(SHAREDSvGET(slot));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	shared_sv* slot;
	SV** svp;
	I32 i;
	SHAREDSvLOCK(shared);
	svp = AvARRAY((AV*)SHAREDSvGET(shared));
	i   = AvFILLp((AV*)SHAREDSvGET(shared));
	while ( i >= 0) {
	    if(SvIV(svp[i])) {
	        Perl_sharedsv_thrcnt_dec(aTHX_ (shared_sv*) SvIV(svp[i]));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	SHAREDSvEDIT(shared);
	av_extend((AV*)SHAREDSvGET(shared), (I32) SvIV(count));
	SHAREDSvRELEASE(shared);




SV*
EXISTS(self, index)
	SV* self
	SV* index
	CODE:
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	SHAREDSvEDIT(shared);
	av_fill((AV*) SHAREDSvGET(shared), (I32) SvIV(count));
	SHAREDSvRELEASE(shared);

SV*
FETCHSIZE(self)
	SV* self
	CODE:
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	shared_sv* slot;
	SHAREDSvLOCK(shared);
	if(av_exists((AV*) SHAREDSvGET(shared), (I32) SvIV(index))) {
	    SV* tmp;
	    SHAREDSvEDIT(shared);
	    tmp = av_delete((AV*)SHAREDSvGET(shared), (I32) SvIV(index),0);
	    SHAREDSvRELEASE(shared);
	    if(SvIV(tmp)) {
		slot = (shared_sv*) SvIV(tmp);
		RETVAL = newSVsv(SHAREDSvGET(slot));
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
	SV* obj = newSViv((IV)shared);
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
        shared_sv* slot;
        SV* hentry;
        SV** hentry_;
	STRLEN len;
	char* ckey = SvPV(key, len);
        SHAREDSvLOCK(shared);
        hentry_ = hv_fetch((HV*) SHAREDSvGET(shared), ckey, len, 0);
        if(hentry_ && SvIV((*hentry_))) {
            hentry = (*hentry_);
            slot = (shared_sv*) SvIV(hentry);
            if(SvROK(SHAREDSvGET(slot)))
                Perl_sharedsv_thrcnt_dec(aTHX_ (shared_sv*) SvIV(SvRV(SHAREDSvGET(slot))));
            SHAREDSvEDIT(slot);
            sv_setsv(SHAREDSvGET(slot), value);
            SHAREDSvRELEASE(slot);
        } else {
            slot = Perl_sharedsv_new(aTHX);
            SHAREDSvEDIT(shared);
            SHAREDSvGET(slot) = newSVsv(value);
            hentry = newSViv((IV)slot);
            hv_store((HV*) SHAREDSvGET(shared), ckey,len , hentry, 0);
            SHAREDSvRELEASE(shared);
        }
        SHAREDSvUNLOCK(shared);


SV*
FETCH(self, key)
        SV* self
        SV* key
        CODE:
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
                slot = (shared_sv*) SvIV(hentry);
                retval = newSVsv(SHAREDSvGET(slot));
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
        shared_sv* slot;
	HE* entry;
	SHAREDSvLOCK(shared);
	Perl_hv_iterinit(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
	entry = Perl_hv_iternext(PL_sharedsv_space, (HV*) SHAREDSvGET(shared));
	while(entry) {
		slot = (shared_sv*) SvIV(Perl_hv_iterval(PL_sharedsv_space, (HV*) SHAREDSvGET(shared), entry));
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
	shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
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
        shared_sv* shared = (shared_sv*) SvIV(SvRV(self));
	shared_sv* slot;
        STRLEN len;
        char* ckey = SvPV(key, len);
        SV* tmp;
	SHAREDSvLOCK(shared);
	SHAREDSvEDIT(shared);
	tmp = hv_delete((HV*) SHAREDSvGET(shared), ckey, len,0);
	SHAREDSvRELEASE(shared);
	if(tmp) {
		slot = SvIV(tmp);	
		RETVAL = newSVsv(SHAREDSvGET(slot));
		Perl_sharedsv_thrcnt_dec(aTHX_ slot);
	} else {
		RETVAL = &PL_sv_undef;
	}
        SHAREDSvUNLOCK(shared);
        OUTPUT:
        RETVAL
