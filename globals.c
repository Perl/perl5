#include "INTERN.h"
#define PERL_IN_GLOBALS_C
#include "perl.h"

#ifdef PERL_OBJECT

#undef PERLVAR
#define PERLVAR(x, y)
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

    PL_piMem = ipM;
    PL_piENV = ipE;
    PL_piStdIO = ipStd;
    PL_piLIO = ipLIO;
    PL_piDir = ipD;
    PL_piSock = ipS;
    PL_piProc = ipP;
}

void*
CPerlObj::operator new(size_t nSize, IPerlMem *pvtbl)
{
    if(pvtbl != NULL)
	return pvtbl->Malloc(nSize);

    return NULL;
}

int&
CPerlObj::ErrorNo(void)
{
    return errno;
}

void
CPerlObj::Init(void)
{
}

#endif   /* PERL_OBJECT */
