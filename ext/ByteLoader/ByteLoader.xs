#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef WIN32
/* this is probably not needed manywhere */
#  include "byterun.c"
#endif

/* defgv must be accessed differently under threaded perl */
/* DEFSV et al are in 5.004_56 */
#ifndef DEFSV
#define DEFSV		GvSV(defgv)
#endif

static I32
#ifdef PERL_OBJECT
byteloader_filter(CPerlObj *pPerl, int idx, SV *buf_sv, int maxlen)
#else
byteloader_filter(int idx, SV *buf_sv, int maxlen)
#endif
{
    dTHR;
    OP *saveroot = PL_main_root;
    OP *savestart = PL_main_start;

#ifdef INDIRECT_BGET_MACROS
    struct bytesream bs;

    bs.data = PL_rsfp;
    bs.fgetc = (int(*) _((void*)))fgetc;
    bs.fread = (int(*) _((char*,size_t,size_t,void*)))fread;
    bs.freadpv = freadpv;
#else
    byterun(PL_rsfp);
#endif

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
