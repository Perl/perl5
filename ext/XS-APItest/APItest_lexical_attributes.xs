MODULE = XS::APItest            PACKAGE = XS::APItest::LexicalAttributes

void
import_attributes(SV *pkg, ...)
    CODE:
        PERL_UNUSED_ARG(pkg);

        prepare_export_lexical();
        for(int i = 1; i < items; i++) {
            const char *name = SvPV_nolen(ST(i));

            const struct PerlAttributeDefinition *attrib;
            if(strEQ(name, "red"))
                attrib = &attribute_red;
            else
                croak("Unrecognised attribute name '%s' to import", name);

            SV *namesv = sv_2mortal(newSVpvf(":%s", name));
            export_lexical(namesv, sv_2mortal(newSVattrdefinition(attrib)));
        }
        finish_export_lexical();
