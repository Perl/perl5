MODULE = XS::APItest PACKAGE = XS::APItest::AUTOLOADtest

int
AUTOLOAD(...)
  INIT:
    SV* comms;
    SV* class_and_method;
  CODE:
    PERL_UNUSED_ARG(items);
    class_and_method = GvSV(CvGV(cv));
    comms = get_sv("main::the_method", 1);
    if (class_and_method == NULL) {
      RETVAL = 1;
    } else if (!SvOK(class_and_method)) {
      RETVAL = 2;
    } else if (!SvPOK(class_and_method)) {
      RETVAL = 3;
    } else {
      sv_setsv(comms, class_and_method);
      RETVAL = 0;
    }
  OUTPUT: RETVAL
