/*

    ipmem.h
    Interface for perl memory allocation

*/

#ifndef __Inc__IPerlMem___
#define __Inc__IPerlMem___

class IPerlMem
{
public:
    virtual void* Malloc(size_t) = 0;
    virtual void* Realloc(void*, size_t) = 0;
    virtual void Free(void*) = 0;
};

#endif	/* __Inc__IPerlMem___ */

