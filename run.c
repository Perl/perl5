#include "EXTERN.h"
#include "perl.h"

char **watchaddr = 0;
char *watchok;

#ifndef DEBUGGING

run() {
    while ( op = (*op->op_ppaddr)() ) ;
}

#else

run() {
    if (!op) {
	warn("NULL OP IN RUN");
	return;
    }
    do {
	if (debug) {
	    if (watchaddr != 0 && *watchaddr != watchok)
		fprintf(stderr, "WARNING: %lx changed from %lx to %lx\n",
		    watchaddr, watchok, *watchaddr);
	    DEBUG_s(debstack());
	    DEBUG_t(debop(op));
	}
    } while ( op = (*op->op_ppaddr)() );
}

#endif

I32
getgimme(op)
OP *op;
{
    return cxstack[cxstack_ix].blk_gimme;
}

I32
debop(op)
OP *op;
{
    SV *sv;
    deb("%s", op_name[op->op_type]);
    switch (op->op_type) {
    case OP_CONST:
	fprintf(stderr, "(%s)", SvPEEK(cSVOP->op_sv));
	break;
    case OP_GVSV:
    case OP_GV:
	if (cGVOP->op_gv) {
	    sv = NEWSV(0,0);
	    gv_fullname(sv, cGVOP->op_gv);
	    fprintf(stderr, "(%s)", SvPV(sv, na));
	    sv_free(sv);
	}
	else
	    fprintf(stderr, "(NULL)");
	break;
    }
    fprintf(stderr, "\n");
    return 0;
}

void
watch(addr)
char **addr;
{
    watchaddr = addr;
    watchok = *addr;
    fprintf(stderr, "WATCHING, %lx is currently %lx\n",
	watchaddr, watchok);
}
