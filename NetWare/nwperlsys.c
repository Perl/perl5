/*
 * Copyright © 2001 Novell, Inc. All Rights Reserved.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the README file.
 *
 */

/*
 * FILENAME     :   nwperlsys.c
 * DESCRIPTION  :   Contains calls to Perl APIs and
 *                  utility functions calls
 *                  
 * Author       :   SGP
 * Date Created :   June 12th 2001.
 * Date Modified:   June 26th 2001.
 */

#include "EXTERN.h"
#include "perl.h"


#ifdef PERL_OBJECT
#define NO_XSLOCKS
#endif

//CHKSGP
//Including this is giving premature end-of-file error during compilation
//#include "XSUB.h"

#ifdef PERL_IMPLICIT_SYS

//Includes iperlsys.h and function definitions
#include "nwperlsys.h"

/*============================================================================================

 Function		:	fnFreeMemEntry

 Description	:	Called for each outstanding memory allocation at the end of a script run.
					Frees the outstanding allocations

 Parameters 	:	ptr	(IN).
					context (IN)

 Returns		:	Nothing.

==============================================================================================*/

void fnFreeMemEntry(void* ptr, void* context)
{
	if(ptr)
	{
		PerlMemFree(NULL, ptr);
	}
}
/*============================================================================================

 Function		:	fnAllocListHash

 Description	:	Hashing function for hash table of memory allocations.

 Parameters 	:	invalue	(IN).

 Returns		:	unsigned.

==============================================================================================*/

unsigned fnAllocListHash(void* const& invalue)
{
    return (((unsigned) invalue & 0x0000ff00) >> 8);
}

/*============================================================================================

 Function		:	perl_alloc

 Description	:	creates a Perl interpreter variable and initializes

 Parameters 	:	none

 Returns		:	Pointer to Perl interpreter

==============================================================================================*/

EXTERN_C PerlInterpreter*
perl_alloc(void)
{
    PerlInterpreter* my_perl = NULL;

	WCValHashTable<void*>*	m_allocList;
	m_allocList = new WCValHashTable<void*> (fnAllocListHash, 256);
	fnInsertHashListAddrs(m_allocList, FALSE);

 	my_perl = perl_alloc_using(&perlMem,
				   NULL,
				   NULL,
				   &perlEnv,
				   &perlStdIO,
				   &perlLIO,
				   &perlDir,
				   &perlSock,
				   &perlProc);
	if (my_perl) {
#ifdef PERL_OBJECT
	    CPerlObj* pPerl = (CPerlObj*)my_perl;
#endif
		//nw5_internal_host = m_allocList;
	}
    return my_perl;
}

/*============================================================================================

 Function		:	perl_alloc_override

 Description	:	creates a Perl interpreter variable and initializes

 Parameters 	:	Pointer to structure containing function pointers

 Returns		:	Pointer to Perl interpreter

==============================================================================================*/
EXTERN_C PerlInterpreter*
perl_alloc_override(struct IPerlMem* ppMem, struct IPerlMem* ppMemShared,
		 struct IPerlMem* ppMemParse, struct IPerlEnv* ppEnv,
		 struct IPerlStdIO* ppStdIO, struct IPerlLIO* ppLIO,
		 struct IPerlDir* ppDir, struct IPerlSock* ppSock,
		 struct IPerlProc* ppProc)
{
    PerlInterpreter *my_perl = NULL;

	WCValHashTable<void*>*	m_allocList;
	m_allocList = new WCValHashTable<void*> (fnAllocListHash, 256);
	fnInsertHashListAddrs(m_allocList, FALSE);

	if (!ppMem)
		ppMem=&perlMem;
	if (!ppEnv)
		ppEnv=&perlEnv;
	if (!ppStdIO)
		ppStdIO=&perlStdIO;
	if (!ppLIO)
		ppLIO=&perlLIO;
	if (!ppDir)
		ppDir=&perlDir;
	if (!ppSock)
		ppSock=&perlSock;
	if (!ppProc)
		ppProc=&perlProc;

	my_perl = perl_alloc_using(ppMem,
				   ppMemShared,
				   ppMemParse,
				   ppEnv,
				   ppStdIO,
				   ppLIO,
				   ppDir,
				   ppSock,
				   ppProc);
	if (my_perl) {
#ifdef PERL_OBJECT
	    CPerlObj* pPerl = (CPerlObj*)my_perl;
#endif
	    //nw5_internal_host = pHost;
	}
    return my_perl;
}
/*============================================================================================

 Function		:	nw5_delete_internal_host

 Description	:	Deletes the alloc_list pointer

 Parameters 	:	alloc_list pointer

 Returns		:	none

==============================================================================================*/

EXTERN_C void
nw5_delete_internal_host(void *h)
{
	WCValHashTable<void*>*	m_allocList;
	void **listptr;
	BOOL m_dontTouchHashLists;
	if (fnGetHashListAddrs(&listptr,&m_dontTouchHashLists)) {
		m_allocList = (WCValHashTable<void*>*)listptr;
		fnInsertHashListAddrs(m_allocList, TRUE);
		if (m_allocList)
		{
			m_allocList->forAll(fnFreeMemEntry, NULL);
			fnInsertHashListAddrs(NULL, FALSE);
			delete m_allocList;
		}
	}
}

#endif /* PERL_IMPLICIT_SYS */
