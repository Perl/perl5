/* This file is part of the "version" CPAN distribution.  Please avoid
   editing it in the perl core. */

#ifdef PERL_CORE
#  define VXS_CLASS "version"
#else
#  define VXS_CLASS "version::vxs"
#endif

#ifdef VXS_XSUB_DETAILS
#  ifdef PERL_CORE
    {"UNIVERSAL::VERSION", XS_UNIVERSAL_VERSION, NULL},
#  else
    {VXS_CLASS "::_VERSION", XS_UNIVERSAL_VERSION, NULL},
#  endif
    {VXS_CLASS "::()", XS_version_noop, NULL},
    {VXS_CLASS "::new", XS_version_new, NULL},
    {VXS_CLASS "::parse", XS_version_new, NULL},
    {VXS_CLASS "::(\"\"", XS_version_stringify, NULL},
    {VXS_CLASS "::stringify", XS_version_stringify, NULL},
    {VXS_CLASS "::(0+", XS_version_numify, NULL},
    {VXS_CLASS "::numify", XS_version_numify, NULL},
    {VXS_CLASS "::normal", XS_version_normal, NULL},
    {VXS_CLASS "::(cmp", XS_version_vcmp, NULL},
    {VXS_CLASS "::(<=>", XS_version_vcmp, NULL},
#  ifdef PERL_CORE
    {VXS_CLASS "::vcmp", XS_version_vcmp, NULL},
#  else
    {VXS_CLASS "::VCMP", XS_version_vcmp, NULL},
#  endif
    {VXS_CLASS "::(bool", XS_version_boolean, NULL},
    {VXS_CLASS "::boolean", XS_version_boolean, NULL},
    {VXS_CLASS "::(+", XS_version_noop, NULL},
    {VXS_CLASS "::(-", XS_version_noop, NULL},
    {VXS_CLASS "::(*", XS_version_noop, NULL},
    {VXS_CLASS "::(/", XS_version_noop, NULL},
    {VXS_CLASS "::(+=", XS_version_noop, NULL},
    {VXS_CLASS "::(-=", XS_version_noop, NULL},
    {VXS_CLASS "::(*=", XS_version_noop, NULL},
    {VXS_CLASS "::(/=", XS_version_noop, NULL},
    {VXS_CLASS "::(abs", XS_version_noop, NULL},
    {VXS_CLASS "::(nomethod", XS_version_noop, NULL},
    {VXS_CLASS "::noop", XS_version_noop, NULL},
    {VXS_CLASS "::is_alpha", XS_version_is_alpha, NULL},
    {VXS_CLASS "::qv", XS_version_qv, NULL},
    {VXS_CLASS "::declare", XS_version_qv, NULL},
    {VXS_CLASS "::is_qv", XS_version_is_qv, NULL},
#else

#ifndef dVAR
#  define dVAR
#endif

XS(XS_UNIVERSAL_VERSION)
{
    dVAR;
    dXSARGS;
    HV *pkg;
    GV **gvp;
    GV *gv;
    SV *sv;
    const char *undef;
    PERL_UNUSED_ARG(cv);

    if (items < 1)
       Perl_croak(aTHX_ "Usage: UNIVERSAL::VERSION(sv, ...)");

    if (SvROK(ST(0))) {
        sv = MUTABLE_SV(SvRV(ST(0)));
        if (!SvOBJECT(sv))
            Perl_croak(aTHX_ "Cannot find version of an unblessed reference");
        pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(ST(0), 0);
    }

    gvp = pkg ? (GV**)hv_fetchs(pkg, "VERSION", FALSE) : NULL;

    if (gvp && isGV(gv = *gvp) && (sv = GvSV(gv)) && SvOK(sv)) {
        SV * const nsv = sv_newmortal();
        sv_setsv(nsv, sv);
        sv = nsv;
	if ( !sv_isobject(sv) || !sv_derived_from(sv, "version"))
	    upg_version(sv, FALSE);

        undef = NULL;
    }
    else {
        sv = &PL_sv_undef;
        undef = "(undef)";
    }

    if (items > 1) {
	SV *req = ST(1);

	if (undef) {
	    if (pkg) {
		const HEK * const name = HvNAME_HEK(pkg);
		Perl_croak(aTHX_
			   "%"HEKf" does not define $%"HEKf
			   "::VERSION--version check failed",
			   HEKfARG(name), HEKfARG(name));
	    } else {
		Perl_croak(aTHX_
			     "%"SVf" defines neither package nor VERSION--version check failed",
			     SVfARG(ST(0)) );
	    }
	}

	if ( !sv_isobject(req) || !sv_derived_from(req, "version")) {
	    /* req may very well be R/O, so create a new object */
	    req = sv_2mortal( new_version(req) );
	}

	if ( vcmp( req, sv ) > 0 ) {
	    if ( hv_exists(MUTABLE_HV(SvRV(req)), "qv", 2 ) ) {
		Perl_croak(aTHX_ "%"HEKf" version %"SVf" required--"
		       "this is only version %"SVf"",
                       HEKfARG(HvNAME_HEK(pkg)),
		       SVfARG(sv_2mortal(vnormal(req))),
		       SVfARG(sv_2mortal(vnormal(sv))));
	    } else {
		Perl_croak(aTHX_ "%"HEKf" version %"SVf" required--"
		       "this is only version %"SVf,
                       HEKfARG(HvNAME_HEK(pkg)),
		       SVfARG(sv_2mortal(vstringify(req))),
		       SVfARG(sv_2mortal(vstringify(sv))));
	    }
	}
    }

    if ( SvOK(sv) && sv_derived_from(sv, "version") ) {
	ST(0) = sv_2mortal(vstringify(sv));
    } else {
	ST(0) = sv;
    }

    XSRETURN(1);
}

XS(XS_version_new)
{
    dVAR;
    dXSARGS;
    if (items > 3 || items < 1)
	croak_xs_usage(cv, "class, version");
    SP -= items;
    {
        SV *vs = ST(1);
	SV *rv;
        STRLEN len;
        const char *classname;
        U32 flags;

	/* Just in case this is something like a tied hash */
	SvGETMAGIC(vs);

        if ( sv_isobject(ST(0)) ) { /* get the class if called as an object method */
            const HV * stash = SvSTASH(SvRV(ST(0)));
            classname = HvNAME(stash);
            len       = HvNAMELEN(stash);
            flags     = HvNAMEUTF8(stash) ? SVf_UTF8 : 0;
        }
        else {
	    classname = SvPV(ST(0), len);
            flags     = SvUTF8(ST(0));
        }

	if ( items == 1 || ! SvOK(vs) ) { /* no param or explicit undef */
	    /* create empty object */
	    vs = sv_newmortal();
	    sv_setpvs(vs, "0");
	}
	else if ( items == 3 ) {
	    vs = sv_newmortal();
	    Perl_sv_setpvf(aTHX_ vs,"v%s",SvPV_nolen_const(ST(2)));
	}

	rv = new_version(vs);
	if ( strnNE(classname,"version", len) ) /* inherited new() */
	    sv_bless(rv, gv_stashpvn(classname, len, GV_ADD | flags));

	mPUSHs(rv);
	PUTBACK;
	return;
    }
}

XS(XS_version_stringify)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	 croak_xs_usage(cv, "lobj, ...");
     SP -= items;
     {
	  SV *	lobj = ST(0);

	  if (sv_isobject(lobj) && sv_derived_from(lobj, "version")) {
	       lobj = SvRV(lobj);
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  mPUSHs(vstringify(lobj));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_numify)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	 croak_xs_usage(cv, "lobj, ...");
     SP -= items;
     {
	  SV *	lobj = ST(0);

	  if (sv_isobject(lobj) && sv_derived_from(lobj, "version")) {
	       lobj = SvRV(lobj);
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  mPUSHs(vnumify(lobj));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_normal)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	 croak_xs_usage(cv, "lobj, ...");
     SP -= items;
     {
	  SV *	lobj = ST(0);

	  if (sv_isobject(lobj) && sv_derived_from(lobj, "version")) {
	       lobj = SvRV(lobj);
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  mPUSHs(vnormal(lobj));

	  PUTBACK;
	  return;
     }
}

XS(XS_version_vcmp)
{
     dVAR;
     dXSARGS;
     if (items < 1)
	 croak_xs_usage(cv, "lobj, ...");
     SP -= items;
     {
	  SV *	lobj = ST(0);

	  if (sv_isobject(lobj) && sv_derived_from(lobj, "version")) {
	       lobj = SvRV(lobj);
	  }
	  else
	       Perl_croak(aTHX_ "lobj is not of type version");

	  {
	       SV	*rs;
	       SV	*rvs;
	       SV * robj = ST(1);
	       const IV	 swap = (IV)SvIV(ST(2));

	       if ( !sv_isobject(robj) || !sv_derived_from(robj, "version") )
	       {
		    robj = new_version(SvOK(robj) ? robj : newSVpvs_flags("0", SVs_TEMP));
		    sv_2mortal(robj);
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

	       mPUSHs(rs);
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
	croak_xs_usage(cv, "lobj, ...");
    SP -= items;
    if (sv_isobject(ST(0)) && sv_derived_from(ST(0), "version")) {
	SV * const lobj = SvRV(ST(0));
	SV * const rs =
	    newSViv( vcmp(lobj,
			  sv_2mortal(new_version(
					sv_2mortal(newSVpvs("0"))
				    ))
			 )
		   );
	mPUSHs(rs);
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
	croak_xs_usage(cv, "lobj, ...");
    if (sv_isobject(ST(0)) && sv_derived_from(ST(0), "version"))
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
	croak_xs_usage(cv, "lobj");
    SP -= items;
    if (sv_isobject(ST(0)) && sv_derived_from(ST(0), "version")) {
	SV * const lobj = ST(0);
	if ( hv_exists(MUTABLE_HV(SvRV(lobj)), "alpha", 5 ) )
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
    PERL_UNUSED_ARG(cv);
    SP -= items;
    {
	SV * ver = ST(0);
	SV * rv;
        STRLEN len = 0;
        const char * classname = "";
        U32 flags = 0;
        if ( items == 2 ) {
	    SvGETMAGIC(ST(1));
	    if (SvOK(ST(1))) {
		ver = ST(1);
	    }
	    else {
		Perl_croak(aTHX_ "Invalid version format (version required)");
	    }
            if ( sv_isobject(ST(0)) ) { /* class called as an object method */
                const HV * stash = SvSTASH(SvRV(ST(0)));
                classname = HvNAME(stash);
                len       = HvNAMELEN(stash);
                flags     = HvNAMEUTF8(stash) ? SVf_UTF8 : 0;
            }
            else {
	       classname = SvPV(ST(0), len);
                flags     = SvUTF8(ST(0));
            }
        }
	if ( !SvVOK(ver) ) { /* not already a v-string */
	    rv = sv_newmortal();
	    sv_setsv(rv,ver); /* make a duplicate */
	    upg_version(rv, TRUE);
	} else {
	    rv = sv_2mortal(new_version(ver));
	}
	if ( items == 2
                && strnNE(classname,"version", len) ) { /* inherited new() */
	    sv_bless(rv, gv_stashpvn(classname, len, GV_ADD | flags));
        }
	PUSHs(rv);
    }
    PUTBACK;
    return;
}

XS(XS_version_is_qv)
{
    dVAR;
    dXSARGS;
    if (items != 1)
	croak_xs_usage(cv, "lobj");
    SP -= items;
    if (sv_isobject(ST(0)) && sv_derived_from(ST(0), "version")) {
	SV * const lobj = ST(0);
	if ( hv_exists(MUTABLE_HV(SvRV(lobj)), "qv", 2 ) )
	    XSRETURN_YES;
	else
	    XSRETURN_NO;
	PUTBACK;
	return;
    }
    else
	Perl_croak(aTHX_ "lobj is not of type version");
}

#endif
