MODULE = XS::APItest            PACKAGE = XS::APItest::global_locale

char *
switch_to_global_and_setlocale(int category, const char * locale)
    CODE:
        switch_to_global_locale();
        RETVAL = setlocale(category, locale);
    OUTPUT:
        RETVAL

bool
sync_locale()
    CODE:
        RETVAL = sync_locale();
    OUTPUT:
        RETVAL

NV
newSvNV(const char * string)
    CODE:
        RETVAL = SvNV(newSVpv(string, 0));
    OUTPUT:
        RETVAL
