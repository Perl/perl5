#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "byterun.h"

static void
freadpv(U32 len, void *data, XPV *pv)
{
    New(666, pv->xpv_pv, len, char);
    fread(pv->xpv_pv, 1, len, (FILE*)data);
    pv->xpv_len = len;
    pv->xpv_cur = len - 1;
}

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
    struct bytestream bs;

    bs.data = PL_rsfp;
    bs.fgetc = (int(*) _((void*)))fgetc;
    bs.fread = (int(*) _((char*,size_t,size_t,void*)))fread;
    bs.freadpv = freadpv;

    byterun(bs);

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
