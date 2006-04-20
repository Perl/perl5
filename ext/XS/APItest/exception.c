#include "EXTERN.h"
#include "perl.h"

#define NO_XSLOCKS
#include "XSUB.h"

static void throws_exception(int throw_e)
{
  if (throw_e)
    croak("boo\n");
}

int exception(int throw_e)
{
  dTHR;
  dXCPT;
  SV *caught = get_sv("XS::APItest::exception_caught", 0);

  XCPT_TRY_START {
    throws_exception(throw_e);
  } XCPT_TRY_END

  XCPT_CATCH
  {
    sv_setiv(caught, 1);
    XCPT_RETHROW;
  }

  sv_setiv(caught, 0);

  return 42;
}

