#include "INTERN.h"
#define PERL_IN_GLOBALS_C
#include "perl.h"

#ifdef PERL_OBJECT

#undef PERLVAR
#define PERLVAR(x, y)
#undef PERLVARA
#define PERLVARA(x, n, y)
#undef PERLVARI
#define PERLVARI(x, y, z) PL_##x = z;
#undef PERLVARIC
#define PERLVARIC(x, y, z) PL_##x = z;

CPerlObj::CPerlObj(IPerlMem* ipM, IPerlEnv* ipE, IPerlStdIO* ipStd,
		   IPerlLIO* ipLIO, IPerlDir* ipD, IPerlSock* ipS,
		   IPerlProc* ipP)
{
    memset(((char*)this)+sizeof(void*), 0, sizeof(CPerlObj)-sizeof(void*));

#include "thrdvar.h"
#include "intrpvar.h"
#include "perlvars.h"

    PL_Mem = ipM;
    PL_Env = ipE;
    PL_StdIO = ipStd;
    PL_LIO = ipLIO;
    PL_Dir = ipD;
    PL_Sock = ipS;
    PL_Proc = ipP;
}

void*
CPerlObj::operator new(size_t nSize, IPerlMem *pvtbl)
{
    if(pvtbl != NULL)
	return pvtbl->pMalloc(pvtbl, nSize);

    return NULL;
}

void
CPerlObj::Init(void)
{
}

#ifdef WIN32		/* XXX why are these needed? */
bool
Perl_do_exec(char *cmd)
{
    return PerlProc_Cmd(cmd);
}

int
CPerlObj::do_aspawn(void *vreally, void **vmark, void **vsp)
{
    return PerlProc_aspawn(vreally, vmark, vsp);
}
#endif  /* WIN32 */

#endif   /* PERL_OBJECT */

int
Perl_fprintf_nocontext(PerlIO *stream, const char *format, ...)
{
    dTHX;
    va_list(arglist);
    va_start(arglist, format);
    return PerlIO_vprintf(stream, format, arglist);
}
