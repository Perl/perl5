/* $Id: Parser.xs,v 2.112 2001/05/10 19:18:07 gisle Exp $
 *
 * Copyright 1999-2001, Gisle Aas.
 * Copyright 1999-2000, Michael A. Chase.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */


/*
 * Standard XS greeting.
 */
#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif



/*
 * Some perl version compatibility gruff.
 */
#include "patchlevel.h"
#if PATCHLEVEL <= 4 /* perl5.004_XX */

#ifndef PL_sv_undef
   #define PL_sv_undef sv_undef
   #define PL_sv_yes   sv_yes
#endif

#ifndef PL_hexdigit
   #define PL_hexdigit hexdigit
#endif

#ifndef ERRSV
   #define ERRSV GvSV(errgv)
#endif

#if (PATCHLEVEL == 4 && SUBVERSION <= 4)
/* The newSVpvn function was introduced in perl5.004_05 */
static SV *
newSVpvn(char *s, STRLEN len)
{
    register SV *sv = newSV(0);
    sv_setpvn(sv,s,len);
    return sv;
}
#endif /* not perl5.004_05 */
#endif /* perl5.004_XX */

#ifndef dNOOP
   #define dNOOP extern int errno
#endif
#ifndef dTHX
   #define dTHX dNOOP
   #define pTHX_
   #define aTHX_
#endif

#ifndef MEMBER_TO_FPTR
   #define MEMBER_TO_FPTR(x) (x)
#endif

#ifndef INT2PTR
   #define INT2PTR(any,d)  (any)(d)
   #define PTR2IV(p)       (IV)(p)
#endif


#if PATCHLEVEL > 6 || (PATCHLEVEL == 6 && SUBVERSION > 0)
   #define RETHROW	   croak(Nullch)
#else
   #define RETHROW    { STRLEN my_na; croak("%s", SvPV(ERRSV, my_na)); }
#endif

/*
 * Include stuff.  We include .c files instead of linking them,
 * so that they don't have to pollute the external dll name space.
 */

#ifdef EXTERN
  #undef EXTERN
#endif

#define EXTERN static /* Don't pollute */

#include "hparser.h"
#include "util.c"
#include "hparser.c"


/*
 * Support functions for the XS glue
 */

static SV*
check_handler(SV* h)
{
    dTHX;
    if (SvROK(h)) {
	SV* myref = SvRV(h);
	if (SvTYPE(myref) == SVt_PVCV)
	    return newSVsv(h);
	if (SvTYPE(myref) == SVt_PVAV)
	    return SvREFCNT_inc(myref);
	croak("Only code or array references allowed as handler");
    }
    return SvOK(h) ? newSVsv(h) : 0;
}


static PSTATE*
get_pstate_iv(SV* sv)
{
    dTHX;
    PSTATE* p = INT2PTR(PSTATE*, SvIV(sv));
    if (p->signature != P_SIGNATURE)
	croak("Bad signature in parser state object at %p", p);
    return p;
}


static PSTATE*
get_pstate_hv(SV* sv)                               /* used by XS typemap */
{
    dTHX;
    HV* hv;
    SV** svp;

    sv = SvRV(sv);
    if (!sv || SvTYPE(sv) != SVt_PVHV)
	croak("Not a reference to a hash");
    hv = (HV*)sv;
    svp = hv_fetch(hv, "_hparser_xs_state", 17, 0);
    if (svp) {
	if (SvROK(*svp))
	    return get_pstate_iv(SvRV(*svp));
	else
	    croak("_hparser_xs_state element is not a reference");
    }
    croak("Can't find '_hparser_xs_state' element in HTML::Parser hash");
    return 0;
}


static void
free_pstate(PSTATE* pstate)
{
    dTHX;
    int i;
    SvREFCNT_dec(pstate->buf);
    SvREFCNT_dec(pstate->pend_text);
    SvREFCNT_dec(pstate->skipped_text);
#ifdef MARKED_SECTION
    SvREFCNT_dec(pstate->ms_stack);
#endif
    SvREFCNT_dec(pstate->bool_attr_val);
    for (i = 0; i < EVENT_COUNT; i++) {
	SvREFCNT_dec(pstate->handlers[i].cb);
	SvREFCNT_dec(pstate->handlers[i].argspec);
    }

    SvREFCNT_dec(pstate->report_tags);
    SvREFCNT_dec(pstate->ignore_tags);
    SvREFCNT_dec(pstate->ignore_elements);
    SvREFCNT_dec(pstate->ignoring_element);

    SvREFCNT_dec(pstate->tmp);

    pstate->signature = 0;
    Safefree(pstate);
}


static int
magic_free_pstate(pTHX_ SV *sv, MAGIC *mg)
{
    free_pstate(get_pstate_iv(sv));
    return 0;
}


MGVTBL vtbl_free_pstate = {0, 0, 0, 0, MEMBER_TO_FPTR(magic_free_pstate)};



/*
 *  XS interface definition.
 */

MODULE = HTML::Parser		PACKAGE = HTML::Parser

PROTOTYPES: DISABLE

void
_alloc_pstate(self)
	SV* self;
    PREINIT:
	PSTATE* pstate;
	SV* sv;
	HV* hv;
        MAGIC* mg;

    CODE:
	sv = SvRV(self);
        if (!sv || SvTYPE(sv) != SVt_PVHV)
            croak("Not a reference to a hash");
	hv = (HV*)sv;

	Newz(56, pstate, 1, PSTATE);
	pstate->signature = P_SIGNATURE;
	pstate->entity2char = perl_get_hv("HTML::Entities::entity2char", TRUE);
	pstate->tmp = NEWSV(0, 20);

	sv = newSViv(PTR2IV(pstate));
	sv_magic(sv, 0, '~', 0, 0);
	mg = mg_find(sv, '~');
        assert(mg);
        mg->mg_virtual = &vtbl_free_pstate;
	SvREADONLY_on(sv);

	hv_store(hv, "_hparser_xs_state", 17, newRV_noinc(sv), 0);

SV*
parse(self, chunk)
	SV* self;
	SV* chunk
    PREINIT:
	PSTATE* p_state = get_pstate_hv(self);
    CODE:
	if (p_state->parsing)
    	    croak("Parse loop not allowed");
        p_state->parsing = 1;
	if (SvROK(chunk) && SvTYPE(SvRV(chunk)) == SVt_PVCV) {
	    SV* generator = chunk;
	    STRLEN len;
	    do {
		dSP;
                int count;
		PUSHMARK(SP);
	        count = perl_call_sv(generator, G_SCALAR|G_EVAL);
		SPAGAIN;
		chunk = count ? POPs : 0;

	        if (SvTRUE(ERRSV)) {
		    p_state->parsing = 0;
		    p_state->eof = 0;
		    RETHROW;
                }

		if (chunk && SvOK(chunk)) {
		    (void)SvPV(chunk, len);  /* get length */
		}
		else {
		    len = 0;
                }
		parse(aTHX_ p_state, len ? chunk : 0, self);

            } while (len && !p_state->eof);
        }
	else {
	    parse(aTHX_ p_state, chunk, self);
        }
        p_state->parsing = 0;
	if (p_state->eof) {
	    p_state->eof = 0;
            ST(0) = sv_newmortal();
        }

SV*
eof(self)
	SV* self;
    PREINIT:
	PSTATE* p_state = get_pstate_hv(self);
    CODE:
        if (p_state->parsing)
            p_state->eof = 1;
        else {
	    p_state->parsing = 1;
	    parse(aTHX_ p_state, 0, self); /* flush */
	    p_state->parsing = 0;
	}

SV*
strict_comment(pstate,...)
	PSTATE* pstate
    ALIAS:
	HTML::Parser::strict_comment = 1
	HTML::Parser::strict_names = 2
        HTML::Parser::xml_mode = 3
	HTML::Parser::unbroken_text = 4
        HTML::Parser::marked_sections = 5
    PREINIT:
	bool *attr;
    CODE:
        switch (ix) {
	case  1: attr = &pstate->strict_comment;       break;
	case  2: attr = &pstate->strict_names;         break;
	case  3: attr = &pstate->xml_mode;             break;
	case  4: attr = &pstate->unbroken_text;        break;
        case  5:
#ifdef MARKED_SECTION
		 attr = &pstate->marked_sections;      break;
#else
	         croak("marked sections not supported"); break;
#endif
	default:
	    croak("Unknown boolean attribute (%d)", ix);
        }
	RETVAL = boolSV(*attr);
	if (items > 1)
	    *attr = SvTRUE(ST(1));
    OUTPUT:
	RETVAL

SV*
boolean_attribute_value(pstate,...)
        PSTATE* pstate
    CODE:
	RETVAL = pstate->bool_attr_val ? newSVsv(pstate->bool_attr_val)
				       : &PL_sv_undef;
	if (items > 1) {
	    SvREFCNT_dec(pstate->bool_attr_val);
	    pstate->bool_attr_val = newSVsv(ST(1));
        }
    OUTPUT:
	RETVAL

void
ignore_tags(pstate,...)
	PSTATE* pstate
    ALIAS:
	HTML::Parser::report_tags = 1
	HTML::Parser::ignore_tags = 2
	HTML::Parser::ignore_elements = 3
    PREINIT:
	HV** attr;
	int i;
    CODE:
	switch (ix) {
	case  1: attr = &pstate->report_tags;     break;
	case  2: attr = &pstate->ignore_tags;     break;
	case  3: attr = &pstate->ignore_elements; break;
	default:
	    croak("Unknown tag-list attribute (%d)", ix);
	}
	if (GIMME_V != G_VOID)
	    croak("Can't report tag lists yet");

	items--;  /* pstate */
	if (items) {
	    if (*attr)
		hv_clear(*attr);
	    else
		*attr = newHV();

	    for (i = 0; i < items; i++) {
		SV* sv = ST(i+1);
		if (SvROK(sv)) {
		    sv = SvRV(sv);
		    if (SvTYPE(sv) == SVt_PVAV) {
			AV* av = (AV*)sv;
			STRLEN j;
			STRLEN len = av_len(av) + 1;
			for (j = 0; j < len; j++) {
			    SV**svp = av_fetch(av, j, 0);
			    if (svp) {
				hv_store_ent(*attr, *svp, newSViv(0), 0);
			    }
			}
		    }
		    else
			croak("Tag list must be plain scalars and arrays");
		}
		else {
		    hv_store_ent(*attr, sv, newSViv(0), 0);
		}
	    }
	}
	else if (*attr) {
	    SvREFCNT_dec(*attr);
            *attr = 0;
	}

SV*
handler(pstate, eventname,...)
	PSTATE* pstate
	SV* eventname
    PREINIT:
	SV* self = ST(0);
	STRLEN name_len;
	char *name = SvPV(eventname, name_len);
        int event = -1;
        int i;
        struct p_handler *h;
    CODE:
	/* map event name string to event_id */
	for (i = 0; i < EVENT_COUNT; i++) {
	    if (strEQ(name, event_id_str[i])) {
	        event = i;
	        break;
	    }
	}
        if (event < 0)
	    croak("No handler for %s events", name);

	h = &pstate->handlers[event];

	/* set up return value */
	if (h->cb) {
	    ST(0) = (SvTYPE(h->cb) == SVt_PVAV)
	                 ? sv_2mortal(newRV_inc(h->cb))
	                 : sv_2mortal(newSVsv(h->cb));
	}
        else {
	    ST(0) = &PL_sv_undef;
        }

        /* update */
        if (items > 3) {
	    SvREFCNT_dec(h->argspec);
	    h->argspec = 0;
	    h->argspec = argspec_compile(ST(3), pstate);
	}
        if (items > 2) {
	    SvREFCNT_dec(h->cb);
            h->cb = 0;
	    h->cb = check_handler(ST(2));
	}


MODULE = HTML::Parser		PACKAGE = HTML::Entities

void
decode_entities(...)
    PREINIT:
        int i;
	HV *entity2char = perl_get_hv("HTML::Entities::entity2char", FALSE);
    PPCODE:
	if (GIMME_V == G_SCALAR && items > 1)
            items = 1;
	for (i = 0; i < items; i++) {
	    if (GIMME_V != G_VOID)
	        ST(i) = sv_2mortal(newSVsv(ST(i)));
	    else if (SvREADONLY(ST(i)))
		croak("Can't inline decode readonly string");
	    decode_entities(aTHX_ ST(i), entity2char);
	}
	SP += items;

void
_decode_entities(string, entities)
    SV* string
    SV* entities
    PREINIT:
	HV* entities_hv;
    CODE:
        if (SvOK(entities)) {
	    if (SvROK(entities) && SvTYPE(SvRV(entities)) == SVt_PVHV) {
		entities_hv = (HV*)SvRV(entities);
	    }
            else {
		croak("2nd argument must be hash reference");
            }
        }
        else {
            entities_hv = 0;
        }
	if (SvREADONLY(string))
	    croak("Can't inline decode readonly string");
	decode_entities(aTHX_ string, entities_hv);

int
UNICODE_SUPPORT()
    PROTOTYPE:
    CODE:
#ifdef UNICODE_ENTITIES
       RETVAL = 1;
#else
       RETVAL = 0;
#endif
    OUTPUT:
       RETVAL


MODULE = HTML::Parser		PACKAGE = HTML::Parser
