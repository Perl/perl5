/*

	ipmem.c
	Interface for perl memory allocation

*/

#include <ipmem.h>

class CPerlMem : public IPerlMem
{
public:
	CPerlMem() { pPerl = NULL; };
	virtual void* Malloc(size_t);
	virtual void* Realloc(void*, size_t);
	virtual void Free(void*);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
protected:
	CPerlObj *pPerl;
};

void* CPerlMem::Malloc(size_t size)
{
	return malloc(size);
}

void* CPerlMem::Realloc(void* ptr, size_t size)
{
	return realloc(ptr, size);
}

void CPerlMem::Free(void* ptr)
{
	free(ptr);
}



