/*    universal.c
 *
 *    Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004,
 *    2005, 2006, 2007 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "The roots of those mountains must be roots indeed; there must be
 * great secrets buried there which have not been discovered since the
 * beginning." --Gandalf, relating Gollum's story
 */

/* This file contains the code that implements the functions in Perl's
 * UNIVERSAL package, such as UNIVERSAL->can().
 */

#include "EXTERN.h"
#define PERL_IN_UNIVERSAL_C
#include "perl.h"

#ifdef USE_PERLIO
#include "perliol.h" /* For the PERLIO_F_XXX */
#endif

/*
 * Contributed by Graham Barr  <Graham.Barr@tiuk.ti.com>
 * The main guts of traverse_isa was actually copied from gv_fetchmeth
 */

STATIC bool
S_isa_lookup(pTHX_ HV *stash, const char *name, const HV* const name_stash,
             int len, int level)
{
    dVAR;
    AV* av;
    GV* gv;
    GV** gvp;
    HV* hv = NULL;
    SV* subgen = NULL;
    const char *hvname;

    /* A stash/class can go by many names (ie. User == main::User), so 
       we compare the stash itself just in case */
    if (name_stash && ((const HV *)stash == name_stash))
        return TRUE;

    hvname = HvNAME_get(stash);

    if (strEQ(hvname, name))
	return TRUE;

    if (strEQ(name, "UNIVERSAL"))
	return TRUE;

    if (level > 100)
	Perl_croak(aTHX_ "Recursive inheritance detected in package '%s'",
		   hvname);

    gvp = (GV**)hv_fetchs(stash, "::ISA::CACHE::", FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (subgen = GvSV(gv))
	&& (hv = GvHV(gv)))
    {
	if (SvIV(subgen) == (IV)PL_sub_generation) {
	    SV** const svp = (SV**)hv_fetch(hv, name, len, FALSE);
	    if (svp) {
		SV * const sv = *svp;
#ifdef DEBUGGING
		if (sv != &PL_sv_undef)
		    DEBUG_o( Perl_deb(aTHX_ "Using cached ISA %s for package %s\n",
				    name, hvname) );
#endif
		return (sv == &PL_sv_yes);
	    }
	}
	else {
	    DEBUG_o( Perl_deb(aTHX_ "ISA Cache in package %s is stale\n",
			      hvname) );
	    hv_clear(hv);
	    sv_setiv(subgen, PL_sub_generation);
	}
    }

    gvp = (GV**)hv_fetchs(stash, "ISA", FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if (!hv || !subgen) {
	    gvp = (GV**)hv_fetchs(stash, "::ISA::CACHE::", TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    if (!hv)
		hv = GvHVn(gv);
	    if (!subgen) {
		subgen = newSViv(PL_sub_generation);
		GvSV(gv) = subgen;
	    }
	}
	if (hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied ISA */
	    I32 items = AvFILLp(av) + 1;
	    while (items--) {
		SV* const sv = *svp++;
		HV* const basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
				    "Can't locate package %"SVf" for @%s::ISA",
				    SVfARG(sv), hvname);
		    continue;
		}
		if (isa_lookup(basestash, name, name_stash, len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return TRUE;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }
    return FALSE;
}

/*
=head1 SV Manipulation Functions

=for apidoc sv_derived_from

Returns a boolean indicating whether the SV is derived from the specified class
I<at the C level>.  To check derivation at the Perl level, call C<isa()> as a
normal Perl method.

=cut
*/

bool
Perl_sv_derived_from(pTHX_ SV *sv, const char *name)
{
    dVAR;
    HV *stash;

    SvGETMAGIC(sv);

    if (SvROK(sv)) {
	const char *type;
        sv = SvRV(sv);
        type = sv_reftype(sv,0);
	if (type && strEQ(type,name))
	    return TRUE;
	stash = SvOBJECT(sv) ? SvSTASH(sv) : NULL;
    }
    else {
        stash = gv_stashsv(sv, FALSE);
    }

    if (stash) {
	HV * const name_stash = gv_stashpv(name, FALSE);
	return isa_lookup(stash, name, name_stash, strlen(name), 0);
    }
    else
	return FALSE;

}

/*
=for apidoc sv_does

Returns a boolean indicating whether the SV performs a specific, named role.
The SV can be a Perl object or the name of a Perl class.

=cut
*/

#include "XSUB.h"

bool
Perl_sv_does(pTHX_ SV *sv, const char *name)
{
    const char *classname;
    bool does_it;

    dSP;
    ENTER;
    SAVETMPS;

    SvGETMAGIC(sv);

    if (!SvOK(sv) || !(SvROK(sv) || (SvPOK(sv) && SvCUR(sv))
		|| (SvGMAGICAL(sv) && SvPOKp(sv) && SvCUR(sv))))
	return FALSE;

    if (sv_isobject(sv)) {
	classname = sv_reftype(SvRV(sv),TRUE);
    } else {
	classname = SvPV(sv,PL_na);
    }

    if (strEQ(name,classname))
	return TRUE;

    PUSHMARK(SP);
    XPUSHs(sv);
    XPUSHs(sv_2mortal(newSVpv(name, 0)));
    PUTBACK;

    call_method("isa", G_SCALAR);
    SPAGAIN;

    does_it = SvTRUE( TOPs );
    FREETMPS;
    LEAVE;

    return does_it;
}

PERL_XS_EXPORT_C void XS_UNIVERSAL_isa(pTHX_ CV *cv);
PERL_XS_EXPORT_C void XS_UNIVERSAL_can(pTHX_ CV *cv);
PERL_XS_EXPORT_C void XS_UNIVERSAL_DOES(pTHX_ CV *cv);
PERL_XS_EXPORT_C void XS_UNIVERSAL_VERSION(pTHX_ CV *cv);
XS(XS_version_new);
XS(XS_version_stringify);
XS(XS_version_numify);
XS(XS_version_normal);
XS(XS_version_vcmp);
XS(XS_version_boolean);
#ifdef HASATTRIBUTE_NORETURN
XS(XS_version_noop) __attribute__noreturn__;
#else
XS(XS_version_noop);
#endif
XS(XS_version_is_alpha);
XS(XS_version_qv);
XS(XS_utf8_is_utf8);
XS(XS_utf8_valid);
XS(XS_utf8_encode);
XS(XS_utf8_decode);
XS(XS_utf8_upgrade);
XS(XS_utf8_downgrade);
XS(XS_utf8_unicode_to_native);
XS(XS_utf8_native_to_unicode);
XS(XS_Internals_SvREADONLY);
XS(XS_Internals_SvREFCNT);
XS(XS_Internals_hv_clear_placehold);
XS(XS_PerlIO_get_layers);
XS(XS_Regexp_DESTROY);
XS(XS_Internals_hash_seed);
XS(XS_Internals_rehash_seed);
XS(XS_Internals_HvREHASH);
XS(XS_Internals_inc_sub_generation);

void
Perl_boot_core_UNIVERSAL(pTHX)
{
    dVAR;
    static const char file[] = __FILE__;

    newXS("UNIVERSAL::isa",             XS_UNIVERSAL_isa,         file);
    newXS("UNIVERSAL::can",             XS_UNIVERSAL_can,         file);
    newXS("UNIVERSAL::DOES",            XS_UNIVERSAL_DOES,        file);
    newXS("UNIVERSAL::VERSION", 	XS_UNIVERSAL_VERSION, 	  file);
    {
	/* register the overloading (type 'A') magic */
	PL_amagic_generation++;
	/* Make it findable via fetchmethod */
	newXS("version::()", XS_version_noop, file);
	newXS("version::new", XS_version_new, file);
	newXS("version::(\"\"", XS_version_stringify, file);
	newXS("version::stringify", XS_version_stringify, file);
	newXS("version::(0+", XS_version_numify, file);
	newXS("version::numify", XS_version_numify, file);
	newXS("version::normal", XS_version_normal, file);
	newXS("version::(cmp", XS_version_vcmp, file);
	newXS("version::(<=>", XS_version_vcmp, file);
	newXS("version::vcmp", XS_version_vcmp, file);
	newXS("version::(bool", XS_version_boolean, file);
	newXS("version::boolean", XS_version_boolean, file);
	newXS("version::(nomethod", XS_version_noop, file);
	newXS("version::noop", XS_version_noop, file);
	newXS("version::is_alpha", XS_version_is_alpha, file);
	newXS("version::qv", XS_version_qv, file);
    }
    newXS("utf8::is_utf8", XS_utf8_is_utf8, file);
    newXS("utf8::valid", XS_utf8_valid, file);
    newXS("utf8::encode", XS_utf8_encode, file);
    newXS("utf8::decode", XS_utf8_decode, file);
    newXS("utf8::upgrade", XS_utf8_upgrade, file);
    newXS("utf8::downgrade", XS_utf8_downgrade, file);
    newXS("utf8::native_to_unicode", XS_utf8_native_to_unicode, file);
    newXS("utf8::unicode_to_native", XS_utf8_unicode_to_native, file);
    newXSproto("Internals::SvREADONLY",XS_Internals_SvREADONLY, file, "\\[$%@];$");
    newXSproto("Internals::SvREFCNT",XS_Internals_SvREFCNT, file, "\\[$%@];$");
    newXSproto("Internals::hv_clear_placeholders",
               XS_Internals_hv_clear_placehold, file, "\\%");
    newXSproto("PerlIO::get_layers",
               XS_PerlIO_get_layers, file, "*;@");
    newXS("Regexp::DESTROY", XS_Regexp_DESTROY, file);
    newXSproto("Internals::hash_seed",XS_Internals_hash_seed, file, "");
    newXSproto("Internals::rehash_seed",XS_Internals_rehash_seed, file, "");
    newXSproto("Internals::HvREHASH", XS_Internals_HvREHASH, file, "\\%");
    newXSproto("Internals::inc_sub_generation",XS_Internals_inc_sub_generation,
	       file, "");
}


XS(XS_UNIVERSAL_isa)
{
    dVAR;
    dXSARGS;

    if (items != 2)
	Perl_croak(aTHX_ "Usage: UNIVERSAL::isa(reference, kind)");
    else {
	SV * const sv = ST(0);
	const char *name;

	SvGETMAGIC(sv);

	if (!SvOK(sv) || !(SvROK(sv) || (SvPOK(sv) && SvCUR(sv))
		    || (SvGMAGICAL(sv) && SvPOKp(sv) && SvCUR(sv))))
	    XSRETURN_UNDEF;

	name = SvPV_nolen_const(ST(1));

	ST(0) = boolSV(sv_derived_from(sv, name));
	XSRETURN(1);
    }
}

XS(XS_UNIVERSAL_can)
{
    dVAR;
    dXSARGS;
    SV   *sv;
    const char *name;
    SV   *rv;
    HV   *pkg = NULL;

    if (items != 2)
	Perl_croak(aTHX_ "Usage: UNIVERSAL::can(object-ref, method)");

    sv = ST(0);

    SvGETMAGIC(sv);

    if (!SvOK(sv) || !(SvROK(sv) || (SvPOK(sv) && SvCUR(sv))
		|| (SvGMAGICAL(sv) && SvPOKp(sv) && SvCUR(sv))))
	XSRETURN_UNDEF;

    name = SvPV_nolen_const(ST(1));
    rv = &PL_sv_undef;

    if (SvROK(sv)) {
        sv = (SV*)SvRV(sv);
        if (SvOBJECT(sv))
            pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(sv, FALSE);
    }

    if (pkg) {
	GV * const gv = gv_fetchmethod_autoload(pkg, name, FALSE);
        if (gv && isGV(gv))
	    rv = sv_2mortal(newRV((SV*)GvCV(gv)));
    }

    ST(0) = rv;
    XSRETURN(1);
}

XS(XS_UNIVERSAL_DOES)
{
    dVAR;
    dXSARGS;

    if (items != 2)
	Perl_croak(aTHX_ "Usage: invocant->does(kind)");
    else {
	SV * const sv = ST(0);
	const char *name;

	name = SvPV_nolen_const(ST(1));
	if (sv_does( sv, name ))
	    XSRETURN_YES;

	XSRETURN_NO;
    }
}

XS(XS_UNIVERSAL_VERSION)
{
    dVAR;
    dXSARGS;
    HV *pkg;
    GV **gvp;
    GV *gv;
    SV *sv;
    const char *undef;

    if (SvROK(ST(0))) {
        sv = (SV*)SvRV(ST(0));
        if (!SvOBJECT(sv))
            Perl_croak(aTHX_ "Cannot find version of an unblessed reference");
        pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(ST(0), FALSE);
    }

    gvp = pkg ? (GV**)hv_fetchs(pkg, "VERSION", FALSE) : NULL;

    if (gvp && isGV(gv = *gvp) && (sv = GvSV(gv)) && SvOK(sv)) {
        SV * const nsv = sv_newmortal();
        sv_setsv(nsv, sv);
        sv = nsv;
	if ( !sv_derived_from(sv, "version"))
	    upg_version(sv);
        undef = NULL;
    }
    else {
        sv = (SV*)&PL_sv_undef;
        undef = "(undef)";
    }

    if (items > 1) {
	SV *req = ST(1);

	if (undef) {
	    if (pkg) {
		const char * const name = HvNAME_get(pkg);
		Perl_croak(aTHX_
			   "%s does not define $%s::VERSION--version check failed",
			   name, name);
	    } else {
		Perl_croak(aTHX_
			     "%s defines neither package nor VERSION--version check failed",
			     SvPVx_nolen_const(ST(0)) );
	     }
	}

	if ( !sv_derived_from(req, "version")) {
	    /* req may very well be R/O, so create a new object */
	    SV * const nsv = sv_newmortal();
	    sv_setsv(nsv, req);
	    req = nsv;
	    upg_version(req);
	}

	if ( vcmp( req, sv ) > 0 )
	    Perl_croak(aTHX_ "%s version %"SVf" (%"SVf") required--"
		       "this is only version %"SVf" (%"SVf")", HvNAME_get(pkg),
		       SVfARG(vnumify(req)),
		       SVfARG(vnormal(req)),
		       SVfARG(vnumify(sv)),
		       SVfARG(vnormal(sv)));
    }

    if ( SvOK(sv) && sv_derived_from(sv, "version") ) {
	ST(0) = vnumify(sv);
    } else {
	ST(0) = sv;
    }

    XSRETURN(1);
}

XS(XS_version_new)
{
    dVAR;
    dXSARGS;
    if (items > 3)
	Perl_croak(aTHX_ "Usage: version::new(class, version)");
    SP -= items;
    {
        SV *vs = ST(1);
	SV *rv;
	const char * const classname =
	    sv_isobject(ST(0)) /* get the class if called as an object method */
		? HvNAME(SvSTASH(SvRV(ST(0))))
		: (char *)SvPV_nolen(ST(0));

	if ( items == 1 || vs == &PL_sv_undef ) { /* no param or explicit undef */
	    /* create empty object */
	    vs = sv_newmortal();
	    sv_setpvn(vs,"",0);
	}
	else if ( items == 3 ) {
	    vs = sv_newmortal();
	    Perl_sv_setpvf(aTHX_ vs,"v%s",SvPV_nolen_const(ST(2)));
	}

	rv = new_version(vs);
	if ( strcmp(classname,"version") != 0 ) /* inherited new() */
	    sv_bless(rv, gv_stashpv(classname,TRUE));

	PUSHs(sv_2mortal(rv));
	PUTBACK;
	return;
    }
}

XS(XS_version_stringify)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	  Perl_croak(aTHX_ "Usage: version::stringify(lobj, ...)");
     SP -= items;
     {
	  SV *	lobj;

	  if (sv_derived_from(ST(0), "version")) {
	       lobj = SvRV(ST(0));
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  PUSHs(sv_2mortal(vstringify(lobj)));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_numify)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	  Perl_croak(aTHX_ "Usage: version::numify(lobj, ...)");
     SP -= items;
     {
	  SV *	lobj;

	  if (sv_derived_from(ST(0), "version")) {
	       lobj = SvRV(ST(0));
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  PUSHs(sv_2mortal(vnumify(lobj)));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_normal)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	  Perl_croak(aTHX_ "Usage: version::normal(lobj, ...)");
     SP -= items;
     {
	  SV *	lobj;

	  if (sv_derived_from(ST(0), "version")) {
	       lobj = SvRV(ST(0));
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  PUSHs(sv_2mortal(vnormal(lobj)));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_vcmp)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	  Perl_croak(aTHX_ "Usage: version::vcmp(lobj, ...)");
     SP -= items;
     {
	  SV *	lobj;

	  if (sv_derived_from(ST(0), "version")) {
	       lobj = SvRV(ST(0));
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  {
	       SV	*rs;
	       SV	*rvs;
	       SV * robj = ST(1);
	       const IV	 swap = (IV)SvIV(ST(2));

	       if ( ! sv_derived_from(robj, "version") )
	       {
		    robj = new_version(robj);
	       }
	       rvs = SvRV(robj);

	       if ( swap )
	       {
		    rs = newSViv(vcmp(rvs,lobj));
	       }
	       else
	       {
		    rs = newSViv(vcmp(lobj,rvs));
	       }

	       PUSHs(sv_2mortal(rs));
	  }

	  PUTBACK;
	  return;
     }
}

XS(XS_version_boolean)
{
    dVAR;
    dXSARGS;
    if (items < 1)
	Perl_croak(aTHX_ "Usage: version::boolean(lobj, ...)");
    SP -= items;
    if (sv_derived_from(ST(0), "version")) {
	SV * const lobj = SvRV(ST(0));
	SV * const rs = newSViv( vcmp(lobj,new_version(newSVpvs("0"))) );
	PUSHs(sv_2mortal(rs));
	PUTBACK;
	return;
    }
    else
	Perl_croak(aTHX_ "lobj is not of type version");
}

XS(XS_version_noop)
{
    dVAR;
    dXSARGS;
    if (items < 1)
	Perl_croak(aTHX_ "Usage: version::noop(lobj, ...)");
    if (sv_derived_from(ST(0), "version"))
	Perl_croak(aTHX_ "operation not supported with version object");
    else
	Perl_croak(aTHX_ "lobj is not of type version");
#ifndef HASATTRIBUTE_NORETURN
    XSRETURN_EMPTY;
#endif
}

XS(XS_version_is_alpha)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: version::is_alpha(lobj)");
    SP -= items;
    if (sv_derived_from(ST(0), "version")) {
	SV * const lobj = ST(0);
	if ( hv_exists((HV*)SvRV(lobj), "alpha", 5 ) )
	    XSRETURN_YES;
	else
	    XSRETURN_NO;
	PUTBACK;
	return;
    }
    else
	Perl_croak(aTHX_ "lobj is not of type version");
}

XS(XS_version_qv)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: version::qv(ver)");
    SP -= items;
    {
	SV *	ver = ST(0);
	if ( !SvVOK(ver) ) { /* only need to do with if not already v-string */
	    SV * const vs = sv_newmortal();
	    char *version;
	    if ( SvNOK(ver) ) /* may get too much accuracy */
	    {
		char tbuf[64];
#ifdef USE_LOCALE_NUMERIC
		char *loc = setlocale(LC_NUMERIC, "C");
#endif
		STRLEN len = my_snprintf(tbuf, sizeof(tbuf), "%.9"NVgf, SvNVX(ver));
#ifdef USE_LOCALE_NUMERIC
		setlocale(LC_NUMERIC, loc);
#endif
		while (tbuf[len-1] == '0' && len > 0) len--;
		version = savepvn(tbuf, len);
	    }
	    else
	    {
		version = savesvpv(ver);
	    }
	    (void)scan_version(version,vs,TRUE);
	    Safefree(version);

	    PUSHs(vs);
	}
	else
	{
	    PUSHs(sv_2mortal(new_version(ver)));
	}

	PUTBACK;
	return;
    }
}

XS(XS_utf8_is_utf8)
{
     dVAR;
     dXSARGS;
     if (items != 1)
	  Perl_croak(aTHX_ "Usage: utf8::is_utf8(sv)");
     else {
	const SV * const sv = ST(0);
	    if (SvUTF8(sv))
		XSRETURN_YES;
	    else
		XSRETURN_NO;
     }
     XSRETURN_EMPTY;
}

XS(XS_utf8_valid)
{
     dVAR;
     dXSARGS;
     if (items != 1)
	  Perl_croak(aTHX_ "Usage: utf8::valid(sv)");
    else {
	SV * const sv = ST(0);
	STRLEN len;
	const char * const s = SvPV_const(sv,len);
	if (!SvUTF8(sv) || is_utf8_string((const U8*)s,len))
	    XSRETURN_YES;
	else
	    XSRETURN_NO;
    }
     XSRETURN_EMPTY;
}

XS(XS_utf8_encode)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: utf8::encode(sv)");
    sv_utf8_encode(ST(0));
    XSRETURN_EMPTY;
}

XS(XS_utf8_decode)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: utf8::decode(sv)");
    else {
	SV * const sv = ST(0);
	const bool RETVAL = sv_utf8_decode(sv);
	ST(0) = boolSV(RETVAL);
	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_utf8_upgrade)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: utf8::upgrade(sv)");
    else {
	SV * const sv = ST(0);
	STRLEN	RETVAL;
	dXSTARG;

	RETVAL = sv_utf8_upgrade(sv);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_utf8_downgrade)
{
    dVAR;
    dXSARGS;
    if (items < 1 || items > 2)
	Perl_croak(aTHX_ "Usage: utf8::downgrade(sv, failok=0)");
    else {
	SV * const sv = ST(0);
        const bool failok = (items < 2) ? 0 : (int)SvIV(ST(1));
        const bool RETVAL = sv_utf8_downgrade(sv, failok);

	ST(0) = boolSV(RETVAL);
	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_utf8_native_to_unicode)
{
 dVAR;
 dXSARGS;
 const UV uv = SvUV(ST(0));

 if (items > 1)
     Perl_croak(aTHX_ "Usage: utf8::native_to_unicode(sv)");

 ST(0) = sv_2mortal(newSViv(NATIVE_TO_UNI(uv)));
 XSRETURN(1);
}

XS(XS_utf8_unicode_to_native)
{
 dVAR;
 dXSARGS;
 const UV uv = SvUV(ST(0));

 if (items > 1)
     Perl_croak(aTHX_ "Usage: utf8::unicode_to_native(sv)");

 ST(0) = sv_2mortal(newSViv(UNI_TO_NATIVE(uv)));
 XSRETURN(1);
}

XS(XS_Internals_SvREADONLY)	/* This is dangerous stuff. */
{
    dVAR;
    dXSARGS;
    SV * const sv = SvRV(ST(0));

    if (items == 1) {
	 if (SvREADONLY(sv))
	     XSRETURN_YES;
	 else
	     XSRETURN_NO;
    }
    else if (items == 2) {
	if (SvTRUE(ST(1))) {
	    SvREADONLY_on(sv);
	    XSRETURN_YES;
	}
	else {
	    /* I hope you really know what you are doing. */
	    SvREADONLY_off(sv);
	    XSRETURN_NO;
	}
    }
    XSRETURN_UNDEF; /* Can't happen. */
}

XS(XS_Internals_SvREFCNT)	/* This is dangerous stuff. */
{
    dVAR;
    dXSARGS;
    SV * const sv = SvRV(ST(0));

    if (items == 1)
	 XSRETURN_IV(SvREFCNT(sv) - 1); /* Minus the ref created for us. */
    else if (items == 2) {
         /* I hope you really know what you are doing. */
	 SvREFCNT(sv) = SvIV(ST(1));
	 XSRETURN_IV(SvREFCNT(sv));
    }
    XSRETURN_UNDEF; /* Can't happen. */
}

XS(XS_Internals_hv_clear_placehold)
{
    dVAR;
    dXSARGS;

    if (items != 1)
	Perl_croak(aTHX_ "Usage: UNIVERSAL::hv_clear_placeholders(hv)");
    else {
	HV * const hv = (HV *) SvRV(ST(0));
	hv_clear_placeholders(hv);
	XSRETURN(0);
    }
}

XS(XS_Regexp_DESTROY)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(cv);
}

XS(XS_PerlIO_get_layers)
{
    dVAR;
    dXSARGS;
    if (items < 1 || items % 2 == 0)
	Perl_croak(aTHX_ "Usage: PerlIO_get_layers(filehandle[,args])");
#ifdef USE_PERLIO
    {
	SV *	sv;
	GV *	gv;
	IO *	io;
	bool	input = TRUE;
	bool	details = FALSE;

	if (items > 1) {
	     SV * const *svp;
	     for (svp = MARK + 2; svp <= SP; svp += 2) {
		  SV * const * const varp = svp;
		  SV * const * const valp = svp + 1;
		  STRLEN klen;
		  const char * const key = SvPV_const(*varp, klen);

		  switch (*key) {
		  case 'i':
		       if (klen == 5 && memEQ(key, "input", 5)) {
			    input = SvTRUE(*valp);
			    break;
		       }
		       goto fail;
		  case 'o': 
		       if (klen == 6 && memEQ(key, "output", 6)) {
			    input = !SvTRUE(*valp);
			    break;
		       }
		       goto fail;
		  case 'd':
		       if (klen == 7 && memEQ(key, "details", 7)) {
			    details = SvTRUE(*valp);
			    break;
		       }
		       goto fail;
		  default:
		  fail:
		       Perl_croak(aTHX_
				  "get_layers: unknown argument '%s'",
				  key);
		  }
	     }

	     SP -= (items - 1);
	}

	sv = POPs;
	gv = (GV*)sv;

	if (!isGV(sv)) {
	     if (SvROK(sv) && isGV(SvRV(sv)))
		  gv = (GV*)SvRV(sv);
	     else if (SvPOKp(sv))
		  gv = gv_fetchsv(sv, 0, SVt_PVIO);
	}

	if (gv && (io = GvIO(gv))) {
	     dTARGET;
	     AV* const av = PerlIO_get_layers(aTHX_ input ?
					IoIFP(io) : IoOFP(io));
	     I32 i;
	     const I32 last = av_len(av);
	     I32 nitem = 0;
	     
	     for (i = last; i >= 0; i -= 3) {
		  SV * const * const namsvp = av_fetch(av, i - 2, FALSE);
		  SV * const * const argsvp = av_fetch(av, i - 1, FALSE);
		  SV * const * const flgsvp = av_fetch(av, i,     FALSE);

		  const bool namok = namsvp && *namsvp && SvPOK(*namsvp);
		  const bool argok = argsvp && *argsvp && SvPOK(*argsvp);
		  const bool flgok = flgsvp && *flgsvp && SvIOK(*flgsvp);

		  if (details) {
		       XPUSHs(namok
			      ? newSVpvn(SvPVX_const(*namsvp), SvCUR(*namsvp))
			      : &PL_sv_undef);
		       XPUSHs(argok
			      ? newSVpvn(SvPVX_const(*argsvp), SvCUR(*argsvp))
			      : &PL_sv_undef);
		       if (flgok)
			    XPUSHi(SvIVX(*flgsvp));
		       else
			    XPUSHs(&PL_sv_undef);
		       nitem += 3;
		  }
		  else {
		       if (namok && argok)
			    XPUSHs(Perl_newSVpvf(aTHX_ "%"SVf"(%"SVf")",
						 SVfARG(*namsvp),
						 SVfARG(*argsvp)));
		       else if (namok)
			    XPUSHs(Perl_newSVpvf(aTHX_ "%"SVf,
						 SVfARG(*namsvp)));
		       else
			    XPUSHs(&PL_sv_undef);
		       nitem++;
		       if (flgok) {
			    const IV flags = SvIVX(*flgsvp);

			    if (flags & PERLIO_F_UTF8) {
				 XPUSHs(newSVpvs("utf8"));
				 nitem++;
			    }
		       }
		  }
	     }

	     SvREFCNT_dec(av);

	     XSRETURN(nitem);
	}
    }
#endif

    XSRETURN(0);
}

XS(XS_Internals_hash_seed)
{
    dVAR;
    /* Using dXSARGS would also have dITEM and dSP,
     * which define 2 unused local variables.  */
    dAXMARK;
    PERL_UNUSED_ARG(cv);
    PERL_UNUSED_VAR(mark);
    XSRETURN_UV(PERL_HASH_SEED);
}

XS(XS_Internals_rehash_seed)
{
    dVAR;
    /* Using dXSARGS would also have dITEM and dSP,
     * which define 2 unused local variables.  */
    dAXMARK;
    PERL_UNUSED_ARG(cv);
    PERL_UNUSED_VAR(mark);
    XSRETURN_UV(PL_rehash_seed);
}

XS(XS_Internals_HvREHASH)	/* Subject to change  */
{
    dVAR;
    dXSARGS;
    if (SvROK(ST(0))) {
	const HV * const hv = (HV *) SvRV(ST(0));
	if (items == 1 && SvTYPE(hv) == SVt_PVHV) {
	    if (HvREHASH(hv))
		XSRETURN_YES;
	    else
		XSRETURN_NO;
	}
    }
    Perl_croak(aTHX_ "Internals::HvREHASH $hashref");
}

XS(XS_Internals_inc_sub_generation)
{
    dVAR;
    /* Using dXSARGS would also have dITEM and dSP,
     * which define 2 unused local variables.  */
    dAXMARK;
    PERL_UNUSED_ARG(cv);
    PERL_UNUSED_VAR(mark);
    ++PL_sub_generation;
    XSRETURN_EMPTY;
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
