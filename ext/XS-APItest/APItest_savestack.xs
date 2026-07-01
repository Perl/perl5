MODULE = XS::APItest            PACKAGE = XS::APItest::savestack

IV
get_savestack_ix()
    CODE:
        RETVAL = PL_savestack_ix;
    OUTPUT:
        RETVAL
