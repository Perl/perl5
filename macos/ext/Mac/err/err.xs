#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = Mac::err		PACKAGE = Mac::err

void
Mac_err_Unix()
	CODE:
		gMacPerl_ErrorFormat = 0;

void
Mac_err_MPW()
	CODE:
		gMacPerl_ErrorFormat = 1;
