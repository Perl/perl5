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

    .localize_mg = &Perl_magicv2_localize_copy,
};

static const struct ScalarVarMagicFunctions magicfuncs_with_keyiv = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .flags = MGv2f_WITH_KEYIV,
    .debug_name = "XS::APItest/with_keyiv",

    .localize_mg = &Perl_magicv2_localize_copy,
};

static const struct ScalarVarMagicFunctions magicfuncs_with_keysv = {
    .ver   = 2,
    .shape = MGv2s_SCALARVAR,
    .flags = MGv2f_WITH_KEYSV,
    .debug_name = "XS::APItest/with_keysv",

    .localize_mg = &Perl_magicv2_localize_copy,
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

    .localize_mg = &Perl_magicv2_localize_copy,
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

    .localize_mg = &Perl_magicv2_localize_copy,
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

static const struct MagicFunctions *S_magicfuncs_by_name(pTHX_ SV *name)
{
    char *namepv = SvPV_nolen(name);
    if(strEQ(namepv, "empty"))           return &magicfuncs_empty;
    if(strEQ(namepv, "weak"))            return &magicfuncs_weak;
    if(strEQ(namepv, "container_empty")) return (struct MagicFunctions *)&magicfuncs_container_empty;
    if(strEQ(namepv, "with_keyiv"))      return (struct MagicFunctions *)&magicfuncs_with_keyiv;
    if(strEQ(namepv, "with_keysv"))      return (struct MagicFunctions *)&magicfuncs_with_keysv;
    if(strEQ(namepv, "inc_on_free"))     return &magicfuncs_inc_on_free;
    if(strEQ(namepv, "inc_on_clone"))    return &magicfuncs_inc_on_clone;
    if(strEQ(namepv, "userstruct"))      return (struct MagicFunctions *)&magicfuncs_userstruct;
    if(strEQ(namepv, "grab_before_get")) return (struct MagicFunctions *)&magicfuncs_grab_before_get;
    if(strEQ(namepv, "inc_after_set"))   return (struct MagicFunctions *)&magicfuncs_inc_after_set;
    if(strEQ(namepv, "inc_after_clear_arr"))  return (struct MagicFunctions *)&magicfuncs_inc_after_clear_arr;
    if(strEQ(namepv, "inc_after_clear_hash")) return (struct MagicFunctions *)&magicfuncs_inc_after_clear_hash;
    croak("Unrecognised magicfuncs name %" SVf, SVfARG(name));
}
