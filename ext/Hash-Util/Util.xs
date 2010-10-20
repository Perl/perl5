#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Hash::Util		PACKAGE = Hash::Util


void
all_keys(hash,keys,placeholder)
	HV *hash
	AV *keys
	AV *placeholder
    PROTOTYPE: \%\@\@
    PREINIT:
        SV *key;
        HE *he;
    PPCODE:
        av_clear(keys);
        av_clear(placeholder);

        (void)hv_iterinit(hash);
	while((he = hv_iternext_flags(hash, HV_ITERNEXT_WANTPLACEHOLDERS))!= NULL) {
	    key=hv_iterkeysv(he);
            if (HeVAL(he) == &PL_sv_placeholder) {
                SvREFCNT_inc(key);
	        av_push(placeholder, key);
            } else {
                SvREFCNT_inc(key);
	        av_push(keys, key);
            }
        }
	XSRETURN(1);

void
hidden_ref_keys(hash)
	HV *hash
    PREINIT:
        SV *key;
        HE *he;
    PPCODE:
        (void)hv_iterinit(hash);
	while((he = hv_iternext_flags(hash, HV_ITERNEXT_WANTPLACEHOLDERS))!= NULL) {
	    key=hv_iterkeysv(he);
            if (HeVAL(he) == &PL_sv_placeholder) {
                XPUSHs( key );
            }
        }

void
legal_ref_keys(hash)
	HV *hash
    PREINIT:
        SV *key;
        HE *he;
    PPCODE:
        (void)hv_iterinit(hash);
	while((he = hv_iternext_flags(hash, HV_ITERNEXT_WANTPLACEHOLDERS))!= NULL) {
	    key=hv_iterkeysv(he);
            XPUSHs( key );
        }

void
hv_store(hash, key, val)
	HV *hash
	SV* key
	SV* val
    PROTOTYPE: \%$$
    CODE:
    {
        SvREFCNT_inc(val);
	if (!hv_store_ent(hash, key, val, 0)) {
	    SvREFCNT_dec(val);
	    XSRETURN_NO;
	} else {
	    XSRETURN_YES;
	}
    }
