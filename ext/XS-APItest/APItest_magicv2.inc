/* Magic functions for XS::APItest::MagicV2 */

static void
magicfunc_grab_before_get(pTHX_ SV *sv, MAGIC *mg)
{
    SV *auxsv = MgAUXSV(mg);
    sv_setsv_nomg(sv, auxsv);
}

static void
magicfunc_inc_after_set(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);

    SV *auxsv = MgAUXSV(mg);
    if(auxsv)
        sv_inc(auxsv);

    /* flag to test sv_magicv2_remove during operation */
    if(MgPRIV(mg) & 0x0001) {
        sv_magicv2_remove(sv, mg);
    }
}

static void
magicfunc_inc(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);

    SV *auxsv = MgAUXSV(mg);
    if(auxsv)
        sv_inc(auxsv);
}

static void
magicfunc_inc_on_clone_clone(pTHX_ SV *nsv, MAGIC *nmg, SV *osv, MAGIC *omg, CLONE_PARAMS *params)
{
    PERL_UNUSED_ARG(nsv);
    PERL_UNUSED_ARG(osv);
    PERL_UNUSED_ARG(omg);
    PERL_UNUSED_ARG(params);

    SV *auxsv = MgAUXSV(nmg);
    if(auxsv)
        sv_inc(auxsv);
}

static OP *
magicfunc_log_pre_newcv(pTHX_ SV *cv, OP *o, MAGIC *mg)
{
    SV *var = get_sv("main::MG_LOG", GV_ADD);

    if (!SvOK(var))
        sv_setpvs(var, "");
    else
        sv_catpvs(var, ",");
    sv_catpvf(var, "pre_newcv(<%" SVf ">:cv=%s)",
            SVfARG(MgAUXSV(mg)), cv == (SV *)PL_compcv ? "PL_compcv" : "?");

    return o;
}

static MAGIC *
magicfunc_log_post_newcv(pTHX_ SV *cv, SV *compcv, MAGIC *compmg)
{
    PERL_UNUSED_ARG(cv);

    SV *var = get_sv("main::MG_LOG", GV_ADD);

    if (!SvOK(var))
        sv_setpvs(var, "");
    else
        sv_catpvs(var, ",");
    sv_catpvf(var, "post_newcv(<%" SVf ">:compcv=%s)",
            SVfARG(MgAUXSV(compmg)), compcv == (SV *)PL_compcv ? "PL_compcv" : "?");

    return NULL;
}

static OP *
magicfunc_add_one_to_expr(pTHX_ SV *cv, OP *o, MAGIC *mg)
{
    PERL_UNUSED_ARG(cv);
    PERL_UNUSED_ARG(mg);

    return newBINOP(OP_ADD, 0, o,
            newSVOP(OP_CONST, 0, newSViv(1)));
}

static MAGIC *
magicfunc_copy_clone(pTHX_ SV *nsv, SV *sv, MAGIC *mg)
{
    MAGIC *nmg = magicv2_copy(nsv, sv, mg);

    MgAUXSV_set(nmg, newSVpvs("this-is-clone"));

    return nmg;
}

static const struct MagicFunctions magicfuncs_empty = {
    .ver   = 2,
    .shape = MGv2s_BASE,
    .debug_name = "XS::APItest/empty",

    /* no funcs */
};

static const struct MagicFunctions magicfuncs_weak = {
    .ver   = 2,
    .shape = MGv2s_BASE,
    .flags = MGv2f_ALWAYS_WEAK_AUXSV,
    .debug_name = "XS::APItest/weak",

    /* no funcs */
};

static const struct ScalarVarMagicFunctions magicfuncs_container_empty = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .debug_name = "XS::APItest/container_empty",

    .localize_mg = &Perl_magicv2_copy,
};

static const struct ScalarVarMagicFunctions magicfuncs_with_keyiv = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .flags = MGv2f_WITH_KEYIV,
    .debug_name = "XS::APItest/with_keyiv",

    .localize_mg = &Perl_magicv2_copy,
};

static const struct ScalarVarMagicFunctions magicfuncs_with_keysv = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .flags = MGv2f_WITH_KEYSV,
    .debug_name = "XS::APItest/with_keysv",

    .localize_mg = &Perl_magicv2_copy,
};

static const struct MagicFunctions magicfuncs_inc_on_free = {
    .ver   = 2,
    .shape = MGv2s_BASE,
    .debug_name = "XS::APItest/inc_on_free",

    .free_mg = &magicfunc_inc,
};

static const struct MagicFunctions magicfuncs_inc_on_clone = {
    .ver   = 2,
    .shape = MGv2s_BASE,
    .debug_name = "XS::APItest/inc_on_clone",

    .clone_mg = &magicfunc_inc_on_clone_clone,
};

struct TwoIVs { IV x, y; };
static const struct ScalarVarMagicFunctions magicfuncs_userstruct = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .debug_name = "XS::APItest/userstruct",
    .user_size = sizeof(struct TwoIVs),

    .localize_mg = &Perl_magicv2_copy,
};

static const struct ScalarVarMagicFunctions magicfuncs_grab_before_get = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .debug_name = "XS::APItest/grab_before_get",

    .pre_get = &magicfunc_grab_before_get,
};

static const struct ScalarVarMagicFunctions magicfuncs_inc_after_set = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .debug_name = "XS::APItest/inc_after_set",

    .localize_mg = &Perl_magicv2_copy,
    .post_set = &magicfunc_inc_after_set,
};

static const struct ArrayVarMagicFunctions magicfuncs_inc_after_clear_arr = {
    .ver   = 2,
    .shape = MGv2s_ARRAYVAR,
    .debug_name = "XS::APItest/inc_after_clear_arr",

    .clear = &magicfunc_inc,
};

static const struct ArrayVarMagicFunctions magicfuncs_inc_after_clear_hash = {
    .ver   = 2,
    .shape = MGv2s_HASHVAR,
    .debug_name = "XS::APItest/inc_after_clear_hash",

    .clear = &magicfunc_inc,
};

static const struct CodeMagicFunctions magicfuncs_log_on_newcv = {
    .ver = 2,
    .shape = MGv2s_CODE,
    .debug_name = "XS::APItest/log_on_newcv",

    .pre_newcv  = &magicfunc_log_pre_newcv,
    .post_newcv = &magicfunc_log_post_newcv,
};

static const struct CodeMagicFunctions magicfuncs_add_one_to_expr = {
    .ver = 2,
    .shape = MGv2s_CODE,
    .debug_name = "XS::APItest/add_one_to_expr",

    .pre_newcv = &magicfunc_add_one_to_expr,
};

static const struct CodeMagicFunctions magicfuncs_copy_clonecv = {
    .ver = 2,
    .shape = MGv2s_CODE,
    .debug_name = "XS::APItest/copy_clonecv",

    .clone_cv = &magicfunc_copy_clone,
};

/* we can't make this one `static` because -Wc++-compat gets upset if we do */
extern const struct ScalarValueMagicFunctions magicfuncs_value;

static void
magicfunc_propagate(pTHX_ SV *osv, MAGIC *omg, SV *nsv, MAGIC *nmg)
{
    PERL_UNUSED_ARG(osv);

    SV *auxsv = MgAUXSV(omg);

    /* Only add this to nsv if it doesn't already have it */
    for(nmg = sv_magicv2_find_by_funcs(nsv, (const struct MagicFunctions *)&magicfuncs_value);
            nmg;
            nmg = sv_magicv2_findnext_by_funcs(nsv, (const struct MagicFunctions *)&magicfuncs_value, nmg)) {
        if(MgAUXSV(nmg) == auxsv)
            return;
    }

    sv_magicv2_add(nsv, (const struct MagicFunctions *)&magicfuncs_value, 0, SvREFCNT_inc(auxsv));
}

const struct ScalarValueMagicFunctions magicfuncs_value = {
    .ver   = 2,
    .shape = MGv2s_SCALARVALUE,
    .debug_name = "XS::APItest/value",

    .propagate = magicfunc_propagate,
};

static const struct {
  const char *name;
  const struct MagicFunctions *funcs;
} magicfuncs[] = {
  {"empty",                                         &magicfuncs_empty},
  {"weak",                                          &magicfuncs_weak},
  {"container_empty",      (struct MagicFunctions *)&magicfuncs_container_empty},
  {"with_keyiv",           (struct MagicFunctions *)&magicfuncs_with_keyiv},
  {"with_keysv",           (struct MagicFunctions *)&magicfuncs_with_keysv},
  {"inc_on_free",                                   &magicfuncs_inc_on_free},
  {"inc_on_clone",                                  &magicfuncs_inc_on_clone},
  {"userstruct",           (struct MagicFunctions *)&magicfuncs_userstruct},
  {"grab_before_get",      (struct MagicFunctions *)&magicfuncs_grab_before_get},
  {"inc_after_set",        (struct MagicFunctions *)&magicfuncs_inc_after_set},
  {"inc_after_clear_arr",  (struct MagicFunctions *)&magicfuncs_inc_after_clear_arr},
  {"inc_after_clear_hash", (struct MagicFunctions *)&magicfuncs_inc_after_clear_hash},
  {"log_on_newcv",         (struct MagicFunctions *)&magicfuncs_log_on_newcv},
  {"add_one_to_expr",      (struct MagicFunctions *)&magicfuncs_add_one_to_expr},
  {"copy_clonecv",         (struct MagicFunctions *)&magicfuncs_copy_clonecv},
  {"value",                (struct MagicFunctions *)&magicfuncs_value},
  {NULL, NULL},
};

static const struct MagicFunctions *S_magicfuncs_by_name(pTHX_ SV *name)
{
    char *namepv = SvPV_nolen(name);

    for (int i = 0; magicfuncs[i].name; i++)
        if (strEQ(namepv, magicfuncs[i].name))
            return magicfuncs[i].funcs;

    croak("Unrecognised magicfuncs name %" SVf, SVfARG(name));
}

/*
 * Local variables:
 * mode: c
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et ft=c:
 */
