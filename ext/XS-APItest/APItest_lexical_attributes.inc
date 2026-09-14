static void
S_apply_attribute_red(pTHX_
    struct PerlAttributeTarget *target,
    SV *attrvalue, void *data)
{
    PERL_UNUSED_ARG(data);

    SV *keysv = newSVpvs_flags("red/", SVs_TEMP);

    /* TODO: it'd be great if `sub named :attrs.... { }` already knew the CvGV
     * of the name during parse time. I'll look into it. For now lets just use
     * the CV refaddr
     */

    switch(target->kind) {
        case PERL_ATTRTARGET_SV:
        {
            SV *sv = target->sv;
            if(SvTYPE(sv) == SVt_PVCV && CvNAMED((CV *)sv)) {
                sv_catpvf(keysv, "%" UVxf "=%" HEKf, PTR2UV(sv), HEKfARG(CvNAME_HEK((CV *)sv)));
            }
            else
                sv_catpvf(keysv, "%" UVxf, PTR2UV(sv));
            break;
        }

        case PERL_ATTRTARGET_PKGSCOPED:
        {
            switch(SvTYPE(target->pkgscoped.sv)) {
                case SVt_PVAV: sv_catpvs(keysv, "@"); break;
                case SVt_PVCV: sv_catpvs(keysv, "&"); break;
                case SVt_PVHV: sv_catpvs(keysv, "%"); break;
                default:       sv_catpvs(keysv, "$"); break;
            }
            GV *gv = target->pkgscoped.namegv;
            HV *stash = GvSTASH(gv);
            sv_catpvn(keysv, HvNAME(stash), HvNAMELEN(stash));
            sv_catpvs(keysv, "::");
            sv_catpvn(keysv, GvNAME(gv), GvNAMELEN(gv));
            break;
        }

        case PERL_ATTRTARGET_LEXICAL:
            sv_catpvf(keysv, "my %" PNf, PNfARG(target->lexical.padname));
            break;

        default:
            croak("Unsure how to apply :red to a non-package scoped target");
    }

    HV *applied_hv = get_hv("main::ATTRIBUTES_APPLIED", GV_ADD);
    hv_store_ent(applied_hv, keysv, newSVsv(attrvalue), 0);
}

static const struct PerlAttributeDefinition attribute_red = {
    .flags = PERL_ATTRf_MAY_VALUE,
    .apply = &S_apply_attribute_red,
};
