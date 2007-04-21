#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* support for Hash::Util::FieldHash, prefix HUF_ */

/* A Perl sub that returns a hashref to the object registry */
#define HUF_OB_REG "Hash::Util::FieldHash::_ob_reg"
/* Magic cookies to recognize object id's.  Hi, Eva, David */
#define HUF_COOKIE 2805.1980
#define HUF_REFADDR_COOKIE 1811.1976

/* For global cache of object registry */
#define MY_CXT_KEY "Hash::Util::FieldHash::_guts" XS_VERSION
typedef struct {
    HV* ob_reg; /* Cache object registry */
} my_cxt_t;
START_MY_CXT

/* Inquire the object registry (a lexical hash) from perl */
HV* HUF_get_ob_reg(void) {
    dSP;
    HV* ob_reg = NULL;
    I32 items;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    items = call_pv(HUF_OB_REG, G_SCALAR|G_NOARGS);
    SPAGAIN;

    if (items == 1 && TOPs && SvROK(TOPs) && SvTYPE(SvRV(TOPs)) == SVt_PVHV)
        ob_reg = (HV*)SvRV(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (!ob_reg)
        Perl_die(aTHX_ "Can't get object registry hash");
    return ob_reg;
}

/* Deal with global context */
#define HUF_INIT 1
#define HUF_CLONE 0
#define HUF_RESET -1

void HUF_global(I32 how) {
    if (how == HUF_INIT) {
        MY_CXT_INIT;
        MY_CXT.ob_reg = HUF_get_ob_reg();
    } else if (how == HUF_CLONE) {
        MY_CXT_CLONE;
        MY_CXT.ob_reg = HUF_get_ob_reg();
    } else if (how == HUF_RESET) {
        dMY_CXT;
        MY_CXT.ob_reg = HUF_get_ob_reg();
    }
}

/* the id as an SV, optionally marked in the nv (unused feature) */
SV* HUF_id(SV* ref, NV cookie) {
    SV* id = sv_newmortal();
    if (cookie == 0 ) {
        SvUPGRADE(id, SVt_PVIV);
    } else {
        SvUPGRADE(id, SVt_PVNV);
        SvNV_set(id, cookie);
        SvNOK_on(id);
    }
    SvIV_set(id, PTR2UV(SvRV(ref)));
    SvIOK_on(id);
    return id;
}

/* plain id, only used for field hash entries in field lists */
SV* HUF_field_id(SV* obj) {
    return HUF_id(obj, 0.0);
}

/* object id (same as plain, may be different in future) */
SV* HUF_obj_id(SV* obj) {
    return HUF_id(obj, 0.0);
}

/* set up uvar magic for any sv */
void HUF_add_uvar_magic(
    SV* sv,                    /* the sv to enchant, visible to get/set */
    I32(* val)(pTHX_ IV, SV*), /* "get" function */
    I32(* set)(pTHX_ IV, SV*), /* "set" function */
    I32 index,                 /* get/set will see this */
    SV* thing                  /* any associated info */
) {
    struct ufuncs uf;
        uf.uf_val = val;
        uf.uf_set = set;
        uf.uf_index = index;
    sv_magic(sv, thing, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
}

/* Fetch the data container of a trigger */
AV* HUF_get_trigger_content(SV* trigger) {
    MAGIC* mg;
    if (trigger && (mg = mg_find(trigger, PERL_MAGIC_uvar)))
        return (AV*)mg->mg_obj;
    return NULL;
}

/* Delete an object from all field hashes it may occur in.  Also delete
 * the object's entry from the object registry.  This function goes in
 * the uf_set field of the uvar magic of a trigger.
 */
I32 HUF_destroy_obj(pTHX_ IV index, SV* trigger) {
    /* Do nothing if the weakref wasn't undef'd.  Also don't bother
     * during global destruction.  (MY_CXT.ob_reg is sometimes funny there) */
    if (!SvROK(trigger) && (!PL_in_clean_all)) {
        dMY_CXT;
        AV* cont = HUF_get_trigger_content(trigger);
        SV* ob_id = *av_fetch(cont, 0, 0);
        HV* field_tab = (HV*) *av_fetch(cont, 1, 0);
        HE* ent;
        hv_iterinit(field_tab);
        while (ent = hv_iternext(field_tab)) {
            SV* field_ref = HeVAL(ent);
            SV* field = SvRV(field_ref);
            hv_delete_ent((HV*)field, ob_id, G_DISCARD, 0);
        }
        /* make it safe in case we must run in global clenaup, after all */
        if (PL_in_clean_all)
            HUF_global(HUF_RESET);
        hv_delete_ent(MY_CXT.ob_reg, ob_id, G_DISCARD, 0);
    }
    return 0;
}

/* Create a trigger for an object.  The trigger is a magical weak ref
 * that fires when the weak ref expires.  it holds the original id of
 * the object, and a list of field hashes from which the object may
 * have to be deleted.  The trigger is stored in the object registry
 * and also deleted when the object expires.
 */
SV* HUF_new_trigger(SV* obj, SV* ob_id) {
    dMY_CXT;
    SV* trigger = sv_rvweaken(newRV_inc(SvRV(obj)));
    AV* cont = newAV();
    sv_2mortal((SV*)cont);
    av_store(cont, 0, SvREFCNT_inc(ob_id));
    av_store(cont, 1, (SV*)newHV());
    HUF_add_uvar_magic(trigger, NULL, &HUF_destroy_obj, 0, (SV*)cont);
    hv_store_ent(MY_CXT.ob_reg, ob_id, trigger, 0);
    return trigger;
}

/* retrieve a trigger for obj if one exists, return NULL otherwise */
SV* HUF_ask_trigger(SV* ob_id) {
    dMY_CXT;
    HE* ent;
    if (ent = hv_fetch_ent(MY_CXT.ob_reg, ob_id, 0, 0))
        return HeVAL(ent);
    return NULL;
}

/* get the trigger for an object, creating it if necessary */
SV* HUF_get_trigger(SV* obj, SV* ob_id) {
    SV* trigger;
    if (!(trigger = HUF_ask_trigger(ob_id)))
        trigger = HUF_new_trigger(obj, ob_id);
    return trigger;
}

/* mark an object (trigger) as having been used with a field */
void HUF_mark_field(SV* trigger, SV* field) {
    AV* cont = HUF_get_trigger_content(trigger);
    HV* field_tab = (HV*) *av_fetch(cont, 1, 0);
    SV* field_ref = newRV_inc(field);
    SV* field_id = HUF_field_id(field_ref);
    hv_store_ent(field_tab, field_id, field_ref, 0);
}

/* These constants are not in the API.  If they ever change in hv.c this code
 * must be updated */
#define HV_FETCH_ISSTORE   0x01
#define HV_FETCH_ISEXISTS  0x02
#define HV_FETCH_LVALUE    0x04
#define HV_FETCH_JUST_SV   0x08

#define HUF_WOULD_CREATE_KEY(x) ((x) != -1 && ((x) & (HV_FETCH_ISSTORE | HV_FETCH_LVALUE)))

/* The key exchange function.  It communicates with S_hv_magic_uvar_xkey
 * in hv.c */
I32 HUF_watch_key(pTHX_ IV action, SV* field) {
    MAGIC* mg = mg_find(field, PERL_MAGIC_uvar);
    SV* keysv;
    if (mg) {
        keysv = mg->mg_obj;
        if (keysv && !SvROK(keysv)) { /* is string an object-id? */
            SV* obj = HUF_ask_trigger(keysv);
            if (obj)
                keysv = obj; /* use the object instead, so registry happens */
        }
        if (keysv && SvROK(keysv)) {
            SV* ob_id = HUF_obj_id(keysv);
            mg->mg_obj = ob_id; /* key replacement */
            if (HUF_WOULD_CREATE_KEY(action)) {
                SV* trigger = HUF_get_trigger(keysv, ob_id);
                HUF_mark_field(trigger, field);
            }
        }
    } else {
        Perl_die(aTHX_ "Rogue call of 'HUF_watch_key'");
    }
    return 0;
}

/* see if something is a field hash */
int HUF_get_status(HV* hash) {
    int ans = 0;
    if (hash && (SvTYPE(hash) == SVt_PVHV)) {
        MAGIC* mg;
        struct ufuncs* uf;
        ans = (mg = mg_find((SV*)hash, PERL_MAGIC_uvar)) &&
            (uf = (struct ufuncs *)mg->mg_ptr) &&
            (uf->uf_val == &HUF_watch_key) &&
            (uf->uf_set == NULL);
    }
    return ans;
}

/* Thread support.  These routines are called by CLONE (and nothing else) */

/* Fix entries for one object in all field hashes */
void HUF_fix_trigger(SV* trigger, SV* new_id) {
    AV* cont = HUF_get_trigger_content(trigger);
    HV* field_tab = (HV*) *av_fetch(cont, 1, 0);
    HV* new_tab = newHV();
    HE* ent;
    SV* old_id = *av_fetch(cont, 0, 0);
    hv_iterinit(field_tab);
    while (ent = hv_iternext(field_tab)) {
        SV* field_ref = HeVAL(ent);
        SV* field_id = HUF_field_id(field_ref);
        HV* field = (HV*)SvRV(field_ref);
        SV* val;
        /* recreate field tab entry */
        hv_store_ent(new_tab, field_id, SvREFCNT_inc(field_ref), 0);
        /* recreate field entry, if any */
        if (val = hv_delete_ent(field, old_id, 0, 0))
            hv_store_ent(field, new_id, SvREFCNT_inc(val), 0);
    }
    /* update the trigger */
    av_store(cont, 0, SvREFCNT_inc(new_id));
    av_store(cont, 1, (SV*)new_tab);
}

/* Go over object registry and fix all objects.  Also fix the object
 * registry.
 */
void HUF_fix_objects(void) {
    dMY_CXT;
    I32 i, len;
    HE* ent;
    AV* oblist = (AV*)sv_2mortal((SV*)newAV());
    hv_iterinit(MY_CXT.ob_reg);
    while(ent = hv_iternext(MY_CXT.ob_reg))
        av_push(oblist, SvREFCNT_inc(hv_iterkeysv(ent)));
    len = av_len(oblist);
    for (i = 0; i <= len; ++i) {
        SV* old_id = *av_fetch(oblist, i, 0);
        SV* trigger = hv_delete_ent(MY_CXT.ob_reg, old_id, 0, 0);
        SV* new_id = HUF_obj_id(trigger);
        HUF_fix_trigger(trigger, new_id);
        hv_store_ent(MY_CXT.ob_reg, new_id, SvREFCNT_inc(trigger), 0);
    }
}

/* test support (not needed for functionality) */

static SV* counter;
I32 HUF_inc_var(pTHX_ IV index, SV* which) {
    sv_setiv(counter, 1 + SvIV(counter));
    return 0;
}

MODULE = Hash::Util::FieldHash          PACKAGE = Hash::Util::FieldHash

BOOT:
{
    HUF_global(HUF_INIT); /* create variables */
}

int
_fieldhash(SV* href, int mode)
PROTOTYPE: $$
CODE:
    HV* field;
    RETVAL = 0;
    if (mode &&
        href && SvROK(href) &&
        (field = (HV*)SvRV(href)) &&
        SvTYPE(field) == SVt_PVHV
    ) {
        HUF_add_uvar_magic(
            SvRV(href),
            &HUF_watch_key,
            NULL,
            0,
            NULL
        );
        RETVAL = HUF_get_status(field);
    }
OUTPUT:
    RETVAL

void
CLONE(char* classname)
CODE:
    if (0 == strcmp(classname, "Hash::Util::FieldHash")) {
        HUF_global(HUF_CLONE);
        HUF_fix_objects();
    }

void
_active_fields(SV* obj)
PPCODE:
    if (SvROK(obj)) {
        SV* ob_id = HUF_obj_id(obj);
        SV* trigger = HUF_ask_trigger(ob_id);
        if (trigger) {
            AV* cont = HUF_get_trigger_content(trigger);
            HV* field_tab = (HV*) *av_fetch(cont, 1, 0);
            HE* ent;
            hv_iterinit(field_tab);
            while (ent = hv_iternext(field_tab)) {
                HV* field = (HV*)SvRV(HeVAL(ent));
                if (hv_exists_ent(field, ob_id, 0))
                    XPUSHs(sv_2mortal(newRV_inc((SV*)field)));
            }
        }
    }

void
_test_uvar_get(SV* svref, SV* countref)
CODE:
    if (SvROK(svref) && SvROK(countref)) {
        counter = SvRV(countref);
        sv_setiv(counter, 0);
        HUF_add_uvar_magic(
            SvRV(svref),
            &HUF_inc_var,
            NULL,
            0,
            SvRV(countref)
        );
    }

void
_test_uvar_set(SV* svref, SV* countref)
CODE:
    if (SvROK(svref) && SvROK(countref)) {
        counter = SvRV(countref);
        sv_setiv(counter, 0);
        counter = SvRV(countref);
        HUF_add_uvar_magic(
            SvRV(svref),
            NULL,
            &HUF_inc_var,
            0,
            SvRV(countref)
        );
    }

void
_test_uvar_same(SV* svref, SV* countref)
CODE:
    if (SvROK(svref) && SvROK(countref)) {
        counter = SvRV(countref);
        sv_setiv(counter, 0);
        HUF_add_uvar_magic(
            SvRV(svref),
            &HUF_inc_var,
            &HUF_inc_var,
            0,
            NULL
        );
    }

