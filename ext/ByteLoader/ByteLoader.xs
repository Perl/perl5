#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "byterun.h"

static I32
byteloader_filter(pTHXo_ int idx, SV *buf_sv, int maxlen)
{
    dTHR;
    OP *saveroot = PL_main_root;
    OP *savestart = PL_main_start;

    byterun(aTHXo);

    if (PL_in_eval) {
        OP *o;

        PL_eval_start = PL_main_start;

        o = newSVOP(OP_CONST, 0, newSViv(1));
        PL_eval_root = newLISTOP(OP_LINESEQ, 0, PL_main_root, o);
        PL_main_root->op_next = o;
        PL_eval_root = newUNOP(OP_LEAVEEVAL, 0, PL_eval_root);
        o->op_next = PL_eval_root;
    
        PL_main_root = saveroot;
        PL_main_start = savestart;
    }

    return 0;
}

MODULE = ByteLoader		PACKAGE = ByteLoader

PROTOTYPES:	ENABLE

void
import(...)
  PPCODE:
    filter_add(byteloader_filter, NULL);

void
unimport(...)
  PPCODE:
    filter_del(byteloader_filter);
